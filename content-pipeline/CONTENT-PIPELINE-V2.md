# Content Pipeline V2 - Master Documentation

**Status:** Active (replaces CONTENT-PIPELINE.md)  
**Last Updated:** 2025-01-30  
**Database ID:** `YOUR_NOTION_DATABASE_ID`

## Overview

The Content Pipeline V2 is a fully automated 5-stage content creation, approval, and optimization system. It consolidates the previous x-trend-reactor, x-morning-post, and x-evening-post workflows into a single, intelligent scanning system with continuous learning capabilities.

**Core Principle:** ALL posts require Alex's explicit approval before publishing to any platform.

---

## STAGE 1: SMART SCAN

**Trigger:** Every 2 hours, 8AM-10PM ET (`0 */2 8-22 * * *`)  
**Cron:** `content-smart-scan`

### Scanning Sources

1. **Bird CLI Commands:**
   - `bird trending` — current trending topics
   - `bird search` — 4 core pillars: AI agents, building in public, security, dev tools
   - `bird news` — breaking news and announcements

2. **Web Search:**
   - `web_search` for breaking tech/AI stories
   - Focus on last 24 hours for recency

### Scoring Algorithm (1-10 scale)

Each discovered topic gets scored based on 4 factors:

#### Recency Score (max +3)
- Last 4 hours: +3
- Last 12 hours: +2  
- Last 24 hours: +1
- Older: 0

#### Engagement Velocity (max +3)
- Viral (explosive growth): +3
- Trending (steady growth): +2
- Growing (moderate activity): +1
- Static: 0

#### Pillar Relevance (max +3)
- Core pillar match: +3
- Adjacent/related: +1
- Off-topic: 0

#### Uniqueness (max +2)
- Nobody else covering: +2
- Some coverage: +1
- Saturated: 0

### Action Thresholds

- **Score 7+:** Auto-create Notion row (status=`Idea`) + trigger auto-draft
- **Score 4-6:** Create Notion row (status=`Idea`) only
- **Score <4:** Log to `memory/trend-log.md`, skip

### Secondary Functions
- Check for `Approved` posts in Notion → trigger posting
- Monitor Discord #content for approval replies

---

## STAGE 2: AUTO-DRAFT

**Trigger:** High-scoring topics (7+) from Smart Scan

### Research Process

1. **Deep Research:**
   - `bird search` for additional context
   - `web_search` for comprehensive coverage
   - Check `memory/` for prior coverage to avoid duplication

2. **Voice Alignment:**
   - Read `memory/x-content-strategy.md` for voice guidelines
   - Match tone, style, and content pillars

### Draft Creation

1. **Generate Content:**
   - Create engaging post matching Alex's voice
   - Include relevant hashtags and mentions
   - Optimize for platform (X vs LinkedIn formatting)

2. **Notion Update:**
   - Create/update Content Calendar row
   - Set status=`Draft`
   - Include: Score, Sources, Platform assignment
   - Add research links and context

3. **Discord Notification:**
   - Send draft to #content channel (ID: `YOUR_DISCORD_CHANNEL_ID`)
   - Include Notion row link
   - Store Discord message ID in Notion row

---

## STAGE 3: APPROVAL + POST

**Critical Rule:** ZERO posts without Alex's approval

### Approval Methods

**Method A - Discord Reply:**
- Alex replies in #content with approval keywords: "post it", "go", "approved"
- System posts immediately upon detection
- Update Notion status to `Published`

**Method B - Notion Status:**
- Alex manually changes Notion status to `Approved`
- Next Smart Scan cycle detects and posts
- Update status to `Published`

### Posting Priority Order

1. **Bird CLI** (preferred)
   - `bird post "content"`
   - Most reliable method

2. **baoyu-post-to-x** (fallback)
   - Chrome CDP automation
   - Use when Bird CLI fails

3. **Manual Paste** (emergency)
   - Provide copy text to Discord
   - Alex pastes manually

### Post-Publishing Actions

1. Update Notion row:
   - Status: `Draft` → `Published`
   - Post URL: Extract from platform response
   - Posted At: Current timestamp
   - Platform: X or LinkedIn

2. Schedule metrics collection (3h delay)

---

## STAGE 4: MEASURE

**Trigger:** 3 hours after each post  
**Cron:** `content-metrics` (`0 21 * * *`)

### Metrics Collection

1. **Data Source:**
   - `bird user-tweets YOUR_X_HANDLE` for X posts
   - LinkedIn API for LinkedIn posts

2. **Tracked Metrics:**
   - Impressions
   - Replies
   - Likes
   - Retweets/Shares
   - Calculated: Engagement Rate

### Performance Analysis

1. **Update Notion:**
   - Fill all metric fields
   - Set Measured At timestamp
   - Calculate engagement rate: (likes + replies + retweets) / impressions

2. **Flag High Performers:**
   - Identify top 20% engagement rate
   - Mark for potential content recycling
   - Log patterns to learning system

---

## STAGE 5: CONTINUOUS LEARNING

**Trigger:** After each measurement cycle

### Weight Updates

1. **Topic Scoring:**
   - High-performing topics: +2 boost to similar topics in future scans
   - Underperforming pillars: reduce pillar weight
   - Track historical performance patterns

2. **Platform Optimization:**
   - X vs LinkedIn performance differences
   - Time-of-day posting patterns
   - Content format preferences

### Weekly Reporting

- Auto-generate performance summary
- Post to Discord #content
- Include recommendations for next week

---

## CRON SCHEDULE

| Cron Name | Schedule | Function |
|-----------|----------|----------|
| `content-smart-scan` | `0 */2 8-22 * * *` | Scan + draft + check approvals + post approved |
| `content-engagement` | `0 12,17 * * *` | Find high-engagement tweets + suggest replies |
| `content-metrics` | `0 21 * * *` | Pull metrics for all posts from today |

**Time Zone:** All times in ET (Eastern Time)

---

## NOTION DATABASE SCHEMA

**Database ID:** `YOUR_NOTION_DATABASE_ID`

### Core Properties

| Property | Type | Purpose |
|----------|------|---------|
| `Title` | Title | Post headline/topic |
| `Status` | Select | Idea/Draft/Approved/Published/Rejected |
| `Platform` | Select | X, LinkedIn |
| `Pillar` | Select | AI agents, building in public, security, dev tools |
| `Content` | Text | Full post content |
| `Score` | Number | Smart scan score (1-10) |
| `Sources` | URL | Research links |

### Engagement Properties

| Property | Type | Purpose |
|----------|------|---------|
| `Impressions` | Number | Total views |
| `Replies` | Number | Reply count |
| `Likes` | Number | Like count |
| `Retweets` | Number | Retweet/share count |
| `Engagement Rate` | Formula | Calculated percentage |

### Workflow Properties

| Property | Type | Purpose |
|----------|------|---------|
| `Posted At` | Date | Publication timestamp |
| `Measured At` | Date | When metrics were collected |
| `Discord Msg ID` | Text | Link to approval message |
| `Post URL` | URL | Link to published post |
| `Scheduled Date` | Date | Optional: scheduled posting |
| `Published Date` | Date | Actual publication date |

### Additional Properties

| Property | Type | Purpose |
|----------|------|---------|
| `Notes` | Text | Additional context |
| `Format` | Select | Thread, Single, Image, etc. |
| `Priority` | Select | High, Medium, Low |

---

## KEY FILES REFERENCE

### Strategy & Voice
- `memory/x-content-strategy.md` — Alex's voice, tone, posting rules, content pillars

### Data & Logs  
- `memory/trend-log.md` — Historical topic scores and trends
- `memory/content-performance.md` — Performance patterns and insights

### Documentation
- `docs/content-strategy/CONTENT-PIPELINE-V2.md` — This master document
- `docs/content-strategy/notion-content-db-schema.md` — Detailed database schema

---

## APPROVAL RULES (NON-NEGOTIABLE)

### Golden Rules
1. **NEVER post to X without Alex's approval**
2. **NEVER post to LinkedIn without Alex's approval**  
3. **ALL drafts go to Discord #content first**
4. **If technical posting fails, provide copy text for manual paste**

### Emergency Protocols
- If Discord is down: Log drafts to `memory/pending-approval.md`
- If Notion is down: Continue with local logs, sync when restored
- If all posting methods fail: Store content in `memory/failed-posts.md`

### Approval Keywords
**Positive:** "post it", "go", "approved", "yes", "send it", "publish"  
**Negative:** "no", "reject", "skip", "not now", "hold"  
**Modification:** "edit", "change", "revise" → require new approval after changes

---

## TROUBLESHOOTING

### Common Issues

**Smart Scan fails:**
- Check Bird CLI authentication
- Verify web search API keys
- Fall back to manual topic identification

**Posting fails:**
- Try Bird CLI → baoyu-post-to-x → manual paste
- Always provide copy text for manual backup

**Metrics missing:**
- Re-run collection after 1 hour delay
- Check API rate limits
- Manual collection if needed

### Monitoring
- Check cron logs daily
- Monitor Discord #content for stuck drafts
- Weekly review of Notion database health

---

## SUCCESS METRICS

### Pipeline Health
- **Scan Rate:** 8 scans daily (8AM-10PM)
- **Draft Quality:** >70% approval rate
- **Posting Success:** >95% successful auto-posting
- **Response Time:** <5 minutes from approval to post

### Content Performance  
- **Engagement Rate:** Target >5% average
- **Pillar Balance:** Equal distribution across 4 pillars
- **Trend Capture:** Breaking stories within 2 hours
- **Voice Consistency:** Matches Alex's style guidelines

---

*End of Document - Version 2.0*