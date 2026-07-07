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

echo "--- LLMIS serving prerequisites (cert-manager, RHCL, Kuadrant, gateway)"
wait_until "cert-manager CSV Succeeded" 900 bash -c \
    "oc get csv -n cert-manager-operator --no-headers 2>/dev/null | grep cert-manager-operator | grep -q Succeeded"
wait_until "RHCL operator CSV Succeeded (pinned v1.3.4)" 1500 bash -c \
    "oc get csv -n openshift-operators -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^rhcl-operator\..*=Succeeded'"
# Known ordering effect of the combined pinned InstallPlan: the Kuadrant
# operator can start before its dependency operators register and caches
# that state; the CR's own message prescribes an operator restart.
if oc get kuadrant kuadrant -n kuadrant-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}' 2>/dev/null | grep -q "not installed"; then
    echo "Kuadrant cached missing dependencies; deleting its operator pod (per CR message; rollout restart is a no-op because OLM reverts template changes)"
    oc delete pod -n openshift-operators -l app=kuadrant --ignore-not-found
    oc get pods -n openshift-operators -o name | grep kuadrant-operator | xargs -r oc delete -n openshift-operators
fi
wait_until "Kuadrant CR Ready" 900 \
    check_eq "True" oc get kuadrant kuadrant -n kuadrant-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
wait_until "maas-default-gateway Programmed" 600 \
    check_eq "True" oc get gateway maas-default-gateway -n openshift-ingress -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}'

wait_until "DSC kserve Managed (activation hook)" 600 \
    check_eq "Managed" oc get datasciencecluster default-dsc -o jsonpath='{.spec.components.kserve.managementState}'
wait_until "DSC KserveReady" 900 \
    check_eq "True" oc get datasciencecluster default-dsc -o jsonpath='{.status.conditions[?(@.type=="KserveReady")].status}'

echo "--- InferenceServices created (readiness requires GPU capacity)"
oc get llminferenceservices.serving.kserve.io -n models-as-a-service 2>/dev/null || true

echo "=== Stage 210 deploy complete. Model pods start when GPU nodes join; run validate.sh for status. ==="
