# openclaw-mail-adapter

Sturdy mail adapter for OpenClaw that replaces Himalaya with mature Unix-style tools.

## Architecture

```
Outbound:
  OpenClaw -> mail-adapter -> msmtp -> Bluehost SMTP (mail.pottersquill.com)

Inbound:
  Bluehost IMAP -> mbsync -> Maildir -> notmuch index -> OpenClaw query layer

Testing:
  OpenClaw -> mail-adapter -> Mailpit (local capture)
```

## Components

| Layer | Tool | Purpose |
|-------|------|---------|
| SMTP Send | msmtp | Outbound mail relay |
| IMAP Sync | mbsync (isync) | Pull mail to local Maildir |
| Local Index | notmuch | Fast search and tagging |
| Test Capture | Mailpit | Safe SMTP testing without real delivery |
| Human Review | aerc (optional) | Terminal mail client |

## Quick Start

### 1. Install
```bash
cd openclaw-mail-adapter
make install
```

### 2. Configure
```bash
mkdir -p ~/.config/openclaw-mail-adapter
cat > ~/.config/openclaw-mail-adapter/secrets.env << 'EOF'
SMTP_USER=admin@pottersquill.com
SMTP_PASSWORD=your-smtp-password
IMAP_USER=admin@pottersquill.com
IMAP_PASSWORD=your-imap-password
EOF
chmod 600 ~/.config/openclaw-mail-adapter/secrets.env
```

### 3. Test
```bash
mail-adapter status
mail-adapter test send --to test@pottersquill.com --subject "Test" --body "Hello"
```

## Commands

### Send Email
```bash
mail-adapter send \
  --to recipient@example.com \
  --subject "Hello" \
  --body "Message body" \
  [--attachment FILE] \
  [--cc recipient2@example.com]
```

### Sync Mail
```bash
mail-adapter sync [folder]
```

### Search Mail
```bash
mail-adapter search --query "from:boss@example.com"
```

### Read Mail
```bash
mail-adapter read --id <message-id>
```

### Test Mode (Mailpit)
```bash
mail-adapter test send --to test@example.com --subject "Test" --body "Hello"
```

## Security

- Passwords stored in 1Password/Bitwarden, referenced via `passwordeval`/`PassCmd`
- No secrets in logs (redacted)
- Audit events for every operation
- Domain allowlist
- Rate limits per account
- Attachment size limits
- Retry logic with exponential backoff

## Audit Events

All actions emit structured audit events:

```json
{
  "event": "email.send",
  "timestamp": "2026-05-06T11:48:00Z",
  "account": "pottersquill",
  "message_id": "<uuid@pottersquill.com>",
  "to": ["recipient@example.com"],
  "subject": "Hello",
  "dry_run": false,
  "success": true,
  "smtp_code": 250,
  "duration_ms": 342
}
```

## Degraded Behavior

| Failure | Behavior |
|---------|----------|
| SMTP unreachable | Queue for retry, notify admin |
| IMAP unreachable | Use local Maildir cache, queue sync |
| Maildir full | Alert, skip sync, preserve existing |
| notmuch index corrupt | Rebuild from Maildir, alert |
| Mailpit down | Fall back to dry-run mode |

## License

MIT