#!/usr/bin/env bash
# Mail adapter configuration loader
# Loads from env, then ~/.config/openclaw-mail-adapter/config.env

set -euo pipefail

CONFIG_DIR="${HOME}/.config/openclaw-mail-adapter"
CONFIG_FILE="${CONFIG_DIR}/config.env"
SECRETS_FILE="${CONFIG_DIR}/secrets.env"

# Defaults
export MAIL_DOMAIN="${MAIL_DOMAIN:-pottersquill.com}"
export SMTP_HOST="${SMTP_HOST:-mail.pottersquill.com}"
export SMTP_PORT="${SMTP_PORT:-465}"
export SMTP_ENCRYPTION="${SMTP_ENCRYPTION:-ssl}"
export SMTP_USER="${SMTP_USER:-}"
export SMTP_PASSWORD="${SMTP_PASSWORD:-}"
export IMAP_HOST="${IMAP_HOST:-mail.pottersquill.com}"
export IMAP_PORT="${IMAP_PORT:-993}"
export IMAP_USER="${IMAP_USER:-}"
export IMAP_PASSWORD="${IMAP_PASSWORD:-}"
export MAILDIR_PATH="${MAILDIR_PATH:-${HOME}/Mail/pottersquill}"
export AUDIT_LOG="${AUDIT_LOG:-${CONFIG_DIR}/audit.log}"
export TEST_MODE="${TEST_MODE:-false}"
export DRY_RUN="${DRY_RUN:-false}"
export RATE_LIMIT_PER_MINUTE="${RATE_LIMIT_PER_MINUTE:-30}"
export MAX_ATTACHMENT_SIZE="${MAX_ATTACHMENT_SIZE:-10485760}"
export ALLOWED_DOMAINS="${ALLOWED_DOMAINS:-pottersquill.com}"

# Load config if exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Load secrets if exists (separate file for security)
if [[ -f "$SECRETS_FILE" ]]; then
    source "$SECRETS_FILE"
fi

# Validate required vars
validate_config() {
    local missing=()
    [[ -z "${SMTP_USER:-}" ]] && missing+=("SMTP_USER")
    [[ -z "${SMTP_PASSWORD:-}" ]] && missing+=("SMTP_PASSWORD")
    [[ -z "${IMAP_USER:-}" ]] && missing+=("IMAP_USER")
    [[ -z "${IMAP_PASSWORD:-}" ]] && missing+=("IMAP_PASSWORD")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: Missing required config: ${missing[*]}" >&2
        echo "Set via environment or ${SECRETS_FILE}" >&2
        return 1
    fi
}

# Secret redaction for logs
redact() {
    local value="$1"
    if [[ ${#value} -gt 4 ]]; then
        echo "${value:0:2}****${value: -2}"
    else
        echo "****"
    fi
}