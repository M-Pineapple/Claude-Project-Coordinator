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
    echo "1. Add the executable path to your Claude Desktop MCP settings"
    echo "2. The executable is located at: .build/release/project-coordinator"
    echo "3. Restart Claude Desktop"
    echo "4. Start using commands like 'list my projects' or 'add a new project'"
else
    echo "❌ Build failed. Please check for errors above."
    exit 1
fi
