# Changelog

All notable changes to Claude Project Coordinator will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
