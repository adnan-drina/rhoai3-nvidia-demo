# Stage 220: Implementation Plan

## Scope

Enable governed model access for agent workloads: one MaaS governance plane
over both the self-hosted Stage 210 models (local) and NVIDIA-hosted NIM
endpoints (external).

## Model Governance Split (confirmed 2026-07-07)

Demo narrative: local = sovereignty (research data and core workflow stay on
the cluster), external = frontier reach (models beyond the local GPU
footprint), MaaS = one governance plane over both.

| Tier | Model | Backend |
|------|-------|---------|
| Local | RedHatAI/gpt-oss-120b | Stage 210 vLLM InferenceService (full H100) |
| Local | RedHatAI/NVIDIA-Nemotron-3-Nano-30B-A3B-FP8 | Stage 210 vLLM InferenceService (MIG 3g.40gb) |
| Local | nvidia/Nemotron-Mini-4B-Instruct | Stage 210 vLLM InferenceService (MIG 2g.20gb) |
| External | nvidia/nemotron-3-super-120b-a12b | NVIDIA API Catalog (integrate.api.nvidia.com) via Stage 310 |

AI-Q (Stage 320) consumes MaaS endpoints and a MaaS-minted key through its
standard OpenAI-compatible wiring (`VLLM_*_BASE_URL` / `VLLM_API_KEY`) — no
application changes required to add governance.

## Components

- [x] MaaS Gateway prerequisites: RHCL operator (rhcl-operator v1.4.1,
      kuadrant-system) + Kuadrant CR Ready; maas-default-gateway in
      openshift-ingress (GitOps, reuses RHOAI data-science-gateway-class and
      the service-CA serving-cert pattern); passthrough Route
      maas.<cluster-domain> mirroring the RHOAI gateway exposure
- [x] MaaS Gateway configuration: DSC kserve.modelsAsService Managed via
      CoP component patch (stage-110 components/maas); maas-api backed by
      PostgreSQL 16 (maas-db, secrets script-created); Authorino listener
      TLS per upstream interim bootstrap + gateway reconcile nudge
      (odh-model-controller race - see Implementation Notes)
- [ ] Local model registration (3x Stage 210 endpoints; requires Running
      models -> completes when GPU capacity lands)
- [ ] External model registration (native ExternalModel CRD discovered;
      onboarding in Stage 310)
- [ ] API key management (requires MaaSModelRef + MaaSSubscription; first
      subscription ships with Stage 310 external models)
- [x] DSC patch for MaaS

## Implementation Notes (live findings, 2026-07-07)

- validate.sh: 11 passed, 0 failed, 1 warning (subscriptions pending 310).
  Functional proof: unauthenticated /v1/models through the gateway returns
  401 (Gateway -> Kuadrant wasm -> Authorino-over-TLS chain live).
- RHOAI 3.4 MaaS requires: a PostgreSQL DB via maas-db-config Secret
  (DB_CONNECTION_URL), Authorino listener TLS (upstream interim bootstrap
  until CONNLINK-528), and the maas-default-gateway to pre-exist.
- Race fixed in deploy.sh: odh-model-controller's gateway-auth-bootstrap
  only checks Authorino TLS on Gateway events; a reconcile nudge annotation
  forces creation of the maas-default-gateway-authn-ssl EnvoyFilter.
- MaaS model surface is CRD-based and GitOps-able:
  externalmodels/maasmodelrefs/maassubscriptions/maasauthpolicies/tenants
  (maas.opendatahub.io). MaaSSubscription binds owner groups to modelRefs
  with token rate limits and billing metadata.
- API endpoint shapes: mint keys at POST /maas-api/v1/api-keys (requires a
  matching subscription); models listed at /v1/models via the gateway.
- Docs source: opendatahub-documentation + opendatahub-io/models-as-a-service
  (docs.redhat.com blocks automated fetch; official 3.4 MaaS guide URL in
  README).

## Acceptance Criteria

- MaaS Gateway is running and healthy
- All three local models accessible through MaaS API
- External model accessible through the same MaaS API and key discipline
- API keys can be minted per subscription
- A single OpenAI-compatible client can hit local and external models by
  switching only model name / endpoint path

## Dependencies

- Stage 210 (model serving foundation)

## Doc Coverage (audit 2026-07-07, MaaS guide + upstream models-as-a-service)

| Procedure / component | Status |
|---|---|
| Prerequisites (OCP >= 4.19.9, RHCL operator, Kuadrant CR, KServe Managed, GatewayClass + maas-default-gateway) | applied |
| Enable modelsAsService in DSC (nested under kserve) | applied |
| PostgreSQL + maas-db-config secret (upstream setup-database.sh) | applied |
| Authorino TLS interim bootstrap + gateway annotations + reconcile nudge | applied (documented exception until CONNLINK-528) |
| Enable MaaS dashboard (genAiStudio, modelAsService flags + Llama Stack operator) | applied (was a gap; found in audit) |
| Full dashboard flag set pinned (Kueue UI, catalog, metrics, NIM, aiAssetCustomEndpoints TP) | applied (was a gap) |
| models-as-a-service subscription namespace (MAAS_SUBSCRIPTION_NAMESPACE, verified in live maas-api env) | applied (was a gap; found in audit) |
| Demo persona RBAC (project + registry) | applied (was a gap) |
| Tiers (tier-to-group-mapping CM, tier namespaces) | pending: not bootstrapped by component; tiers materialize via dashboard tier management or explicit CM; wire demo groups to tiers in Stage 310 alongside subscriptions |
| MaaSSubscription / MaaSModelRef / MaaSAuthPolicy / ExternalModel CRs | Stage 310 scope (upstream sample layout captured: subscription+authpolicy in models-as-a-service ns, MaaSModelRef next to the model) |
| Playground test (test-maas-models-in-playground) | pending models (Stage 310) |
| CRITICAL cross-stage finding | MaaSModelRef.modelRef.kind enum is [LLMInferenceService, ExternalModel] only - classic InferenceService (Stage 210 as-deployed) cannot be MaaS-governed; see stage-210 PLAN |

## RHCL Remediation Record (2026-07-07, executed hands-on per OLM docs)

- Symptom: external-model completions failed; payload-processing ext-proc
  absent because RHCL v1.4.1 injects its wasm shim as a raw EnvoyFilter
  while the RHOAI ext-proc anchors on the WasmPlugin subfilter name.
- Fix (proven rhoai3-demo config + OCP "install a specific Operator
  version" procedure): uninstall v1.4.1 (Subscription+CSV), reinstall
  pinned startingCSV rhcl-operator.v1.3.4 with Manual approval in
  openshift-operators; approve only the pinned InstallPlan; the v1.3.5
  upgrade InstallPlan intentionally remains unapproved.
- Encountered and resolved: pinned InstallPlan reported Failed on
  authconfigs CRD replace ("existing CRs ... too restrictive") - the
  documented trap; stale 1.4 dependency chain (authorino/limitador/dns
  subs+CSVs in kuadrant-system) removed per the uninstall procedure;
  generated AuthConfigs deleted and regenerated (22/22) under 1.3; stale
  1.4 EnvoyFilters deleted, 1.3 regenerated (WasmPlugin + auth/ratelimit).
  The authconfigs CRD remains at the 1.4 schema (more permissive; runtime
  proven by E2E) - recorded, not papered over.
- Verified live: wasm shim delivered via ECDS, ext_proc.bbr present in the
  gateway 443 filter chain (config obtained via oc port-forward - in-pod
  curl greps silently return empty and must not be trusted), path rewrite
  and single-Authorization provider key injection proven byte-exact with a
  temporary in-cluster header-echo ExternalModel (removed after use).
- Generated maas-api-key-cleanup CronJob defect (http:8080 vs https:8443)
  confirmed; generated CronJob suspended by deploy.sh; annotated
  replacement CronJob in Git until the product fix lands.
