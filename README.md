# Claude Project Coordinator

An MCP (Model Context Protocol) server for managing and coordinating multiple Xcode/Swift projects. This server provides tools for tracking project status, searching code patterns, and maintaining a knowledge base of development insights.

## Features

- 🚀 **Project Management**: Track multiple Xcode projects with status, notes, and metadata
- 🔍 **Smart Search**: Search across projects and documentation for code patterns
- 📚 **Knowledge Base**: Maintain patterns, templates, and troubleshooting guides
- 🤖 **Auto-Detection**: Automatically detects SwiftUI, UIKit, SPM, and other technologies
- 💾 **Persistent Storage**: All data stored locally in structured JSON format
- 🔐 **Security First**: Comprehensive input validation and path traversal protection

## Security Features (v1.2.0+)

- 🛡️ **Input Validation**: Comprehensive validation of all user inputs
- 🚫 **Path Traversal Protection**: Blocks malicious paths like `../../../etc/passwd`
- 📁 **Directory Access Control**: Configurable allowed directories for projects
- 🚨 **Injection Prevention**: Validates search patterns to prevent command injection
- ⚖️ **Reasonable Limits**: Input length limits to prevent buffer overflow attacks
- 📝 **Clear Error Messages**: Helpful guidance when security validation fails
- ⚙️ **Configurable Security**: Customize security policies via `security-config.json`

## Installation

### Prerequisites
- macOS with Swift 5.9+
- Claude Desktop app

### Build from Source

1. Clone the repository:
```bash
git clone https://github.com/M-Pineapple/Claude-Project-Coordinator.git
cd Claude-Project-Coordinator
```

2. Build the project:
```bash
swift build -c release
```

3. Note the path to the built executable:
```bash
.build/release/project-coordinator
```

### Configure Claude Desktop

1. Open Claude Desktop
2. Navigate to: **Settings** → **Developer** → **Model Context Protocol**
3. Add the configuration:

```json
{
  "mcpServers": {
    "project-coordinator": {
      "command": "/path/to/Claude-Project-Coordinator/.build/release/project-coordinator",
      "args": []
    }
  }
}
```

4. Restart Claude Desktop

## Usage

Once configured, you can interact with the Project Coordinator through Claude:

### Basic Commands

- **List projects**: "Show me all my tracked projects"
- **Add project**: "Add my WeatherApp project at ~/Developer/WeatherApp"
- **Update status**: "Update WeatherApp status to 'Implementing API integration'"
- **Search patterns**: "Find all SwiftUI patterns"
- **Get project details**: "What's the status of my TodoApp?"

### Example Workflow

```
You: "Add my new SwiftUI project called FinanceTracker at ~/Developer/FinanceTracker"
Claude: "Successfully added project: FinanceTracker..."

You: "Update FinanceTracker status to 'Working on Core Data models'"
Claude: "Successfully updated FinanceTracker"

You: "Which of my projects use Core Data?"
Claude: [Shows all projects with Core Data in their tech stack or notes]
```

## Security Configuration

The tool automatically creates a `KnowledgeBase/security-config.json` file with sensible defaults:

```json
{
  "allowedPaths": [
    "~/Developer",
    "~/GitHub", 
    "~/Documents",
    "~/Projects",
    "~/Desktop/Development",
    "~/Xcode"
  ],
  "maxProjectNameLength": 100,
  "maxDescriptionLength": 2000,
  "maxNotesLength": 10000,
  "maxSearchPatternLength": 300,
  "enableValidation": true
}
```

### Customizing Security

- **Add allowed directories**: Edit the `allowedPaths` array to include your project locations
- **Adjust limits**: Modify maximum lengths as needed for your workflow
- **Disable validation**: Set `enableValidation` to `false` (not recommended)

## MCP Tools Available

### `list_projects`
Lists all tracked projects with their metadata

### `add_project`
Adds a new project to track
- Parameters: `name`, `path`, `description` (optional)
- **Security**: Validates project name, path, and description

### `get_project_status`
Gets detailed information about a specific project
- Parameters: `projectName`
- **Security**: Validates project name

### `update_project_status`
Updates project status and/or notes
- Parameters: `projectName`, `status` (optional), `notes` (optional)
- **Security**: Validates all text inputs

### `search_code_patterns`
Searches through projects and knowledge base
- Parameters: `pattern`
- **Security**: Validates search pattern for injection attempts

## Project Structure

```
Claude-Project-Coordinator/
├── Sources/
│   └── ProjectCoordinator/
│       ├── main.swift              # Entry point
│       ├── MCPServer.swift         # MCP protocol implementation
│       ├── ProjectManager.swift    # Project management logic
│       └── SecurityValidator.swift # Input validation and security
├── KnowledgeBase/
│   ├── projects/                  # Project data storage
│   ├── patterns/                  # Code patterns
│   ├── templates/                 # Project templates
│   ├── tools/                     # Development tools/guides
│   └── security-config.json       # Security configuration
├── scripts/
│   └── build.sh                   # Build script
├── Package.swift                  # Swift package manifest
├── CHANGELOG.md                   # Version history
└── README.md                      # This file
```

## Knowledge Base

The Knowledge Base comes pre-populated with:
- SwiftUI patterns and best practices
- Xcode keyboard shortcuts
- Troubleshooting guides
- Project templates

You can add your own content by creating markdown files in the appropriate directories.

## How It Works

The Project Coordinator:
1. Communicates with Claude Desktop using the MCP protocol over stdio
2. Validates all inputs through the comprehensive security system
3. Stores project data as JSON files in `KnowledgeBase/projects/`
4. Automatically detects technologies by scanning project directories
5. Maintains an index for quick searching and retrieval

## Security Considerations

**For Individual Developers:**
- Default security settings are designed for personal development workflows
- Protects against common attack vectors while maintaining usability
- All validation can be customized or disabled if needed

**For Organizations:**
- This tool provides a solid foundation for enterprise deployment
- Additional security measures may be needed for production environments
- Consider implementing additional authentication and audit logging for shared use

## Contributing

Contributions are welcome! Please feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation
- Share your patterns and templates

## Technical Details

- Built with Swift using no external dependencies
- Uses JSON-RPC for MCP communication
- Async/await for modern Swift concurrency
- Actor-based architecture for thread safety
- Comprehensive input validation and security hardening

## License

MIT License - feel free to use this in your own projects!

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history and security improvements.

## Acknowledgments

Built as part of exploring the Model Context Protocol (MCP) ecosystem for enhancing AI-assisted development workflows.

---

Made with ❤️ from 🍍 Pineapple
