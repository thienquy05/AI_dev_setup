# PRD template for applications (web, desktop, mobile, services)

Companion to `PRD_TEMPLATE.md` (research / ML). Copy to `docs/PRD.md` and delete what does not apply. Keep section numbers stable; plans and prompts refer to them.

## Header
Status, version, date, owner, reviewers, visibility (public / private), privacy rule (placeholders only).

## 1. Executive summary
1.1 Problem (2–3 sentences). 1.2 Proposed solution. 1.3 Expected impact (3 bullets). 1.4 Success metrics (3–5, measurable). 1.5 Definition of Done.

## 2. Users and context
2.1 User types and what each needs. 2.2 Key journeys (step lists). 2.3 Devices, platforms, languages, accessibility needs. 2.4 Cost of not solving.

## 3. Scope
3.1 In scope (ID, item, priority P0–P2). 3.2 Out of scope. 3.3 MVP. 3.4 Later phases.

## 4. Requirements
4.1 User stories with acceptance criteria. 4.2 Functional requirements (FR-xx). 4.3 Non-functional: performance budgets, availability, accessibility (WCAG level), privacy, security, i18n, offline behavior, supported browsers/OS.

## 5. Data
Entities and fields, ownership, retention and deletion, what is personal data, where it is stored, who can read and write what (access model), migrations.

## 6. Security and privacy
Assets, actors, trust boundaries, threat list with controls and the test that proves each control, secrets handling, third parties that receive data. Links `docs/process/SECURITY_GATE.md`.

## 7. Technical specification
Architecture diagram, components, APIs (routes, inputs, outputs, errors), dependencies with reasons, configuration and environment variables (names only), code layout.

## 8. Design
Screens and states (default, empty, loading, error, limit reached, offline), responsive breakpoints, themes, motion and reduced motion, copy.

## 9. Environments and release
Local setup, CI, preview, staging, production, deploy and rollback, monitoring and alerts, cost limits.

## 10. Testing and QA
10.1 Verification loop (`docs/process/TESTING.md`). 10.2 Edge-case catalog (every row is a required test). 10.3 Acceptance checklist.

## 11. Implementation Phases, gates and exit criteria
Table: phase, contents, status (pending / in progress / complete), exit criteria, review and security gate.

## 12. Risks and mitigations
Table: risk, probability, impact, mitigation.

## 13. Decisions and open questions
Table: ID, question, default if unanswered, status, decided by, date.

## Appendices
Glossary, runbook, research notes.
