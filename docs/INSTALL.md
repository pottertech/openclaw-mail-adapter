# Installation Guide

## Prerequisites

- bash 4.0+
- jq (JSON processing)
- uuidgen (usually pre-installed)

## Install Dependencies

### macOS
```bash
brew install msmtp isync notmuch mailpit
```

### Debian/Ubuntu
```bash
sudo apt-get install msmtp isync notmuch
# Mailpit: download from https://github.com/axllent/mailpit/releases
```

## Install openclaw-mail-adapter

### Option 1: Copy from workspace
```bash
cp -r ~/.openclaw/workspace/openclaw-mail-adapter ~/.openclaw/skills/
chmod +x ~/.openclaw/skills/openclaw-mail-adapter/{bin,src,tests}/*.sh
```

### Option 2: Symlink (for development)
```bash
ln -s ~/.openclaw/workspace/openclaw-mail-adapter ~/.openclaw/skills/openclaw-mail-adapter
```

## Configure

1. Create config directory:
```bash
mkdir -p ~/.config/openclaw-mail-adapter
```

2. Create secrets file:
```bash
cat > ~/.config/openclaw-mail-adapter/secrets.env << 'EOF'
SMTP_USER=admin@pottersquill.com
SMTP_PASSWORD=your-password-here
IMAP_USER=admin@pottersquill.com
IMAP_PASSWORD=your-password-here
EOF
chmod 600 ~/.config/openclaw-mail-adapter/secrets.env
```

3. Test configuration:
```bash
mail-adapter status
```

## Verify Installation

Run the test suite:
```bash
cd ~/.openclaw/skills/openclaw-mail-adapter
bash tests/test-send.sh
```

## Optional: Configure msmtp

Create `~/.config/msmtp/config`:
```
defaults
auth on
tls on
tls_starttls off

account pottersquill
host mail.pottersquill.com
port 465
from admin@pottersquill.com
user admin@pottersquill.com
passwordeval "cat ~/.config/openclaw-mail-adapter/secrets.env | grep SMTP_PASSWORD | cut -d= -f2"
```

## Optional: Configure mbsync

Create `~/.mbsyncrc`:
```
IMAPAccount pottersquill
Host mail.pottersquill.com
Port 993
User admin@pottersquill.com
PassCmd "grep IMAP_PASSWORD ~/.config/openclaw-mail-adapter/secrets.env | cut -d= -f2"
SSLType IMAPS

IMAPStore pottersquill-remote
Account pottersquill

MaildirStore pottersquill-local
Path ~/Mail/pottersquill/
Inbox ~/Mail/pottersquill/Inbox

Channel pottersquill-inbox
Master :pottersquill-remote:INBOX
Slave :pottersquill-local:Inbox
Create Both
Expunge Both
SyncState *
```