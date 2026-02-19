#!/usr/bin/env python3
"""System health check task."""

import json
import shutil
import subprocess
from pathlib import Path
from typing import Any, Dict, List

from .base import Task


class SystemHealthTask(Task):
    """Quick system health check."""
    
    @property
    def name(self) -> str:
        return "system_health"
    
    @property
    def description(self) -> str:
        return "Check OpenClaw gateway, disk space, and cron job health"
    
    def _check_gateway(self) -> Dict[str, Any]:
        """Check if OpenClaw gateway is running."""
        try:
            result = subprocess.run(
                ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "http://localhost:18789"],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            status_code = result.stdout.strip()
            is_running = status_code.startswith("2") or status_code.startswith("3")
            
            return {
                "status": "healthy" if is_running else "unhealthy",
                "http_code": status_code,
                "details": "Gateway responding" if is_running else "Gateway not responding"
            }
        except subprocess.TimeoutExpired:
            return {
                "status": "unhealthy",
                "details": "Gateway request timed out"
            }
        except Exception as e:
            return {
                "status": "unknown",
                "details": f"Failed to check gateway: {e}"
            }
    
    def _check_disk_space(self) -> Dict[str, Any]:
        """Check disk space."""
        try:
            usage = shutil.disk_usage(self._workspace)
            
            total_gb = usage.total / (1024 ** 3)
            used_gb = usage.used / (1024 ** 3)
            free_gb = usage.free / (1024 ** 3)
            percent_used = (usage.used / usage.total) * 100
            
            # Warn if >90% used
            status = "healthy"
            if percent_used > 90:
                status = "critical"
            elif percent_used > 80:
                status = "warning"
            
            return {
                "status": status,
                "total_gb": round(total_gb, 2),
                "used_gb": round(used_gb, 2),
                "free_gb": round(free_gb, 2),
                "percent_used": round(percent_used, 1),
                "details": f"{percent_used:.1f}% used, {free_gb:.1f}GB free"
            }
        except Exception as e:
            return {
                "status": "unknown",
                "details": f"Failed to check disk space: {e}"
            }
    
    def _check_cron_jobs(self) -> Dict[str, Any]:
        """Check for failed cron jobs."""
        try:
            result = subprocess.run(
                ["openclaw", "cron", "list", "--json"],
                capture_output=True,
                text=True,
                timeout=10,
            )

            if result.returncode != 0:
                return {
                    "status": "unknown",
                    "details": f"Failed to list cron jobs: {result.stderr}",
                }

            try:
                cron_data = json.loads(result.stdout)
            except json.JSONDecodeError:
                return {
                    "status": "unknown",
                    "details": "Failed to parse cron list JSON",
                }

            jobs: List[Dict[str, Any]] = []
            if isinstance(cron_data, dict) and isinstance(cron_data.get("jobs"), list):
                jobs = [j for j in cron_data["jobs"] if isinstance(j, dict)]
            elif isinstance(cron_data, list):
                jobs = [j for j in cron_data if isinstance(j, dict)]

            failed_jobs = []
            total_enabled = 0
            rate_limited_only = True

            for job in jobs:
                if not job.get("enabled", False):
                    continue

                total_enabled += 1

                state = job.get("state") or {}
                last_status = state.get("lastStatus", "")
                consecutive = int(state.get("consecutiveErrors", 0) or 0)
                last_error = (state.get("lastError") or "")

                is_failing = last_status == "error" or consecutive > 0
                if not is_failing:
                    continue

                err_lc = last_error.lower()
                is_rate_limit = ("rate_limit" in err_lc) or ("cooldown" in err_lc) or ("429" in err_lc)
                if not is_rate_limit:
                    rate_limited_only = False

                failed_jobs.append(
                    {
                        "id": job.get("id", "unknown"),
                        "name": job.get("name", "unknown"),
                        "last_run_at_ms": state.get("lastRunAtMs"),
                        "consecutive_errors": consecutive,
                        "error": last_error or "unknown",
                        "rate_limit": is_rate_limit,
                    }
                )

            if not failed_jobs:
                status = "healthy"
            elif rate_limited_only:
                status = "degraded"  # noisy but not broken
            else:
                status = "unhealthy"

            return {
                "status": status,
                "total_enabled": total_enabled,
                "failed_count": len(failed_jobs),
                "failed_jobs": failed_jobs,
                "details": (
                    f"{len(failed_jobs)} failing jobs" if failed_jobs else "All enabled cron jobs healthy"
                ),
            }

        except subprocess.TimeoutExpired:
            return {
                "status": "unknown",
                "details": "Cron list command timed out",
            }
        except Exception as e:
            return {
                "status": "unknown",
                "details": f"Failed to check cron jobs: {e}",
            }

    def run(self) -> Dict[str, Any]:
        """Execute system health check."""
        self.log("Running system health check")
        
        # Run all checks
        gateway = self._check_gateway()
        disk = self._check_disk_space()
        cron = self._check_cron_jobs()
        
        # Determine overall status
        statuses = [gateway["status"], disk["status"], cron["status"]]
        
        if "critical" in statuses:
            overall_status = "critical"
        elif "unhealthy" in statuses:
            overall_status = "unhealthy"
        elif "warning" in statuses or "degraded" in statuses:
            overall_status = "warning"
        elif "unknown" in statuses:
            overall_status = "degraded"
        else:
            overall_status = "healthy"
        
        # Log individual checks
        self.log("Gateway check", **gateway)
        self.log("Disk check", **disk)
        self.log("Cron check", **cron)
        
        # Alert on critical issues
        if overall_status in ["critical", "unhealthy"]:
            alert_parts = []
            if gateway["status"] != "healthy":
                alert_parts.append(f"Gateway: {gateway['details']}")
            if disk["status"] in ["critical", "warning"]:
                alert_parts.append(f"Disk: {disk['details']}")
            if cron["status"] == "unhealthy":
                alert_parts.append(f"Cron: {cron['failed_count']} jobs failing")
            
            self.alert(
                f"System health {overall_status}: " + "; ".join(alert_parts),
                level="error" if overall_status == "critical" else "warning"
            )
        
        return {
            "success": True,
            "message": f"System health: {overall_status}",
            "overall_status": overall_status,
            "checks": {
                "gateway": gateway,
                "disk": disk,
                "cron": cron
            }
        }
