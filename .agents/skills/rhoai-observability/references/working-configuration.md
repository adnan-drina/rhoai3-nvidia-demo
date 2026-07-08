# Working Configuration (rhoai3-nvidia-demo, confirmed live 2026-07-08)

RHOAI 3.4 Observability dashboard + Workload metrics, validated on
OCP 4.20.26 / RHOAI 3.4.2 (cluster-52lrs).

## Required Wiring (all GitOps, stage-120 observability/)

- Cluster Observability Operator PINNED `cluster-observability-operator.v1.4.0`
  (Manual + approve-installplan Job). COO 1.5.x fails the RHOAI-generated
  PersesDatasource with `spec.client.tls.caCert: namespace is required` -
  the documented operator-compatibility mismatch. The pin lives in the
  authoritative table in docs/OPERATIONS.md.
- Red Hat build of OpenTelemetry (opentelemetry-product, stable). The RHOAI
  Monitoring service HARD-REQUIRES it even for metrics-only
  ("OpenTelemetryCollector operator must be installed"; the pipeline runs
  collectorReplicas: 2). Tempo operator installed alongside per skill
  prerequisites (traces deferred).
- DSCI `spec.monitoring.metrics` MUST be non-empty (replicas + storage
  size/retention) or NO metrics stack deploys. DSCI is operator-created:
  activate via sync-hook Job (observability/dsci-metrics), never author
  the DSCI.
- Workload metrics page: label `openshift-kueue-operator` namespace
  `openshift.io/cluster-monitoring: "true"`. UWM excludes openshift-*
  namespaces, so without the label the RH Kueue ServiceMonitor is scraped
  by nothing and the page stays empty.
- Result state: Monitoring/default-monitoring Ready=True; in
  redhat-ods-monitoring: prometheus (COO MonitoringStack) 3/3, Perses,
  OTel collector x2 + target allocator, thanos-querier, proxies.

## Traps

- A leftover second OperatorGroup in the COO namespace stalls OLM
  SILENTLY: Subscription reports healthy catalogs but no InstallPlan is
  ever generated and status.state stays empty. Exactly one OperatorGroup
  per namespace.
- Downgrade procedure (1.5.x -> 1.4.0): delete Subscription + CSV, sync
  the pinned Subscription, approve Job approves only the pinned plan.
  Operands and CRDs survive.
- The Monitoring service reports its missing prerequisites ONE AT A TIME;
  converge iteratively rather than assuming the first fix was complete.
- Alertmanager replica 2 may stay Pending on small clusters
  (anti-affinity + tainted nodes); replica 1 carries the service.

## Complementary Grafana Stack (stage-210 grafana/)

Ported from rhoai3-demo: OAuth-proxied Grafana (SAR-gated to demo
groups), thanos-querier datasource via cluster-monitoring-view SA token,
vLLM KServe/GPU + LLM performance dashboards, console link hook. This is
the reference projects' primary model-serving observability surface.
