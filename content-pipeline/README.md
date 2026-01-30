# Content Pipeline

Automated content creation pipeline for X and LinkedIn using Moltbot cron jobs + Notion as the single source of truth.

## How It Works

```
SCAN → DRAFT → APPROVE → POST → MEASURE → LEARN
 2h      auto    human     auto    3h post    weekly
```

**3 cron jobs replace 8+:**

| Cron | Schedule | What It Does |
|------|----------|-------------|
| `content-smart-scan` | Every 2h (8AM-10PM) | Scan trends, score topics, auto-draft high scorers, check Notion for approved posts |
| `content-engagement` | 12PM + 5PM | Find high-engagement tweets, draft value-add replies |
| `content-metrics` | 9PM | Pull engagement metrics, update Notion, flag top performers |

## Topic Scoring (1-10)

Each scanned topic gets scored on 4 dimensions:

- **Recency:** Last 4h = +3, 12h = +2, 24h = +1
- **Engagement velocity:** Viral = +3, trending = +2, growing = +1
- **Pillar relevance:** Core pillar = +3, adjacent = +1
- **Uniqueness:** Nobody else covering it = +2

Score 7+ → auto-draft + send to Discord for approval
Score 4-6 → log as Idea in Notion
Score <4 → log to trend-log.md, skip

## Approval Flow

All posts require human approval — no autonomous posting.

1. Draft appears in Discord #content with Notion link
2. Human replies "post it" → agent posts immediately
3. OR human marks Notion status = Approved → next scan cron picks it up

## Notion Database Properties

Your Content Calendar database needs these properties:

| Property | Type | Purpose |
|----------|------|---------|
| Title | Title | Post headline |
| Status | Select | Idea → Draft → Approved → Published → Rejected |
| Platform | Multi-select | X, LinkedIn |
| Pillar | Select | Your content pillars |
| Content | Rich text | Full draft |
| Score | Number | Topic relevance score (0-10) |
| Sources | URL | Source link |
| Impressions | Number | Post impressions |
| Replies | Number | Reply count |
| Likes | Number | Like count |
| Retweets | Number | Retweet count |
| Engagement Rate | Number | Calculated % |
| Posted At | Date | When posted |
| Measured At | Date | When metrics pulled |

## Setup

1. Create a Notion database with the properties above
2. Share it with your Notion integration
3. Update the database ID in your cron job payloads
4. Set your Discord channel ID for draft notifications
5. Configure your content pillars in `voice-and-strategy.md`

## Files

- `CONTENT-PIPELINE-V2.md` — Full pipeline specification (crons read this)
- `voice-and-strategy.md` — Voice, tone, posting rules, algorithm notes
