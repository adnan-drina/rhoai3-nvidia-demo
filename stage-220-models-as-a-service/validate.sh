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

echo "=== Stage 220: Validation ==="
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

MAAS_NS="redhat-ods-applications"

check "stage-220 Application Synced" \
    check_eq "Synced" oc get application stage-220-models-as-a-service -n openshift-gitops -o jsonpath='{.status.sync.status}'
check "RHCL operator CSV Succeeded" bash -c \
    "oc get csv -n kuadrant-system -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^rhcl-operator\..*=Succeeded'"
check "Kuadrant CR Ready" \
    check_eq "True" oc get kuadrant kuadrant -n kuadrant-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
check "Authorino listener TLS enabled" \
    check_eq "true" oc get authorino authorino -n kuadrant-system -o jsonpath='{.spec.listener.tls.enabled}'
check "maas-default-gateway Programmed" \
    check_eq "True" oc get gateway maas-default-gateway -n openshift-ingress -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}'
check "Authorino TLS EnvoyFilter present" \
    oc get envoyfilter maas-default-gateway-authn-ssl -n openshift-ingress
check "DSC ModelsAsServiceReady" \
    check_eq "True" oc get datasciencecluster default-dsc -o jsonpath='{.status.conditions[?(@.type=="ModelsAsServiceReady")].status}'
check "maas-api pod Running" bash -c \
    "oc get pods -n $MAAS_NS -l app.kubernetes.io/name=maas-api --no-headers | grep -q ' Running'"
check "maas-db ready" bash -c \
    "oc get deployment maas-db -n $MAAS_NS -o jsonpath='{.status.readyReplicas}' | grep -x 1"
check "maas external route exists" \
    oc get route maas-default-gateway -n openshift-ingress

check "Dashboard genAiStudio + modelAsService enabled" bash -c \
    "oc get odhdashboardconfig odh-dashboard-config -n $MAAS_NS -o jsonpath='{.spec.dashboardConfig.genAiStudio}{.spec.dashboardConfig.modelAsService}' | grep -x truetrue"
check "DSC LlamaStackOperatorReady (MaaS dashboard prerequisite)" \
    check_eq "True" oc get datasciencecluster default-dsc -o jsonpath='{.status.conditions[?(@.type=="LlamaStackOperatorReady")].status}'

# Functional: the gateway must REJECT unauthenticated model access (401
# proves the Gateway -> Kuadrant wasm -> Authorino (TLS) chain end to end).
DOMAIN=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')
code=$(curl -sk -o /dev/null -w '%{http_code}' "https://maas.$DOMAIN/v1/models" --max-time 20 || echo 000)
if [[ "$code" == "401" ]]; then
    echo "PASS: unauthenticated /v1/models rejected with 401 (authz chain live)"
    PASS=$((PASS + 1))
else
    echo "FAIL: unauthenticated /v1/models returned $code (expected 401)"
    FAIL=$((FAIL + 1))
fi

# API-key subscriptions require MaaSModelRef/ExternalModel + MaaSSubscription
# resources, which arrive with Stage 310 model registration.
if oc get maassubscriptions.maas.opendatahub.io -A --no-headers 2>/dev/null | grep -q .; then
    check "MaaSSubscription present" bash -c "true"
else
    echo "WARN: no MaaSSubscription yet (API-key minting activates with Stage 310 model registration)"
    WARN=$((WARN + 1))
fi

echo
echo "Result: $PASS passed, $FAIL failed, $WARN warnings"
[[ $FAIL -eq 0 ]]
