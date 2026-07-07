#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment
if [[ -f "$REPO_ROOT/.env" ]]; then
    set -a; source "$REPO_ROOT/.env"; set +a
fi

# Verify cluster guard
if [[ -z "${RHOAI_EXPECTED_API_SERVER:-}" ]]; then
    echo "ERROR: Set RHOAI_EXPECTED_API_SERVER in .env before deploying."
    exit 1
fi
CURRENT_SERVER=$(oc whoami --show-server 2>/dev/null || true)
if [[ -z "$CURRENT_SERVER" ]] || [[ "$CURRENT_SERVER" != *"$RHOAI_EXPECTED_API_SERVER"* ]]; then
    echo "ERROR: Current API server does not match RHOAI_EXPECTED_API_SERVER."
    echo "  Expected substring: $RHOAI_EXPECTED_API_SERVER"
    echo "  Current server: $CURRENT_SERVER"
    exit 1
fi

echo "=== Stage 210: Model Serving Foundation ==="
echo "Target cluster: $CURRENT_SERVER"

wait_until() {
    local desc=$1 timeout=$2; shift 2
    local start elapsed
    start=$(date +%s)
    until "$@" >/dev/null 2>&1; do
        elapsed=$(( $(date +%s) - start ))
        if (( elapsed > timeout )); then
            echo "ERROR: timed out after ${timeout}s waiting for: $desc"
            return 1
        fi
        sleep 10
    done
    echo "OK: $desc"
}

check_eq() {
    local expected=$1; shift
    [[ "$("$@" 2>/dev/null)" == "$expected" ]]
}

# KServe must be enabled first (stage-110 DSC kserve component patch).
if ! check_eq "Managed" oc get datasciencecluster default-dsc -o jsonpath='{.spec.components.kserve.managementState}'; then
    echo "ERROR: DSC kserve component is not Managed; sync stage-110 first."
    exit 1
fi

echo "--- Stage 210 ArgoCD Application"
oc apply -f "$REPO_ROOT/gitops/argocd/app-of-apps/stage-210-model-serving-foundation.yaml"
wait_until "stage-210 Application synced" 900 \
    check_eq "Synced" oc get application stage-210-model-serving-foundation -n openshift-gitops \
    -o jsonpath='{.status.sync.status}'

echo "--- InferenceServices created (readiness requires GPU capacity)"
oc get inferenceservice -n demo-sandbox

echo "=== Stage 210 deploy complete. Model pods start when GPU nodes join; run validate.sh for status. ==="
