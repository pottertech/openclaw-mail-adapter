# Bug Report: BASH_SOURCE[0] Empty in Subshells

## Reporter
- **Agent:** Brodie Foxworth
- **Date:** 2026-05-10 11:21 EDT
- **Severity:** Medium
- **Status:** Open

## Issue Summary
The original SKILL/scripts fail when sourced due to `${BASH_SOURCE[0]}` being empty in subshells.

## Affected Files
- `src/send.sh`
- `src/sync.sh`
- `src/search.sh`
- `src/read.sh`
- `src/validate.sh`
- `src/audit.sh`

## Root Cause
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

When scripts are sourced (not executed directly), `${BASH_SOURCE[0]}` may be empty or different in subshells, causing `dirname` to fail.

## Impact
- Scripts fail in cron jobs (isolated sessions)
- Scripts fail when sourced from other scripts
- Breaks mail adapter automation

## Proposed Fix
Replace `${BASH_SOURCE[0]}` with a more robust path detection:

```bash
# Option 1: Use $0 as fallback
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Option 2: Use absolute paths
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "$0")" && pwd)}"

# Option 3: Set SCRIPT_DIR externally when sourcing
export SCRIPT_DIR="/path/to/openclaw-mail-adapter"
source "${SCRIPT_DIR}/src/send.sh"
```

## Testing Needed
- [ ] Source scripts in subshells
- [ ] Source scripts in cron jobs
- [ ] Direct execution still works
- [ ] Relative path sourcing works

## Next Steps
1. Fix all affected scripts
2. Test in isolated sessions
3. Update cron job configuration
4. Verify fix works in production