---
name: production-workflow
description: "enforce a production-first coding workflow for app and web projects, especially vite and flutter repositories. use when chatgpt is asked to write code, fix bugs, refactor, audit a repo, test end-to-end flows, integrate backend, deploy, or update implementation status. always reply in vietnamese. after every task that changes code or operational behavior, update the project's living docs: review.md, roadmap.md, and assessment.md. compress long-running context into those docs so they become the durable source of truth."
---

# Production Workflow

## Overview

Follow a production-first workflow for code tasks in application repositories. Prioritize stability, end-to-end flow integrity, API contract correctness, deploy safety, and documentation freshness over feature expansion.

## Core operating rules

- Always reply in Vietnamese unless the user explicitly asks for another language.
- Treat code, configuration, schema, CI, deploy scripts, app state wiring, and operational docs as production work.
- Do not add new features before stabilizing the main flow, fixing blocking bugs, and verifying critical contracts.
- Prefer small, reversible changes over broad refactors during stabilization.
- Use the repository's current code and runtime behavior as the source of truth when docs disagree.

## Trigger conditions

Use this skill when the user asks to:

- write or modify code
- fix bugs or crashes
- audit the repository before backend integration or release
- test or stabilize end-to-end flows
- connect frontend/mobile apps to backend APIs
- deploy or change runtime/infrastructure behavior
- summarize project status after implementation work

Do not use this skill for purely conceptual chat with no code or file impact.

## Workflow

Follow these steps in order.

### 1. Classify the task

Determine whether the task is primarily one of these:

- stabilization: bug fixing, crash fixing, state/navigation/lifecycle cleanup
- integration: backend wiring, API contract alignment, environment/config updates
- delivery: build, release, deploy, monitoring, operational changes
- documentation: review, roadmap, assessment, handoff, context compression

### 2. Inspect current truth

Before changing code:

- inspect the relevant files and current repository structure
- inspect existing docs if present:
  - `docs/REVIEW.md`
  - `docs/ROADMAP.md`
  - `docs/ASSESSMENT.md`
- if these docs disagree with code, trust code/runtime first and record the mismatch

### 3. Execute production-first changes

Apply changes using this priority order:

1. compile errors, crashes, failing builds
2. state, lifecycle, navigation, loading, API contract mismatches
3. critical end-to-end flows
4. deploy/runtime safety
5. UI polish and secondary cleanup

For vite and flutter repositories, explicitly watch for:

- hardcoded mock data leaking into production paths
- provider/store/repository wiring mistakes
- enum or field-name mismatches across frontend and backend
- loading loops, stale cache, incorrect empty/error states
- route guards, auth bootstrap, and startup configuration drift
- environment/config divergence across local, staging, and production

### 4. Validate after implementation

After each meaningful code change, validate with the most relevant checks available, such as:

- build or static analysis
- targeted tests
- critical flow walkthrough
- config/runtime sanity checks

Do not claim completion without naming what was verified and what remains unverified.

### 5. Update living docs every time

After every task that changes code, behavior, or operational state, update the living docs.

#### Required files

Always update these files if they exist. If the repo has a `docs/` directory and any required file is missing, create it:

- `docs/REVIEW.md`
- `docs/ROADMAP.md`
- `docs/ASSESSMENT.md`

#### Optional files

Update these when relevant:

- `docs/STABILIZATION_PLAN.md` for audit, bug-fixing, and end-to-end flow work
- `docs/DEPLOY_CHECKLIST.md` for deploy, infra, environment, or runtime changes

#### Update intent per file

Use these roles consistently:

- `REVIEW.md`: what changed, what was verified, what remains risky, key decisions made
- `ROADMAP.md`: milestone status, sequence of remaining work, immediate next actions
- `ASSESSMENT.md`: current technical truth, blockers, known mismatches, quality and production readiness assessment

See `references/doc-update-templates.md` for suggested structure.

### 6. Compress long context into docs

When the conversation becomes long, the repo is complex, or the work spans multiple sessions, write a durable handoff summary into the living docs instead of relying on chat memory.

Use this rule:

- `ASSESSMENT.md`: store the latest technical truth, blockers, assumptions, and unresolved risks
- `ROADMAP.md`: store the latest execution order and next milestones
- `REVIEW.md`: store the latest implementation summary and verification results

Treat these docs as the project's persistent memory layer.

## Output expectations in chat

In the final response for code work:

- summarize what changed
- state what was verified
- state what was not verified
- state which docs were updated
- keep the answer in Vietnamese

## Guardrails

- Do not silently skip doc updates after code work.
- Do not say a task is production-ready if build, flow, contract, or deploy risk is still open.
- Do not optimize for aesthetics before critical flow stability.
- Do not preserve outdated roadmap text when code has already diverged; update the docs.
