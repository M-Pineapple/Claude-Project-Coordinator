#!/bin/bash

# Phase 1 Security Test Script for Claude Project Coordinator

echo "🔐 Testing Phase 1 Security Implementation"
echo "=========================================="

# Navigate to project directory
cd "/Users/rogers/GitHub/MCP Directory/Claude-Project-Coordinator"

echo "📦 Building project..."
swift build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "🧪 Phase 1 Security Features Implemented:"
    echo "  • Input validation for project names"
    echo "  • Path traversal protection"
    echo "  • Text sanitization for descriptions and notes"
    echo "  • Search pattern validation"
    echo "  • Configurable allowed directories"
    echo "  • Security configuration management"
    echo ""
    echo "🎯 Next Steps:"
    echo "  1. Test the MCP server with Claude Desktop"
    echo "  2. Try adding projects with various inputs to test validation"
    echo "  3. Attempt edge cases like path traversal attacks"
    echo "  4. Monitor the security-config.json file creation"
    echo ""
    echo "📝 To test security features:"
    echo "  • Try adding a project with '../..' in the path"
    echo "  • Use very long project names (>100 chars)"
    echo "  • Include special characters in project names"
    echo "  • Search for patterns with command injection attempts"
    echo ""
    echo "🗂️  Security config will be created at:"
    echo "    KnowledgeBase/security-config.json"
else
    echo "❌ Build failed!"
    echo "Please check the error messages above."
fi
