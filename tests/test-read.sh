#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SKILL_DIR}/src/config.sh"

echo "=== Test: Read from Maildir ==="

# Create a test message in Maildir
mkdir -p "${MAILDIR_PATH}/Inbox/new"
TEST_MSG="${MAILDIR_PATH}/Inbox/new/test-$(date +%s).msg"

cat > "$TEST_MSG" << 'EOF'
From: test@example.com
Date: Wed, 06 May 2026 12:00:00 +0000
Subject: Test Message
Message-Id: <test123@example.com>
Content-Type: text/plain; charset=UTF-8

This is a test message body.
EOF

echo "Created test message: $TEST_MSG"

# Test reading the message
echo ""
echo "=== Read raw ==="
bash "${SKILL_DIR}/src/read.sh" "test123" raw | head -5

echo ""
echo "=== Read text ==="
bash "${SKILL_DIR}/src/read.sh" "test123" text | head -5

# Cleanup
rm "$TEST_MSG"

echo ""
echo "Read tests passed"