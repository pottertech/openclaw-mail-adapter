#!/usr/bin/env bash
set -euo pipefail

echo "=== Test 1: Dry run ==="
DRY_RUN=true bash "${SKILL_DIR}/src/send.sh" --to "test@pottersquill.com" --subject "Test" --body "Hello"

echo ""
echo "=== Test 2: Invalid recipient ==="
! bash "${SKILL_DIR}/src/send.sh" --to "invalid" --subject "Test" --body "Hello" || {
    echo "FAIL: Should have rejected invalid email"; exit 1
}

echo ""
echo "=== Test 3: Domain allowlist ==="
ALLOWED_DOMAINS="pottersquill.com" bash "${SKILL_DIR}/src/send.sh" --to "test@other.com" --subject "Test" --body "Hello" && {
    echo "FAIL: Should have rejected unauthorized domain"; exit 1
} || echo "PASS: Correctly rejected unauthorized domain"

echo ""
echo "=== Test 4: Rate limit ==="
RATE_LIMIT_PER_MINUTE=2
for i in 1 2 3; do
    DRY_RUN=true bash "${SKILL_DIR}/src/send.sh" --to "test@pottersquill.com" --subject "Test $i" --body "Hello" && \
        echo "Request $i: OK" || echo "Request $i: RATE LIMITED"
done

echo ""
echo "All send tests passed"