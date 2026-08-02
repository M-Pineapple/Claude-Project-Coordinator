# Claude Project Coordinator

Swift MCP server for tracking Xcode/Swift projects. Local JSON knowledge base.
Complements Memory Service (project status vs conversational context). No money-path
boundary. Public MIT under M-Pineapple.

## Governance

Read `~/Github/cv-agent-governance/AGENTS.md` first. Closest-file-wins: this file
wins for repo-specific rules.

Memory namespace for this repo: `dev-cpc` (never reserved trading tags — see
`cv-agent-governance/skills/memory-tagging/SKILL.md`).

## Hard boundaries

- None money-path. Still treat user project data under `KnowledgeBase/projects/`
  and `KnowledgeBase/analytics/` as private — never commit those JSON files.
- Stdio MCP: never write diagnostics to stdout. Use `CPCLog` (stderr only).

## Coding standards

Swift 6. Use modern-swift / swift-testing skills from the Cursor skill set.
Prefer the official `MCP` Swift SDK over hand-rolled JSON-RPC.

## Build and test

```bash
swift build -c release
swift test
```

Executable: `.build/release/project-coordinator`

Optional: `CPC_KNOWLEDGE_BASE=/path/to/KnowledgeBase` overrides data location.

## Gotchas

- Allowed project roots are compiled into `SecurityValidator.allowedBasePaths`.
  Rebuild after changing them.
- Version string lives in `CPCVersion` (`Sources/ProjectCoordinator/Version.swift`).
  Keep `mcp.json`, CHANGELOG, and GitHub releases in sync with it.
- Analytics migration is file-existence gated. Do not call a bulk remigrate on
  every start.
