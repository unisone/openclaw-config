# openclaw-config

Battle-tested configs, scripts, and workspace templates for **OpenClaw**.

- Upstream: https://github.com/openclaw/openclaw
- This repo is **not** an SDK or plugin - it's a set of *copyable* building blocks.

## What you get

- **Memory Engine** (`scripts/memory-engine/`): capture → recall → decay → learn (nightly) + self-review (MISS/FIX) from real logs
- **Gateway config snippets** (`config/*.json5`): compaction, pruning, model fallbacks, Discord setup, memory search
- **Workspace templates** (`templates/`): `AGENTS.md`, `SOUL.md`, `HEARTBEAT.md`, etc.
- **Optional content pipeline** (`content-pipeline/`): cron-driven draft → approval → post → metrics loop

## What's New (Feb 2026)

**🚀 New Config Examples:**
- **`pro-optimization.json5`** - Production-tuned power user settings (the "dial it to 11" config)
- **`feature-unlocks.json5`** - Enable the "60% to 100%" features that ship disabled by default
- **`memory-lancedb-setup.json5`** - LanceDB-backed long-term memory with auto-capture/recall
- **`web-search-perplexity.json5`** - Switch from Brave to Perplexity (no rate limits)

**📚 New Docs:**
- **`diagnosis-protocol.md`** - Check tools before recommending workarounds
- **`context-overflow-prevention.md`** - Rules for spawning sub-agents under heavy load

**🛠️ New Scripts:**
- **`post-update-macos-arm64.sh`** - Reinstall native dependencies after `npm update`

**📊 Updated with Real Production Values:**
- **Compaction & Pruning** - Updated with actual running config: `reserveTokensFloor: 20000`, `softThresholdTokens: 8000`
- **Context Overflow Prevention** - Balanced production settings (not aggressive test config)
- **Model Setup** - Current production model stack: Opus primary, Sonnet + GPT-5.2 fallbacks, Kimi for subagents
- **Memory Recall** - Increased to 6 results per context (0.4% of window, better continuity)
- **Cron Concurrency** - Increased to 5 (morning window has overlapping jobs)
- **Subagent Thinking** - Changed to "high" (subagents do real work)

**Why These Matter:**
OpenClaw ships conservative by default - it prioritizes "just works" over "maximum power." The new configs represent stable, production-tested optimizations that power users want but newcomers don't need to think about. Not experimental. Not bleeding edge. Just the settings that work when you know what you're doing.

## Who this is for

You'll like this repo if you:

- run OpenClaw daily and want your setup to be **more stable under heavy tool usage**
- are tired of "self-improvement" prompts that don't stick
- want a practical starting point for a *real* workspace (templates + scripts), not a blank folder

## Safety / privacy (read before copying)

These files are meant to be copied into your workspace, which means you should treat them like production config:

- **Never commit secrets** (API keys, tokens, cookie DBs)
- Skim any file before you copy it; some templates contain placeholder personal details
- If you fork this repo: keep it clean (no private data, no logs)

## Quickstart (recommended)

Pick only what you want. Most people start with **templates + memory engine**.

```bash
# 1) Clone
git clone https://github.com/unisone/openclaw-config.git
cd openclaw-config

# 2) Copy templates into your workspace (edit them after)
# Replace ~/clawd with your OpenClaw workspace path.
rsync -av templates/ ~/clawd/

# 3) Copy the memory engine
mkdir -p ~/clawd/scripts/
rsync -av scripts/memory-engine/ ~/clawd/scripts/memory-engine/
chmod +x ~/clawd/scripts/memory-engine/*.sh

# 4) Run an initial capture (creates/updates memory/store.json)
cd ~/clawd
bash scripts/memory-engine/capture.sh

# 5) Try recall
bash scripts/memory-engine/recall.sh "context overflow"
```

### Add the nightly job

Run nightly learning (capture → decay → self-review → insights):

- Option A: add a cron job in OpenClaw that runs `bash scripts/memory-engine/learn.sh`
- Option B: run it manually at first to confirm it matches your workflow

## Gateway config snippets

Config examples live in `config/*.json5`.

Typical workflow:

1. Open your OpenClaw config file (`~/.openclaw/openclaw.json` on most installs)
2. Copy the snippet you need
3. Merge it into your config (don't blindly replace)

Start here:

- `config/compaction-and-pruning.json5` — highest impact stability settings
- `config/context-overflow-prevention.json5` — defensive settings for heavy tool use
- `config/model-aliases-and-fallbacks.json5` — provider fallbacks
- `config/memory-search.json5` — semantic search over memory files
- `config/memory-lancedb-setup.json5` — LanceDB + OpenAI embeddings + auto-capture/recall
- `config/web-search-perplexity.json5` — Perplexity search (no rate limits with paid key)
- `config/discord-setup.json5` — practical Discord defaults

### Power User Configs (NEW)

**`pro-optimization.json5`** — The "dial it to 11" config. Every optimization that makes OpenClaw faster, smarter, and more capable without sacrificing stability. What changes:
- Longer session idle time (12h vs 24h for Discord)
- Faster auth recovery (2h billing backoff vs 24h)
- Aggressive caching (15min search, 10min web fetch)
- Subagent cleanup (60min archive)
- Smart message handling (auto-remove 👀 reactions)
- Low thinking by default

**When to use:** You understand the config, you're running OpenClaw daily, you want maximum capability.

**`feature-unlocks.json5`** — The "60% to 100%" config. Enables production-ready features that ship disabled to avoid overwhelming new users. What unlocks:
- Session transcript search (memory search covers ALL past conversations)
- Image/audio auto-analysis (no need to ask "what's in this image?")
- Link auto-fetch (paste a link, agent reads it — up to 3 links, 15s timeout)
- Typing indicator (shows when agent is thinking)
- Heartbeat active hours (proactive checks during work hours)
- Hot reload (auto-reload config changes without restart)

**When to use:** You've read `AGENTS.md`, you have `HEARTBEAT.md` configured, you want the full power-user experience.

**How to apply:**
```bash
# Read the configs, copy sections you want into ~/.openclaw/openclaw.json
# Restart gateway after changes
openclaw gateway restart
```

**Pro tip:** Apply `pro-optimization.json5` first, run for a few days, then add `feature-unlocks.json5`. Changing everything at once makes it hard to tell what broke if something goes wrong.

## Repo layout

```text
openclaw-config/
  agents/               # Multi-agent persona prompts
  config/               # JSON5 snippets you can merge into your gateway config
  content-pipeline/     # Optional: cron-driven content workflow
  docs/                 # Deep dives (e.g., context overflow prevention)
  scripts/memory-engine/# Capture/recall/decay/learn + self-review
  templates/            # Workspace bootstrap files
  workflows/            # Optional Lobster workflows
```

## Contributing

PRs welcome, but keep it strict:

- **Must be tested** in a real OpenClaw workspace
- **No personal data** (keys, usernames, emails, logs)
- Explain *why* a setting/script exists, not just what it does

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT (see [LICENSE](./LICENSE))
