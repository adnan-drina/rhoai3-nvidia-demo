# RHOAI 3.4 MaaS — Product Feedback / Bug Reports

Environment (reproduced 2026-07-08, OCP 4.20.26, AWS single-AZ sandbox):
- RHOAI: rhods-operator.3.4.2
- RHCL: rhcl-operator.v1.3.4 (pinned; deps authorino/limitador/dns v1.3.1)
- LlamaStackDistribution: 0.4.0 (server 0.7.2+rhaiv.0), dashboard-created playground
- MaaS payload processing: odh-ai-gateway-payload-processing-rhel9@sha256:f50970346465edcb371d06365f9d794bd4069c7a2a40e033f69bea0a37c2bbf2 (bbr, gateway-api-inference-extension v1.5.0-rc.2)

---

## Bug 1: ExternalModel with provider-namespaced target ID cannot be used from the Gen AI playground (MaaS flow)

### Summary
The playground "Add to playground" flow for MaaS models sends the MaaS
resource name as the OpenAI `model` field. The MaaS gateway payload
processor validates the request-body model against
`ExternalModel.spec.targetModel` but does NOT rewrite it. Providers whose
model IDs contain `/` (all NVIDIA API Catalog models, e.g.
`openai/gpt-oss-120b`, `nvidia/nemotron-3-nano-30b-a3b`) can never
satisfy this: `/` is not permitted in Kubernetes resource names, so
resource name and targetModel cannot be equal. Result: every playground
chat against such a model fails; direct API use works only when the
caller sends targetModel verbatim.

### Resources (exact, live cluster)
```json
{
  "apiVersion": "maas.opendatahub.io/v1alpha1",
  "kind": "ExternalModel",
  "metadata": {"name": "gpt-oss-120b-hosted", "namespace": "models-as-a-service"},
  "spec": {
    "credentialRef": {"name": "nvidia-api-credentials"},
    "endpoint": "integrate.api.nvidia.com",
    "provider": "openai",
    "targetModel": "openai/gpt-oss-120b"
  }
}
```
```json
{
  "apiVersion": "maas.opendatahub.io/v1alpha1",
  "kind": "MaaSModelRef",
  "metadata": {"name": "gpt-oss-120b-hosted", "namespace": "models-as-a-service"},
  "spec": {"modelRef": {"kind": "ExternalModel", "name": "gpt-oss-120b-hosted"}},
  "status": {
    "endpoint": "https://maas.apps.<cluster-domain>/models-as-a-service/gpt-oss-120b-hosted",
    "httpRouteGatewayName": "maas-default-gateway",
    "phase": "Ready"
  }
}
```

### Reproduction (gateway level, valid demo-premium API key)
```
POST https://maas.<domain>/models-as-a-service/gpt-oss-120b-hosted/v1/chat/completions

body model="gpt-oss-120b-hosted"  (what the playground sends)
 -> inference error: NotFound - model in request body 'gpt-oss-120b-hosted' doesn't match ExternalModel

body model="gpt-oss-120b"
 -> inference error: NotFound - model in request body 'gpt-oss-120b' doesn't match ExternalModel

body model="openai/gpt-oss-120b"  (targetModel verbatim)
 -> 200 {"id":"chatcmpl-...","object":"chat.completion",...}
```

### LlamaStack logs (playground chat attempt, model added via MaaS flow)
```
ERROR ... llama_stack.providers.inline.responses.builtin.responses.openai_responses:785
      response creation failed  category=openai_responses
      error_message=inference error: NotFound - model in request body
      'gpt-oss-120b-hosted' doesn't match ExternalModel
      model=maas-vllm-inference-1/gpt-oss-120b-hosted
```
Dashboard chat surface shows:
```
LlamaStack error on operation CreateResponse:
POST "http://lsd-genai-playground-service.demo-sandbox.svc.cluster.local:8321/v1/responses": 500 Internal Server Error
```

### Expected behavior
Either the payload processor rewrites the request-body model to
`spec.targetModel` (making the resource name a first-class alias), or the
playground MaaS flow sends `targetModel`. Documented workaround we use:
dashboard Custom Endpoints (Tech Preview) with model ID == provider ID and
the per-model MaaS URL.

---

## Bug 2: Streamed responses through the MaaS gateway truncate ~50% (SSE parsed as JSON)

### Summary
With `stream: true`, roughly half of responses through the MaaS gateway
terminate mid-body ("peer closed connection without sending complete
message body (incomplete chunked read)" at the client). The payload
processor logs a JSON parse failure for every SSE chunk. Reproduced with
any tokenRateLimits value (300k/min and 100,000,000/min identical);
`tokenRateLimits` is schema-required so the metering path cannot be
disabled. Direct provider streaming (bypassing the gateway) is 100%
clean; non-streaming through the gateway is 100% clean.

### payload-processing log (every streamed response)
```json
{"level":"error","caller":"handlers/response.go:76",
 "msg":"Failed to parse response body as JSON, skipping response plugins",
 "error":"invalid character 'd' looking for beginning of value",
 "stacktrace":"sigs.k8s.io/gateway-api-inference-extension/pkg/bbr/handlers.(*Server).HandleResponseBody
   sigs.k8s.io/gateway-api-inference-extension@v1.5.0-rc.2/pkg/bbr/handlers/response.go:76 ..."}
```
('d' = the `data:` prefix of an SSE chunk.)

### Measurements (6 streamed requests each, same model/key)
- via gateway, limits 300k/min: 3 clean / 3 truncated
- via gateway, limits 100M/min: 1 clean / 5 truncated
- direct to provider: clean
- non-streaming via gateway: clean (all runs)
