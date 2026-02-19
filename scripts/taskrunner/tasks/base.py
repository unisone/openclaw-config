#!/usr/bin/env python3
"""Base task class for the task runner system."""

import json
import time
from abc import ABC, abstractmethod
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional


class Task(ABC):
    """Base class for all runnable tasks."""
    
    def __init__(self, dry_run: bool = False):
        self.dry_run = dry_run
        self.start_time: Optional[float] = None
        self.end_time: Optional[float] = None
        self._workspace = Path("~/.openclaw/workspace")
        self._alerts_dir = self._workspace / "scripts/taskrunner/alerts"
    
    @property
    @abstractmethod
    def name(self) -> str:
        """Task name (used for logging and lockfiles)."""
        pass
    
    @property
    @abstractmethod
    def description(self) -> str:
        """Human-readable task description."""
        pass
    
    @abstractmethod
    def run(self) -> Dict[str, Any]:
        """
        Execute the task.
        
        Returns:
            Dict with task results. Should include at least:
            - success: bool
            - message: str
            - Any task-specific data
        """
        pass
    
    def execute(self) -> Dict[str, Any]:
        """
        Wrapper that handles timing and error catching.
        
        Returns:
            Dict with execution results including timing info.
        """
        self.start_time = time.time()
        result = {
            "task": self.name,
            "dry_run": self.dry_run,
            "timestamp": datetime.now().isoformat(),
            "success": False,
        }
        
        try:
            task_result = self.run()
            result.update(task_result)
            result["success"] = task_result.get("success", False)
        except Exception as e:
            result["success"] = False
            result["error"] = str(e)
            result["error_type"] = type(e).__name__
        finally:
            self.end_time = time.time()
            result["duration_seconds"] = round(self.end_time - self.start_time, 3)
        
        return result
    
    def alert(self, message: str, level: str = "info") -> None:
        """
        Write an alert to be picked up by the heartbeat.
        
        Args:
            message: Alert message
            level: Alert level (info, warning, error)
        """
        self._alerts_dir.mkdir(parents=True, exist_ok=True)
        pending_file = self._alerts_dir / "pending.json"
        
        alert = {
            "task": self.name,
            "timestamp": datetime.now().isoformat(),
            "level": level,
            "message": message,
        }
        
        # Read existing alerts
        alerts = []
        if pending_file.exists():
            try:
                with open(pending_file, "r") as f:
                    alerts = json.load(f)
            except (json.JSONDecodeError, IOError):
                alerts = []
        
        # Append new alert
        alerts.append(alert)
        
        # Write back
        if not self.dry_run:
            with open(pending_file, "w") as f:
                json.dump(alerts, f, indent=2)
    
    def log(self, message: str, **kwargs) -> None:
        """Log a message (can be overridden for custom logging)."""
        data = {
            "task": self.name,
            "timestamp": datetime.now().isoformat(),
            "message": message,
            **kwargs
        }
        print(json.dumps(data))
