#!/usr/bin/env bash
# Sync mail via mbsync

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/validate.sh"
source "${SCRIPT_DIR}/audit.sh"

sync_mail() {
    local folder="${1:-INBOX}"
    local full_sync="${2:-false}"
    
    check_maildir_available || return 1
    
    local mbsyncrc="${CONFIG_DIR}/mbsyncrc"
    if [[ ! -f "$mbsyncrc" ]]; then
        cat > "$mbsyncrc" << EOF
IMAPAccount pottersquill
Host ${IMAP_HOST}
Port ${IMAP_PORT}
User ${IMAP_USER}
Pass ${IMAP_PASSWORD}
SSLType IMAPS

IMAPStore pottersquill-remote
Account pottersquill

MaildirStore pottersquill-local
Path ${MAILDIR_PATH}/
Inbox ${MAILDIR_PATH}/Inbox

Channel pottersquill-inbox
Master :pottersquill-remote:INBOX
Slave :pottersquill-local:Inbox
Create Both
Expunge Both
SyncState *

Channel pottersquill-sent
Master :pottersquill-remote:Sent
Slave :pottersquill-local:Sent
Create Both
Expunge Both
SyncState *
EOF
    fi
    
    local sync_flags=""
    [[ "$full_sync" == "true" ]] && sync_flags="--full"
    
    local start_time end_time
    start_time=$(date +%s)
    
    if mbsync -c "$mbsyncrc" $sync_flags "pottersquill-inbox" 2>/tmp/mbsync_err; then
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        local msg_count=0
        if [[ -d "${MAILDIR_PATH}/${folder}/new" ]]; then
            msg_count=$(find "${MAILDIR_PATH}/${folder}/new" -type f | wc -l)
        fi
        
        notmuch new 2>/dev/null || true
        
        audit_sync true "$folder" "$msg_count"
        echo "Synced $folder in ${duration}s ($msg_count messages)"
        return 0
    else
        local error_msg
        error_msg=$(cat /tmp/mbsync_err 2>/dev/null | head -1)
        audit_sync false "$folder" 0 "$error_msg"
        echo "ERROR: Sync failed: $error_msg" >&2
        return 1
    fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && sync_mail "$@"