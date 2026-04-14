# Demo Script — "Terraform + Agentic Workflows with GitHub Copilot (and Work IQ)"

**Audience:** Infrastructure / Platform Engineering  
**Duration:** ~45 minutes + Q&A  
**Goal:** Show GitHub Copilot value for day-to-day infra tasks: IaC authoring, validation, plan review, PR acceleration, and offloading toil.

---

## Core Concepts

| Capability | Description | Where it runs |
|---|---|---|
| **Agent Mode (IDE)** | Interactive "inner loop" — multi-step, runs commands/tests, self-corrects | VS Code |
| **Copilot CLI** | Terminal-native agent — same workflows where infra engineers live | Terminal |
| **Coding Agent / Cloud Agent** | Async "outer loop" — Issue → isolated environment → PR | GitHub.com |
| **Work IQ** | Work context (meetings, emails, docs, Teams) wired into your coding assistant | CLI / MCP |

---

## 0) Pre-Demo Checklist

- [ ] VS Code open with this repo (`C:\source\copilot-infra-demo`)
- [ ] Terminal in repo root with `terraform` available (or use pre-recorded `plan.txt`)
- [ ] GitHub Copilot Chat enabled — Agent mode available (mode dropdown: Ask / Edit / Agent)
- [ ] GitHub Copilot CLI installed + authenticated
- [ ] Work IQ configured (or screenshots/recorded output as fallback)
- [ ] `plan.txt` present in repo root (pre-recorded plan output for CLI demo)

> **Note:** If the repo is on Azure DevOps / Azure Repos, that's fine — Agent Mode and Copilot usage aren't dependent on GitHub hosting. Just skip GitHub-only PR automation or show a concept slide.

---

## 1) Opening (2 minutes) — Set Expectations

### Say:

> "Thanks again for Tuesday — today we'll keep it **infrastructure-first** and **Terraform-first**. We'll cover three practical workflows:
>
> 1. Interactive Terraform changes with **Agent Mode** in the IDE  
> 2. Terminal-first automation with **Copilot CLI**  
> 3. Where it makes sense, offloading bigger work to a **coding agent** that returns a PR  
>
> We'll keep governance in mind: you'll see approvals, transparency of actions, and review-first workflows."

### Why this framing works:
- Agent mode = multi-step IDE work proposing file edits, running terminal commands/tests, and iterating
- Coding agent = returns PRs after working asynchronously in an isolated environment

---

## 2) Agenda Slide (30 seconds)

Show:

1. Terraform module hardening with IDE Agent Mode
2. Plan review + runbook generation in terminal (Copilot CLI)
3. Delegation → PR workflow (coding agent / cloud agent)
4. Work IQ "context injection"
5. Q&A

---

## 3) Demo Part A — Terraform "Hardening" with Agent Mode (12–15 minutes)

**Objective:** Show agent mode doing multi-file edits + running fmt/validate/tests and self-correcting.

### A1. Frame Agent Mode (30 seconds)

**Say:**

> "Agent Mode is the interactive, synchronous agent inside VS Code. Unlike simple chat or single-file edits, it can **reason over the workspace**, make coordinated changes, **run terminal commands/tests**, detect failures, and **iterate** until it reaches the goal."

### A2. Prompt: Enforce Tagging + Validations

Open Copilot Chat → select **Agent** mode → paste:

```
You are in a Terraform repository.

Goal: enforce required tags across modules and make plans fail fast.

Tasks:
1) Add a standard tags variable (map(string)) and merge with mandatory
   tags: environment, owner, cost_center.
2) Add validation so terraform validate fails if any mandatory tag is
   missing or empty.
3) Update outputs (if any) to expose resolved tags for downstream.
4) Update README.md with a short "Tagging & Validation" section
   describing the behavior and how to use it.

After changes, run:
- terraform fmt -recursive
- terraform validate

If validate fails, fix and retry until it passes.

Summarize what you changed and why.
```

### Talk Track While It Runs:

- *"Notice it chooses relevant files and proposes edits."*
- *"It will suggest terminal commands; we approve those."* (Agent mode runs terminal commands/tests and loops.)

### A3. Mini "Debug Loop" Moment (2–3 minutes)

If `terraform validate` fails (even intentionally), highlight:

> "This is the **self-correcting loop**: it watches the output and iterates."

### A4. Close Part A (30 seconds)

**Say:**

> "This is ideal when an engineer is actively working and wants fast iteration — **inner-loop** Terraform authoring plus guardrails."

---

## 4) Demo Part B — Copilot CLI for Terraform Ops (10–12 minutes)

**Objective:** Speak to infra engineers in terminal: interpret plan output, generate runbooks, scripts, and consistent ops responses.

### B1. Frame Copilot CLI (30 seconds)

**Say:**

> "Copilot CLI brings an agent into the terminal — great for DevOps workflows. It's **editor-agnostic** and runs locally in your terminal."

### B2. Start Copilot CLI in Repo Root

```powershell
cd C:\source\copilot-infra-demo
copilot
```

### B3. Prompt: Explain Plan + Risk Classify

```
Review the Terraform plan output in plan.txt in this folder.
Summarize the change set in plain English.
Classify changes as: low risk / medium risk / high risk, and explain why.
Provide a short pre-check list and rollback guidance.
```

**Talk track:**

- *"This is where infra teams spend time — understanding blast radius and writing runbooks."*
- *"We still keep humans in control: review, approvals, and change management."*

### B4. Prompt: Create a Reusable Runbook

```
Create RUNBOOK_terraform_change.md with:
- Purpose
- Preconditions / Access checks
- Commands to run (fmt/validate/plan/apply)
- Verification steps
- Rollback steps
- Common failure modes + mitigations

Keep it generic so it can be reused across environments.
```

### B5. Optional: PowerShell Script Generation

```
Create a PowerShell script deploy-infra.ps1 that:
1) Runs terraform init
2) Runs terraform plan -out=tfplan and saves the output
3) Asks for confirmation before apply
4) Runs terraform apply tfplan
5) Captures outputs and writes them to deployment-output.json
6) Has proper error handling and logging throughout

Make it production-ready with parameters for environment and backend config.
```

**Talk track:**

- *"This is another workflow infra teams ask for — reusable deployment scripts that follow your standards."*

### B6. Optional: Custom Agent Mention (30 seconds)

> "If you want consistent runbooks every time, Copilot supports **custom agents** and repo-level conventions — we can encode your standards once."
>
> Custom agents for Copilot CLI live under `.github/agents/`.

---

## 5) Demo Part C — `/delegate`, `/agent`, and Coding Agent (15–18 minutes)

**Objective:** Show three ways to offload work — from a quick inline agent call, to delegation, to fully async PR automation.

### C1. Frame the Three Modes (1 minute)

**Say:**

> "We've seen the **inner loop** with Agent Mode in VS Code. Now let's look at how Copilot CLI lets you offload work in three ways:
>
> 1. **`/agent`** — run a sub-agent right here in the terminal for a focused task  
> 2. **`/delegate`** — hand off a larger task to the cloud agent, which opens a draft PR  
> 3. **Coding agent from GitHub.com** — assign an issue and get a PR back"

---

### C2. `/agent` — Inline Sub-Agent in CLI (5 minutes)

**Say:**

> "`/agent` runs a sub-agent that can explore your codebase, make changes, and run commands — all within your CLI session. Think of it as 'Agent Mode but in the terminal.'"

#### Demo Prompt 1 — Security audit

In Copilot CLI:

```
/agent Review all .tf files in this repo for security best practices.
Check for: missing encryption settings, overly permissive network rules,
missing diagnostic settings, and resources without lifecycle blocks.
Create a file SECURITY_FINDINGS.md with your findings and recommendations.
```

**Talk track:**

- *"Notice it's reading files, analyzing patterns, and producing a structured report."*
- *"This is great for quick audits before a PR — you stay in the terminal."*

#### Demo Prompt 2 — Generate a module

```
/agent Create a new Terraform module under modules/storage/ that provisions
an Azure Storage Account with:
- Blob versioning enabled
- Soft delete for blobs (7 days) and containers (7 days)
- Private endpoint support (variable toggle)
- Required tags passed through
- A README.md for the module
Run terraform fmt on the new files when done.
```

**Talk track:**

- *"The agent creates the entire module structure — main.tf, variables.tf, outputs.tf, README — in one go."*
- *"It even runs `terraform fmt` to ensure formatting is correct."*

---

### C3. `/delegate` — Hand Off to Cloud Agent → PR (5 minutes)

**Say:**

> "When the task should land as a PR — maybe it's bigger, or you want a review gate — use `/delegate`. It hands off to the **cloud agent**, which works in an isolated environment and opens a draft PR."

#### Demo Prompt — CI Workflow

In Copilot CLI:

```
/delegate Add a GitHub Actions workflow (.github/workflows/terraform-ci.yml)
that runs on pull requests and does:
1) terraform fmt -check -recursive
2) terraform init -backend=false
3) terraform validate
4) terraform plan -no-color (saved as an artifact)
5) Post the plan output as a PR comment

Also update README.md with a "CI/CD" section explaining:
- What the workflow does
- How to read the plan artifact
- What to do if fmt or validate fails
```

**Call out what's happening:**

- *"It commits a checkpoint, creates a branch, and opens a draft PR."*
- *"The cloud agent works in the background — we can keep working."*
- *"When it's done, we get a notification and can review the PR."*

> **Tip:** We already have a reference workflow in `.github/workflows/terraform-ci.yml` — you can show this as the "expected result" if delegation takes too long live.

#### Show the Reference Workflow

If `/delegate` is still running or if you want to fast-forward:

> "Here's what the workflow looks like — let me show you the one we already have as a reference."

Open `.github/workflows/terraform-ci.yml` and walk through:

- **Format check** → fails fast on formatting issues
- **Init + Validate** → catches config errors before plan
- **Plan + artifact upload** → plan is saved and posted to the PR as a comment
- **PR comment with results table** → reviewers see status at a glance

---

### C4. Coding Agent from GitHub.com (3 minutes)

**Say:**

> "The third mode is **fully async**: you assign a GitHub Issue to Copilot, and the coding agent picks it up. It works in an ephemeral environment, creates a branch, and opens a PR — like an async team member."

#### Walk Through the Issue Template

Show `.github/ISSUE_TEMPLATE/terraform-module-request.md`:

> "We've set up an issue template for Terraform module requests. When someone files an issue like 'Create a monitoring module with alerts for Key Vault,' they can assign it to Copilot."

#### Show the Setup Steps

Show `.github/workflows/copilot-setup-steps.yml`:

> "This `copilot-setup-steps.yml` workflow tells the coding agent how to set up its environment — install Terraform, run init. It's how you customize the agent's workspace."

#### Scenario (talk-through or live)

> "Imagine someone files an issue: *'Add a Terraform module for Azure Monitor diagnostic settings that auto-attaches to all resources.'*
>
> They assign it to Copilot. The coding agent:
> 1. Spins up an isolated environment  
> 2. Reads the issue requirements  
> 3. Creates the module, writes tests, runs fmt/validate  
> 4. Opens a draft PR linked to the issue  
>
> The engineer reviews, requests changes, and Copilot iterates — all in the PR."

---

### C5. Close Part C (30 seconds)

**Summary:**

| Command / Mode | Where it runs | Best for |
|---|---|---|
| `/agent` | Your terminal (inline) | Quick audits, module generation, scripts |
| `/delegate` | Cloud agent → draft PR | Larger tasks that need PR review |
| Coding agent (issue) | GitHub.com → draft PR | Backlog items, team-wide requests |

**Say:**

> "Three levels of delegation: **inline**, **PR-targeted**, and **fully async from an issue**. All produce reviewable, auditable output."

---

## 6) Demo Part D — Work IQ (3–5 minutes)

**Objective:** Make "Copilot + work context" real: requirements/decisions/owners without leaving the dev workflow.

### D1. One-Sentence Definition

**Say:**

> "Work IQ is a CLI and MCP server that connects AI assistants to **Microsoft 365 Copilot data** — emails, meetings, docs, Teams — so your coding assistant can pull the 'work around the work.'"

### D2. Micro-Demo Prompt

If Work IQ is configured:

```
Using Work IQ: summarize what was decided in my most recent meeting
about the infrastructure migration project.
Return 5 bullets.
```

**Alternative prompts if the above isn't relevant:**

```
Using Work IQ: find any recent emails about Terraform module standards
or tagging policies. Summarize the key requirements.
```

```
Using Work IQ: who are the stakeholders for the cloud migration project
based on recent meetings and email threads?
```

### D3. Tie It Back

> "This reduces time spent hunting meeting notes and aligns the changes you're making in Terraform with the decisions and stakeholders."

---

## 7) Closing + Q&A (5 minutes)

### Summary Slide / Talking Points

| What we showed | Copilot capability | Value |
|---|---|---|
| Tag enforcement + validation | Agent Mode (IDE) | Fast, safe iteration with guardrails |
| Plan review + risk classification | Copilot CLI | Terminal-native, blast-radius clarity |
| Runbook + script generation | Copilot CLI | Consistent ops documentation |
| CI workflow via delegation | Coding Agent | Async PR workflow, backlog automation |
| Meeting/email context | Work IQ | Decisions → code without tab-switching |

### Closing Statement

> "The through-line is: **Copilot meets infrastructure engineers where they already work** — in the IDE, in the terminal, and in the PR review. Governance stays intact: every change is visible, reviewable, and auditable."

---

## Appendix: Copy-Paste Prompts

### Agent Mode — Tag Hardening
```
You are in a Terraform repository.

Goal: enforce required tags across modules and make plans fail fast.

Tasks:
1) Add a standard tags variable (map(string)) and merge with mandatory
   tags: environment, owner, cost_center.
2) Add validation so terraform validate fails if any mandatory tag is
   missing or empty.
3) Update outputs (if any) to expose resolved tags for downstream.
4) Update README.md with a short "Tagging & Validation" section
   describing the behavior and how to use it.

After changes, run:
- terraform fmt -recursive
- terraform validate

If validate fails, fix and retry until it passes.

Summarize what you changed and why.
```

### CLI — Plan Review
```
Review the Terraform plan output in plan.txt in this folder.
Summarize the change set in plain English.
Classify changes as: low risk / medium risk / high risk, and explain why.
Provide a short pre-check list and rollback guidance.
```

### CLI — Runbook Generation
```
Create RUNBOOK_terraform_change.md with:
- Purpose
- Preconditions / Access checks
- Commands to run (fmt/validate/plan/apply)
- Verification steps
- Rollback steps
- Common failure modes + mitigations

Keep it generic so it can be reused across environments.
```

### CLI — PowerShell Script
```
Create a PowerShell script deploy-infra.ps1 that:
1) Runs terraform init
2) Runs terraform plan -out=tfplan and saves the output
3) Asks for confirmation before apply
4) Runs terraform apply tfplan
5) Captures outputs and writes them to deployment-output.json
6) Has proper error handling and logging throughout

Make it production-ready with parameters for environment and backend config.
```

### CLI — /agent Security Audit
```
/agent Review all .tf files in this repo for security best practices.
Check for: missing encryption settings, overly permissive network rules,
missing diagnostic settings, and resources without lifecycle blocks.
Create a file SECURITY_FINDINGS.md with your findings and recommendations.
```

### CLI — /agent Module Generation
```
/agent Create a new Terraform module under modules/storage/ that provisions
an Azure Storage Account with:
- Blob versioning enabled
- Soft delete for blobs (7 days) and containers (7 days)
- Private endpoint support (variable toggle)
- Required tags passed through
- A README.md for the module
Run terraform fmt on the new files when done.
```

### CLI — /delegate CI Workflow
```
/delegate Add a GitHub Actions workflow (.github/workflows/terraform-ci.yml)
that runs on pull requests and does:
1) terraform fmt -check -recursive
2) terraform init -backend=false
3) terraform validate
4) terraform plan -no-color (saved as an artifact)
5) Post the plan output as a PR comment

Also update README.md with a "CI/CD" section explaining:
- What the workflow does
- How to read the plan artifact
- What to do if fmt or validate fails
```

### Work IQ — Meeting Context
```
Using Work IQ: summarize what was decided in my most recent meeting
about the infrastructure migration project.
Return 5 bullets.
```

---

## Appendix: Repo Structure (Before Demo)

```
copilot-infra-demo/
├── main.tf                           # Azure resources (no tags!)
├── variables.tf                      # Inputs (no tag validation)
├── outputs.tf                        # Basic outputs
├── providers.tf                      # AzureRM provider + backend
├── terraform.tfvars                  # Sample values
├── plan.txt                          # Pre-recorded plan output for CLI
├── README.md                         # Basic readme (enhanced during demo)
├── modules/
│   └── networking/
│       ├── main.tf                   # VNet, subnets, NSGs
│       ├── variables.tf
│       └── outputs.tf
└── .github/
    ├── agents/
    │   └── terraform-runbook.yml     # Custom agent for runbook generation
    ├── ISSUE_TEMPLATE/
    │   └── terraform-module-request.md  # Issue template for coding agent
    └── workflows/
        ├── terraform-ci.yml          # Reference CI workflow (show during demo)
        └── copilot-setup-steps.yml   # Coding agent environment setup
```

### What's intentionally missing (for the demo to add):
- ❌ No `tags` variable or tag enforcement → **Agent Mode adds this**
- ❌ No `validation` blocks → **Agent Mode adds this**
- ❌ No runbook or deployment scripts → **Copilot CLI generates these**
- ❌ No security audit → **`/agent` produces this**
- ❌ No storage module → **`/agent` creates this**

### What's pre-staged (reference / fallback):
- ✅ `terraform-ci.yml` — reference CI workflow (show if `/delegate` is slow)
- ✅ `copilot-setup-steps.yml` — coding agent env setup (walk through)
- ✅ Issue template — for coding agent demo scenario
- ✅ Custom agent config — for runbook consistency mention

This "before" state lets each demo section **visibly add value**.
