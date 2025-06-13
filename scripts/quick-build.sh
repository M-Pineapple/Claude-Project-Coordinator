#!/bin/bash

# Quick build script for Claude Project Coordinator

# Build the project
swift build -c release

# Show the result
if [ -f ".build/release/project-coordinator" ]; then
    echo "✅ Build complete!"
    echo ""
    echo "Executable location: .build/release/project-coordinator"
    echo ""
    echo "Add this path to your Claude Desktop MCP configuration."
else
    echo "❌ Build failed. Please check for errors above."
fi
