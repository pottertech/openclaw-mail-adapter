#!/usr/bin/env bash
set -euo pipefail

echo "=== Test: Sync ==="
if [[ -z "${IMAP_PASSWORD:***" ]]; then
    echo "SKIP: IMAP_PASSWORD not set"
    exit 0
fi

bash "${SKILL_DIR}/src/sync.sh" INBOX
echo "Sync test completed"