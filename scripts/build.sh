#!/bin/bash

# Build script for Claude Project Coordinator

echo "🔨 Building Claude Project Coordinator..."

# Clean previous build
swift package clean

# Build in release mode for better performance
swift build -c release

# Create symlink for easier access
if [ -f ".build/release/project-coordinator" ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Add this to your Claude Desktop MCP settings:"
    echo ""
    echo '{
  "project-coordinator": {
    "command": "'$(pwd)'/.build/release/project-coordinator",
    "args": ["--port", "3000"]
  }
}'
    echo ""
    echo "2. Restart Claude Desktop"
    echo "3. Start using commands like 'list my projects' or 'add a new project'"
else
    echo "❌ Build failed. Please check for errors above."
    exit 1
fi
