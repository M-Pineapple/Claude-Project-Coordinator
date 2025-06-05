# Changelog

All notable changes to Claude Project Coordinator will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
