# Claude Project Coordinator

An MCP (Model Context Protocol) server for managing and coordinating multiple Xcode/Swift projects. This server provides tools for tracking project status, searching code patterns, and maintaining a knowledge base of development insights.

## Features

- 🚀 **Project Management**: Track multiple Xcode projects with status, notes, and metadata
- 🔍 **Smart Search**: Search across projects and documentation for code patterns
- 📚 **Knowledge Base**: Maintain patterns, templates, and troubleshooting guides
- 🤖 **Auto-Detection**: Automatically detects SwiftUI, UIKit, SPM, and other technologies
- 💾 **Persistent Storage**: All data stored locally in structured JSON format

## Installation

### Prerequisites
- macOS with Swift 5.9+
- Claude Desktop app

### Build from Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/Claude-Project-Coordinator.git
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

## MCP Tools Available

### `list_projects`
Lists all tracked projects with their metadata

### `add_project`
Adds a new project to track
- Parameters: `name`, `path`, `description` (optional)

### `get_project_status`
Gets detailed information about a specific project
- Parameters: `projectName`

### `update_project_status`
Updates project status and/or notes
- Parameters: `projectName`, `status` (optional), `notes` (optional)

### `search_code_patterns`
Searches through projects and knowledge base
- Parameters: `pattern`

## Project Structure

```
Claude-Project-Coordinator/
├── Sources/
│   └── ProjectCoordinator/
│       ├── main.swift           # Entry point
│       ├── MCPServer.swift      # MCP protocol implementation
│       └── ProjectManager.swift # Project management logic
├── KnowledgeBase/
│   ├── projects/               # Project data storage
│   ├── patterns/               # Code patterns
│   ├── templates/              # Project templates
│   └── tools/                  # Development tools/guides
├── scripts/
│   └── build.sh               # Build script
├── Package.swift              # Swift package manifest
└── README.md                  # This file
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
2. Stores project data as JSON files in `KnowledgeBase/projects/`
3. Automatically detects technologies by scanning project directories
4. Maintains an index for quick searching and retrieval

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

## License

MIT License - feel free to use this in your own projects!

## Acknowledgments

Built as part of exploring the Model Context Protocol (MCP) ecosystem for enhancing AI-assisted development workflows.

---

Made with ❤️ from 🍍 Pineapple 

