#!/usr/bin/env python3
"""
Task runner dispatcher.

Usage:
    python3 runner.py <task_name> [--dry-run]

Examples:
    python3 runner.py memory_capture
    python3 runner.py memory_consolidate --dry-run
    python3 runner.py system_health
"""

import argparse
import fcntl
import importlib
import json
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional


# Exit codes
EXIT_SUCCESS = 0
EXIT_ERROR = 1
EXIT_LOCKED = 2


class TaskRunner:
    """Main task runner orchestrator."""
    
    def __init__(self, workspace_path: str = None):
        if workspace_path is None:
            # Default to ~/.openclaw/workspace if not specified
            workspace_path = Path.home() / ".openclaw" / "workspace"
        self.workspace = Path(workspace_path)
        self.taskrunner_dir = self.workspace / "scripts/taskrunner"
        self.logs_dir = self.taskrunner_dir / "logs"
        self.logs_dir.mkdir(parents=True, exist_ok=True)
        self.log_file = self.logs_dir / "tasks.jsonl"
    
    def _acquire_lock(self, task_name: str) -> Optional[int]:
        """
        Acquire a lockfile for the task.
        
        Returns:
            File descriptor if lock acquired, None if locked by another process.
        """
        lock_path = Path(f"/tmp/taskrunner-{task_name}.lock")
        
        try:
            fd = open(lock_path, "w")
            fcntl.flock(fd.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            fd.write(f"{datetime.now().isoformat()}\n")
            fd.flush()
            return fd.fileno()
        except IOError:
            return None
    
    def _release_lock(self, fd: int) -> None:
        """Release the lockfile."""
        try:
            fcntl.flock(fd, fcntl.LOCK_UN)
        except:
            pass
    
    def _log_result(self, result: Dict[str, Any]) -> None:
        """Append task result to JSON lines log."""
        try:
            with open(self.log_file, "a") as f:
                f.write(json.dumps(result) + "\n")
        except IOError as e:
            print(f"ERROR: Failed to write log: {e}", file=sys.stderr)
    
    def _import_task(self, task_name: str):
        """
        Import and return the task class.
        
        Args:
            task_name: Name of the task module (e.g., 'memory_capture')
        
        Returns:
            Task class
        
        Raises:
            ImportError: If task module not found
            AttributeError: If task class not found in module
        """
        module_name = f"tasks.{task_name}"
        module = importlib.import_module(module_name)
        
        # Convention: each task module has a class named after the task in PascalCase
        # e.g., memory_capture -> MemoryCaptureTask
        class_name = "".join(word.capitalize() for word in task_name.split("_")) + "Task"
        
        if not hasattr(module, class_name):
            raise AttributeError(f"Task module '{task_name}' has no class '{class_name}'")
        
        return getattr(module, class_name)
    
    def _run_with_retry(
        self, 
        task_instance, 
        max_attempts: int = 3, 
        backoff_base: float = 2.0
    ) -> Dict[str, Any]:
        """
        Execute task with exponential backoff retry.
        
        Args:
            task_instance: Task instance to run
            max_attempts: Maximum number of retry attempts
            backoff_base: Base for exponential backoff (seconds)
        
        Returns:
            Task execution result
        """
        for attempt in range(1, max_attempts + 1):
            result = task_instance.execute()
            
            if result["success"]:
                if attempt > 1:
                    result["retry_attempts"] = attempt - 1
                return result
            
            # If not last attempt, wait before retrying
            if attempt < max_attempts:
                wait_time = backoff_base ** (attempt - 1)
                print(
                    json.dumps({
                        "event": "retry",
                        "attempt": attempt,
                        "max_attempts": max_attempts,
                        "wait_seconds": wait_time,
                        "error": result.get("error", "Unknown error")
                    })
                )
                time.sleep(wait_time)
        
        # All attempts failed
        result["retry_attempts"] = max_attempts - 1
        result["all_attempts_failed"] = True
        return result
    
    def run_task(self, task_name: str, dry_run: bool = False) -> int:
        """
        Run a task with full error handling and logging.
        
        Args:
            task_name: Name of the task to run
            dry_run: If True, run in dry-run mode
        
        Returns:
            Exit code (0 = success, 1 = error, 2 = locked)
        """
        lock_fd = None
        
        try:
            # Acquire lock
            lock_fd = self._acquire_lock(task_name)
            if lock_fd is None:
                error_result = {
                    "task": task_name,
                    "timestamp": datetime.now().isoformat(),
                    "success": False,
                    "error": "Task is already running (locked)",
                    "locked": True
                }
                self._log_result(error_result)
                print(json.dumps(error_result), file=sys.stderr)
                return EXIT_LOCKED
            
            # Import task
            try:
                TaskClass = self._import_task(task_name)
            except (ImportError, AttributeError) as e:
                error_result = {
                    "task": task_name,
                    "timestamp": datetime.now().isoformat(),
                    "success": False,
                    "error": f"Failed to import task: {e}",
                    "error_type": type(e).__name__
                }
                self._log_result(error_result)
                print(json.dumps(error_result), file=sys.stderr)
                return EXIT_ERROR
            
            # Instantiate and run
            task_instance = TaskClass(dry_run=dry_run)
            result = self._run_with_retry(task_instance)
            
            # Log result
            self._log_result(result)
            
            # Print result
            print(json.dumps(result, indent=2))
            
            return EXIT_SUCCESS if result["success"] else EXIT_ERROR
        
        except Exception as e:
            error_result = {
                "task": task_name,
                "timestamp": datetime.now().isoformat(),
                "success": False,
                "error": str(e),
                "error_type": type(e).__name__
            }
            self._log_result(error_result)
            print(json.dumps(error_result), file=sys.stderr)
            return EXIT_ERROR
        
        finally:
            if lock_fd is not None:
                self._release_lock(lock_fd)


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Task runner dispatcher",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 runner.py memory_capture
  python3 runner.py memory_consolidate --dry-run
  python3 runner.py system_health
        """
    )
    parser.add_argument("task", help="Task name to run")
    parser.add_argument(
        "--dry-run", 
        action="store_true", 
        help="Run in dry-run mode (no writes)"
    )
    
    args = parser.parse_args()
    
    runner = TaskRunner()
    exit_code = runner.run_task(args.task, dry_run=args.dry_run)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
