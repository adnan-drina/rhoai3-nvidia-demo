#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -f "$REPO_ROOT/.env" ]]; then
    set -a; source "$REPO_ROOT/.env"; set +a
fi

if [[ -z "${RHOAI_EXPECTED_API_SERVER:-}" ]]; then
    echo "ERROR: Set RHOAI_EXPECTED_API_SERVER in .env before deploying."
    exit 1
fi

CURRENT_SERVER=$(oc whoami --show-server 2>/dev/null || true)
if [[ -z "$CURRENT_SERVER" ]] || [[ "$CURRENT_SERVER" != *"$RHOAI_EXPECTED_API_SERVER"* ]]; then
    echo "ERROR: Current API server does not match RHOAI_EXPECTED_API_SERVER."
    exit 1
fi

echo "=== Stage 330: Agent Evaluation ==="
echo "Target cluster: $CURRENT_SERVER"

echo "Stage 330 deployment not yet implemented."
