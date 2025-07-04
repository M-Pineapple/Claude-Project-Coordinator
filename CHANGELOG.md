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

# Changelog

All notable changes to Claude Project Coordinator will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
