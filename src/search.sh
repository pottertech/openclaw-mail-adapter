#!/usr/bin/env bash
# Search mail via notmuch

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/audit.sh"

search_mail() {
    local query="${1:-}"
    local format="${2:-json}"
    
    [[ -z "$query" ]] && { echo "ERROR: Query required" >&2; return 1; }
    
    check_maildir_available || return 1
    
    notmuch new 2>/dev/null || true
    
    local start_time end_time
    start_time=$(date +%s)
    
    local results
    if results=$(notmuch search --format=json "$query" 2>/tmp/notmuch_err); then
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local count
        count=$(echo "$results" | jq 'length')
        
        audit_search true "$query" "$count"
        
        if [[ "$format" == "json" ]]; then
            echo "$results" | jq .
        else
            echo "$results" | jq -r '.[] | "\(.date_relative) | \(.authors) | \(.subject)"'
        fi
        
        return 0
    else
        local error_msg
        error_msg=$(cat /tmp/notmuch_err 2>/dev/null | head -1)
        audit_search false "$query" 0 "$error_msg"
        echo "ERROR: Search failed: $error_msg" >&2
        return 1
    fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && search_mail "$@"