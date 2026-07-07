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

echo "=== Stage 110: RHOAI Base Platform ==="
echo "Target cluster: $CURRENT_SERVER"

wait_until() {
    # wait_until <description> <timeout-seconds> <command...>
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
    # check_eq <expected> <command...> - true when command output equals expected
    local expected=$1; shift
    [[ "$("$@" 2>/dev/null)" == "$expected" ]]
}

# ArgoCD pulls this stage from Git; warn when local GitOps content is ahead.
if [[ -n "$(git -C "$REPO_ROOT" status --porcelain gitops/ 2>/dev/null)" ]]; then
    echo "WARNING: uncommitted changes under gitops/ - ArgoCD deploys the pushed revision, not your working tree."
fi

echo "--- Bootstrap: OpenShift GitOps operator (script-applied by design)"
oc apply -k "$REPO_ROOT/gitops/bootstrap/base"
wait_until "ArgoCD CRD registered" 600 oc get crd argocds.argoproj.io
wait_until "openshift-gitops namespace" 600 oc get namespace openshift-gitops
wait_until "default ArgoCD instance created" 600 oc get argocd openshift-gitops -n openshift-gitops

echo "--- Bootstrap: ArgoCD instance config, AppProject, controller RBAC"
oc apply -k "$REPO_ROOT/gitops/bootstrap/overlays/demo"
wait_until "ArgoCD instance Available" 600 \
    check_eq "Available" oc get argocd openshift-gitops -n openshift-gitops -o jsonpath='{.status.phase}'

echo "--- Model registry DB secret (local-only, never committed)"
if ! oc get secret model-registry-db -n rhoai-model-registries >/dev/null 2>&1; then
    oc get namespace rhoai-model-registries >/dev/null 2>&1 || oc create namespace rhoai-model-registries
    DB_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20)
    oc create secret generic model-registry-db -n rhoai-model-registries \
        --from-literal=database-name=model_registry \
        --from-literal=database-user=mlmduser \
        --from-literal=database-password="$DB_PASSWORD"
    echo "Created model-registry-db secret."
else
    echo "model-registry-db secret already present."
fi

echo "--- Stage 110 ArgoCD Application"
oc apply -f "$REPO_ROOT/gitops/argocd/app-of-apps/stage-110-rhoai-base-platform.yaml"
wait_until "stage-110 Application synced and healthy" 1200 \
    check_eq "Synced Healthy" oc get application stage-110-rhoai-base-platform -n openshift-gitops \
    -o jsonpath='{.status.sync.status} {.status.health.status}'

echo "--- Operator installs (managed by ArgoCD sync)"
wait_until "ODF operator CSV Succeeded" 1200 bash -c \
    "oc get csv -n openshift-storage -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^odf-operator\..*=Succeeded'"
wait_until "RHOAI operator CSV Succeeded" 1200 bash -c \
    "oc get csv -n redhat-ods-operator -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^rhods-operator\..*=Succeeded'"

echo "=== Stage 110 deploy complete. Run validate.sh for full health checks. ==="
