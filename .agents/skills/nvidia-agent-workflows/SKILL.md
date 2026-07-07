---
name: nvidia-agent-workflows
metadata:
  version: 1.0.0
  platform-family: nvidia
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "NVIDIA Integration"
---

# NVIDIA Agent Workflows

## Purpose

Guide the design and implementation of multi-agent research workflows using
NVIDIA technologies on Red Hat OpenShift AI.

## Multi-Agent Research Architecture

A multi-agent research workflow coordinates multiple specialized AI agents to
solve complex research tasks:

- **Orchestrator Agent**: Coordinates the workflow, breaks down tasks, and
  synthesizes results
- **Research Agent**: Performs literature search, data retrieval, and
  information gathering
- **Analysis Agent**: Processes data, runs computations, and generates insights
- **Synthesis Agent**: Combines findings into coherent reports and
  recommendations
- **Safety Agent**: Applies guardrails and compliance checks to agent outputs

## Integration Points

- Agent models served through NIM or KServe/vLLM endpoints
- Agent-to-agent communication through governed MaaS endpoints
- Workflow orchestration through configurable agent frameworks
- Observability through OpenTelemetry tracing
- Safety through NeMo Guardrails

## Deployment on OpenShift

Agent workflows should be:
- Defined as declarative configurations in Git
- Deployed through ArgoCD as Kubernetes workloads
- Observable through distributed tracing
- Evaluable through the agent evaluation framework
