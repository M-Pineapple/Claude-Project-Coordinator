<div align="center">

<img src="assets/logo.svg" alt="Claude Project Coordinator logo" width="240"/>

# Claude Project Coordinator

</div>

An MCP (Model Context Protocol) server for managing and coordinating multiple Xcode/Swift projects. Track project status, search code patterns, and keep a local knowledge base of development insights — with Claude Desktop, Cursor, or Claude Code as the assistant.

**v1.4.0** uses the [official Swift MCP SDK](https://github.com/modelcontextprotocol/swift-sdk). CPC tracks *project artefacts and status*. Pair it with a memory MCP for *decisions and conversation context* — they complement each other.

## Features

- **Project Management**: Track multiple Xcode projects with status, notes, and metadata
- **Smart Search**: Search across projects and documentation for code patterns
- **Knowledge Base**: Maintain patterns, templates, and troubleshooting guides
- **Auto-Detection**: Automatically detects SwiftUI, UIKit, SPM, and other technologies
- **Persistent Storage**: All data stored locally in structured JSON format
- **Security First**: Input validation and path allowlisting (compiled into the binary)
- **Project Analytics**: Time tracking, activity heat maps, and health scoring
- **Technology Trends**: Analyse framework usage across projects

## Prerequisites

- macOS 13+
- Swift 6.0+ (Xcode 16+)
- An MCP host: Claude Desktop, Cursor, or Claude Code

## Installation

### Build from source

```bash
git clone https://github.com/M-Pineapple/Claude-Project-Coordinator.git
cd Claude-Project-Coordinator
swift build -c release
```

Executable path:

```text
.build/release/project-coordinator
```

### Claude Desktop

Settings → Developer → Model Context Protocol:

```json
{
  "mcpServers": {
    "project-coordinator": {
      "command": "/absolute/path/to/Claude-Project-Coordinator/.build/release/project-coordinator",
      "args": []
    }
  }
}
```

### Cursor

Add the same server entry to your Cursor MCP settings (MCP servers JSON), using the absolute path to `.build/release/project-coordinator`.

### Claude Code

Register the server in your Claude Code MCP config with the same `command` path.

Optional: set `CPC_KNOWLEDGE_BASE` to point at a custom KnowledgeBase directory.

## Usage

### Basic prompts

- List projects: "Show me all my tracked projects"
- Add project: "Add my WeatherApp project at ~/Developer/WeatherApp"
- Update status: "Update WeatherApp status to 'Implementing API integration'"
- Search patterns: "Find all SwiftUI patterns"
- Get details: "What's the status of my TodoApp?"

### Analytics prompts

- Timeline: "How long has WeatherApp been in development?"
- Heat map: "Show me my project activity this week"
- Trends: "What technologies am I using most?"
- Health: "Which projects need my attention?"

See [ANALYTICS-EXAMPLES.md](ANALYTICS-EXAMPLES.md) for sample output.

## MCP tools

| Tool | Purpose |
|---|---|
| `list_projects` | List tracked projects |
| `add_project` | Add a project (`name`, `path`, optional `description`) |
| `get_project_status` | Details for one project |
| `update_project_status` | Update status and/or notes |
| `search_code_patterns` | Search projects and knowledge base |
| `get_project_timeline` | Status history and durations |
| `get_activity_heatmap` | Recent activity heat map (`days` optional) |
| `get_technology_trends` | Framework usage across projects |
| `get_project_health` | Health scores and recommendations |

## Security

Security settings are compiled into `Sources/ProjectCoordinator/SecurityValidator.swift`.

**Default allowed roots:** `~/Developer`, `~/Documents`, `~/GitHub`, `~/Projects`, `~/Desktop/Development`, `~/Xcode`

**Limits:** project name 100, path 500, description 2,000, notes 10,000, search pattern 300 characters.

To change allowlists or limits, edit the source and rebuild:

```bash
swift build -c release
```

Then restart your MCP host.

## Project structure

```text
Claude-Project-Coordinator/
├── Sources/
│   ├── ProjectCoordinator/     # Library (MCP bootstrap, manager, analytics, security)
│   └── project-coordinator/    # Executable entry point
├── Tests/ProjectCoordinatorTests/
├── KnowledgeBase/              # Patterns, templates, local project/analytics data
├── scripts/                    # Build and repair helpers
├── Package.swift
├── AGENTS.md
└── README.md
```

## Upgrading from v1.3.x

1. Pull latest and rebuild with Swift 6: `swift build -c release`
2. Point your MCP host at the new binary path
3. If creation dates were corrupted by the old re-migration bug, run:

```bash
./scripts/repair-analytics-dates.sh
```

## 💖 Support This Project

If CPC has helped streamline your development workflow or saved you time managing projects, consider supporting its development:

<a href="https://www.buymeacoffee.com/mpineapple" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>

Your support helps me:
- Maintain and improve CPC with new features
- Keep the project open-source and free for everyone
- Dedicate more time to addressing user requests and bug fixes
- Explore new tools that enhance developer productivity

Thank you for considering supporting my work! 🙏

## Contributing

Contributions are welcome. Please report bugs, suggest features, open pull requests, or share patterns and templates.

## License

MIT License.

## Acknowledgments

Built for the MCP ecosystem. Protocol stack: [modelcontextprotocol/swift-sdk](https://github.com/modelcontextprotocol/swift-sdk).

---

Made with ❤️ from 🍍 Pineapple
