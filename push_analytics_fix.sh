#!/bin/bash

# Navigate to the repository
cd /Users/rogers/GitHub/Claude-Project-Coordinator

# Copy the fixed file over the original
cp Sources/ProjectCoordinator/ProjectManager_v132_fixed.swift Sources/ProjectCoordinator/ProjectManager.swift

# Stage the changes
git add Sources/ProjectCoordinator/ProjectManager.swift

# Commit with a descriptive message
git commit -m "Fix analytics data loading in v1.3.2

- Add analytics initialization in ProjectManager.initialize()
- Ensure analytics data loads from disk for existing projects
- Load analytics after migrating projects to prevent empty data"

# Push to GitHub
git push origin main

echo "✅ v1.3.2 analytics fix pushed to GitHub!"
