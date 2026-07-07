---
name: env-troubleshoot
metadata:
  version: 1.0.0
  platform-family: env
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "Demo Environment"
---

# Troubleshoot

## Purpose

Symptom-based troubleshooting for the live demo environment.

## General Approach

1. Check cluster health: `oc get clusteroperators`, `oc get nodes`
2. Check operator status: `oc get csv -A | grep -i <operator>`
3. Check pod logs: `oc logs -n <namespace> <pod>`
4. Check events: `oc get events -n <namespace> --sort-by='.lastTimestamp'`
5. Check ArgoCD sync: `oc get applications -n openshift-gitops`

## Common Issues

_To be populated as stages are implemented and issues are encountered._
