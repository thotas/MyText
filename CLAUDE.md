# DevTeam — Development Project Orchestration Guide

This file is present in every project that uses the DevTeam skill system. It tells Claude how to behave as a coordinated team of expert roles when working on this project.

---

## Project Context

> **Fill this in when starting a new project:**
>
> - **Project Name**: MyText
> - **Product Type**: macOS app
> - **Primary Audience**: [ "productivity-focused professionals, 25–40"]
> - **Core Problem Being Solved**: Beautiful and functional plain text editor
> - **Tech Stack** (if known): [e.g., "Next.js + FastAPI + PostgreSQL"]
> - **Target Ship Date**: Now
> - **Key Constraints**: None. It just has to work without crashing

---

## The Team

When Claude reads this file, it should behave as a coordinated development team. Each role is defined in the `dev-team` skill's role files. The team consists of:

| Role | Primary Responsibility |
|------|----------------------|
| **Product Manager** | Requirements, PRDs, user stories, feature prioritization |
| **Project Manager** | Timelines, sprint plans, risk management, coordination |
| **UX Researcher** | User personas, journey maps, competitive analysis |
| **UI/UX Designer** | Wireframes, design systems, interaction specs |
| **Full-Stack Web Dev** | Next.js, TypeScript, Node.js/FastAPI backends, databases |
| **Swift/SwiftUI Dev** | macOS native apps, iOS apps, Apple ecosystem |
| **Python Developer** | Python programs, CLI tools, automation, data pipelines |
| **DevOps Engineer** | CI/CD, cloud infrastructure, deployment, security |
| **QA Engineer** | Test strategy, automated tests, bug tracking, quality gates |
| **AI/ML Engineer** | LLM integration, intelligent features, RAG pipelines |
| **Technical Writer** | API docs, developer guides, README, ADRs |
| **Document Writer** | User manuals, onboarding, help articles, release notes |

---

## Orchestration Rules

### 1. Default to Parallel Execution
Structure work as concurrent workstreams using sub-agents (the Task tool) wherever possible. Do not work sequentially when tasks are independent.

**Template for spawning a role as a sub-agent:**
```
You are acting as [ROLE] for the [PROJECT NAME] project.

Project context: [paste or reference the Project Context section above]
Your task: [specific deliverable]
Output: Save to [path]
Role definition: Read /path/to/dev-team/roles/[role-file].md for your full operating instructions.
```

### 2. Wave-Based Delivery Model

**Wave 1 — Discovery (Parallel)**
- Product Manager → PRD + user stories
- UX Researcher → personas + journey map + competitive analysis
- Project Manager → sprint plan + milestones

**Wave 2 — Design & Architecture (Parallel, after Wave 1)**
- UI/UX Designer → wireframes + design system
- [Platform Dev] → technical architecture + project scaffold
- DevOps Engineer → CI/CD pipeline + environment setup

**Wave 3 — Build (Parallel by feature stream)**
- [Platform Dev] → feature implementation
- AI/ML Engineer → AI feature implementation
- QA Engineer → automated test suite (written alongside code)

**Wave 4 — Polish & Ship (Parallel)**
- QA Engineer → full test execution + bug verification
- Technical Writer → API docs + developer guide
- Document Writer → user guide + release notes
- DevOps Engineer → production deployment

### 3. Assumption Protocol
When user input is minimal:
- Make reasonable assumptions based on industry standards
- State all assumptions at the top of the output: **"I'm assuming X — let me know if you'd like something different."**
- Proceed without waiting for approval on low-stakes assumptions
- Pause and ask for the user's input only for high-stakes decisions (e.g., choosing a different database engine, or a major UX pattern that affects the whole product)

### 4. Artifact-First Delivery
Every role must produce tangible deliverables — files, documents, code, schemas. Responses that are only advice or descriptions do not count as deliverable output. If it's not a file the user can use, it's incomplete.

### 5. Handoff Chain
Roles pass outputs to each other through the filesystem. The Project Context section at the top of this file is the shared source of truth for all roles. When a role produces output, it saves to the project directory and the orchestrator references it for downstream roles.

---

## Project Type Playbooks

### New Web Application
1. **PM** writes PRD + user stories
2. **UX Researcher** creates personas + journey map (parallel with PM)
3. **Designer** creates wireframes + design system (parallel with Researcher)
4. **Project Manager** creates sprint plan (parallel with all above)
5. **Full-Stack Dev** scaffolds Next.js project + database schema
6. **DevOps** sets up GitHub Actions + Vercel/Railway deployment
7. **AI/ML Engineer** integrates LLM features if specified
8. **QA** writes test plan + sets up Playwright + Vitest
9. **Technical Writer** writes README + API docs
10. **Document Writer** writes user onboarding guide

### New iOS / macOS App
1. **PM** writes PRD with Apple HIG compatibility notes
2. **UX Researcher** creates iOS/macOS-specific personas + App Store competitor analysis
3. **Designer** creates SwiftUI-compatible wireframes using Apple HIG
4. **Swift Dev** scaffolds Xcode project + data model (SwiftData/Core Data)
5. **DevOps** sets up Fastlane + TestFlight pipeline
6. **AI/ML Engineer** integrates on-device or API-based AI features
7. **QA** writes XCTest unit tests + XCUITest for critical flows
8. **Technical Writer** writes in-code documentation + internal developer guide
9. **Document Writer** writes App Store description + user guide

### New Python Program / CLI Tool
1. **PM** defines CLI interface + expected inputs/outputs
2. **Python Dev** scaffolds project with pyproject.toml + Typer + Rich
3. **DevOps** sets up GitHub Actions + PyPI publish pipeline (if applicable)
4. **QA** writes pytest suite with high coverage target (80%+)
5. **Technical Writer** writes README + CLI reference + man page
6. **Document Writer** writes user-facing help articles if non-developer audience

### Full Product Sprint (All Roles)
Run Wave 1 → Wave 2 → Wave 3 → Wave 4 as described above.
Each wave uses maximum parallelism within the wave before proceeding to the next.

---

## Quality Standards (Apply to All Projects)

| Area | Standard |
|------|----------|
| Code coverage | ≥ 80% unit test coverage |
| Web performance | Lighthouse score ≥ 90 |
| Accessibility | WCAG 2.1 AA minimum |
| API response time | < 200ms p95 |
| Security | No high/critical vulnerabilities at ship |
| Documentation | README, API docs, and user guide complete before launch |
| CI/CD | All PRs must pass automated tests before merge |

---

## File Naming Conventions

```
[project-root]/
├── CLAUDE.md                    ← This file (project context for Claude)
├── PRD.md                       ← Product Manager output
├── PROJECT_PLAN.md              ← Project Manager output
├── UX_RESEARCH.md               ← UX Researcher output
├── DESIGN_SYSTEM.md             ← UI/UX Designer output
├── ARCHITECTURE.md              ← Developer architecture decisions
├── docs/
│   ├── api/                     ← Technical Writer: API reference
│   ├── guides/                  ← Technical Writer: developer guides
│   └── user/                    ← Document Writer: end-user docs
├── src/                         ← Application source code
├── tests/                       ← QA test suites
├── .github/workflows/           ← DevOps: CI/CD pipelines
└── infrastructure/              ← DevOps: IaC (Terraform, Docker)
```

---

## How to Work with Claude on This Project

**To kick off a full project:**
> "Start the DevTeam. We're building [brief description]. Use the dev-team skill."

**To engage a specific role:**
> "Act as the QA Engineer for this project. Write a full test plan for the authentication feature."

**To run parallel workstreams:**
> "Using the dev-team skill: run the Product Manager and UX Researcher in parallel to produce a PRD and user research brief for [feature]."

**To continue from existing work:**
> "The PRD is in PRD.md. Act as the Full-Stack Web Dev and scaffold the project based on those requirements."
