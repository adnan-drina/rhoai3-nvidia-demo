# Troubleshooting

Symptom-based diagnostics and recovery guidance for the multi-agent research
workflows demo.

## General Diagnostics

```bash
oc get clusteroperators
oc get nodes
oc get csv -n redhat-ods-operator
oc get csv -n nvidia-gpu-operator
oc get applications -n openshift-gitops
```

## Node Disk Pressure and Evicted Pod Accumulation

**Symptom**: hundreds of Failed/ContainerStatusUnknown pods accumulate on a
node; `oc` list commands time out; node reports `DiskPressure=True`.

**Root cause**: LLMInferenceService router-scheduler pods are CPU workloads.
With model predictors Pending on GPU capacity, the router-schedulers land on
workers, get evicted on ephemeral-storage pressure, and are recreated in a
loop. Each cycle leaves dead-pod filesystem artifacts that fill the node's
/var partition and block kubelet image garbage collection.

**Recovery**:

1. Identify affected nodes:
   ```bash
   oc get nodes -o custom-columns='NAME:.metadata.name,DISK_PRESSURE:.status.conditions[?(@.type=="DiskPressure")].status'
   ```

2. Delete stale pods on the affected node:
   ```bash
   oc delete pods --all-namespaces --field-selector=status.phase=Failed
   oc delete pods --all-namespaces --field-selector=status.phase=Succeeded
   ```

3. Scale down the source LLMInferenceServices to stop the eviction cycle:
   ```bash
   for m in gpt-oss-120b nemotron-nano-30b nemotron-mini-4b; do
     oc patch llminferenceservice $m -n models-as-a-service \
       --type merge -p '{"spec":{"replicas":0}}'
   done
   ```

4. If disk pressure persists, drain the node and let kubelet GC recover:
   ```bash
   oc adm drain <node> --ignore-daemonsets --delete-emptydir-data
   # Wait for DiskPressure to clear
   oc adm uncordon <node>
   ```

5. Optionally accelerate image GC:
   ```bash
   oc debug node/<node> -- chroot /host crictl rmi --prune
   ```

**Prevention**: keep LLMInferenceService replicas at 0 until GPU nodes join
the cluster. The ArgoCD Application uses `ignoreDifferences` on
`/spec/replicas` so scaling does not cause sync drift.

## OLM: Subscription Healthy But No InstallPlan

**Symptom**: a Subscription shows healthy catalog sources but
`status.state` stays empty and no InstallPlan appears.

**Root cause**: multiple OperatorGroups exist in the namespace. OLM stalls
silently when more than one OperatorGroup is present.

**Recovery**:

```bash
oc get operatorgroup -n <namespace>
# Delete the stray OperatorGroup (keep only the one created by the stage)
oc delete operatorgroup <stray-og> -n <namespace>
```

Resolution resumes within a minute.

## ArgoCD Application Not Syncing

**Symptom**: ArgoCD Application shows OutOfSync but auto-sync does not
correct it.

**Diagnostics**:

```bash
oc get application <app-name> -n openshift-gitops -o yaml | grep -A 20 status:
```

Common causes:

- `targetRevision` points to a branch that does not exist on the remote.
- A resource managed by the Application was modified directly with
  `oc apply` or `oc patch`, creating a conflict that auto-sync cannot
  resolve. Check the Application events for specific resource conflicts.
- CRD not yet installed when the Application tries to sync a CR instance.
  The dependent operator subscription may still be installing.

## GPU Nodes Not Joining

**Symptom**: MachineSet shows desired replicas but Machine stays in
Provisioning or Failed.

**Diagnostics**:

```bash
oc get machinesets -n openshift-machine-api
oc get machines -n openshift-machine-api
oc describe machine <machine-name> -n openshift-machine-api
```

Common causes:

- `InsufficientInstanceCapacity` in the target AZ — try a different AZ
  by setting `RHOAI_GPU_FULL_AZ` / `RHOAI_GPU_MIG_AZ` in `.env` and
  re-running stage-120 deploy.
- Subnet not tagged with the cluster's infra ID — `deploy.sh` filters
  subnets by cluster tags; hand-made subnets need matching tags.
- Instance quota exceeded in the AWS account.
