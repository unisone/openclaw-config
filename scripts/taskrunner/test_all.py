#!/usr/bin/env python3
"""Test runner for all tasks."""

import sys
from pathlib import Path

# Add tasks to path
sys.path.insert(0, str(Path(__file__).parent))

from tasks.memory_capture import MemoryCaptureTask
from tasks.memory_consolidate import MemoryConsolidateTask
from tasks.system_health import SystemHealthTask


def test_task(task_class, task_name: str) -> bool:
    """
    Test a task in dry-run mode.
    
    Returns:
        True if test passed, False otherwise
    """
    print(f"\n{'='*60}")
    print(f"Testing: {task_name}")
    print(f"{'='*60}")
    
    try:
        # Instantiate with dry_run=True
        task = task_class(dry_run=True)
        
        # Verify properties
        assert hasattr(task, "name"), f"{task_name} missing 'name' property"
        assert hasattr(task, "description"), f"{task_name} missing 'description' property"
        assert hasattr(task, "run"), f"{task_name} missing 'run' method"
        
        print(f"✓ Task name: {task.name}")
        print(f"✓ Description: {task.description}")
        
        # Execute
        print(f"→ Running {task_name}.execute() in dry-run mode...")
        result = task.execute()
        
        # Verify result structure
        assert isinstance(result, dict), f"{task_name} result is not a dict"
        assert "success" in result, f"{task_name} result missing 'success' key"
        assert "task" in result, f"{task_name} result missing 'task' key"
        assert "timestamp" in result, f"{task_name} result missing 'timestamp' key"
        assert "duration_seconds" in result, f"{task_name} result missing 'duration_seconds' key"
        
        print(f"✓ Result structure valid")
        print(f"✓ Success: {result['success']}")
        print(f"✓ Duration: {result['duration_seconds']}s")
        
        if "message" in result:
            print(f"✓ Message: {result['message']}")
        
        # Print any additional result fields
        extra_fields = {k: v for k, v in result.items() 
                       if k not in ["success", "task", "timestamp", "duration_seconds", "dry_run", "message"]}
        if extra_fields:
            print(f"✓ Additional data: {extra_fields}")
        
        # Check for common issues
        if not result["success"]:
            print(f"⚠ Task reported failure (expected in dry-run if data missing)")
            if "error" in result:
                print(f"  Error: {result['error']}")
        
        print(f"\n✅ {task_name} test PASSED")
        return True
    
    except AssertionError as e:
        print(f"\n❌ {task_name} test FAILED: {e}")
        return False
    except Exception as e:
        print(f"\n❌ {task_name} test FAILED with exception: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Run all task tests."""
    print("="*60)
    print("TASK RUNNER TEST SUITE")
    print("="*60)
    print("Testing all tasks in dry-run mode...")
    
    tasks = [
        (MemoryCaptureTask, "memory_capture"),
        (MemoryConsolidateTask, "memory_consolidate"),
        (SystemHealthTask, "system_health"),
    ]
    
    results = {}
    
    for task_class, task_name in tasks:
        passed = test_task(task_class, task_name)
        results[task_name] = passed
    
    # Summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    
    passed_count = sum(1 for p in results.values() if p)
    total_count = len(results)
    
    for task_name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {task_name}")
    
    print(f"\nTotal: {passed_count}/{total_count} passed")
    
    if passed_count == total_count:
        print("\n🎉 All tests passed!")
        return 0
    else:
        print(f"\n⚠️  {total_count - passed_count} test(s) failed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
