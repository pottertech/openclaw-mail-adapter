#!/usr/bin/env bash
# Read mail from local Maildir

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/audit.sh"

read_mail() {
    local message_id="${1:-}"
    local format="${2:-text}"
    
    [[ -z "$message_id" ]] && { echo "ERROR: Message ID required" >&2; return 1; }
    
    check_maildir_available || return 1
    
    local msg_path
    msg_path=$(find "$MAILDIR_PATH" -type f -name "*${message_id}*" 2>/dev/null | head -1)
    
    if [[ -z "$msg_path" || ! -f "$msg_path" ]]; then
        audit_read false "$message_id" "Message not found in Maildir"
        echo "ERROR: Message not found: $message_id" >&2
        return 1
    fi
    
    local output=""
    
    case "$format" in
        raw)
            output=$(cat "$msg_path")
            ;;
        html)
            output=$(cat "$msg_path" | grep -A1000 "Content-Type: text/html" | grep -v "^Content-Type:" | sed '1d' | base64 -d 2>/dev/null || cat "$msg_path" | grep -A1000 "Content-Type: text/html" | grep -v "^Content-Type:" | sed '1d')
            ;;
        text|*)
            output=$(cat "$msg_path" | grep -A1000 "Content-Type: text/plain" | grep -v "^Content-Type:" | sed '1d' | head -100)
            [[ -z "$output" ]] && output=$(cat "$msg_path" | head -200)
            ;;
    esac
    
    audit_read true "$message_id"
    
    echo "From: $(grep "^From:" "$msg_path" | head -1 | cut -d: -f2- | xargs)"
    echo "Date: $(grep "^Date:" "$msg_path" | head -1 | cut -d: -f2- | xargs)"
    echo "Subject: $(grep "^Subject:" "$msg_path" | head -1 | cut -d: -f2- | xargs)"
    echo "---"
    echo "$output"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && read_mail "$@"