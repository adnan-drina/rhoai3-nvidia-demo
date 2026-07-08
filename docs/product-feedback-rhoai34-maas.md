# RHOAI 3.4 MaaS: RHOAIENG-63297 workaround is not applicable to provider-namespaced model IDs

Related issue: RHOAIENG-63297 "GET /v1/models returns MaaSModelRef name
instead of ExternalModel name used in inference body" - RESOLVED, fixed
in the MaaS API for RHOAI 3.5
(https://github.com/opendatahub-io/models-as-a-service).

The published RHOAI 3.4 workaround for that issue is: "the MaaSModelRef
CR name will need to match the model ID for the External Model
provider." This report documents that the workaround CANNOT be applied
when the provider model ID is namespaced (contains "/") - which covers
every NVIDIA API Catalog model - because "/" is not permitted in
Kubernetes resource names. For such models the identity mismatch remains
unresolvable on 3.4, and the Gen AI playground MaaS flow fails for them.

Questions for the team:
- Does the 3.5 fix make the catalog (and the playground MaaS flow) use a
  value that works for namespaced targetModel IDs?
- Is a 3.4 z-stream backport planned?


## Environment

- OpenShift 4.20.26 (AWS)
- OpenShift AI: rhods-operator.3.4.2 (stable-3.4)
- Red Hat Connectivity Link: rhcl-operator.v1.3.4 (authorino/limitador/dns operators v1.3.1)
- Gen AI playground: dashboard-created LlamaStackDistribution 0.4.0 (server 0.7.2+rhaiv.0)
- MaaS payload processing: odh-ai-gateway-payload-processing-rhel9
  @sha256:f50970346465edcb371d06365f9d794bd4069c7a2a40e033f69bea0a37c2bbf2
  (bbr, gateway-api-inference-extension v1.5.0-rc.2)

Example model throughout: `openai/gpt-oss-120b` served by the NVIDIA API
Catalog (`integrate.api.nvidia.com`, OpenAI-compatible).

## 1. Configuration per RHOAI 3.4 documentation - does NOT work in the playground

Authored per the RHOAI 3.4 MaaS guide (external models): provider Secret
with the `api-key` data key and bbr-managed label, `ExternalModel` with
provider/endpoint/targetModel, `MaaSModelRef` publishing it, plus a
MaaSSubscription and MaaSAuthPolicy covering the model (omitted here for
brevity; both Ready). All resources reconcile to `Ready`:

```yaml
apiVersion: maas.opendatahub.io/v1alpha1
kind: ExternalModel
metadata:
  name: gpt-oss-120b-hosted            # '/' is not permitted in K8s names,
  namespace: models-as-a-service       # so the name cannot equal targetModel
spec:
  credentialRef:
    name: nvidia-api-credentials       # Secret, data key api-key, label
                                       # inference.networking.k8s.io/bbr-managed: "true"
  endpoint: integrate.api.nvidia.com
  provider: openai
  targetModel: openai/gpt-oss-120b
---
apiVersion: maas.opendatahub.io/v1alpha1
kind: MaaSModelRef
metadata:
  name: gpt-oss-120b-hosted
  namespace: models-as-a-service
spec:
  modelRef:
    kind: ExternalModel
    name: gpt-oss-120b-hosted
```

`MaaSModelRef` status (Ready; gateway route generated):

```yaml
status:
  phase: Ready
  endpoint: https://maas.apps.<cluster-domain>/models-as-a-service/gpt-oss-120b-hosted
  httpRouteGatewayName: maas-default-gateway
  httpRouteName: gpt-oss-120b-hosted
```

The model appears on the AI asset endpoints page (MaaS source) as Ready.
The user adds it to a Gen AI playground ("Add to playground"). The
dashboard generates a LlamaStackDistribution with this provider and model
registration (verbatim from the generated `llama-stack-config` ConfigMap):

```yaml
providers:
  inference:
  - provider_id: maas-vllm-inference-1
    provider_type: remote::vllm
    config:
      api_token: ${env.VLLM_API_TOKEN_1:=fake}
      base_url: https://maas.apps.<cluster-domain>/models-as-a-service/gpt-oss-120b-hosted/v1
registered_resources:
  models:
  - provider_id: maas-vllm-inference-1
    model_id: gpt-oss-120b-hosted        # <- the MaaS RESOURCE name
    model_type: llm
```

## 2. Failure and logs

Every playground chat against the model fails. Dashboard chat surface:

```
LlamaStack error on operation CreateResponse:
POST "http://lsd-genai-playground-service.demo-sandbox.svc.cluster.local:8321/v1/responses": 500 Internal Server Error
```

LlamaStackDistribution pod log:

```
ERROR ... llama_stack.providers.inline.responses.builtin.responses.openai_responses:785
      response creation failed  category=openai_responses
      error_message=inference error: NotFound - model in request body
      'gpt-oss-120b-hosted' doesn't match ExternalModel
      model=maas-vllm-inference-1/gpt-oss-120b-hosted
```

The rejection is produced by the MaaS gateway payload processor, which
VALIDATES the OpenAI `model` field against `ExternalModel.spec.targetModel`
but does not rewrite it. Reproduction at the gateway with a valid API key
(subscription covers the model):

```
POST https://maas.<domain>/models-as-a-service/gpt-oss-120b-hosted/v1/chat/completions

  "model": "gpt-oss-120b-hosted"     (what the playground sends)
  -> inference error: NotFound - model in request body 'gpt-oss-120b-hosted' doesn't match ExternalModel

  "model": "openai/gpt-oss-120b"     (targetModel verbatim)
  -> 200 {"id":"chatcmpl-...","object":"chat.completion",...}
```

Root cause chain:
1. the playground MaaS flow sends the MaaS resource name as `model`;
2. the gateway requires `model` == `spec.targetModel` exactly;
3. the provider requires its namespaced ID (`openai/gpt-oss-120b`;
   the bare `gpt-oss-120b` returns HTTP 404 from the provider);
4. Kubernetes forbids `/` in resource names.

No resource name can satisfy 1-4 simultaneously, so ANY documented
ExternalModel whose provider uses namespaced model IDs (all NVIDIA API
Catalog models) is unusable from the playground.

## 3. Configuration that works, and what changed

Workaround via the dashboard Custom Endpoints feature (Tech Preview;
`dashboardConfig.aiAssetCustomEndpoints: true` plus
`genAiStudioConfig.aiAssetCustomEndpoints.externalProviders: true`).
Created from the AI asset endpoints page ("Create endpoint"); generated
configuration (verbatim from `gen-ai-aa-custom-model-endpoints`):

```yaml
providers:
  inference:
  - provider_id: endpoint-1
    provider_type: remote::openai
    config:
      base_url: https://maas.apps.<cluster-domain>/models-as-a-service/gpt-oss-120b-hosted/v1
      allowed_models:
      - openai/gpt-oss-120b
      custom_gen_ai:
        api_key:
          secretRef:
            name: endpoint-api-key-1     # user's MaaS API key (sk-oai-*)
            key: api_key
registered_resources:
  models:
  - provider_id: endpoint-1
    model_id: openai/gpt-oss-120b        # <- provider ID, entered verbatim
    model_type: llm
```

Playground chat now succeeds (response: expected model output; verified
repeatedly).

What changed - one thing only: **the model ID sent upstream**. The custom
endpoint form lets the user enter the provider ID verbatim
(`openai/gpt-oss-120b`), so the request body reaching the gateway equals
`spec.targetModel` and passes validation. Same gateway URL, same MaaS
governance (the user's own API key, tier-checked by the subscription),
same ExternalModel underneath.

Two caveats of the workaround:
- the custom endpoint duplicates the model entry on the AI asset
  endpoints page (catalog row + endpoint row);
- the endpoint verification button probes `GET {url}/models`, which the
  MaaS per-model route does not expose (404), so verification always
  fails even though inference works.

## Requested fix

For RHOAI 3.4 (until/unless the 3.5 fix is backported), either of:
- the payload processor rewrites the request-body `model` to
  `spec.targetModel` (making the MaaS resource name a first-class alias
  that also satisfies the RHOAIENG-63297 workaround for namespaced IDs), or
- the playground MaaS flow registers/sends `targetModel` instead of the
  resource name.
