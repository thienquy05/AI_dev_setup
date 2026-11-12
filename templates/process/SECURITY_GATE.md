# Security gate

Applies to every project, private or public. Goal: no known vulnerability ships. Adapt the tool list to the stack; keep the procedure.

## 1. Layers
| When | What | Tools (prefer installed and well-known open source) |
|---|---|---|
| Every commit (local) | Secrets and privacy | Gitleaks (pre-commit or CI), the project's own privacy scan if it has one |
| Every PR (CI, required check) | Secrets, dependencies, static analysis | Gitleaks; dependency audit (`npm audit --audit-level=high`, `pip-audit`, or OSV-Scanner); CodeQL (free on public repos) or Semgrep OSS (any repo); language linters with security rules (for example ruff `S` rules, eslint security plugins) |
| End of every phase | Deep review of the phase | ECC `security-reviewer` / `security-scan`, Claude Code `/security-review`, the Cloudflare `security-audit` skill (if enabled), an independent review of every fix |
| Before production | Release checklist (§4) | Full-repo audit, runtime checks against the deployed build |

## 2. Phase procedure
1. **Freeze the candidate.** Stop adding features; merge the phase's PRs; record the candidate commit SHA. Nothing is audited from an open branch.
2. **Sweep.** Required CI checks green; dependency and code-scanning alerts read and triaged.
3. **Audit.** Run the phase audit tools on the candidate. Output stays outside the repo (git-ignored or a private folder).
4. **Triage** every record: `confirmed` → fix; `needs_validation` → write a test or runtime check that settles it; `rejected` → keep the reason; hardening ideas → a list.
5. **Fix test-first.** One branch per finding group (`fix/security-<slug>`): a regression test that fails for the stated reason, the smallest fix, full suite green.
6. **Re-run** the audit on the new candidate SHA. New confirmed findings repeat steps 5–6.
7. **Independent review** of the fixes and the phase diff (`REVIEW.md`).
8. **Record and ask.** Progress file line: candidate SHA, tools and versions, findings by severity and status, fixes, accepted items, date. Then ask the owner to approve the phase.

## 3. Pass criteria
- No open confirmed critical or high finding.
- Every medium fixed or explicitly accepted by the owner (accepted items list the compensating control).
- Every `needs_validation` settled by a test or runtime check.
- The audit runs completed (not cut short by a budget or error).
- Final audit, review and checks all refer to one recorded SHA.

## 4. Pre-production checklist
- [ ] Phase gate passed on the exact commit being deployed.
- [ ] No secrets in the repo history (`gitleaks detect` over full history).
- [ ] Dependencies: no known high/critical vulnerabilities; lockfile committed; versions pinned.
- [ ] Demo, seed and test accounts removed or disabled in production.
- [ ] Authentication, authorization and data isolation tested with negative cases (wrong user, no token, expired token).
- [ ] Input validation at every trust boundary; output encoding in UIs; file uploads checked for type and size.
- [ ] Security headers and cookie flags checked on the deployed URL (CSP, HSTS, `Secure`, `HttpOnly`, `SameSite`).
- [ ] Preview and old deployment URLs protected or unreachable.
- [ ] Rate limits on login, signup, password reset and any costly endpoint.
- [ ] Logging contains no secrets or personal data; errors do not leak stack traces.
- [ ] Secrets rotated if they were ever shared, logged or used in development.
- [ ] Backups and restore tested, if the project stores data.
- [ ] For apps that call LLMs or run agents: prompt-injection tests, tool permissions least-privilege, untrusted content never treated as instructions (OWASP Top 10 for LLM and Agentic Applications).
- [ ] Agent tooling config reviewed (MCP servers, hooks, skills) with a scanner such as ECC AgentShield.

## 5. Handling findings
- Exploit details (steps, payloads, proofs) never go into git, PRs, issues or public chats. The progress file gets counts, severities and fix links only.
- A regression test is named after the control it checks, not the exploit.
- After go-live: contain first (disable the feature, rotate tokens), fix privately, publish the fix at the last moment, verify in production.

## 6. Pinning third-party skills
Before each run of a downloaded skill or tool, verify it has not changed since it was reviewed (commit SHA or a content hash of its files). A changed skill is re-read before use.
