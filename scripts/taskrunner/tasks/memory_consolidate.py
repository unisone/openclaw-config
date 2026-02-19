#!/usr/bin/env python3
"""Memory consolidation task - prune old and duplicate memories."""

import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Set

from .base import Task


class MemoryConsolidateTask(Task):
    """Consolidate memory store by pruning old/low-importance and duplicate entries."""
    
    @property
    def name(self) -> str:
        return "memory_consolidate"
    
    @property
    def description(self) -> str:
        return "Prune old, low-importance, and duplicate memory entries"
    
    def _calculate_word_overlap(self, text1: str, text2: str) -> float:
        """
        Calculate Jaccard similarity (word overlap ratio).
        
        Returns:
            Float between 0 and 1, where 1 is identical
        """
        words1 = set(text1.lower().split())
        words2 = set(text2.lower().split())
        
        if not words1 or not words2:
            return 0.0
        
        intersection = len(words1 & words2)
        union = len(words1 | words2)
        
        return intersection / union if union > 0 else 0.0
    
    def _is_duplicate(self, text: str, existing_texts: List[str], threshold: float = 0.9) -> bool:
        """
        Check if text is a duplicate of any existing text.
        
        Args:
            text: Text to check
            existing_texts: List of existing texts to compare against
            threshold: Similarity threshold (0.9 = 90% overlap)
        
        Returns:
            True if duplicate found
        """
        for existing in existing_texts:
            similarity = self._calculate_word_overlap(text, existing)
            if similarity >= threshold:
                return True
        return False
    
    def run(self) -> Dict[str, Any]:
        """Execute memory consolidation."""
        store_path = self._workspace / "memory/store.json"
        
        # Check if store exists
        if not store_path.exists():
            return {
                "success": True,
                "message": "No memory store found (store.json does not exist)",
                "pruned_count": 0,
                "remaining_count": 0
            }
        
        # Read store
        try:
            with open(store_path, "r") as f:
                memories = json.load(f)
        except (json.JSONDecodeError, IOError) as e:
            return {
                "success": False,
                "message": f"Failed to read memory store: {e}"
            }
        
        if not isinstance(memories, list):
            return {
                "success": False,
                "message": "Memory store is not a list"
            }
        
        original_count = len(memories)
        self.log(f"Loaded {original_count} memories from store")
        
        # Prune old, low-importance entries (>14 days old, importance < 0.3)
        cutoff_date = datetime.now() - timedelta(days=14)
        kept_memories = []
        pruned_by_age = 0
        
        for memory in memories:
            # Parse timestamp
            timestamp_str = memory.get("timestamp", "")
            try:
                timestamp = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
            except (ValueError, AttributeError):
                # Keep if we can't parse timestamp (be conservative)
                kept_memories.append(memory)
                continue
            
            importance = memory.get("importance", 0.5)
            
            # Prune if old AND low importance
            if timestamp < cutoff_date and importance < 0.3:
                pruned_by_age += 1
                self.log(
                    f"Pruning old low-importance memory",
                    timestamp=timestamp_str,
                    importance=importance,
                    text_preview=memory.get("text", "")[:50]
                )
            else:
                kept_memories.append(memory)
        
        # Prune duplicates (keep first occurrence)
        seen_texts = []
        deduplicated_memories = []
        pruned_by_duplication = 0
        
        for memory in kept_memories:
            text = memory.get("text", "")
            
            if self._is_duplicate(text, seen_texts, threshold=0.9):
                pruned_by_duplication += 1
                self.log(
                    f"Pruning duplicate memory",
                    text_preview=text[:50]
                )
            else:
                seen_texts.append(text)
                deduplicated_memories.append(memory)
        
        final_count = len(deduplicated_memories)
        pruned_total = original_count - final_count
        
        self.log(
            f"Consolidation complete",
            original_count=original_count,
            pruned_by_age=pruned_by_age,
            pruned_by_duplication=pruned_by_duplication,
            pruned_total=pruned_total,
            remaining_count=final_count
        )
        
        # Write back (unless dry-run)
        if not self.dry_run:
            try:
                # Create backup first
                backup_path = store_path.with_suffix(".json.bak")
                with open(backup_path, "w") as f:
                    json.dump(memories, f, indent=2)
                
                # Write cleaned store
                with open(store_path, "w") as f:
                    json.dump(deduplicated_memories, f, indent=2)
                
                self.log(f"Wrote cleaned store to {store_path}")
            except IOError as e:
                return {
                    "success": False,
                    "message": f"Failed to write memory store: {e}",
                    "pruned_count": pruned_total,
                    "remaining_count": final_count
                }
        
        # Alert if significant pruning occurred
        if pruned_total > 50:
            self.alert(
                f"Memory consolidation pruned {pruned_total} entries "
                f"({pruned_by_age} old, {pruned_by_duplication} duplicates). "
                f"{final_count} memories remaining.",
                level="info"
            )
        
        return {
            "success": True,
            "message": f"Pruned {pruned_total} memories ({pruned_by_age} old, {pruned_by_duplication} duplicates)",
            "original_count": original_count,
            "pruned_by_age": pruned_by_age,
            "pruned_by_duplication": pruned_by_duplication,
            "pruned_count": pruned_total,
            "remaining_count": final_count
        }
