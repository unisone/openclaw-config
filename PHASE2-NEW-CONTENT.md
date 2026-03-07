# PHASE 2: New Release-Worthy Content for v2026.03.06

## NEW SCRIPTS (Priority: High)

### 1. Reel Pipeline (`scripts/reel-pipeline/`)
**What**: Automated Instagram Reel generation from JSON briefs
**Why**: Complete new content automation workflow
**Files**:
- `scripts/reel-pipeline/README.md`
- `scripts/reel-pipeline/generate-reel.sh`
- `scripts/reel-pipeline/lib/` (all files)
**Status**: Production-ready, documented

### 2. Security Scripts (`scripts/security/`)
**What**: Security auditing and hardening tools
**Why**: Production security automation
**Files**: All files in `scripts/security/`
**Status**: Should be reviewed for personal data first

### 3. Session Management Scripts
**What**: Improved session operations
**Files**:
- `scripts/session-cleanup.sh`
- `scripts/session-metrics.sh`
- `scripts/session-ops-weekly-report.sh`
- `scripts/session-store-hygiene.sh`
- `scripts/session-watchdog.sh`
- `scripts/state-backup-push.sh`
- `scripts/migrate-ops-crons.sh`
**Status**: Production-tested

## UPDATED SCRIPTS

### 1. Taskrunner Updates (`scripts/taskrunner/`)
**What**: Python task runner improvements
**Changed Files**:
- `IMPLEMENTATION_SUMMARY.md`
- `QUICK_REFERENCE.md`
- `README.md`
- `runner.py`
- `tasks/base.py`
- `tasks/delivery_audit.py` (new)
**Status**: Significant updates since v2026.02.27

## NEW DOCS (Priority: Critical)

### 1. STEPPS Quality Framework
**Files**:
- `docs/STEPPS-CALIBRATION.md` (NEW)
- `docs/STEPPS-QUALITY-GATE.md` (NEW)
**What**: Content quality scoring system with auto-calibration
**Why**: Core content production workflow
**Status**: Production-tested, foundational

### 2. Writing Style Guide
**File**: `docs/WRITING-STYLE-GUIDE.md` (NEW)
**What**: Anti-slop rules for AI-generated content
**Why**: Content quality enforcement
**Status**: Production-tested

### 3. Multi-Agent Research
**File**: `docs/MULTI-AGENT-RESEARCH-2026-03.md` (NEW)
**What**: Latest multi-agent orchestration research
**Why**: Architecture improvements
**Status**: Research document

### 4. Agent Architecture V2
**Files**:
- `docs/AGENT-ARCHITECTURE-V2.md` (NEW)
- `docs/AGENT-ARCHITECTURE-V2-SUMMARY.md` (NEW)
**What**: Updated agent architecture design
**Why**: System evolution documentation
**Status**: Design document

## INSTAGRAM/CONTENT DOCS

### From `docs/instagram/` (if applicable)
**Check**: `docs/instagram/` directory for any production-ready docs

### From `knowledge/instagram-*.md`
**Files**:
- `knowledge/instagram-creative-research.md` (exists in workspace, not in repo)
- `knowledge/instagram-pro-playbook.md` (exists in workspace, not in repo)
**Status**: May contain personal/business info — review first

## SCRIPTS TO EXCLUDE (Personal/Deprecated)

- `scripts/compose_carousel.py` (likely personal)
- `scripts/ig_post_carousel.py` (likely personal)
- `scripts/parts-express-catalog.py` (business-specific)
- `scripts/scrape_prices.py` (business-specific)
- `scripts/x_visual_card.py` (personal)
- `scripts/x_visual_feedback.py` (personal)
- `scripts/anti_slop_lint.py` (may be redundant with WRITING-STYLE-GUIDE.md)
- `scripts/_deprecated/` (obviously)
- `scripts/git-bundle-backup*.sh` (personal paths)

## PRIORITY ORDER FOR RELEASE

### Tier 1 (Must Have)
1. STEPPS-CALIBRATION.md
2. STEPPS-QUALITY-GATE.md
3. WRITING-STYLE-GUIDE.md
4. Reel pipeline (complete)
5. Taskrunner updates

### Tier 2 (Nice to Have)
1. Session management scripts (generic versions)
2. AGENT-ARCHITECTURE-V2.md
3. MULTI-AGENT-RESEARCH-2026-03.md

### Tier 3 (Review First)
1. Security scripts (check for personal data)
2. Instagram docs (check for business references)

## CHANGELOG THEMES

1. **Content Quality Framework** — STEPPS scoring + calibration
2. **Reel Pipeline** — Automated video generation
3. **Session Management** — Production session ops tools
4. **Taskrunner Evolution** — Python task orchestration improvements
5. **Agent Architecture** — V2 design documentation

## ACTION ITEMS

- [ ] Copy Tier 1 docs (sanitize any personal references)
- [ ] Copy reel pipeline (sanitize paths if needed)
- [ ] Copy taskrunner updates (sanitize)
- [ ] Copy session scripts (sanitize personal paths)
- [ ] Review security scripts for personal data
- [ ] Write comprehensive RELEASE-v2026.03.06.md
- [ ] Test all scripts for hardcoded paths
