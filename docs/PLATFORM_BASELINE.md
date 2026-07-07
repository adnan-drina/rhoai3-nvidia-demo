# Platform Baseline

This file is the canonical platform target for the demo and shared skills.
Update it first when preparing an upgrade.

## Current Baseline

| Component | Version | Documentation |
|-----------|---------|---------------|
| Red Hat OpenShift AI Self-Managed | 3.4 | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/ |
| Red Hat OpenShift Container Platform | 4.20 | https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/ |
| Red Hat OpenShift Data Foundation | 4.20 | https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.20/ |

## Version Match Rule

Project documentation, skills, and GitOps review notes must use the official
Red Hat documentation version that matches the pinned baseline for each product
family.

For the current baseline, RHOAI product-documentation links should use:

```text
https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/
```

For the current baseline, OCP product-documentation links should use:

```text
https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/
```

For the current baseline, ODF product-documentation links should use:

```text
https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.20/
```

Do not use `latest` or another product version for product configuration unless
the Red Hat documentation landing page intentionally links to an unversioned
Customer Portal article or no version-specific document exists. Record that as
an explicit exception in the relevant README, review note, or skill reference.

This baseline pins product documentation versions and selected operator
lifecycle policy where required. It does not pin generated operand image
fields, copied CSV content, or operator-created Deployments. If a generated
operand is incompatible with the installed operator or CRD, update the
Subscription lifecycle policy, product baseline, or a documented product CR
field; do not treat generated image fields as project-owned desired state.

## Red Hat OpenShift AI 3.4 Documentation Index

Use the official RHOAI 3.4 landing page as the entry point:
https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/

- **Get started**:
  [Get started with projects, workbenches, and pipelines](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/getting_started_with_red_hat_openshift_ai_self-managed)
- **Plan**:
  [Prepare your platform and hardware for Red Hat AI](https://docs.redhat.com/en/documentation/red_hat_ai/3/html/supported_product_and_hardware_configurations/index),
  [Choose a validated model](https://docs.redhat.com/en/documentation/red_hat_ai/3/html/validated_models/index)
- **Install**:
  [Installing and uninstalling OpenShift AI Self-Managed](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/installing_and_uninstalling_openshift_ai_self-managed)
- **Administer**:
  [Managing OpenShift AI](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/managing_openshift_ai),
  [Working with accelerators](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/working_with_accelerators),
  [Configuring your model-serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/configuring_your_model-serving_platform),
  [Working with Llama Stack](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/working_with_llama_stack)
- **Deploy**:
  [Deploying models](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/deploying_models/index),
  [Govern LLM access with Models-as-a-Service](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/govern_llm_access_with_models-as-a-service/index)
- **Train**:
  [Customize Models for Gen AI and Agentic AI Applications](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/customize_models_for_gen_ai_and_agentic_ai_applications/index)
- **Evaluate**:
  [Evaluating AI systems](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/evaluating_ai_systems/index)
- **Maintain Safety**:
  [Ensuring AI safety with guardrails](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/enabling_ai_safety_with_guardrails/index)

## OpenShift Container Platform 4.20 Documentation Index

Use the official OCP 4.20 landing page as the entry point:
https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/

- **AI workloads**:
  [AI workloads](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/ai_workloads/index)
- **CI/CD, GitOps, and builds**:
  [GitOps](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/gitops/index)
- **Machine management and nodes**:
  [Machine management](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/machine_management/index),
  [Nodes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/nodes/index)
- **Storage**:
  [Storage](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/storage/index)

## OpenShift Data Foundation 4.20 Documentation Index

Use the official ODF 4.20 landing page as the entry point:
https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.20/

- **Planning**:
  [Planning your deployment](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.20/html-single/planning_your_deployment/index)
- **Deploying**:
  [Deploying OpenShift Data Foundation using Amazon Web Services](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.20/html-single/deploying_openshift_data_foundation_using_amazon_web_services/index)
- **Managing**:
  [Managing hybrid and multicloud resources](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.20/html/managing_hybrid_and_multicloud_resources/index)

## Source Hierarchy

1. Official Red Hat product documentation for the active baseline.
2. NVIDIA official documentation for NIM, NeMo, and agent frameworks.
3. Official Red Hat articles, blogs, and product messaging for narrative and examples.
4. Existing repo implementation, scripts, and READMEs.
5. Live cluster schema verification with commands such as `oc explain` and `oc get crd`.

Official product documentation remains the source of truth for supported
configuration. Do not invent CR fields, API versions, annotations, or operator
configuration.

## Skill Metadata Policy

Shared skills should reference this repository baseline rather than repeating
exact platform versions in every skill frontmatter. Use exact version-specific
reference files only when a workflow genuinely differs across platform versions.
