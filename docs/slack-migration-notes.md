# Slack Configuration Migration Notes

## OpenClaw 2026.2.14 Breaking Change: `dmPolicy` → `dm.policy`

OpenClaw 2026.2.14 introduced a key migration in the Slack plugin configuration to improve consistency and clarity.

### What Changed

**Before (2026.2.13 and earlier):**
```json5
{
  plugins: {
    slack: {
      dmPolicy: "allowlist",
      // ...
    }
  }
}
```

**After (2026.2.14+):**
```json5
{
  plugins: {
    slack: {
      dm: {
        policy: "allowlist",
        enabled: true
      },
      // ...
    }
  }
}
```

### Why This Changed

The nested `dm` object provides better organization for DM-specific settings and allows for future expansion (e.g., DM-specific rate limits, typing indicators, etc.).

### How to Migrate

#### Automatic Migration (Recommended)

Run the OpenClaw doctor tool to automatically fix your config:

```bash
openclaw doctor --fix
```

This will:
1. Detect the old `dmPolicy` key
2. Convert it to the new `dm.policy` structure
3. Add `dm.enabled: true` if DM policy is set
4. Back up your original config to `openclaw.json.backup`

#### Manual Migration

If you prefer to migrate manually:

1. Open your config file: `~/.openclaw/openclaw.json`
2. Find the `slack` plugin section
3. Replace `dmPolicy: "value"` with:
   ```json5
   dm: {
     policy: "value",
     enabled: true
   }
   ```
4. Save and restart the gateway: `openclaw gateway restart`

### Compatibility

- **OpenClaw 2026.2.14+**: Requires new format
- **OpenClaw 2026.2.13 and earlier**: Uses old format
- **Upgrade path**: Run `openclaw doctor --fix` after upgrading

### Related Settings

The `dm` object now centralizes all DM-related settings:

```json5
dm: {
  policy: "allowlist",      // "open", "allowlist", or "block"
  enabled: true,            // Enable/disable DM support entirely
  // Future settings may be added here:
  // requireMention: false,
  // rateLimit: { messages: 10, windowSeconds: 60 }
}
```

### Troubleshooting

**Error: "Unknown config key: dmPolicy"**
- You're running OpenClaw 2026.2.14+ with old config format
- Run `openclaw doctor --fix` to auto-migrate

**DMs not working after upgrade**
- Check that `dm.enabled: true` is set
- Verify your `allowlist` includes your user ID (find it in Slack → right-click your profile → Copy Member ID)
- Check gateway logs: `openclaw gateway logs`

**Want to revert to old version?**
- Downgrade OpenClaw: `openclaw update --version 2026.2.13`
- Restore backup config: `cp ~/.openclaw/openclaw.json.backup ~/.openclaw/openclaw.json`
- Restart gateway: `openclaw gateway restart`

## Session Sprawl Prevention

The Slack plugin defaults to creating a session for **every channel and thread** where the bot is mentioned. This can quickly lead to hundreds of idle sessions.

### Recommended Settings

```json5
{
  plugins: {
    slack: {
      groupPolicy: "allowlist",  // Only create sessions for listed channels
      dm: {
        policy: "allowlist",     // Only accept DMs from listed users
        enabled: true
      },
      allowlist: [
        "YOUR_OPS_CHANNEL_ID",  // ops channel
        "C9876543210",  // #engineering channel
        "U0ABCDEFGHI"   // Your user ID (for DMs)
      ],
      reactionNotifications: "off"  // Prevent spam from emoji reactions
    }
  }
}
```

### Finding Channel/User IDs

**Channel ID:**
1. Right-click the channel name in Slack
2. Select "View channel details"
3. Scroll to bottom — channel ID is shown there (starts with `C`)

**User ID:**
1. Right-click your profile picture
2. Select "Copy member ID"
3. ID starts with `U`

### Alternative: Open Policy

If you want the bot to respond everywhere (not recommended for large workspaces):

```json5
{
  plugins: {
    slack: {
      groupPolicy: "open",
      dm: { policy: "open", enabled: true },
      requireMention: {
        channel: true,   // Still require @mention in channels
        dm: false
      }
    }
  }
}
```

This prevents the bot from responding to every message, but allows anyone to interact via @mention.

## See Also

- [config/slack-setup.json5](../config/slack-setup.json5) - Full Slack configuration example
- [OpenClaw Slack Plugin Docs](https://github.com/openclaw/openclaw/blob/main/docs/plugins/slack.md)
