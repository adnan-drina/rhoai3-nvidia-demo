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
    echo "ERROR: Set RHOAI_EXPECTED_API_SERVER in .env before validating."
    exit 1
fi
CURRENT_SERVER=$(oc whoami --show-server 2>/dev/null || true)
if [[ -z "$CURRENT_SERVER" ]] || [[ "$CURRENT_SERVER" != *"$RHOAI_EXPECTED_API_SERVER"* ]]; then
    echo "ERROR: Current API server does not match RHOAI_EXPECTED_API_SERVER."
    exit 1
fi

echo "=== Stage 210: Validation ==="
PASS=0
FAIL=0
WARN=0

check() {
    local desc=$1; shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $desc"; PASS=$((PASS + 1))
    else
        echo "FAIL: $desc"; FAIL=$((FAIL + 1))
    fi
}

check_eq() {
    local expected=$1; shift
    [[ "$("$@" 2>/dev/null)" == "$expected" ]]
}

check "stage-210 Application Synced" \
    check_eq "Synced" oc get application stage-210-model-serving-foundation -n openshift-gitops -o jsonpath='{.status.sync.status}'
check "DSC kserve component Managed" \
    check_eq "Managed" oc get datasciencecluster default-dsc -o jsonpath='{.spec.components.kserve.managementState}'
check "RHCL operator CSV Succeeded (pinned line)" bash -c \
    "oc get csv -n openshift-operators -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^rhcl-operator\..*=Succeeded'"
check "Kuadrant CR Ready" \
    check_eq "True" oc get kuadrant kuadrant -n kuadrant-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
check "Authorino listener TLS enabled" \
    check_eq "true" oc get authorino authorino -n kuadrant-system -o jsonpath='{.spec.listener.tls.enabled}'
check "maas-default-gateway Programmed" \
    check_eq "True" oc get gateway maas-default-gateway -n openshift-ingress -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}'
check "DSC LLMIS dependencies satisfied" \
    check_eq "True" oc get datasciencecluster default-dsc -o jsonpath='{.status.conditions[?(@.type=="KserveLLMInferenceServiceDependencies")].status}'
check "3 LLMInferenceServices present" bash -c \
    "oc get llminferenceservices.serving.kserve.io -n models-as-a-service --no-headers | wc -l | grep -Eq '^ *3$'"

gpu_nodes=$(oc get nodes -l node-role.kubernetes.io/gpu --no-headers 2>/dev/null | grep -c ' Ready' || true)

for isvc in gpt-oss-120b nemotron-3-nano-30b-a3b nemotron-mini-4b-instruct; do
    check "LLMInferenceService $isvc exists" oc get llminferenceservices.serving.kserve.io "$isvc" -n models-as-a-service
    ready=$(oc get llminferenceservices.serving.kserve.io "$isvc" -n models-as-a-service \
        -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo unknown)
    if [[ "$ready" == "True" ]]; then
        echo "PASS: LLMInferenceService $isvc Ready"; PASS=$((PASS + 1))
    elif [[ "$gpu_nodes" -eq 0 ]]; then
        echo "WARN: LLMInferenceService $isvc not Ready (no GPU nodes yet; AWS capacity pending)"
        WARN=$((WARN + 1))
    else
        echo "FAIL: LLMInferenceService $isvc not Ready (GPU nodes present)"; FAIL=$((FAIL + 1))
    fi
done

# Endpoint smoke test only when everything is Ready
if [[ "$gpu_nodes" -ge 1 ]]; then
    check "gpt-oss-120b endpoint responds (models list)" bash -c \
        "oc run curl-test-\$\$ --rm -i --restart=Never --image=registry.access.redhat.com/ubi9/ubi-minimal -n models-as-a-service --overrides='{\"spec\":{\"activeDeadlineSeconds\":60}}' -- curl -s https://gpt-oss-120b.models-as-a-service.svc.cluster.local:8000/v1/models -k | grep -q gpt-oss"
else
    echo "WARN: endpoint smoke tests skipped (no GPU nodes)"
    WARN=$((WARN + 1))
fi

echo
echo "Result: $PASS passed, $FAIL failed, $WARN warnings (GPU capacity waits)"
[[ $FAIL -eq 0 ]]
