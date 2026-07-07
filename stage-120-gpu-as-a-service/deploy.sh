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

echo "=== Stage 120: GPU as a Service ==="
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

# GPU MachineSets are generated from the live worker MachineSet because they
# embed cluster-specific values (infra ID, AMI, subnet, IAM profile). They are
# script-managed infrastructure, not ArgoCD-managed (documented in PLAN.md).
# Capacity strategy: both target us-east-2c; on InsufficientInstanceCapacity
# the Machine API retries until AWS capacity appears (accepted risk).
echo "--- GPU MachineSets (2x p5.4xlarge: gpu-full, gpu-mig)"
GPU_INSTANCE_TYPE="${RHOAI_GPU_INSTANCE_TYPE:-p5.4xlarge}"
INFRA_ID=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
WORKER_MS=$(oc get machineset -n openshift-machine-api -o name | grep -v gpu | head -1 | cut -d/ -f2)

# Optional per-role AZ overrides (RHOAI_GPU_FULL_AZ / RHOAI_GPU_MIG_AZ).
# Requires a tagged private subnet named
# <infra>-subnet-private-<az> in the target AZ (see docs/OPERATIONS.md).
for role in gpu-full gpu-mig; do
    case "$role" in
        gpu-full) MIG_CONFIG="all-disabled"; MS_AZ="${RHOAI_GPU_FULL_AZ:-}" ;;
        gpu-mig)  MIG_CONFIG="all-balanced"; MS_AZ="${RHOAI_GPU_MIG_AZ:-}" ;;
    esac
    oc get machineset "$WORKER_MS" -n openshift-machine-api -o json | \
        MS_ROLE="$role" MIG_CONFIG="$MIG_CONFIG" INFRA_ID="$INFRA_ID" \
        GPU_INSTANCE_TYPE="$GPU_INSTANCE_TYPE" MS_AZ="$MS_AZ" python3 -c "
import json, os, sys
ms = json.load(sys.stdin)
role = os.environ['MS_ROLE']
name = f\"{os.environ['INFRA_ID']}-{role}\"
ms.pop('status', None)
for k in ('creationTimestamp', 'resourceVersion', 'uid', 'generation', 'annotations', 'managedFields'):
    ms['metadata'].pop(k, None)
ms['metadata']['name'] = name
ms['spec']['replicas'] = 1
ms['spec']['selector']['matchLabels']['machine.openshift.io/cluster-api-machineset'] = name
tpl = ms['spec']['template']
tpl['metadata']['labels']['machine.openshift.io/cluster-api-machineset'] = name
node_labels = tpl['spec'].setdefault('metadata', {}).setdefault('labels', {})
node_labels['node-role.kubernetes.io/gpu'] = ''
node_labels['nvidia.com/mig.config'] = os.environ['MIG_CONFIG']
tpl['spec']['taints'] = [{'key': 'nvidia.com/gpu', 'effect': 'NoSchedule'}]
pv = tpl['spec']['providerSpec']['value']
pv['instanceType'] = os.environ['GPU_INSTANCE_TYPE']
az = os.environ.get('MS_AZ')
if az:
    pv['placement']['availabilityZone'] = az
    pv['subnet']['filters'][0]['values'] = [f\"{os.environ['INFRA_ID']}-subnet-private-{az}\"]
for bd in pv.get('blockDevices', []):
    if 'ebs' in bd:
        bd['ebs']['volumeSize'] = max(int(bd['ebs'].get('volumeSize', 120)), 200)
json.dump(ms, sys.stdout)
" | oc apply -f -
done
oc get machineset -n openshift-machine-api | grep -E 'NAME|gpu-'

echo "--- Stage 120 ArgoCD Application (and stage-110 branch repin)"
oc apply -f "$REPO_ROOT/gitops/argocd/app-of-apps/stage-110-rhoai-base-platform.yaml"
oc apply -f "$REPO_ROOT/gitops/argocd/app-of-apps/stage-120-gpu-as-a-service.yaml"
wait_until "stage-120 Application synced" 900 \
    check_eq "Synced" oc get application stage-120-gpu-as-a-service -n openshift-gitops \
    -o jsonpath='{.status.sync.status}'

echo "--- Operator installs (managed by ArgoCD sync)"
wait_until "NFD operator CSV Succeeded" 1200 bash -c \
    "oc get csv -n openshift-nfd -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^nfd\..*=Succeeded'"
wait_until "GPU operator CSV Succeeded" 1200 bash -c \
    "oc get csv -n nvidia-gpu-operator -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^gpu-operator-certified\..*=Succeeded'"
wait_until "Kueue operator CSV Succeeded" 1200 bash -c \
    "oc get csv -n openshift-kueue-operator -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^kueue-operator\..*=Succeeded'"

echo "--- Dashboard surfaces for this stage (documented OdhDashboardConfig patch)"
# Kueue UI + distributed workload metrics + observability pages belong to this stage.
oc patch odhdashboardconfig odh-dashboard-config -n redhat-ods-applications \
    --type merge -p '{"spec":{"dashboardConfig":{"disableKueue":false,"disableDistributedWorkloads":false,"observabilityDashboard":true}}}'

echo "=== Stage 120 deploy complete. GPU Machines may wait on AWS capacity; run validate.sh for status. ==="
