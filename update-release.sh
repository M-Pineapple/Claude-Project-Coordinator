#!/bin/bash

echo "🏷️ Updating GitHub release..."

# Delete the old tag locally and remotely
echo "Removing old alpha tag..."
git tag -d v0.1.0-alpha
git push origin --delete v0.1.0-alpha

# Create a new tag at the current clean commit
echo "Creating new clean alpha tag..."
git tag -a v0.1.0-alpha -m "Initial Alpha Release - MCP for Xcode/Swift project coordination"
git push origin v0.1.0-alpha

echo ""
echo "✅ Tag updated! Now you need to:"
echo "1. Go to https://github.com/M-Pineapple/Claude-Project-Coordinator/releases"
echo "2. Click on the v0.1.0-alpha release"
echo "3. Click 'Edit release'"
echo "4. Make sure it's pointing to the new tag"
echo "5. Save the release"
echo ""
echo "The source code download will now have the clean version!"
