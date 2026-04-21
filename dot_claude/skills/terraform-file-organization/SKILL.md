---
name: terraform-file-organization
description: "Workflow for creating well-organized, production-ready Terraform modules with single-responsibility files organized by functional concern. **ALWAYS use this skill when:** Creating new .tf files, organizing existing Terraform code, deciding whether to extend vs create new files, splitting monolithic Terraform modules, or designing module structure. Guides functional decomposition (one concern per file—not by technology), documentation headers with links, proper code organization, and terraform validate compliance. Works for any Terraform project (modules, root modules for new features, AWS, GCP, Azure). Ensures clean, maintainable, professionally-structured Terraform code that passes validation."
compatibility: Requires `terraform` CLI tool (for validation). Context7 MCP server optional for documentation lookups.
---

# Terraform File Organization Skill

## Core Principle

**One functional concern per file.** Each `.tf` file should encapsulate a single technical responsibility:
- `workload.tf` → Cloud Run service, service account, IAM (invokers/deployers/viewers)
- `workload_external_exposure.tf` → External load balancer, global address, Cloud Armor
- `workload_internal_exposure.tf` → Internal load balancer, forwarding rules, HTTPS proxy
- `workload_secrets.tf` → Secret Manager activation, anti-corruption layers, TLS secrets
- `workload_telemetry.tf` → Observability sidecars, telemetry IAM roles, config buckets

**Not by technology.** Don't create `cloud_run.tf`, `load_balancer.tf`, or `iam.tf`. Instead, group resources by the *function* they enable.

---

## Workflow

### 1. Identify the Functional Concern

Before writing code, clarify what this file does in one sentence:
- "This file configures Cloud Run service and its service account."
- "This file exposes the service via an external load balancer."
- "This file manages secrets used by the workload."

If you can't describe it in one sentence, it's probably two files.

### 2. Write the Documentation Header

Every `.tf` file opens with a block comment (using `/**` and `*/`) that:
- Explains WHAT the file does and WHY (2-4 sentences)
- States the design principle or tradeoff being addressed
- References links to relevant GCP/Terraform documentation **only** (no full doc text)
- Closes with a final `*/`

**Example:**
```hcl
/**
 * Application workload from the digital factory is serverless.
 * By default it is represented by a unique cloud run service to support web app computation.
 * Egress and ingress traffic is forbidden to bypass enterprise proxy.
 * For this reason we only accept traffic coming from internal service and load balancer.
 *
 * More info:
 * https://cloud.google.com/run/docs/overview/what-is-cloud-run
 * https://cloud.google.com/run/docs/configuring/vpc-connectors
 * https://cloud.google.com/run/docs/securing/managing-access#make-service-public
 */
```

### 3. Organize Code Within the File

**Recommended order:**
1. **Locals** — Derived values, conditionals, computed names. Place `locals` blocks near the resources that consume them, not in one central block.
2. **Data sources** — Read external state (projects, existing resources, secret versions).
3. **Resources** — The actual GCP resources.
4. **Outputs** (rare in sub-modules) — Only if this file directly outputs something important to the parent module.

**Example structure:**
```hcl
/**
 * Documentation header...
 */

locals {
  # Computed flags for resource creation
  create_external_load_balancer = contains(["EXTERNAL"], var.service_exposure) ? 1 : 0
}

resource "google_compute_global_address" "elb_ip" {
  count   = local.create_external_load_balancer
  project = local.project_id
  name    = "..."
  # ...
}

locals {
  # Locals used downstream
  elb_ip = try(google_compute_global_address.elb_ip[0].address, null)
}

module "elb" {
  count = local.create_external_load_balancer
  # ...
}
```

### 4. Resource Conditionality

If resources are only created under certain conditions (e.g., `service_exposure = "EXTERNAL"`), use `count` or `for_each` and derive them from `local.create_*` variables. This makes it immediately clear which resources are conditional and under what circumstances.

```hcl
locals {
  create_external_exposure = var.service_exposure == "EXTERNAL" ? 1 : 0
}

resource "google_compute_security_policy" "armor" {
  count = local.create_external_exposure
  # ...
}
```

### 5. Naming Conventions

- **Files:** Use snake_case, named by functional concern: `workload.tf`, `workload_external_exposure.tf`, not `cloud_run.tf`
- **Resources:** Use descriptive resource names that reflect their purpose: `google_cloud_run_v2_service.main`, `google_compute_security_policy.armor`
- **Locals and variables:** Match your module's established naming (check existing files first)

### 6. Comments in Code

- **What and Why, not How.** Explain non-obvious decisions, domain intent, or constraints.
- **Temporal context is bad.** Don't write "Added in PR #123" or "Fixed by us last week." Comments should be timeless.
- **Link to issues/designs when applicable.** If a `TODO` exists, reference the issue: `# TODO: https://github.com/org/repo/issues/456`

Example good comment:
```hcl
# We create a discriminated service name to avoid collisions on rapid recreates.
# This allows CI to redeploy without manual state cleanup.
local.discriminized_service_name = "${local.service_name}-${random_string.discriminator.id}"
```

Example bad comment:
```hcl
# Fixed in commit abc123
# Added random suffix to prevent naming conflicts (fixed by Bot on 2024-01-15)
```

### 7. Validation

Before considering the file complete, run:
```bash
terraform validate
```

from the module root (or the repository root if validating across modules). This ensures:
- Syntax is correct
- All referenced variables exist
- Resource types are valid
- No circular dependencies

If `terraform validate` fails, fix the issue before moving on. This is non-negotiable.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad | Better Approach |
|--------------|-------------|-----------------|
| One giant `main.tf` with 500+ lines | Hard to navigate, unclear responsibility | Split by functional concern |
| `locals.tf` with all computed values | Locals lose context; hard to understand dependencies | Keep `locals` near consuming resources |
| Comments explaining "what" the code does | Terraform is self-documenting; comments should explain intent | Document intent; write clear variable/resource names |
| Circular dependencies or deep resource chains | Fragile; one change breaks everything | Use data sources for lookups; modularize |
| Resource count with hardcoded numbers | Magic numbers are confusing | Use `local.create_*` flags derived from inputs |
| Mixing terraform root module with provider setup | Makes root module hard to refactor | Keep root module focused on orchestration; keep provider setup in modules |

---

## When to Create New Files vs. Extend Existing

**Create a new file if:**
- The new resources serve a different functional purpose than existing files
- Example: Adding Cloud Armor? Create `workload_external_exposure_security_policy.tf` (not `security.tf`)
- The file would exceed ~200 lines and could be logically split

**Extend an existing file if:**
- The new resources directly support the existing concern
- Example: Adding IAM bindings for the Cloud Run service? Add to `workload.tf`
- The new code feels like a natural extension of the file's purpose

---

## Module Structure Example

For a typical GCP web application module (`application_core`):

```
application_core/
├── main.tf                                    # Project data, global locals
├── workload.tf                                # Cloud Run service, service account, IAM
├── workload_exposure_backend.tf               # Shared NEG + backend service
├── workload_internal_exposure.tf              # ILB, forwarding rules, HTTPS proxy
├── workload_external_exposure.tf              # ELB, global address, secondary NEGs
├── workload_external_exposure_security_policy.tf  # Cloud Armor, IP whitelisting
├── workload_secrets.tf                        # Secret Manager, TLS secrets, anti-corruption
├── workload_telemetry.tf                      # OTel sidecar, telemetry IAM
├── variables.tf                               # Input variables
├── outputs.tf                                 # Module outputs
├── versions.tf                                # Provider constraints
├── config.yaml                                # Static configs (OTel, etc.)
├── README.md                                  # Module documentation
└── CLAUDE.md                                  # Developer guidance (this project's pattern)
```

---

## Using Context7 for Documentation

If Context7 MCP is available, use it to look up:
- GCP service documentation (Cloud Run, Load Balancer, Secret Manager, etc.)
- Terraform provider docs for `google` and `google-beta`
- Architecture best practices for the specific concern

When referencing external docs in the file header, use the full URL and a brief description. Example:

```hcl
/**
 * More info:
 * https://cloud.google.com/load-balancing/docs/https#http3-negotiation
 * https://cloud.google.com/run/docs/configuring/services/cloud-storage-volume-mounts
 */
```

---

## Checklist Before Marking File Complete

- [ ] File has a clear functional purpose (can describe in one sentence)
- [ ] Documentation header explains WHAT and WHY with links to relevant docs
- [ ] Resources are organized by locals → data sources → resources
- [ ] Conditional resources use `local.create_*` flags
- [ ] All comments explain intent, not timeline
- [ ] File names match functional concern (not technology)
- [ ] `terraform validate` passes from the module root
- [ ] File does not exceed ~250 lines (if longer, split by concern)
- [ ] Naming conventions match the module's existing patterns

