#!/usr/bin/env bash
# Validation and security checks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Rate limiting state
RATE_LIMIT_FILE="${CONFIG_DIR}/.rate_limit_state"

check_rate_limit() {
    local now
    now=$(date +%s)
    local window_start=$((now - 60))
    
    local count=0
    if [[ -f "$RATE_LIMIT_FILE" ]]; then
        local temp_file
        temp_file=$(mktemp)
        while read -r timestamp; do
            if [[ "$timestamp" -gt "$window_start" ]]; then
                echo "$timestamp" >> "$temp_file"
                ((count++))
            fi
        done < "$RATE_LIMIT_FILE"
        mv "$temp_file" "$RATE_LIMIT_FILE"
    fi
    
    if [[ "$count" -ge "$RATE_LIMIT_PER_MINUTE" ]]; then
        echo "ERROR: Rate limit exceeded ($RATE_LIMIT_PER_MINUTE/min)" >&2
        return 1
    fi
    
    echo "$now" >> "$RATE_LIMIT_FILE"
}

validate_recipient() {
    local email="$1"
    
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "ERROR: Invalid email format: $email" >&2
        return 1
    fi
    
    local domain="${email##*@}"
    local allowed=false
    IFS=',' read -ra domains <<< "$ALLOWED_DOMAINS"
    for d in "${domains[@]}"; do
        if [[ "$domain" == "$d" || "$ALLOWED_DOMAINS" == "*" ]]; then
            allowed=true
            break
        fi
    done
    
    if [[ "$allowed" != true ]]; then
        echo "ERROR: Domain not in allowlist: $domain" >&2
        return 1
    fi
}

validate_attachment() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "ERROR: Attachment not found: $file" >&2
        return 1
    fi
    
    local size
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    
    if [[ "$size" -gt "$MAX_ATTACHMENT_SIZE" ]]; then
        echo "ERROR: Attachment too large: $size bytes (max: $MAX_ATTACHMENT_SIZE)" >&2
        return 1
    fi
}

check_smtp_available() {
    if ! nc -w5 -z "${SMTP_HOST}" "${SMTP_PORT}" 2>/dev/null; then
        echo "WARNING: SMTP server unreachable: ${SMTP_HOST}:${SMTP_PORT}" >&2
        return 1
    fi
    return 0
}

check_maildir_available() {
    if [[ ! -d "$MAILDIR_PATH" ]]; then
        mkdir -p "$MAILDIR_PATH"
    fi
    if [[ ! -w "$MAILDIR_PATH" ]]; then
        echo "ERROR: Maildir not writable: $MAILDIR_PATH" >&2
        return 1
    fi
}