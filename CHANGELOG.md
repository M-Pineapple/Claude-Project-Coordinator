# Changelog

All notable changes to Dev Project Coordinator (formerly Claude Project Coordinator) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- The desk server no longer mints a new write token on every start. It reuses `desk/.write-token` when that file is a regular file (not a symlink) owned by the current user, mode 0600, holding exactly 64 lowercase hex characters. A missing file mints a token. A file that fails any check is never trusted: it is replaced with a fresh 0600 token and a warning goes to stderr without the token. Session cookies from before a restart keep working, so the Dock app no longer shows "Move failed" after a restart (#29).
- `dpc start_desk_server --rotate` and `start_desk_server rotate=true` now rotate on a fresh start too. Rotation stays the only way to replace a valid token.

## [2.0.1] - 2026-11-10

### Added
- Done cards older than 14 days are hidden on the Kanban Done column. **Show archived (N)** reveals them, muted. The window is `DPC_ARCHIVE_DAYS` or `archiveDays` in `security-config.json` (default 14). Cards are never deleted, and `cards.json` gains no archive field.
- Optional `note` on a card for a short evidence line (a commit or a URL). Omitted from `cards.json` when empty. Set from `add_card`, `update_card`, and `move_card`. Shown on the board and matched by `search_desk`.

### Fixed
- Card writes from the desk page and MCP tools now hold the same `flock` on `<knowledge base>/.dpc.lock` as the `dpc` wrapper around the whole load, change and save, so a write landing at the same moment as another no longer drops one change. The `dpc` wrapper, which holds the lock while it runs this binary, passes its locked descriptor as `DPC_LOCK_FD`. The binary skips taking the lock only when that descriptor is the same file as `.dpc.lock` and a fresh handle on the file is refused the lock. The desk server always ignores the variable. A write waits up to 15 seconds for the lock without blocking a thread, then reports an error. The lock file is opened with `O_NOFOLLOW` and `O_CLOEXEC`.
- A `cards.json` that exists but cannot be read or parsed now returns an error to the caller instead of quietly keeping the old board in memory. A missing `cards.json` is an empty board, including one removed while a long-running process holds the old board in memory.

### Changed
- `get_desk_summary` and `get_project_status` omit archived cards from lists and report an archived count. Pass `includeArchived` to list them. `search_desk` still returns archived cards and marks them. Moving a card out of done, or any edit that refreshes `updated`, brings it back. The Done in 7 days stat and the analytics tab are unchanged.

### Fixed
- Saving `cards.json` on Linux uses `rename(2)`. `FileManager.replaceItemAt` fails there even when the file exists, so a second save never landed.

## [2.0.0] - 2026-10-31

### Licence
- Relicensed from MIT to Apache License 2.0, with a NOTICE file. Earlier releases stay under MIT.

### Added
- Multi-language detector (swift, python, javascript, typescript, node, go, rust, ruby, php, java, kotlin, csharp, dotnet, cpp, docker, web, plus spm / xcode-project / xcode-workspace / swiftui from a shallow scan)
- Non-coding project kinds with optional path, including accounting and business
- Analytics tab dashboard: project health gauges, 14-day activity heat map, technology trends, collapsible status timeline, shared with the MCP tools
- Kind-aware health: non-coding projects are not penalised for missing code docs or a tech stack
- Automatic register from working directory and git remote
- Find-or-create, rename, and merge for non-coding work
- Kanban cards and default columns backlog, doing, review, done, parked
- Optional `memoryRef` on cards (opaque; DPC never calls a memory service)
- `get_desk_summary` with an 800-token cap
- Local Analytics + Kanban HTML page (`open_desk`)
- Opt-in loopback desk server for drag-and-drop (`127.0.0.1:47821`, write token mode 0600, Safari Add to Dock)
- Desk logo, favicon, and PWA manifest for a standalone Dock web app
- Kanban cards with kind, PR, and memoryRef chips, relative time, keyboard move, and optimistic drag
- `dpc` executable alias
- `DPC_KNOWLEDGE_BASE` (preferred over `CPC_KNOWLEDGE_BASE`)
- Grok Bot paste-in prompt and skill under `docs/grok-bot/`

### Changed
- Display name is Dev Project Coordinator. MCP server key stays `project-coordinator`
- Log prefix is `[DPC]`
- `add_project` no longer requires a path
- Search is `search_desk` (`search_code_patterns` remains as an alias)
- Security allowlist honours `security-config.json` and `DPC_ALLOWED_PATHS`
- `~/Desktop` is not an allowed root by default (only `~/Desktop/Development`); add it through `security-config.json` or `DPC_ALLOWED_PATHS` if you need it
- README and Quick Start rewritten for the product
- Desk server uses a fixed port and a one-time sign-in code (`?signin=`, valid once, for 10 minutes). The bookmark URL has no token. The write token is long-lived until rotation
- Desk subtitle: nothing leaves this machine

### Fixed
- `*-analytics.json` is not loaded as a project
- KnowledgeBase templates are written only when missing
- Swift-only fallback on add is gone
- Quick Start no longer shows `--port 3000`
- Desk server rejects an empty, duplicate, or oversized `Content-Length` with 400 instead of trapping
- Desk server matches the `Content-Length` header name exactly (case-insensitive)
- Desk server checks Host on every request and rejects a Host header without a port
- Desk server Host/Origin allowlist is IPv4 loopback only (`127.0.0.1` and `localhost`)
- Desk token file is created 0600; path checks resolve symlinks and drop forbidden roots
- Desk sign-in uses a single-use in-memory code. `?token=` is rejected. Calling `start_desk_server` while running mints a new code without rotating
- Desk responses send `Referrer-Policy: no-referrer`. PR chips are https-only with `rel="noopener noreferrer"` and `target="_blank"`
- Invalid `DPC_DESK_PORT` logs a warning and falls back. Invalid `deskPort` in security-config is ignored without rewriting the file

### Deprecated
- `CPC_KNOWLEDGE_BASE` and the `project-coordinator` server key. Removal in v3.0

## [1.4.2] - 2026-10-15

### Changed
- CI: workflow token limited to `contents: read` and actions pinned to commit SHAs (#13), with a test that checks both.

## [1.4.1] - 2026-10-15

### Changed
- Docs: removed internal governance references from the repository documentation (#10). No code changes.

## [1.4.0] - 2026-08-02

### Added
- Official Model Context Protocol Swift SDK (`modelcontextprotocol/swift-sdk`)
- Library + executable split for testable core (`ProjectCoordinator` + `project-coordinator`)
- `CPC_KNOWLEDGE_BASE` environment override for data location
- Real Swift Testing coverage for security, migration-once, paths, and version pin
- GitHub Actions CI (`swift build` / `swift test`)
- Repo governance files (`AGENTS.md`, `CLAUDE.md`)

### Fixed
- Path allowlist no longer accepts the home directory via reverse prefix matching
- Diagnostics no longer print to stdout (MCP stdio safe; logs go to stderr via `CPCLog`)
- Startup no longer re-migrates analytics that already exist on disk
- KnowledgeBase discovery walks upward from the executable instead of a fixed three-level climb
- Version strings aligned to **1.4.0** across binary, `mcp.json`, and docs

### Changed
- Requires Swift 6.0+
- Capabilities advertise tools only (removed unimplemented `resources` claim)
- Public analytics sample replaces personal `global-tech-stats.json`
- Removed internal release notes and ops scripts from the public tree

## [1.3.2] - 2025-07-04

### Fixed
- **CRITICAL**: Fixed analytics re-migration bug that occurred on every restart
- Projects no longer lose their creation dates when restarting Claude Desktop
- Analytics files are now properly checked on disk before migration
- Added repair script for users affected by date corruption

### Added
- `scripts/repair-analytics-dates.sh` - Repair tool for fixing corrupted project dates
- Better logging during migration to track what's happening
- File existence checks to prevent unnecessary re-migrations

### Changed
- Migration now only runs for projects without existing analytics files
- Improved startup performance by avoiding unnecessary saves

## [1.3.2] - 2025-07-02

### Fixed 🐛
- **Analytics Data Loading Issue** - Fixed critical bug where analytics data was not loading from disk
  - Analytics were being initialized but not loading existing data
  - Health scores, activity heatmaps, and tech trends showed empty results
  - Fix: Added `loadAnalytics()` call after initializing analytics in `ProjectManager.initialize()`
  - This ensures all persisted analytics data is properly loaded on startup
  - Affected all analytics features introduced in v1.3.0

### Technical Details
- Added analytics initialization sequence in `ProjectManager.initialize()`:
  1. Initialize analytics with base path
  2. Ensure all projects exist in analytics (migrate if needed)
  3. Load analytics data from disk using `loadAnalytics()`
- Without this fix, analytics data was written to disk but never read back on restart

## [1.3.1] - 2025-07-02

### Fixed 🐛
- **Analytics Migration Date Bug** - Fixed issue where existing projects showed incorrect creation dates after migration
  - Projects were showing migration timestamp instead of original creation date
  - All migrated projects appeared to be created "30-40 minutes ago"
  - Fix: Changed `init(from project: Project)` to use `project.lastModified` as `createdDate`
  - Added `scripts/fix-analytics-dates.swift` for users who already migrated
  - This bug affected all users upgrading from pre-v1.3.0 with existing projects

### Added
- **Fix Script** - `scripts/fix-analytics-dates.swift` to correct already-migrated analytics files
  - Automatically detects and fixes incorrect creation dates
  - Shows before/after dates for transparency
  - Skips already-correct projects
  - Run with: `swift scripts/fix-analytics-dates.swift` from CPC directory

## [1.3.0] - 2025-06-13

### Added 📊
- **Project Analytics Engine** - Comprehensive analytics system for tracking project metrics
- **Time Tracking** - Automatic tracking of time spent in each project status
- **Activity Heat Map** - Visual representation of project activity levels
- **Technology Trends** - Analysis of framework and technology usage across projects
- **Project Health Scoring** - Intelligent health metrics with recommendations
- **Status Timeline** - Track complete history of status changes with durations
- **Activity Logging** - Record all project interactions (status changes, notes, searches)

### New MCP Tools 🛠️
- `get_project_timeline` - View status history and time spent in each phase
- `get_activity_heatmap` - See which projects are most active (customizable time range)
- `get_technology_trends` - Analyze technology adoption and usage patterns
- `get_project_health` - Get health scores and actionable recommendations

### Technical Implementation
- New `ProjectAnalytics.swift` with comprehensive analytics models
- `ProjectWithAnalytics` struct extends original Project model
- Automatic migration of existing projects to analytics system
- Analytics data persisted in `KnowledgeBase/analytics/` directory
- Zero manual effort - all tracking happens automatically

### Analytics Features Detail

#### Time Tracking
- Tracks duration in each status (Planning, Development, Testing, etc.)
- Human-readable durations ("3 days, 14 hours")
- Complete status history with timestamps
- Total project age calculation

#### Activity Heat Map
- Visual activity indicators (💤 🔥 🔥🔥 🔥🔥🔥)
- Configurable time periods (default: 7 days)
- Daily activity breakdown
- Event type tracking (status changes, notes, tasks)

#### Technology Trends
- Framework usage percentages across projects
- Emerging technology identification
- Technology adoption timeline
- Project-to-technology mapping

#### Project Health Scoring
- Multi-factor health assessment (0-100 score)
- Factors: Activity, Staleness, Documentation, Task Completion
- Automatic categorization (Critical, Needs Attention, Healthy)
- Actionable recommendations for improvement

## [1.2.0] - 2025-06-07

### Added 🔐
- **Comprehensive Input Validation System** - New `SecurityValidator.swift` with robust security checks
- **Path Traversal Protection** - Blocks malicious paths like `../../../etc/passwd` and similar attack vectors
- **Directory Access Control** - Configurable allowed directories to restrict project locations to safe paths
- **Command Injection Prevention** - Validates search patterns to prevent injection attacks (`$(`, `eval(`, etc.)
- **Input Length Limits** - Prevents buffer overflow attacks with reasonable limits (project names: 100 chars, descriptions: 2000 chars)
- **Character Validation** - Restricts project names to safe character sets (alphanumeric, spaces, hyphens, underscores, parentheses, brackets)
- **Security Configuration System** - `security-config.json` for customizable security policies
- **Enhanced Error Messages** - Clear, helpful error messages with recovery suggestions when security validation fails

### Security Improvements 🛡️
- **Secure Method Variants** - All user-facing operations now use validated secure methods (`addProjectSecure`, `updateProjectStatusSecure`, etc.)
- **Backwards Compatibility** - Original methods preserved for internal use, security can be toggled via configuration
- **Cross-Platform Safety** - Manual control character detection for Swift version compatibility
- **XSS Prevention** - Basic script tag removal and control character filtering in text inputs

### Technical Details
- `SecurityValidator.swift`: New comprehensive validation system with configurable policies
- `ProjectManager.swift`: Added secure method variants with input validation
- `MCPServer.swift`: Updated to use secure methods for all user-facing operations
- Enhanced error handling with detailed security violation reporting
- Automatic security configuration file generation with sensible defaults

### Default Security Configuration
```json
{
  "allowedPaths": ["~/Developer", "~/GitHub", "~/Documents", "~/Projects", "~/Desktop/Development", "~/Xcode"],
  "maxProjectNameLength": 100,
  "maxDescriptionLength": 2000,
  "maxNotesLength": 10000,
  "maxSearchPatternLength": 300,
  "enableValidation": true
}
```

### Migration Notes
- **No Breaking Changes** - All existing functionality works exactly as before
- **Automatic Upgrade** - Security features activate automatically on first run
- **Configuration** - Customize allowed directories by editing `KnowledgeBase/security-config.json`
- **Disable Security** - Set `"enableValidation": false` in config if needed (not recommended)

## [1.1.0] - 2025-06-04

### Fixed
- Fixed hardcoded path issue by using relative path construction from executable location for portable installation
- Fixed JSON date decoding error when loading existing projects by adding ISO8601 date decoding strategy
- Fixed incorrect build script arguments - removed unnecessary port configuration
- Added EXAMPLE file exclusion when loading projects to prevent loading template files

### Changed
- Knowledge base path is now constructed relative to the executable location, making the tool portable across different installations
- Project loading now properly handles date formats in existing project files
- Build script now provides correct MCP configuration without port arguments

### Technical Details
- `ProjectManager.swift`: Changed from hardcoded `/Users/user/GitHub/Claude-Project-Coordinator/KnowledgeBase` to dynamic path construction using `Bundle.main.executablePath`
- `ProjectManager.swift`: Added `decoder.dateDecodingStrategy = .iso8601` in `loadProjects()` method
- `ProjectManager.swift`: Added `&& !file.contains("EXAMPLE")` filter to skip example files
- `scripts/build.sh`: Updated configuration example to use `"args": []` instead of `["--port", "3000"]`

## [1.0.0] - 2025-06-03

### Added
- Initial release of Claude Project Coordinator
- Project tracking and management functionality
- Knowledge base structure with patterns and troubleshooting guides
- Swift code patterns and Xcode tips
- Commands: list_projects, get_project_status, search_code_patterns, add_project, update_project_status
