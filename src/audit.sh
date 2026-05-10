#!/usr/bin/env bash
# Audit event logging - structured JSON

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

AUDIT_FILE="${AUDIT_LOG}"

ensure_audit_dir() {
    local dir
    dir="$(dirname "$AUDIT_FILE")"
    [[ -d "$dir" ]] || mkdir -p "$dir"
}

emit_audit() {
    local event="$1"
    local payload="$2"
    
    ensure_audit_dir
    
    local timestamp
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    
    local audit_entry
    audit_entry=$(jq -n \
        --arg event "$event" \
        --arg timestamp "$timestamp" \
        --argjson payload "$payload" \
        '{
            event: $event,
            timestamp: $timestamp,
            payload: $payload
        }')
    
    echo "$audit_entry" >> "$AUDIT_FILE"
    echo "$audit_entry" >&2
}

audit_send() {
    local success="$1"
    local to="$2"
    local subject="$3"
    local dry_run="$4"
    local smtp_code="${5:-}"
    local duration_ms="${6:-}"
    local error="${7:-}"
    
    local to_redacted
    to_redacted=$(echo "$to" | sed 's/[^@]*/****/g')
    
    local payload
    payload=$(jq -n \
        --arg to "$to_redacted" \
        --arg subject "$subject" \
        --argjson success "$success" \
        --argjson dry_run "$dry_run" \
        --arg smtp_code "${smtp_code:-null}" \
        --arg duration_ms "${duration_ms:-null}" \
        --arg error "${error:-null}" \
        '{
            to: $to,
            subject: $subject,
            success: $success,
            dry_run: $dry_run,
            smtp_code: $smtp_code,
            duration_ms: $duration_ms,
            error: $error
        }')
    
    emit_audit "email.send" "$payload"
}

audit_sync() {
    local success="$1"
    local folder="$2"
    local messages_synced="${3:-0}"
    local error="${4:-}"
    
    local payload
    payload=$(jq -n \
        --arg folder "$folder" \
        --argjson success "$success" \
        --argjson messages_synced "$messages_synced" \
        --arg error "${error:-null}" \
        '{
            folder: $folder,
            success: $success,
            messages_synced: $messages_synced,
            error: $error
        }')
    
    emit_audit "email.sync" "$payload"
}

audit_search() {
    local success="$1"
    local query="$2"
    local results_count="${3:-0}"
    local error="${4:-}"
    
    local payload
    payload=$(jq -n \
        --arg query "$query" \
        --argjson success "$success" \
        --argjson results_count "$results_count" \
        --arg error "${error:-null}" \
        '{
            query: $query,
            success: $success,
            results_count: $results_count,
            error: $error
        }')
    
    emit_audit "email.search" "$payload"
}

audit_read() {
    local success="$1"
    local message_id="$2"
    local error="${3:-}"
    
    local payload
    payload=$(jq -n \
        --arg message_id "$message_id" \
        --argjson success "$success" \
        --arg error "${error:-null}" \
        '{
            message_id: $message_id,
            success: $success,
            error: $error
        }')
    
    emit_audit "email.read" "$payload"
}