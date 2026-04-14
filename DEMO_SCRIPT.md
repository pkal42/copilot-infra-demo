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

## 5) Demo Part C — Delegation: CLI → Cloud Agent → PR (12–15 minutes)

**Objective:** Show "team productivity" — offload work and get a PR back.

### C1. Frame Delegation (30–45 seconds)

**Say:**

> "When the task is larger and should land as a PR anyway, you can **delegate** from the CLI. `/delegate` hands off the task to the cloud agent, which opens a draft PR and works in the background."

### C2. Run Delegation

In Copilot CLI:

```
/delegate Add a GitHub Actions workflow that runs terraform fmt -check,
terraform validate, and a terraform plan on pull requests.
Also update README.md with the CI behavior and how to interpret
plan artifacts.
```

**Call out what's happening:**

- *"It commits a checkpoint and creates a branch, then opens a draft PR and continues in the background."*

### C3. Explain Coding/Cloud Agent (1 minute)

**Say:**

> "The cloud agent / coding agent is **asynchronous** — it works in an ephemeral environment powered by GitHub Actions, producing a PR for human review."
>
> "This is a strong fit for **backlog items** and repetitive hygiene tasks."

**Customer-safe line:**

> "Agent mode is **synchronous** in VS Code, coding agent is **asynchronous** on GitHub.com; they complement each other."

### C4. Show the PR (if available)

Navigate to GitHub → show the draft PR → highlight:

- The branch and commit message
- The CI workflow file it created
- The README updates
- That it's a **draft** — human review required before merge

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

### CLI — Delegate CI Workflow
```
/delegate Add a GitHub Actions workflow that runs terraform fmt -check,
terraform validate, and a terraform plan on pull requests.
Also update README.md with the CI behavior and how to interpret
plan artifacts.
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
├── main.tf                  # Azure resources (RG, Key Vault, Storage, Log Analytics)
├── variables.tf             # Input variables (NO tag validation yet)
├── outputs.tf               # Basic outputs
├── providers.tf             # AzureRM provider + backend
├── terraform.tfvars         # Sample values
├── plan.txt                 # Pre-recorded terraform plan output
├── README.md                # Basic readme (will be enhanced)
├── modules/
│   └── networking/
│       ├── main.tf          # VNet, subnets, NSGs
│       ├── variables.tf
│       └── outputs.tf
└── .github/
    └── agents/              # Placeholder for custom agents
```

### What's intentionally missing (for the demo to add):
- ❌ No `tags` variable or tag enforcement
- ❌ No `validation` blocks
- ❌ No CI/CD workflow
- ❌ No runbook or deployment scripts
- ❌ No tagging section in README

This "before" state lets each demo section **visibly add value**.
