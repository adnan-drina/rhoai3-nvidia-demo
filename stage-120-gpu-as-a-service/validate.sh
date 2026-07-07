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

echo "=== Stage 120: Validation ==="
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

INFRA_ID=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')

# GitOps
check "stage-120 Application Synced" \
    check_eq "Synced" oc get application stage-120-gpu-as-a-service -n openshift-gitops -o jsonpath='{.status.sync.status}'

# Operators
check "NFD operator CSV Succeeded" bash -c \
    "oc get csv -n openshift-nfd -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^nfd\..*=Succeeded'"
check "GPU operator CSV Succeeded" bash -c \
    "oc get csv -n nvidia-gpu-operator -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^gpu-operator-certified\..*=Succeeded'"
check "Kueue operator CSV Succeeded" bash -c \
    "oc get csv -n openshift-kueue-operator -o jsonpath='{range .items[*]}{.metadata.name}={.status.phase}{\"\n\"}{end}' | grep -E '^kueue-operator\..*=Succeeded'"

# GPU MachineSets and capacity status (capacity wait is WARN, not FAIL)
for role in gpu-full gpu-mig; do
    ms="$INFRA_ID-$role"
    check "MachineSet $ms exists (replicas 1)" \
        check_eq "1" oc get machineset "$ms" -n openshift-machine-api -o jsonpath='{.spec.replicas}'
    phase=$(oc get machine -n openshift-machine-api \
        -l machine.openshift.io/cluster-api-machineset="$ms" \
        -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo none)
    if [[ "$phase" == "Running" ]]; then
        echo "PASS: Machine for $ms is Running"; PASS=$((PASS + 1))
    else
        msg=$(oc get machine -n openshift-machine-api \
            -l machine.openshift.io/cluster-api-machineset="$ms" \
            -o jsonpath='{.items[0].status.providerStatus.conditions[0].message}' 2>/dev/null || true)
        if echo "$msg" | grep -q InsufficientInstanceCapacity; then
            echo "WARN: Machine for $ms waiting on AWS p5.4xlarge capacity (retrying; accepted risk)"
            WARN=$((WARN + 1))
        else
            echo "FAIL: Machine for $ms phase=$phase ${msg:0:120}"
            FAIL=$((FAIL + 1))
        fi
    fi
done

# Instances (only meaningful once wave-2 manifests are merged)
check "NodeFeatureDiscovery instance exists" bash -c \
    "oc get nodefeaturediscovery -n openshift-nfd -o name | grep -q ."
check "ClusterPolicy exists (mig.strategy mixed)" \
    check_eq "mixed" oc get clusterpolicy gpu-cluster-policy -o jsonpath='{.spec.mig.strategy}'
check "Kueue CR Available" bash -c \
    "oc get kueues.kueue.openshift.io cluster -o jsonpath='{.status.conditions[?(@.type==\"Available\")].status}' | grep -x True"
check "ClusterQueue exists" bash -c \
    "oc get clusterqueue -o name | grep -q ."
check "Hardware profiles exist (h100-full, mig-3g-40gb, mig-2g-20gb)" bash -c \
    "oc get hardwareprofile h100-full mig-3g-40gb mig-2g-20gb -n redhat-ods-applications -o name | grep -c hardwareprofile | grep -x 3"
check "DSC kueue component Unmanaged" \
    check_eq "Unmanaged" oc get datasciencecluster default-dsc -o jsonpath='{.spec.components.kueue.managementState}'

# Workload observability (RHOAI Workload metrics page data path)
check "User Workload Monitoring prometheus running" bash -c \
    "oc get pods -n openshift-user-workload-monitoring --no-headers | grep prometheus-user-workload | grep -q ' Running'"
check "Kueue metrics ServiceMonitor exists" \
    oc get servicemonitor kueue-metrics -n openshift-kueue-operator

# GPU node checks (only pass once capacity arrives)
gpu_nodes=$(oc get nodes -l node-role.kubernetes.io/gpu -o name 2>/dev/null | wc -l | tr -d ' ')
if [[ "$gpu_nodes" -ge 1 ]]; then
    check "GPU node(s) expose nvidia.com/gpu or MIG resources" bash -c \
        "oc get nodes -l node-role.kubernetes.io/gpu -o jsonpath='{range .items[*]}{.status.allocatable}{\"\n\"}{end}' | grep -qE 'nvidia.com/(gpu|mig-)'"
else
    echo "WARN: no GPU nodes joined yet (AWS capacity pending)"
    WARN=$((WARN + 1))
fi

echo
echo "Result: $PASS passed, $FAIL failed, $WARN warnings (capacity waits)"
[[ $FAIL -eq 0 ]]
