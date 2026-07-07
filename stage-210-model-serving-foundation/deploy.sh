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

# KServe is activated by this stage's dsc-activation hook Job during sync.

echo "--- Stage 210 ArgoCD Application"
oc apply -f "$REPO_ROOT/gitops/argocd/app-of-apps/stage-210-model-serving-foundation.yaml"
wait_until "stage-210 Application synced" 900 \
    check_eq "Synced" oc get application stage-210-model-serving-foundation -n openshift-gitops \
    -o jsonpath='{.status.sync.status}'

wait_until "DSC kserve Managed (activation hook)" 600 \
    check_eq "Managed" oc get datasciencecluster default-dsc -o jsonpath='{.spec.components.kserve.managementState}'
wait_until "DSC KserveReady" 900 \
    check_eq "True" oc get datasciencecluster default-dsc -o jsonpath='{.status.conditions[?(@.type=="KserveReady")].status}'

echo "--- InferenceServices created (readiness requires GPU capacity)"
oc get llminferenceservices.serving.kserve.io -n models-as-a-service 2>/dev/null || true

echo "--- Dashboard surfaces for this stage (documented OdhDashboardConfig patch)"
# Model serving metrics + NIM serving UI belong to this stage.
oc patch odhdashboardconfig odh-dashboard-config -n redhat-ods-applications \
    --type merge -p '{"spec":{"dashboardConfig":{"disableKServeMetrics":false,"disablePerformanceMetrics":false,"disableNIMModelServing":false}}}'

echo "=== Stage 210 deploy complete. Model pods start when GPU nodes join; run validate.sh for status. ==="
