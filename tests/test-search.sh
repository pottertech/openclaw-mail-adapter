#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Test: Search ==="

# Note: Requires notmuch index to exist
# This is a manual test - run after sync

if ! which notmuch >/dev/null; then
    echo "SKIP: notmuch not installed"
    exit 0
fi

echo "Searching for recent messages..."
bash "${SKILL_DIR}/src/search.sh" "date:1d.." plain | head -5 || echo "No results (expected if no mail synced)"

echo ""
echo "Search test complete"