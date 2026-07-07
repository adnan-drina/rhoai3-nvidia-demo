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
