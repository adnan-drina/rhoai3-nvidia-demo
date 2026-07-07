# Troubleshooting

This document will contain symptom-based diagnostics and recovery guidance
once stages are implemented.

## General Diagnostics

```bash
# Check cluster health
oc get clusteroperators
oc get nodes

# Check RHOAI operator
oc get csv -n redhat-ods-operator

# Check GPU operator
oc get csv -n nvidia-gpu-operator

# Check ArgoCD applications
oc get applications -n openshift-gitops
```

## Known Issues

_To be documented as stages are implemented._
