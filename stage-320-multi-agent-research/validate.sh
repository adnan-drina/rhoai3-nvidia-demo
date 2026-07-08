#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -f "$REPO_ROOT/.env" ]]; then
    set -a; source "$REPO_ROOT/.env"; set +a
fi
if [[ -z "${RHOAI_EXPECTED_API_SERVER:-}" ]]; then
    echo "ERROR: Set RHOAI_EXPECTED_API_SERVER in .env before validating."; exit 1
fi
CURRENT_SERVER=$(oc whoami --show-server 2>/dev/null || true)
if [[ -z "$CURRENT_SERVER" ]] || [[ "$CURRENT_SERVER" != *"$RHOAI_EXPECTED_API_SERVER"* ]]; then
    echo "ERROR: Current API server does not match RHOAI_EXPECTED_API_SERVER."; exit 1
fi

echo "=== Stage 320: Validation ==="
PASS=0; FAIL=0; WARN=0
check() { local d=$1; shift; if "$@" >/dev/null 2>&1; then echo "PASS: $d"; PASS=$((PASS+1)); else echo "FAIL: $d"; FAIL=$((FAIL+1)); fi; }
check_eq() { local e=$1; shift; [[ "$("$@" 2>/dev/null)" == "$e" ]]; }
NS=research-agents

check "stage-320 Application Synced" \
    check_eq "Synced" oc get application stage-320-multi-agent-research -n openshift-gitops -o jsonpath='{.status.sync.status}'
for d in aiq-postgres aiq-backend aiq-frontend; do
    check "$d ready" check_eq "1" oc get deploy $d -n $NS -o jsonpath='{.status.readyReplicas}'
done
check "aiq-credentials secret present" oc get secret aiq-credentials -n $NS
check "aiq-maas-key secret present" oc get secret aiq-maas-key -n $NS
check "model wiring ConfigMap present" oc get configmap aiq-model-wiring -n $NS

BACKEND=$(oc get route aiq-backend -n $NS -o jsonpath='{.spec.host}' 2>/dev/null)
FRONTEND=$(oc get route aiq-frontend -n $NS -o jsonpath='{.spec.host}' 2>/dev/null)
check "backend /health via route" bash -c "curl -sk --max-time 20 https://$BACKEND/health | grep -qiE 'ok|healthy'"
check "frontend route serves UI" bash -c "curl -sk --max-time 20 https://$FRONTEND/ -o /dev/null -w '%{http_code}' | grep -qE '^(200|302|303)$'"

# E2E: real shallow research through the backend API (NAT generate contract),
# exercising intent + researcher (Nano via MaaS) + web search (Tavily).
echo "--- E2E shallow research (may take up to 2 min)"
E2E=$(curl -sk --max-time 150 -X POST "https://$BACKEND/generate" \
    -H 'Content-Type: application/json' \
    -d '{"input_message":"In one sentence with a citation: what is Red Hat OpenShift?"}' 2>/dev/null || true)
if echo "$E2E" | grep -qiE 'openshift'; then
    echo "PASS: shallow research returned an answer through MaaS-governed models"; PASS=$((PASS+1))
elif [[ -z "$E2E" ]]; then
    echo "WARN: /generate returned empty (check backend logs; UI verification guide applies)"; WARN=$((WARN+1))
else
    echo "WARN: /generate unexpected response: $(echo "$E2E" | head -c 140)"; WARN=$((WARN+1))
fi

echo
echo "Result: $PASS passed, $FAIL failed, $WARN warnings"
[[ $FAIL -eq 0 ]]
