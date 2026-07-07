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

echo "=== Stage 310: Validation ==="
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

MAAS_NS="models-as-a-service"

check "stage-310 Application Synced" \
    check_eq "Synced" oc get application stage-310-nvidia-nim-agents -n openshift-gitops -o jsonpath='{.status.sync.status}'
check "nvidia-api-credentials secret present" \
    oc get secret nvidia-api-credentials -n "$MAAS_NS"
check "4 ExternalModels present" bash -c \
    "oc get externalmodels.maas.opendatahub.io -n $MAAS_NS --no-headers | wc -l | grep -Eq '^ *4$'"
check "4 hosted MaaSModelRefs present" bash -c \
    "oc get maasmodelrefs.maas.opendatahub.io -n $MAAS_NS --no-headers | wc -l | grep -Eq '^ *4$'"
check "3 local MaaSModelRefs present (demo-sandbox)" bash -c \
    "oc get maasmodelrefs.maas.opendatahub.io -n demo-sandbox --no-headers | wc -l | grep -Eq '^ *3$'"
check "2 MaaSSubscriptions present" bash -c \
    "oc get maassubscriptions.maas.opendatahub.io -n $MAAS_NS --no-headers | wc -l | grep -Eq '^ *2$'"
check "2 MaaSAuthPolicies present" bash -c \
    "oc get maasauthpolicies.maas.opendatahub.io -n $MAAS_NS --no-headers | wc -l | grep -Eq '^ *2$'"

# Governed E2E: mint an API key (subscription auto-selected), list models,
# run a small completion against a hosted model through the MaaS gateway.
DOMAIN=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')
KEY_RESP=$(curl -sk -X POST "https://maas.$DOMAIN/maas-api/v1/api-keys" \
    -H "Authorization: Bearer $(oc whoami -t)" -H 'Content-Type: application/json' \
    -d '{"name":"stage-310-validation"}' --max-time 30 || true)
MAAS_KEY=$(echo "$KEY_RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('key',''))" 2>/dev/null || true)
if [[ -n "$MAAS_KEY" ]]; then
    echo "PASS: MaaS API key minted (subscription resolved)"; PASS=$((PASS + 1))
    if curl -sk "https://maas.$DOMAIN/v1/models" -H "Authorization: Bearer $MAAS_KEY" --max-time 30 | grep -q 'nemotron'; then
        echo "PASS: /v1/models lists registered models"; PASS=$((PASS + 1))
    else
        echo "FAIL: /v1/models did not list registered models"; FAIL=$((FAIL + 1))
    fi
    COMPLETION=$(curl -sk "https://maas.$DOMAIN/$MAAS_NS/nemotron-mini-4b-hosted/v1/chat/completions" \
        -H "Authorization: Bearer $MAAS_KEY" -H 'Content-Type: application/json' \
        -d '{"model":"nvidia/nemotron-mini-4b-instruct","messages":[{"role":"user","content":"Reply with exactly: MAAS-OK"}],"max_tokens":10}' \
        --max-time 60 || true)
    if echo "$COMPLETION" | grep -q 'MAAS-OK\|choices'; then
        echo "PASS: governed completion through MaaS gateway -> NVIDIA API Catalog"; PASS=$((PASS + 1))
    else
        echo "FAIL: governed completion failed: $(echo "$COMPLETION" | head -c 200)"; FAIL=$((FAIL + 1))
    fi
else
    echo "FAIL: could not mint MaaS API key: $(echo "$KEY_RESP" | head -c 200)"; FAIL=$((FAIL + 1))
fi

echo
echo "Result: $PASS passed, $FAIL failed, $WARN warnings"
[[ $FAIL -eq 0 ]]
