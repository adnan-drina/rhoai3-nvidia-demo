#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment
if [[ -f "$REPO_ROOT/.env" ]]; then
    set -a; source "$REPO_ROOT/.env"; set +a
fi

# Verify cluster guard (read-only checks, but still target the right cluster)
if [[ -z "${RHOAI_EXPECTED_API_SERVER:-}" ]]; then
    echo "ERROR: Set RHOAI_EXPECTED_API_SERVER in .env before validating."
    exit 1
fi
CURRENT_SERVER=$(oc whoami --show-server 2>/dev/null || true)
if [[ -z "$CURRENT_SERVER" ]] || [[ "$CURRENT_SERVER" != *"$RHOAI_EXPECTED_API_SERVER"* ]]; then
    echo "ERROR: Current API server does not match RHOAI_EXPECTED_API_SERVER."
    exit 1
fi

echo "=== Stage 110: Validation ==="
PASS=0
FAIL=0

check() {
    # check <description> <command...>
    local desc=$1; shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

check_eq() {
    local expected=$1; shift
    [[ "$("$@" 2>/dev/null)" == "$expected" ]]
}

# GitOps bootstrap
check "OpenShift GitOps operator CSV Succeeded" bash -c \
    "oc get csv -n openshift-operators -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^openshift-gitops-operator\..*=Succeeded'"
check "ArgoCD instance Available" \
    check_eq "Available" oc get argocd openshift-gitops -n openshift-gitops -o jsonpath='{.status.phase}'
check "ArgoCD tracking method is annotation" \
    check_eq "annotation" oc get argocd openshift-gitops -n openshift-gitops -o jsonpath='{.spec.resourceTrackingMethod}'
check "AppProject rhoai-nvidia-demo exists" \
    oc get appproject rhoai-nvidia-demo -n openshift-gitops
check "stage-110 Application Synced+Healthy" \
    check_eq "Synced Healthy" oc get application stage-110-rhoai-base-platform -n openshift-gitops \
    -o jsonpath='{.status.sync.status} {.status.health.status}'

# ODF MCG
check "ODF operator CSV Succeeded" bash -c \
    "oc get csv -n openshift-storage -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^odf-operator\..*=Succeeded'"
check "NooBaa Ready" \
    check_eq "Ready" oc get noobaa noobaa -n openshift-storage -o jsonpath='{.status.phase}'
check "Default backing store Ready" \
    check_eq "Ready" oc get backingstore noobaa-default-backing-store -n openshift-storage -o jsonpath='{.status.phase}'
check "MCG S3 route exists" oc get route s3 -n openshift-storage

# RHOAI
check "RHOAI operator CSV Succeeded (stable-3.4 channel)" bash -c \
    "oc get csv -n redhat-ods-operator -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^rhods-operator\..*=Succeeded'"
check "DSCInitialization Ready" bash -c \
    "oc get dscinitialization -o jsonpath='{.items[0].status.phase}' | grep -x Ready"
check "DataScienceCluster Ready" bash -c \
    "oc get datasciencecluster -o jsonpath='{.items[0].status.phase}' | grep -x Ready"
check "RHOAI dashboard route exists" bash -c \
    "oc get route -n redhat-ods-applications -o name | grep -q ."

echo
echo "Result: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
