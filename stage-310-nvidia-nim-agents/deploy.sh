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

echo "=== Stage 310: NVIDIA hosted models via MaaS ==="
echo "Target cluster: $CURRENT_SERVER"

wait_until() {
    local desc=$1 timeout=$2; shift 2
    local start
    start=$(date +%s)
    until "$@" >/dev/null 2>&1; do
        if (( $(date +%s) - start > timeout )); then
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

if [[ -z "${NVIDIA_API_KEY:-}" ]]; then
    echo "ERROR: NVIDIA_API_KEY is not set in .env (required for hosted NIM access)."
    exit 1
fi

echo "--- NVIDIA API credential secret (local-only, never committed)"
oc create secret generic nvidia-api-credentials -n models-as-a-service \
    --from-literal=api-key="$NVIDIA_API_KEY" \
    --dry-run=client -o yaml | oc apply -f -
# Data key "api-key" AND this label are both required by the
# payload-processing ext-proc (proven rhoai3-demo trap: missing label ->
# "provider 'openai' credentials not found").
oc label secret nvidia-api-credentials -n models-as-a-service \
    inference.networking.k8s.io/bbr-managed=true --overwrite

echo "--- Stage 310 ArgoCD Application"
oc apply -f "$REPO_ROOT/gitops/argocd/app-of-apps/stage-310-nvidia-nim-agents.yaml"
wait_until "stage-310 Application synced" 900 \
    check_eq "Synced" oc get application stage-310-nvidia-nim-agents -n openshift-gitops \
    -o jsonpath='{.status.sync.status}'
wait_until "ExternalModels present (4)" 300 bash -c \
    "oc get externalmodels.maas.opendatahub.io -n models-as-a-service --no-headers | wc -l | grep -qx ' *4'"
wait_until "MaaSSubscriptions present (2)" 300 bash -c \
    "oc get maassubscriptions.maas.opendatahub.io -n models-as-a-service --no-headers | wc -l | grep -qx ' *2'"

echo "=== Stage 310 deploy complete. Run validate.sh for the governed E2E test. ==="
