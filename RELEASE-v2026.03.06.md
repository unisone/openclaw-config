# OpenClaw Config v2026.03.06 — Content Quality & Production Automation

**Release Date:** March 6, 2026  
**Previous Release:** [v2026.02.27](./RELEASE-v2026.02.27.md)

This release introduces a comprehensive content quality framework (STEPPS), automated reel generation, enhanced taskrunner capabilities, and refined agent architecture documentation.

---

## 🎯 Highlights

### 1. **STEPPS Content Quality Framework**
A 50-point scoring system with auto-calibration for AI-generated content:
- **Quality gate:** All content scored before publication (40/50 minimum)
- **Auto-calibration:** Biweekly threshold adjustments based on performance
- **Score tracking:** JSONL-based performance logs feed calibration loops
- **Category enforcement:** 5 STEPPS dimensions (Social Currency, Triggers, Emotion, Public, Practical Value)

**Files:**
- `docs/STEPPS-QUALITY-GATE.md` — Scoring rubric and pass rules
- `docs/STEPPS-CALIBRATION.md` — Auto-calibration loop documentation
- `docs/WRITING-STYLE-GUIDE.md` — Anti-slop rules for content drafting

**Why it matters:** Prevents generic AI-generated content from shipping. Enforces quality standards with measurable, self-improving thresholds.

---

### 2. **Automated Reel Generation Pipeline**
Complete workflow for Instagram Reel generation from JSON briefs:
- **Architecture:** AI backgrounds → text overlays → Ken Burns effects → TTS voiceover
- **Modular:** Skip AI backgrounds (`--no-ai`) or voiceover (`--no-tts`)
- **Production-tested:** Runs via cron (`ig-visual-generator`) with brief-based input

**Files:**
- `scripts/reel-pipeline/README.md` — Architecture and usage
- `scripts/reel-pipeline/generate-reel.sh` — Orchestration script
- `scripts/reel-pipeline/lib/` — Python generators for frames, video stitching, audio

**Usage:**
```bash
cd scripts/reel-pipeline
./generate-reel.sh brief.json
```

**Why it matters:** Fully automated visual content generation from text → publishable Reels in minutes.

---

### 3. **Taskrunner Enhancements**
Python task runner improvements for production workflows:
- **New task:** `delivery_audit.py` — Audit cron job delivery configurations
- **Updated docs:** `IMPLEMENTATION_SUMMARY.md`, `QUICK_REFERENCE.md`, `README.md`
- **Path normalization:** All paths now use `$HOME/.openclaw/workspace` (generic)
- **Enhanced base:** Improved error handling and workspace path resolution

**Files:**
- `scripts/taskrunner/tasks/delivery_audit.py` (NEW)
- `scripts/taskrunner/runner.py` (updated)
- `scripts/taskrunner/tasks/base.py` (updated)
- `scripts/taskrunner/IMPLEMENTATION_SUMMARY.md` (updated)
- `scripts/taskrunner/QUICK_REFERENCE.md` (updated)
- `scripts/taskrunner/README.md` (updated)

**Why it matters:** More robust task orchestration with better diagnostics and portability.

---

### 4. **Agent Architecture V2 Documentation**
Updated system design documentation:
- `docs/AGENT-ARCHITECTURE-V2.md` — Full V2 architecture
- `docs/AGENT-ARCHITECTURE-V2-SUMMARY.md` — Executive summary
- `docs/MULTI-AGENT-RESEARCH-2026-03.md` — Latest multi-agent research

**Why it matters:** Documents current best practices for agent orchestration and architecture evolution.

---

## 📦 All Changes

### New Files

#### Documentation
- `docs/STEPPS-CALIBRATION.md` — Auto-calibration loop for content quality
- `docs/STEPPS-QUALITY-GATE.md` — 50-point content scoring rubric
- `docs/WRITING-STYLE-GUIDE.md` — Anti-slop rules for AI content
- `docs/AGENT-ARCHITECTURE-V2.md` — V2 agent architecture
- `docs/AGENT-ARCHITECTURE-V2-SUMMARY.md` — V2 architecture summary
- `docs/MULTI-AGENT-RESEARCH-2026-03.md` — Multi-agent orchestration research

#### Scripts
- `scripts/reel-pipeline/` (NEW) — Complete reel generation pipeline
  - `scripts/reel-pipeline/README.md`
  - `scripts/reel-pipeline/generate-reel.sh`
  - `scripts/reel-pipeline/lib/generate-frames.py`
  - `scripts/reel-pipeline/lib/stitch-video.sh`
  - `scripts/reel-pipeline/lib/add-audio.sh`
  - `scripts/reel-pipeline/output/` (placeholder)
- `scripts/taskrunner/tasks/delivery_audit.py` (NEW)

### Updated Files

#### Core Configuration
- `LICENSE` — Copyright holder updated to "OpenClaw Config Contributors"
- `README.md` — URLs updated to use `github.com/unisone/openclaw-config`
- `DEPLOY.md` — URLs updated
- `RELEASE-v2026.02.17.md` — URLs updated

#### Configuration Files
- `config/feature-unlocks.json5` — URL updated

#### Production Hardening
- `production-hardening/IMPLEMENTATION.md` — URLs updated
- `production-hardening/install.sh` — URLs updated
- `production-hardening/config/launchagent.plist` — Description updated
- `production-hardening/config/gitignore.template` — Source attribution updated

#### Scripts
- `scripts/posting-gate/setup.sh` — Legacy config paths updated (`.clawdbot` → `.openclaw`)
- `scripts/taskrunner/runner.py` — Hardcoded paths → `$HOME/.openclaw/workspace`
- `scripts/taskrunner/tasks/base.py` — Hardcoded paths → `$HOME/.openclaw/workspace`
- `scripts/taskrunner/README.md` — Hardcoded paths → `$HOME/.openclaw/workspace`
- `scripts/taskrunner/QUICK_REFERENCE.md` — Hardcoded paths → `$HOME/.openclaw/workspace`
- `scripts/taskrunner/IMPLEMENTATION_SUMMARY.md` — Hardcoded paths → `$HOME/.openclaw/workspace`

#### Workflows
- `workflows/agent-swarm-orchestration.md` — Legacy paths updated (`.clawdbot` → `.openclaw/workspace`)

---

## 🔧 Breaking Changes

**None.** All changes are additive or cosmetic (path/URL normalization).

---

## 📝 Migration Guide

### For Existing Users

No migration required. This release is fully backward-compatible.

### For New Users

1. **STEPPS Quality Framework** (optional but recommended):
   - Read `docs/STEPPS-QUALITY-GATE.md` for scoring rules
   - Integrate scoring into content workflows
   - Track scores in `memory/stepps-tracking.jsonl` (see `docs/STEPPS-CALIBRATION.md`)

2. **Reel Pipeline** (optional):
   - Copy `scripts/reel-pipeline/` to your workspace
   - Install dependencies (see `scripts/reel-pipeline/README.md`)
   - Test with: `./scripts/reel-pipeline/generate-reel.sh your-brief.json`

3. **Taskrunner Updates**:
   - Update `scripts/taskrunner/` from this release
   - Paths now use `$HOME/.openclaw/workspace` (generic)
   - New task: `delivery_audit` (cron delivery validation)

---

## 🎨 STEPPS Framework Quick Start

### 1. Score Your Drafts

Before posting any content, score it with STEPPS:

```
STEPPS_SCORE: 43/50 (S8 T9 E8 P8 V10)
```

**Pass threshold:** 40/50  
**Hard fail:** Any category below 6

### 2. Track Performance

Append to `memory/stepps-tracking.jsonl`:

```json
{"ts":"2026-03-06T12:00:00Z","agent":"dan-twitter","type":"reply","score":43,"breakdown":"S8 T9 E8 P8 V10","passed":true}
```

### 3. Calibrate Biweekly

Run calibration (manual or cron):
- Reads last 14 days of tracking data
- Adjusts thresholds based on performance
- Updates `memory/stepps-calibration.md`
- Posts scorecard to Slack/Discord

See `docs/STEPPS-CALIBRATION.md` for rules.

---

## 🚀 Reel Pipeline Quick Start

### Generate a Reel

```bash
cd scripts/reel-pipeline

# Full pipeline (AI backgrounds + TTS voiceover)
./generate-reel.sh brief.json

# Skip AI backgrounds (use gradients)
./generate-reel.sh brief.json --no-ai

# Skip TTS voiceover
./generate-reel.sh brief.json --no-tts
```

### Brief Schema

```json
{
  "topic": "Your topic here",
  "format": "reel",
  "beats": [
    {
      "text": "Hook: Grab attention.",
      "duration": 3,
      "style": "hook",
      "bg_prompt": "dark server room, blue lights, volumetric fog"
    },
    {
      "text": "Body: Deliver value.",
      "duration": 4,
      "style": "body",
      "bg_prompt": "minimalist office, warm lighting, shallow depth of field"
    }
  ]
}
```

Output: `scripts/reel-pipeline/output/<timestamp>-<topic>/reel-final.mp4`

---

## 🛠️ Installation

### Quick Install (Production Hardening)

```bash
curl -O https://raw.githubusercontent.com/unisone/openclaw-config/main/production-hardening/install.sh
chmod +x install.sh
./install.sh
```

### Manual Install

```bash
git clone https://github.com/unisone/openclaw-config.git
cd openclaw-config

# Copy what you need:
cp config/* ~/.openclaw/
cp -r scripts/* ~/.openclaw/workspace/scripts/
cp -r docs/* ~/.openclaw/workspace/docs/
```

---

## 📖 Documentation

### New Docs
- **[STEPPS Quality Gate](./docs/STEPPS-QUALITY-GATE.md)** — Content scoring rubric
- **[STEPPS Calibration](./docs/STEPPS-CALIBRATION.md)** — Auto-calibration loop
- **[Writing Style Guide](./docs/WRITING-STYLE-GUIDE.md)** — Anti-slop rules
- **[Reel Pipeline README](./scripts/reel-pipeline/README.md)** — Automated video generation
- **[Agent Architecture V2](./docs/AGENT-ARCHITECTURE-V2.md)** — System design

### Core Docs
- **[README](./README.md)** — Overview and quick start
- **[Production Hardening](./production-hardening/README.md)** — Deployment guide
- **[Deployment Guide](./DEPLOY.md)** — Release workflow

---

## 🐛 Known Issues

None reported.

---

## 🙏 Acknowledgments

This release builds on learnings from production deployments, community feedback, and internal testing.

Special thanks to contributors who identified path normalization issues and content quality gaps that informed the STEPPS framework.

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/unisone/openclaw-config/issues)
- **Discussions**: [GitHub Discussions](https://github.com/unisone/openclaw-config/discussions)
- **Docs**: [README](./README.md)

---

## 📅 Roadmap

### Next Release (v2026.03.20)
- Session management scripts (generic versions)
- Security hardening enhancements
- Instagram content pipeline documentation
- Enhanced multi-agent orchestration patterns

---

**Free and open source:** [MIT License](./LICENSE)  
**Repository:** https://github.com/unisone/openclaw-config
