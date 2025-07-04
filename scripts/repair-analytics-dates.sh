#!/bin/bash
# CPC Analytics Date Repair Tool
# Fixes incorrect creation dates while preserving all historical data

echo "🔧 CPC Analytics Date Repair Tool"
echo "================================="
echo ""

# Determine KnowledgeBase path relative to script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
KB_PATH="$(dirname "$SCRIPT_DIR")/KnowledgeBase"

if [ ! -d "$KB_PATH" ]; then
    echo "❌ KnowledgeBase not found at: $KB_PATH"
    echo ""
    echo "Please run this script from your CPC installation directory."
    exit 1
fi

PROJECTS_DIR="$KB_PATH/projects"

echo "📂 Working directory: $PROJECTS_DIR"
echo ""

# First, let's check the current state
echo "📊 Current Analytics Status:"
echo "----------------------------"

# Count files
PROJ_COUNT=$(ls -1 "$PROJECTS_DIR"/*.json 2>/dev/null | grep -v analytics | grep -v EXAMPLE | wc -l)
ANALYTICS_COUNT=$(ls -1 "$PROJECTS_DIR"/*-analytics.json 2>/dev/null | wc -l)

echo "Project files: $PROJ_COUNT"
echo "Analytics files: $ANALYTICS_COUNT"
echo ""

# Show date discrepancies
echo "📅 Date Analysis:"
echo "-----------------"

for proj_file in "$PROJECTS_DIR"/*.json; do
    # Skip analytics files and examples
    if [[ "$proj_file" == *"-analytics.json" ]] || [[ "$proj_file" == *"EXAMPLE"* ]]; then
        continue
    fi
    
    # Get project name
    basename=$(basename "$proj_file" .json)
    analytics_file="$PROJECTS_DIR/${basename}-analytics.json"
    
    if [ -f "$analytics_file" ]; then
        # Extract dates using grep and sed
        proj_date=$(grep -o '"lastModified"[[:space:]]*:[[:space:]]*"[^"]*"' "$proj_file" | sed 's/.*"\([^"]*\)"$/\1/')
        analytics_date=$(grep -o '"createdDate"[[:space:]]*:[[:space:]]*"[^"]*"' "$analytics_file" | sed 's/.*"\([^"]*\)"$/\1/')
        
        if [ "$proj_date" != "$analytics_date" ]; then
            echo "❌ $basename:"
            echo "   Project lastModified: $proj_date"
            echo "   Analytics createdDate: $analytics_date"
        else
            echo "✅ $basename: Dates match"
        fi
    else
        echo "⚠️  $basename: No analytics file"
    fi
done

echo ""
echo "🔄 Do you want to repair the dates? (y/n)"
read -r response

if [[ "$response" != "y" ]]; then
    echo "Repair cancelled."
    exit 0
fi

# Create backup
echo ""
echo "📦 Creating backup..."
BACKUP_DIR="$KB_PATH/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$PROJECTS_DIR" "$BACKUP_DIR/"
echo "✅ Backup created at: $BACKUP_DIR"

# Perform the repair
echo ""
echo "🔧 Repairing analytics dates..."

# Create a Python script for JSON manipulation
cat > /tmp/repair_cpc_dates.py << 'EOF'
#!/usr/bin/env python3
import json
import sys
import os
from datetime import datetime

def repair_analytics_file(proj_file, analytics_file):
    try:
        # Read project file
        with open(proj_file, 'r') as f:
            project = json.load(f)
        
        # Read analytics file
        with open(analytics_file, 'r') as f:
            analytics = json.load(f)
        
        # Get the project path for file system date lookup
        project_path = project.get('path', '').replace('~', os.path.expanduser('~'))
        
        # Try to get creation date from file system
        correct_date = None
        if os.path.exists(project_path):
            try:
                # Get file creation time (birth time on macOS)
                stat_info = os.stat(project_path)
                if hasattr(stat_info, 'st_birthtime'):
                    # Convert to ISO format
                    creation_time = datetime.fromtimestamp(stat_info.st_birthtime)
                    correct_date = creation_time.isoformat() + 'Z'
                    print(f"     Found filesystem creation date: {correct_date}")
            except:
                pass
        
        # Fallback to lastModified if we couldn't get filesystem date
        if not correct_date:
            correct_date = project.get('lastModified')
            print(f"     Using lastModified as fallback")
        
        if not correct_date:
            print(f"  ⚠️  No date found for {proj_file}")
            return False
        
        # Update createdDate
        old_date = analytics.get('createdDate')
        analytics['createdDate'] = correct_date
        
        # Also fix the first status history entry if it exists
        if 'statusHistory' in analytics and len(analytics['statusHistory']) > 0:
            # Only update if it matches the old created date
            if analytics['statusHistory'][0]['startDate'] == old_date:
                analytics['statusHistory'][0]['startDate'] = correct_date
        
        # Write back with proper formatting
        with open(analytics_file, 'w') as f:
            json.dump(analytics, f, indent=2, sort_keys=True)
        
        print(f"  ✅ Fixed {os.path.basename(analytics_file)}")
        print(f"     Changed {old_date} → {correct_date}")
        return True
    except Exception as e:
        print(f"  ❌ Error processing {analytics_file}: {str(e)}")
        return False

if __name__ == "__main__":
    repair_analytics_file(sys.argv[1], sys.argv[2])
EOF

chmod +x /tmp/repair_cpc_dates.py

# Process each project
for proj_file in "$PROJECTS_DIR"/*.json; do
    # Skip analytics files and examples
    if [[ "$proj_file" == *"-analytics.json" ]] || [[ "$proj_file" == *"EXAMPLE"* ]]; then
        continue
    fi
    
    basename=$(basename "$proj_file" .json)
    analytics_file="$PROJECTS_DIR/${basename}-analytics.json"
    
    if [ -f "$analytics_file" ]; then
        echo ""
        echo "Processing $basename..."
        python3 /tmp/repair_cpc_dates.py "$proj_file" "$analytics_file"
    fi
done

# Clean up
rm -f /tmp/repair_cpc_dates.py

echo ""
echo "✅ Repair complete!"
echo ""
echo "📝 Next steps:"
echo "1. Restart Claude Desktop to load the repaired data"
echo "2. Check the project timelines - they should show correct dates"
echo "3. If something went wrong, restore from: $BACKUP_DIR"
echo ""
echo "🎉 Done!"
