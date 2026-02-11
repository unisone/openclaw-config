#!/usr/bin/env python3
"""Memory capture task - extract key items from daily memory files."""

import json
import re
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Tuple

from .base import Task


class MemoryCaptureTask(Task):
    """Capture key facts, decisions, and preferences from daily memory files."""
    
    @property
    def name(self) -> str:
        return "memory_capture"
    
    @property
    def description(self) -> str:
        return "Extract key items from today's and yesterday's memory files"
    
    def _calculate_importance(self, text: str, markers: List[str]) -> float:
        """
        Calculate importance score based on content and markers.
        
        Returns:
            Float between 0 and 1
        """
        score = 0.5  # Default
        
        text_lower = text.lower()
        
        # High importance markers
        if any(marker in text_lower for marker in ["blocker", "critical", "urgent", "important"]):
            score += 0.3
        
        # Decision markers
        if any(marker in text_lower for marker in ["decision", "decided", "chose"]):
            score += 0.2
        
        # Project/work markers
        if any(marker in text_lower for marker in ["project", "milestone", "deadline"]):
            score += 0.1
        
        # TODO/action markers
        if any(marker in text_lower for marker in ["todo", "action", "task"]):
            score += 0.05
        
        # Length bonus (longer = more detail)
        if len(text) > 200:
            score += 0.1
        
        return min(score, 1.0)  # Cap at 1.0
    
    def _extract_items(self, file_path: Path) -> List[Tuple[str, List[str]]]:
        """
        Extract key items from a markdown file.
        
        Returns:
            List of (text, markers) tuples
        """
        if not file_path.exists():
            return []
        
        try:
            with open(file_path, "r") as f:
                content = f.read()
        except IOError:
            return []
        
        items = []
        
        # Pattern 1: Headers (##, ###, etc.)
        header_pattern = r'^(#{2,})\s+(.+)$'
        for match in re.finditer(header_pattern, content, re.MULTILINE):
            level = len(match.group(1))
            text = match.group(2).strip()
            items.append((text, ["header"]))
        
        # Pattern 2: Bold items (- ** ... **)
        bold_pattern = r'^\s*-\s+\*\*(.+?)\*\*(.*)$'
        for match in re.finditer(bold_pattern, content, re.MULTILINE):
            text = (match.group(1) + match.group(2)).strip()
            items.append((text, ["bold_item"]))
        
        # Pattern 3: Lines with markers
        marker_patterns = {
            "TODO": r'(?i)TODO:?\s*(.+)',
            "DECISION": r'(?i)DECISION:?\s*(.+)',
            "BLOCKER": r'(?i)BLOCKER:?\s*(.+)',
            "ACTION": r'(?i)ACTION:?\s*(.+)',
            "NOTE": r'(?i)NOTE:?\s*(.+)',
        }
        
        for marker, pattern in marker_patterns.items():
            for match in re.finditer(pattern, content, re.MULTILINE):
                text = match.group(1).strip()
                items.append((text, [marker.lower()]))
        
        # Pattern 4: Bullet points that look important (contain certain keywords)
        important_keywords = [
            "decided", "completed", "shipped", "launched", "fixed", "broke",
            "learned", "discovered", "insight", "problem", "solution"
        ]
        bullet_pattern = r'^\s*[-*]\s+(.+)$'
        for match in re.finditer(bullet_pattern, content, re.MULTILINE):
            text = match.group(1).strip()
            if any(keyword in text.lower() for keyword in important_keywords):
                items.append((text, ["important_bullet"]))
        
        return items
    
    def _calculate_word_overlap(self, text1: str, text2: str) -> float:
        """Calculate Jaccard similarity (word overlap ratio)."""
        words1 = set(text1.lower().split())
        words2 = set(text2.lower().split())
        
        if not words1 or not words2:
            return 0.0
        
        intersection = len(words1 & words2)
        union = len(words1 | words2)
        
        return intersection / union if union > 0 else 0.0
    
    def _is_duplicate(self, text: str, existing_memories: List[Dict], threshold: float = 0.85) -> bool:
        """Check if text is already in memory store."""
        for memory in existing_memories:
            existing_text = memory.get("text", "")
            similarity = self._calculate_word_overlap(text, existing_text)
            if similarity >= threshold:
                return True
        return False
    
    def run(self) -> Dict[str, Any]:
        """Execute memory capture."""
        memory_dir = self._workspace / "memory"
        store_path = memory_dir / "store.json"
        
        # Ensure memory directory exists
        if not memory_dir.exists():
            return {
                "success": False,
                "message": "Memory directory does not exist"
            }
        
        # Load existing store
        existing_memories = []
        if store_path.exists():
            try:
                with open(store_path, "r") as f:
                    existing_memories = json.load(f)
                if not isinstance(existing_memories, list):
                    existing_memories = []
            except (json.JSONDecodeError, IOError):
                existing_memories = []
        
        # Get today and yesterday's dates
        today = datetime.now().date()
        yesterday = today - timedelta(days=1)
        
        # Find daily files
        daily_files = [
            (memory_dir / f"{today.isoformat()}.md", "today"),
            (memory_dir / f"{yesterday.isoformat()}.md", "yesterday"),
        ]
        
        # Extract items
        all_items = []
        files_processed = []
        
        for file_path, label in daily_files:
            if file_path.exists():
                items = self._extract_items(file_path)
                all_items.extend([(text, markers, label) for text, markers in items])
                files_processed.append(str(file_path.name))
                self.log(f"Extracted {len(items)} items from {file_path.name}")
        
        if not all_items:
            return {
                "success": True,
                "message": "No items found in daily files",
                "files_processed": files_processed,
                "items_extracted": 0,
                "items_added": 0,
                "items_skipped": 0
            }
        
        # Filter out duplicates and create memory entries
        new_memories = []
        skipped_count = 0
        
        for text, markers, source in all_items:
            # Skip if too short
            if len(text) < 10:
                skipped_count += 1
                continue
            
            # Skip if duplicate
            if self._is_duplicate(text, existing_memories + new_memories):
                skipped_count += 1
                self.log(f"Skipping duplicate", text_preview=text[:50])
                continue
            
            # Calculate importance
            importance = self._calculate_importance(text, markers)
            
            # Create memory entry
            memory = {
                "text": text,
                "timestamp": datetime.now().isoformat(),
                "importance": round(importance, 2),
                "source": source,
                "markers": markers,
                "category": "auto_captured"
            }
            
            new_memories.append(memory)
            self.log(
                f"Captured new memory",
                importance=importance,
                markers=markers,
                text_preview=text[:50]
            )
        
        # Append to store (unless dry-run)
        if new_memories and not self.dry_run:
            try:
                combined_memories = existing_memories + new_memories
                
                # Create backup first
                if store_path.exists():
                    backup_path = store_path.with_suffix(".json.bak")
                    with open(backup_path, "w") as f:
                        json.dump(existing_memories, f, indent=2)
                
                # Write updated store
                with open(store_path, "w") as f:
                    json.dump(combined_memories, f, indent=2)
                
                self.log(f"Wrote {len(new_memories)} new memories to store")
            except IOError as e:
                return {
                    "success": False,
                    "message": f"Failed to write memory store: {e}",
                    "items_extracted": len(all_items),
                    "items_added": len(new_memories),
                    "items_skipped": skipped_count
                }
        
        return {
            "success": True,
            "message": f"Captured {len(new_memories)} new memories from {len(files_processed)} files",
            "files_processed": files_processed,
            "items_extracted": len(all_items),
            "items_added": len(new_memories),
            "items_skipped": skipped_count
        }
