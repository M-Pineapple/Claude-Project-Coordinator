## 🚨 Critical Update for v1.3.0+ Users

If you're experiencing incorrect project creation dates (all showing today's date), run:
```bash
./scripts/repair-analytics-dates.sh
```

This fixes a bug where analytics were re-migrated on every restart. Fixed in v1.3.2.

---

# Claude Project Coordinator

An MCP (Model Context Protocol) server for managing and coordinating multiple Xcode/Swift projects. This server provides tools for tracking project status, searching code patterns, and maintaining a knowledge base of development insights.

## Features

- 🚀 **Project Management**: Track multiple Xcode projects with status, notes, and metadata
- 🔍 **Smart Search**: Search across projects and documentation for code patterns
- 📚 **Knowledge Base**: Maintain patterns, templates, and troubleshooting guides
- 🤖 **Auto-Detection**: Automatically detects SwiftUI, UIKit, SPM, and other technologies
- 💾 **Persistent Storage**: All data stored locally in structured JSON format
- 🔐 **Security First**: Comprehensive input validation and path traversal protection
- 📊 **Project Analytics**: Time tracking, activity heat maps, and health scoring (v1.3.0+)
- 📈 **Technology Trends**: Analyze framework usage and adoption patterns (v1.3.0+)

## Security Features (v1.2.0+)

- 🛡️ **Input Validation**: Comprehensive validation of all user inputs
- 🚫 **Path Traversal Protection**: Blocks malicious paths like `../../../etc/passwd`
- 📁 **Directory Access Control**: Configurable allowed directories for projects
- 🚨 **Injection Prevention**: Validates search patterns to prevent command injection
- ⚖️ **Reasonable Limits**: Input length limits to prevent buffer overflow attacks
- 📝 **Clear Error Messages**: Helpful guidance when security validation fails
- ⚙️ **Hardcoded Security**: Security policies are compiled into the binary for reliability

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

### Analytics Commands (v1.3.0+)

- **Time tracking**: "How long has Ubermania been in development?"
- **Activity heat map**: "Show me my project activity this week"
- **Technology trends**: "What technologies am I using most?"
- **Health check**: "Which projects need my attention?"

📊 **See [ANALYTICS-EXAMPLES.md](ANALYTICS-EXAMPLES.md) for detailed output examples and productive prompts!**

### Example Workflow

```
You: "Add my new SwiftUI project called FinanceTracker at ~/Developer/FinanceTracker"
Claude: "Successfully added project: FinanceTracker..."

You: "Update FinanceTracker status to 'Working on Core Data models'"
Claude: "Successfully updated FinanceTracker"

You: "Which of my projects use Core Data?"
Claude: [Shows all projects with Core Data in their tech stack or notes]
```

### Analytics Output Example

```
You: "Show my project activity this week"

Claude:
## Project Activity Heat Map (Past 7 Days)

🔥🔥🔥 **TodoApp** (15 activity points - 6 events)
🔥🔥 **WeatherStation** (8 activity points - 3 events)
🔥 **PortfolioSite** (3 activity points - 2 events)
💤 **OldBlogEngine** (0 activity points)

### Daily Activity Breakdown:
- Monday: 4 events
- Tuesday: 8 events
- Wednesday: 3 events
```

## Security Configuration

Security settings are **hardcoded in the Swift source code** for reliability and security. The default configuration includes:

### Default Security Settings

**Allowed Project Directories:**
- `~/Developer`
- `~/Documents`
- `~/GitHub` 
- `~/Projects`
- `~/Desktop/Development`
- `~/Xcode`

**Input Limits:**
- **Project names**: 100 characters maximum
- **Project paths**: 500 characters maximum
- **Descriptions**: 2,000 characters maximum
- **Notes**: 10,000 characters maximum
- **Search patterns**: 300 characters maximum

### Customizing Security Settings

To modify security settings:

1. **Edit the source code**: Open `Sources/ProjectCoordinator/SecurityValidator.swift`

2. **Modify the configuration values**:
   ```swift
   // Add/remove allowed base paths
   static let allowedBasePaths = [
       NSHomeDirectory() + "/Developer",
       NSHomeDirectory() + "/Documents", 
       NSHomeDirectory() + "/GitHub",
       NSHomeDirectory() + "/Projects",
       NSHomeDirectory() + "/Desktop/Development",
       NSHomeDirectory() + "/Xcode"
       // Add your custom paths here
   ]
   
   // Adjust length limits
   static let maxProjectNameLength = 100
   static let maxDescriptionLength = 2000
   static let maxNotesLength = 10000
   static let maxSearchPatternLength = 300
   ```

3. **Rebuild the project**:
   ```bash
   swift build -c release
   ```

4. **Restart Claude Desktop** to use the updated binary

### Why Hardcoded Configuration?

- **Security**: Configuration cannot be tampered with at runtime
- **Reliability**: No risk of configuration file corruption or manipulation
- **Simplicity**: No additional file management or parsing complexity
- **Performance**: Settings are compiled in, no runtime parsing overhead

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
│       └── SecurityValidator.swift # Input validation and security configuration
├── KnowledgeBase/
│   ├── projects/                  # Project data storage
│   ├── patterns/                  # Code patterns
│   ├── templates/                 # Project templates
│   └── tools/                     # Development tools/guides
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

## Project Analytics (v1.3.0+)

The analytics system runs automatically in the background, tracking:

### Time Tracking
- Automatically tracks time spent in each project status
- No manual timers needed - just update status normally
- View complete timeline with: `get_project_timeline`

### Activity Monitoring
- Records all interactions: status changes, notes, searches
- Generates heat maps showing project activity levels
- Identify your most and least active projects

### Technology Analysis
- Tracks framework and tool usage across all projects
- Identifies emerging technologies you're experimenting with
- Shows adoption trends over time

### Health Scoring
- Multi-factor analysis of project health (0-100 score)
- Factors: activity level, staleness, documentation, task completion
- Provides actionable recommendations for improvement

**Note**: Analytics are presented as formatted text in Claude chat, optimized for readability and quick insights. See [ANALYTICS-EXAMPLES.md](ANALYTICS-EXAMPLES.md) for real output examples.

## 💖 Support This Project

If CPC has helped streamline your development workflow or saved you time managing projects, consider supporting its development:

<a href="https://www.buymeacoffee.com/mpineapple" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>

Your support helps me:
- Maintain and improve CPC with new features
- Keep the project open-source and free for everyone
- Dedicate more time to addressing user requests and bug fixes
- Explore new tools that enhance developer productivity

Thank you for considering supporting my work! 🙏

## How It Works

The Project Coordinator:
1. Communicates with Claude Desktop using the MCP protocol over stdio
2. Validates all inputs through the comprehensive security system
3. Stores project data as JSON files in `KnowledgeBase/projects/`
4. Stores analytics data in `KnowledgeBase/analytics/`
5. Automatically detects technologies by scanning project directories
6. Maintains an index for quick searching and retrieval
7. Tracks all project interactions for analytics

## Security Considerations

**For Individual Developers:**
- Default security settings are designed for personal development workflows
- Protects against common attack vectors while maintaining usability
- Security settings can be customized by modifying source code and rebuilding

**For Organizations:**
- Organizations should evaluate their own security requirements
- Additional security measures may be needed for production environments
- Consider implementing additional authentication and audit logging for shared use
- Hardcoded configuration prevents runtime tampering

## Example Files & Documentation

- **[ANALYTICS-EXAMPLES.md](ANALYTICS-EXAMPLES.md)** - Real output examples and productive prompts
- **[CHANGELOG.md](CHANGELOG.md)** - Detailed version history
- **Security Features** - See the Security Configuration section above

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
