# Quick Start Guide

## Setting Up the Project Coordinator

### 1. Build the Project

Open Terminal and navigate to the project directory:
```bash
cd /Users/yourusername/GitHub/Claude-Project-Coordinator
chmod +x build.sh
./build.sh
```

### 2. Configure Claude Desktop

1. Open Claude Desktop
2. Go to **Preferences** → **Developer** → **Model Context Protocol**
3. Click **Add Server**
4. Add this configuration:

```json
{
  "project-coordinator": {
    "command": "/Users/yourusername/GitHub/Claude-Project-Coordinator/.build/release/project-coordinator",
    "args": ["--port", "3000"]
  }
}
```

5. Restart Claude Desktop

### 3. Test the Connection

In a new Claude chat, type:
```
Can you list my tracked projects?
```

You should see a response indicating no projects are tracked yet.

## Using the Coordinator

### Adding Your First Project

```
Add my WeatherApp project at ~/Developer/WeatherApp
```

The coordinator will:
- Detect if it's using SwiftUI or UIKit
- Check for Xcode project/workspace files
- Create a project summary
- Update the knowledge base index

### Common Commands

1. **List all projects**
   ```
   Show me all my projects
   ```

2. **Get project details**
   ```
   What's the status of WeatherApp?
   ```

3. **Update project status**
   ```
   Update WeatherApp status to "Working on API integration"
   ```

4. **Search across projects**
   ```
   Which projects use Combine?
   Find all async/await patterns
   ```

5. **Add notes to a project**
   ```
   Add note to WeatherApp: "Need to implement caching"
   ```

## Customizing Your Knowledge Base

### Adding Code Patterns

1. Navigate to `/KnowledgeBase/patterns/`
2. Create a new `.md` file (e.g., `networking-patterns.md`)
3. Add your patterns using markdown code blocks

### Adding Troubleshooting Guides

1. Navigate to `/KnowledgeBase/tools/`
2. Add guides for common issues you encounter

### Project Templates

1. Navigate to `/KnowledgeBase/templates/`
2. Add starter templates for different project types

## Tips for Effective Use

### 1. Keep Project Status Updated
Update your project status regularly so Claude has current context:
```
Update MyApp status to "Refactoring view models"
```

### 2. Use Descriptive Project Names
When adding projects, use clear names:
```
Add project name:"WeatherApp-iOS" path:"~/Developer/WeatherApp"
Add project name:"WeatherApp-Widget" path:"~/Developer/WeatherAppWidget"
```

### 3. Document Patterns as You Learn
When you solve a tricky problem, add it to the patterns:
1. Create a file in `/KnowledgeBase/patterns/`
2. Document the problem and solution
3. Claude will be able to reference it later

### 4. Track Learning Progress
Use project notes to track what you're learning:
```
Update LearningSwiftUI notes to "Completed navigation chapter, working on data flow"
```

## Workflow Examples

### Starting a New Project
1. Create the Xcode project
2. Add it to the coordinator:
   ```
   Add project TodoApp at ~/Developer/TodoApp description:"Learning Core Data"
   ```
3. Ask Claude for help:
   ```
   I'm starting TodoApp - can you show me a Core Data setup pattern?
   ```

### Cross-Project Code Reuse
```
I need the networking service pattern I used in WeatherApp for my new project
```

Claude will search your projects and patterns to find relevant code.

### Learning from Past Solutions
```
How did I handle authentication in my previous projects?
```

The coordinator will search across all your projects for authentication implementations.

## Troubleshooting

### MCP Server Not Connecting
1. Check if the build was successful:
   ```bash
   ls -la /Users/rogers/GitHub/Claude-Project-Coordinator/.build/release/
   ```
2. Verify the path in Claude Desktop settings matches exactly
3. Check Console.app for error messages
4. Try rebuilding with `swift build -c release`

### Projects Not Saving
1. Check permissions on the KnowledgeBase directory
2. Ensure the path doesn't contain special characters
3. Try with absolute paths instead of `~`

### Search Not Finding Results
1. Patterns are case-insensitive but must be substrings
2. Check that files are saved as `.md` in the correct directories
3. Rebuild the project index by updating any project

## Advanced Features

### Batch Updates
You can update multiple aspects at once:
```
Update WeatherApp status:"Implementing widgets" notes:"Using WidgetKit, need to share data"
```

### Project Archiving
When a project is complete, update its status:
```
Update WeatherApp status:"Completed - Archived"
```

### Pattern Categories
Organize patterns by creating subdirectories:
```
/KnowledgeBase/patterns/
  networking/
  ui-patterns/
  data-persistence/
  testing/
```

## Best Practices

1. **Regular Updates**: Update project status at least weekly
2. **Descriptive Names**: Use clear, searchable project names
3. **Document Decisions**: Add notes about why you chose certain approaches
4. **Pattern Evolution**: Update patterns as you learn better ways
5. **Error Documentation**: Document errors and their solutions in troubleshooting guides

## Integration with Development Workflow

### Pre-commit Hook
Add a reminder to update project status:
```bash
#!/bin/bash
echo "Remember to update project status in Claude Coordinator!"
```

### Weekly Review
Every week, ask Claude:
```
Show me all my projects and their current status
```

Then update any outdated information.

### Code Review Companion
When reviewing your code:
```
I'm reviewing my networking code in WeatherApp - any patterns I should consider?
```

## Next Steps

1. **Add Your First Project**: Start with your current active project
2. **Explore Templates**: Check out the SwiftUI app template
3. **Read Patterns**: Browse the included Swift patterns
4. **Customize**: Add your own patterns and guides
5. **Iterate**: The coordinator becomes more valuable as you add more content

Remember: The coordinator is like having a personalized development notebook that Claude can search and reference. The more you put into it, the more helpful it becomes!
