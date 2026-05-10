#!/usr/bin/env bash
# Send email via msmtp with validation, audit, retry

set -euo pipefail

# Handle both direct execution and sourcing
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${0:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
    # Fallback: try to find scripts relative to PATH
    SCRIPT_DIR="$(dirname "$(which send-email 2>/dev/null || echo '.')")"
fi

source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/validate.sh"
source "${SCRIPT_DIR}/audit.sh"

send_email() {
    local to="${1:-}"
    local subject="${2:-}"
    local body="${3:-}"
    local from="${4:-${SMTP_USER}}"
    local attachments=()
    local cc=()
    local bcc=()
    
    shift 3
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --attachment|-a)
                attachments+=("$2")
                shift 2
                ;;
            --cc)
                cc+=("$2")
                shift 2
                ;;
            --bcc)
                bcc+=("$2")
                shift 2
                ;;
            --from)
                from="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    [[ -z "$to" ]] && { echo "ERROR: Recipient required" >&2; return 1; }
    [[ -z "$subject" ]] && { echo "ERROR: Subject required" >&2; return 1; }
    
    validate_recipient "$to" || return 1
    check_rate_limit || return 1
    
    for addr in "${cc[@]+"${cc[@]}"}" "${bcc[@]+"${bcc[@]}"}"; do
        [[ -n "$addr" ]] && validate_recipient "$addr" || return 1
    done
    
    for att in "${attachments[@]+"${attachments[@]}"}"; do
        [[ -n "$att" ]] && validate_attachment "$att" || return 1
    done
    
    local boundary="----=_Part_$(date +%s)_$$"
    local message=""
    
    message+="From: ${from}"$'\n'
    message+="To: ${to}"$'\n'
    [[ ${#cc[@]} -gt 0 ]] && message+="Cc: $(IFS=,; echo "${cc[*]}")"$'\n'
    message+="Subject: ${subject}"$'\n'
    message+="Date: $(date -R)"$'\n'
    message+="Message-Id: <$(uuidgen)@${MAIL_DOMAIN}>"$'\n'
    message+="MIME-Version: 1.0"$'\n'
    
    if [[ ${#attachments[@]} -gt 0 ]]; then
        message+="Content-Type: multipart/mixed; boundary=\"${boundary}\""$'\n'
        message+=$'\n'"--${boundary}"$'\n'
        message+="Content-Type: text/plain; charset=UTF-8"$'\n'
        message+="Content-Transfer-Encoding: 7bit"$'\n'
        message+=$'\n'"${body}"$'\n'
        
        for att in "${attachments[@]}"; do
            local filename basename mime_type encoded
            filename="$(realpath "$att")"
            basename="$(basename "$att")"
            mime_type="$(file -b --mime-type "$att")"
            encoded="$(base64 "$att")"
            
            message+=$'\n'"--${boundary}"$'\n'
            message+="Content-Type: ${mime_type}; name=\"${basename}\""$'\n'
            message+="Content-Disposition: attachment; filename=\"${basename}\""$'\n'
            message+="Content-Transfer-Encoding: base64"$'\n'
            message+=$'\n'"${encoded}"$'\n'
        done
        
        message+="--${boundary}--"$'\n'
    else
        message+="Content-Type: text/plain; charset=UTF-8"$'\n'
        message+="Content-Transfer-Encoding: 7bit"$'\n'
        message+=$'\n'"${body}"$'\n'
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN - Would send:"
        echo "To: $to"
        echo "Subject: $subject"
        echo "From: $from"
        echo "Body: ${body:0:100}..."
        audit_send true "$to" "$subject" true
        return 0
    fi
    
    if [[ "$TEST_MODE" == "true" ]]; then
        echo "TEST MODE - Routing to Mailpit"
        echo "$message" | msmtp --host=127.0.0.1 --port=1025 --from="$from" "$to"
        audit_send true "$to" "$subject" false 250
        return 0
    fi
    
    local attempt=0
    local max_attempts=3
    local smtp_code=""
    local start_time end_time duration_ms
    
    start_time=$(perl -MTime::HiRes=time -e 'printf "%.0f\n", time*1000')
    
    while [[ $attempt -lt $max_attempts ]]; do
        ((attempt++))
        
        if ! check_smtp_available; then
            [[ $attempt -lt $max_attempts ]] && sleep $((2 ** attempt)) && continue
            end_time=$(perl -MTime::HiRes=time -e 'printf "%.0f\n", time*1000')
            duration_ms=$((end_time - start_time))
            audit_send false "$to" "$subject" false "" "$duration_ms" "SMTP unreachable"
            return 1
        fi
        
        if echo "$message" | msmtp --account=pottersquill --from="$from" "$to" 2>/tmp/msmtp_err; then
            end_time=$(perl -MTime::HiRes=time -e 'printf "%.0f\n", time*1000')
            duration_ms=$((end_time - start_time))
            audit_send true "$to" "$subject" false 250 "$duration_ms"
            return 0
        else
            smtp_code=$(grep -oP 'smtpstatus=\K\d+' /tmp/msmtp_err || echo "unknown")
            if [[ "$smtp_code" =~ ^(4[0-9][0-9])$ ]]; then
                [[ $attempt -lt $max_attempts ]] && sleep $((2 ** attempt))
            else
                break
            fi
        fi
    done
    
    end_time=$(perl -MTime::HiRes=time -e 'printf "%.0f\n", time*1000')
    duration_ms=$((end_time - start_time))
    local error_msg
    error_msg=$(cat /tmp/msmtp_err 2>/dev/null | head -1)
    audit_send false "$to" "$subject" false "$smtp_code" "$duration_ms" "$error_msg"
    return 1
}

# Only auto-run if executed directly, not sourced
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
    send_email "$@"
fi