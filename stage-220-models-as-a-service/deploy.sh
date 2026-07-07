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

echo "=== Stage 220: Models as a Service ==="
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

MAAS_NS="redhat-ods-applications"

echo "--- MaaS database secrets (local-only, never committed)"
if ! oc get secret maas-db-credentials -n "$MAAS_NS" >/dev/null 2>&1; then
    DB_PASSWORD=$(openssl rand -hex 16)
    oc create secret generic maas-db-credentials -n "$MAAS_NS" \
        --from-literal=database-name=maas \
        --from-literal=database-user=maas \
        --from-literal=database-password="$DB_PASSWORD"
    oc create secret generic maas-db-config -n "$MAAS_NS" \
        --from-literal=DB_CONNECTION_URL="postgresql://maas:${DB_PASSWORD}@maas-db.${MAAS_NS}.svc.cluster.local:5432/maas?sslmode=disable"
    echo "Created maas-db-credentials and maas-db-config secrets."
else
    echo "maas-db secrets already present."
fi

echo "--- Stage 220 ArgoCD Application"
oc apply -f "$REPO_ROOT/gitops/argocd/app-of-apps/stage-220-models-as-a-service.yaml"
wait_until "stage-220 Application synced" 900 \
    check_eq "Synced" oc get application stage-220-models-as-a-service -n openshift-gitops \
    -o jsonpath='{.status.sync.status}'

# Authorino TLS is GitOps-owned (Authorino CR + pre-annotated Service +
# service-CA trust hook Job in rhcl/instance). Nudge the RHOAI
# gateway-auth-bootstrap so it observes TLS and creates the authn-ssl
# EnvoyFilter (it only reconciles on Gateway events).
echo "--- Gateway reconcile nudge for Authorino TLS EnvoyFilter"
oc annotate gateway maas-default-gateway -n openshift-ingress \
    reconcile.opendatahub.io/nudge="$(date +%s)" --overwrite
wait_until "Authorino TLS EnvoyFilter created" 300 \
    oc get envoyfilter maas-default-gateway-authn-ssl -n openshift-ingress

echo "--- External access route (mirrors the RHOAI data-science-gateway pattern)"
DOMAIN=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')
oc create route passthrough maas-default-gateway -n openshift-ingress \
    --service=maas-default-gateway-data-science-gateway-class --port=443 \
    --hostname="maas.$DOMAIN" 2>/dev/null || echo "maas route already present"

echo "--- MaaS dashboard interface (documented OdhDashboardConfig admin patch)"
# OdhDashboardConfig is an operator-created singleton; per the RHOAI 3.4
# MaaS guide, enable Gen AI studio and the MaaS page (AI asset endpoints).
# Full demo flag set pinned explicitly (upstream defaults vary per build;
# disableHardwareProfiles is deprecated and must not be set).
oc patch odhdashboardconfig odh-dashboard-config -n "$MAAS_NS" --type merge \
    -p '{"spec":{"dashboardConfig":{
"genAiStudio":true,
"modelAsService":true,
"aiAssetCustomEndpoints":true
}}}'

echo "--- Suspend defective generated key-cleanup CronJob (known 3.4 defect)"
oc patch cronjob maas-api-key-cleanup -n "$MAAS_NS" --type merge \
    -p '{"spec":{"suspend":true}}' 2>/dev/null || true

echo "--- MaaS API rollout"
wait_until "DSC ModelsAsServiceReady" 1200 \
    check_eq "True" oc get datasciencecluster default-dsc -o jsonpath='{.status.conditions[?(@.type=="ModelsAsServiceReady")].status}'
wait_until "maas-api pod Running" 600 bash -c \
    "oc get pods -n $MAAS_NS -l app.kubernetes.io/name=maas-api --no-headers | grep -q ' Running'"

echo "=== Stage 220 deploy complete. Run validate.sh for full health checks. ==="
