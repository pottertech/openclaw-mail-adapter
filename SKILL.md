---
name: openclaw-mail-adapter
description: "Sturdy mail adapter for OpenClaw using msmtp, mbsync, notmuch, and Mailpit."
homepage: https://github.com/pottertech/openclaw-mail-adapter
metadata:
  {
    "openclaw":
      {
        "emoji": "📧",
        "requires": { "bins": ["msmtp", "mbsync", "notmuch", "mailpit"] },
        "install":
          [
            {
              "id": "brew",
              "kind": "brew",
              "formula": "msmtp isync notmuch mailpit",
              "bins": ["msmtp", "mbsync", "notmuch", "mailpit"],
              "label": "Install mail tools (brew)",
            },
          ],
      },
  }
---

# openclaw-mail-adapter

Sturdy mail adapter replacing Himalaya with mature Unix tools.

## Architecture

```
Outbound:  OpenClaw → mail-adapter → msmtp → mail.pottersquill.com
Inbound:   mail.pottersquill.com → mbsync → Maildir → notmuch → OpenClaw
Testing:   OpenClaw → mail-adapter → Mailpit (localhost:1025)
```

## Commands

### Send Email
```bash
mail-adapter send --to recipient@pottersquill.com --subject "Hello" --body "Message"
```

### Sync Mail
```bash
mail-adapter sync [folder]
```

### Search Mail
```bash
mail-adapter search --query "from:boss@pottersquill.com"
```

### Read Mail
```bash
mail-adapter read --id <message-id>
```

### Test Mode (Mailpit)
```bash
mail-adapter test send --to test@example.com --subject "Test" --body "Hello"
```

## Configuration

Environment or `~/.config/openclaw-mail-adapter/secrets.env`:
```bash
SMTP_USER=admin@pottersquill.com
SMTP_PASSWORD=***
IMAP_USER=admin@pottersquill.com
IMAP_PASSWORD=***
MAIL_DOMAIN=pottersquill.com
```

## Security

- No secrets in logs (redacted)
- Audit trail for every operation
- Domain allowlist
- Rate limiting
- Attachment size limits
- Retry with exponential backoff