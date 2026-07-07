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
API_SERVER=$(oc whoami --show-server)

# Persona hygiene (project rule): validation runs as the demo personas, never
# kubeadmin; temporary keys carry meaningful names and are revoked after use.
persona_e2e() {
    # persona_e2e <user> <password> <subscription> <model-ref> <target-model>
    local user=$1 pass=$2 subscription=$3 modelref=$4 target=$5
    local kc token key_resp maas_key key_id completion
    kc=$(mktemp)
    if ! oc login "$API_SERVER" -u "$user" -p "$pass" \
        --insecure-skip-tls-verify=true --kubeconfig="$kc" >/dev/null 2>&1; then
        echo "FAIL: $user login failed (check AI_*_PASSWORD in .env)"; FAIL=$((FAIL + 1)); rm -f "$kc"; return
    fi
    token=$(oc --kubeconfig="$kc" whoami -t)
    key_resp=$(curl -sk -X POST "https://maas.$DOMAIN/maas-api/v1/api-keys" \
        -H "Authorization: Bearer $token" -H 'Content-Type: application/json' \
        -d "{\"name\":\"stage310-${subscription}-validation\",\"description\":\"temporary stage-310 validate.sh key for $user; auto-revoked\",\"subscription\":\"$subscription\"}" \
        --max-time 30 || true)
    maas_key=$(echo "$key_resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('key',''))" 2>/dev/null || true)
    key_id=$(echo "$key_resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || true)
    if [[ -z "$maas_key" ]]; then
        echo "FAIL: $user could not mint key on $subscription: $(echo "$key_resp" | head -c 160)"
        FAIL=$((FAIL + 1)); rm -f "$kc"; return
    fi
    echo "PASS: $user minted temporary key stage310-${subscription}-validation"; PASS=$((PASS + 1))
    if curl -sk "https://maas.$DOMAIN/v1/models" -H "Authorization: Bearer $maas_key" --max-time 30 | grep -q "$modelref"; then
        echo "PASS: $user sees $modelref in /v1/models"; PASS=$((PASS + 1))
    else
        echo "FAIL: $user does not see $modelref in /v1/models"; FAIL=$((FAIL + 1))
    fi
    completion=$(curl -sk "https://maas.$DOMAIN/$MAAS_NS/$modelref/v1/chat/completions" \
        -H "Authorization: Bearer $maas_key" -H 'Content-Type: application/json' \
        -d "{\"model\":\"$target\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with exactly: MAAS-OK\"}],\"max_tokens\":10}" \
        --max-time 90 || true)
    if echo "$completion" | grep -q 'choices'; then
        echo "PASS: $user governed completion via $modelref"; PASS=$((PASS + 1))
    else
        echo "FAIL: $user governed completion via $modelref: $(echo "$completion" | head -c 160)"; FAIL=$((FAIL + 1))
    fi
    if [[ -n "$key_id" ]]; then
        curl -sk -X DELETE "https://maas.$DOMAIN/maas-api/v1/api-keys/$key_id" \
            -H "Authorization: Bearer $token" -o /dev/null --max-time 30 || true
        echo "PASS: $user temporary key revoked"; PASS=$((PASS + 1))
    fi
    rm -f "$kc"
}

if [[ -n "${AI_DEVELOPER_PASSWORD:-}" ]]; then
    persona_e2e ai-developer "$AI_DEVELOPER_PASSWORD" demo-standard nemotron-mini-4b-hosted nvidia/nemotron-mini-4b-instruct
else
    echo "WARN: AI_DEVELOPER_PASSWORD unset; skipping developer-path E2E"; WARN=$((WARN + 1))
fi
if [[ -n "${AI_ADMIN_PASSWORD:-}" ]]; then
    persona_e2e ai-admin "$AI_ADMIN_PASSWORD" demo-premium gpt-oss-120b-hosted openai/gpt-oss-120b
else
    echo "WARN: AI_ADMIN_PASSWORD unset; skipping admin-path E2E"; WARN=$((WARN + 1))
fi

echo
echo "Result: $PASS passed, $FAIL failed, $WARN warnings"
[[ $FAIL -eq 0 ]]
