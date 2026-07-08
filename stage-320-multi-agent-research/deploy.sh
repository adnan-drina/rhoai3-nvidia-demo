#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -f "$REPO_ROOT/.env" ]]; then
    set -a; source "$REPO_ROOT/.env"; set +a
fi
if [[ -z "${RHOAI_EXPECTED_API_SERVER:-}" ]]; then
    echo "ERROR: Set RHOAI_EXPECTED_API_SERVER in .env before deploying."; exit 1
fi
CURRENT_SERVER=$(oc whoami --show-server 2>/dev/null || true)
if [[ -z "$CURRENT_SERVER" ]] || [[ "$CURRENT_SERVER" != *"$RHOAI_EXPECTED_API_SERVER"* ]]; then
    echo "ERROR: Current API server does not match RHOAI_EXPECTED_API_SERVER."
    echo "  Expected substring: $RHOAI_EXPECTED_API_SERVER"; echo "  Current server: $CURRENT_SERVER"; exit 1
fi
if [[ -z "${TAVILY_API_KEY:-}" ]]; then
    echo "ERROR: TAVILY_API_KEY missing in .env (required for web research)."; exit 1
fi

echo "=== Stage 320: Multi-Agent Research (AI-Q) ==="
echo "Target cluster: $CURRENT_SERVER"

wait_until() {
    local desc=$1 timeout=$2; shift 2
    local start elapsed; start=$(date +%s)
    until "$@" >/dev/null 2>&1; do
        elapsed=$(( $(date +%s) - start ))
        if (( elapsed > timeout )); then echo "ERROR: timed out after ${timeout}s waiting for: $desc"; return 1; fi
        sleep 10
    done
    echo "OK: $desc"
}
check_eq() { local expected=$1; shift; [[ "$("$@" 2>/dev/null)" == "$expected" ]]; }

NS=research-agents
DOMAIN=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')
MAAS="https://maas.$DOMAIN/models-as-a-service"

echo "--- Namespace (app resources sync via ArgoCD; ensure ns for secrets)"
oc get ns $NS >/dev/null 2>&1 || oc create ns $NS

echo "--- Secrets (local-only, never committed)"
if ! oc get secret aiq-credentials -n $NS >/dev/null 2>&1; then
    oc create secret generic aiq-credentials -n $NS \
        --from-literal=DB_USER_NAME=aiq \
        --from-literal=DB_USER_PASSWORD="$(openssl rand -hex 16)" \
        --from-literal=TAVILY_API_KEY="$TAVILY_API_KEY" \
        ${SERPER_API_KEY:+--from-literal=SERPER_API_KEY="$SERPER_API_KEY"}
    echo "Created aiq-credentials."
else
    echo "aiq-credentials already present."
fi

# Persona hygiene: the research app runs with ai-researcher's own MaaS key
# (rhoai-demo-users are demo-premium owners), meaningful name, rotatable.
if ! oc get secret aiq-maas-key -n $NS >/dev/null 2>&1; then
    KC=$(mktemp)
    oc login "$CURRENT_SERVER" -u ai-researcher -p "$AI_RESEARCHER_PASSWORD" \
        --insecure-skip-tls-verify=true --kubeconfig="$KC" >/dev/null 2>&1
    TOK=$(oc --kubeconfig="$KC" whoami -t); rm -f "$KC"
    RESP=$(curl -sk -X POST "https://maas.$DOMAIN/maas-api/v1/api-keys" \
        -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' \
        -d '{"name":"aiq-research-agent-demo-premium","description":"AI-Q research app key (owned by ai-researcher); rotate via MaaS API keys page","subscription":"demo-premium"}')
    KEY=$(echo "$RESP" | python3 -c "import json,sys;print(json.load(sys.stdin).get('key',''))")
    if [[ -z "$KEY" ]]; then echo "ERROR: MaaS key mint failed: $(echo "$RESP" | head -c 160)"; exit 1; fi
    oc create secret generic aiq-maas-key -n $NS --from-literal=api-key="$KEY"
    echo "Created aiq-maas-key (aiq-research-agent-demo-premium)."
else
    echo "aiq-maas-key already present."
fi

echo "--- Model wiring (hosted NVIDIA models via MaaS; Option-2 posture)"
# Local swap (GPU arrival): point BASE_URLs at the local refs and model ids
# at the served names (gpt-oss-120b, nemotron-3-nano-30b-a3b,
# nemotron-mini-4b-instruct) - see PLAN.md demo beats.
oc create configmap aiq-model-wiring -n $NS \
    --from-literal=VLLM_BASE_URL="$MAAS/nemotron-nano-30b-hosted" \
    --from-literal=VLLM_RESEARCHER_MODEL="nvidia/nemotron-3-nano-30b-a3b" \
    --from-literal=VLLM_INTENT_BASE_URL="$MAAS/nemotron-nano-30b-hosted" \
    --from-literal=VLLM_INTENT_MODEL="nvidia/nemotron-3-nano-30b-a3b" \
    --from-literal=VLLM_ORCHESTRATOR_BASE_URL="$MAAS/gpt-oss-120b-hosted" \
    --from-literal=VLLM_ORCHESTRATOR_MODEL="openai/gpt-oss-120b" \
    --from-literal=VLLM_SUMMARY_BASE_URL="$MAAS/nemotron-mini-4b-hosted" \
    --from-literal=VLLM_SUMMARY_MODEL="nvidia/nemotron-mini-4b-instruct" \
    --dry-run=client -o yaml | oc apply -f -

echo "--- Stage 320 ArgoCD Application"
oc apply -f "$REPO_ROOT/gitops/argocd/app-of-apps/stage-320-multi-agent-research.yaml"
wait_until "stage-320 Application synced" 900 \
    check_eq "Synced" oc get application stage-320-multi-agent-research -n openshift-gitops \
    -o jsonpath='{.status.sync.status}'

echo "--- Workload rollout"
for d in aiq-postgres aiq-backend aiq-frontend; do
    wait_until "$d Available" 900 \
        check_eq "1" oc get deploy $d -n $NS -o jsonpath='{.status.readyReplicas}'
done

echo "=== Stage 320 deploy complete. Run validate.sh for E2E checks. ==="
