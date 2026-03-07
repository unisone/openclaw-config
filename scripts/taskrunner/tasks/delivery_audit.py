#!/usr/bin/env python3
"""Cron delivery audit.

Goal: prevent silent failures when deliveries point to the wrong platform/channel.
"""

import json
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Set

from .base import Task


class DeliveryAuditTask(Task):
    @property
    def name(self) -> str:
        return "delivery_audit"

    @property
    def description(self) -> str:
        return "Validate enabled cron job delivery targets against current Slack allowlist"

    def _load_allowed_slack_channels(self) -> Set[str]:
        config_path = Path("$HOME/.openclaw/openclaw.json")
        try:
            data = json.loads(config_path.read_text())
        except Exception:
            return set()

        slack = (data.get("channels") or {}).get("slack") or {}
        chans = slack.get("channels") or {}
        if isinstance(chans, dict):
            return set(chans.keys())
        return set()

    def run(self) -> Dict[str, Any]:
        allowed_channels = self._load_allowed_slack_channels()

        result = subprocess.run(
            ["openclaw", "cron", "list", "--json"],
            capture_output=True,
            text=True,
            timeout=15,
        )
        if result.returncode != 0:
            return {
                "success": False,
                "message": f"delivery_audit: failed to list cron jobs: {result.stderr}",
            }

        try:
            cron_data = json.loads(result.stdout)
        except json.JSONDecodeError:
            return {
                "success": False,
                "message": "delivery_audit: failed to parse cron list JSON",
            }

        jobs: List[Dict[str, Any]] = []
        if isinstance(cron_data, dict) and isinstance(cron_data.get("jobs"), list):
            jobs = [j for j in cron_data["jobs"] if isinstance(j, dict)]
        elif isinstance(cron_data, list):
            jobs = [j for j in cron_data if isinstance(j, dict)]

        problems: List[Dict[str, str]] = []

        for job in jobs:
            if not job.get("enabled", False):
                continue

            delivery = job.get("delivery")
            # No delivery configured is fine (some jobs emit system events into main session).
            if delivery is None:
                continue
            if not isinstance(delivery, dict):
                continue

            mode = delivery.get("mode")
            if mode == "none":
                continue

            channel = delivery.get("channel")
            to = delivery.get("to")

            # If delivery object exists but is incomplete, flag it.
            if not channel:
                problems.append({"job": job.get("name", "<unnamed>"), "issue": "delivery.channel missing"})
                continue

            if channel != "slack":
                problems.append({"job": job.get("name", "<unnamed>"), "issue": f"delivery.channel={channel} (expected slack)"})
                continue

            if not to:
                problems.append({"job": job.get("name", "<unnamed>"), "issue": "delivery.to missing"})
                continue

            if isinstance(to, str) and to.startswith("channel:") and allowed_channels:
                chan_id = to.split("channel:", 1)[1]
                if chan_id not in allowed_channels:
                    problems.append({"job": job.get("name", "<unnamed>"), "issue": f"delivery.to={to} not in slack allowlist"})

        if problems:
            lines = [f"- {p['job']}: {p['issue']}" for p in problems[:10]]
            more = "" if len(problems) <= 10 else f" (+{len(problems)-10} more)"
            self.alert(
                "Cron delivery audit: found delivery config issues:\n" + "\n".join(lines) + more,
                level="warning",
            )

        return {
            "success": True,
            "message": f"delivery_audit: checked {len([j for j in jobs if j.get('enabled')])} enabled jobs; issues={len(problems)}",
            "enabled_jobs": len([j for j in jobs if j.get("enabled")]),
            "issues": problems,
        }
