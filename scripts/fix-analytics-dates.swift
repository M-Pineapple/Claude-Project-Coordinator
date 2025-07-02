#!/usr/bin/env swift

import Foundation

// MARK: - Models (matching CPC structure)

struct Project: Codable {
    let name: String
    let path: String
    var description: String?
    var status: String?
    var notes: String?
    var techStack: [String]
    var lastModified: Date
    var currentTasks: [String]
}

struct StatusHistory: Codable {
    let status: String
    let startDate: Date
    var endDate: Date?
}

struct ActivityEvent: Codable {
    enum EventType: String, Codable {
        case statusChange = "status_change"
        case noteAdded = "note_added"
        case taskAdded = "task_added"
        case taskCompleted = "task_completed"
        case accessed = "accessed"
        case searched = "searched"
    }
    
    let timestamp: Date
    let type: EventType
    let description: String?
}

struct ProjectWithAnalytics: Codable {
    let name: String
    let path: String
    var description: String?
    var status: String?
    var notes: String?
    var techStack: [String]
    var lastModified: Date
    var currentTasks: [String]
    var statusHistory: [StatusHistory] = []
    var activityLog: [ActivityEvent] = []
    var createdDate: Date
    var completedTasks: [String] = []
}

// MARK: - Fix Script

print("🔧 Claude Project Coordinator v1.3.x Analytics Date Fix")
print("======================================================")
print("")

let knowledgeBasePath = "KnowledgeBase"
let projectsPath = "\(knowledgeBasePath)/projects"

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
encoder.dateEncodingStrategy = .iso8601

print("🔍 Scanning for analytics files to fix...")
print("")

var fixedCount = 0
var errorCount = 0
var skippedCount = 0

let formatter = DateFormatter()
formatter.dateStyle = .medium
formatter.timeStyle = .short

if let files = try? FileManager.default.contentsOfDirectory(atPath: projectsPath) {
    for file in files where file.hasSuffix("-analytics.json") {
        let analyticsPath = "\(projectsPath)/\(file)"
        let projectName = file.replacingOccurrences(of: "-analytics.json", with: "")
        let projectPath = "\(projectsPath)/\(projectName).json"
        
        print("📁 Processing: \(projectName)")
        
        // Read original project to get correct date
        do {
            let projectData = try Data(contentsOf: URL(fileURLWithPath: projectPath))
            let project = try decoder.decode(Project.self, from: projectData)
            
            let analyticsData = try Data(contentsOf: URL(fileURLWithPath: analyticsPath))
            var analytics = try decoder.decode(ProjectWithAnalytics.self, from: analyticsData)
            
            // Check if fix is needed
            let timeDiff = abs(analytics.createdDate.timeIntervalSince(project.lastModified))
            if timeDiff < 1.0 { // Already fixed if dates match
                print("  ✓ Already correct (no fix needed)")
                skippedCount += 1
                continue
            }
            
            let oldDate = analytics.createdDate
            analytics.createdDate = project.lastModified
            
            // Save fixed analytics
            let fixedData = try encoder.encode(analytics)
            try fixedData.write(to: URL(fileURLWithPath: analyticsPath))
            
            print("  ✅ Fixed creation date:")
            print("     Old: \(formatter.string(from: oldDate))")
            print("     New: \(formatter.string(from: analytics.createdDate))")
            
            fixedCount += 1
        } catch {
            print("  ❌ Error: \(error.localizedDescription)")
            errorCount += 1
        }
    }
} else {
    print("❌ Could not find projects directory at: \(projectsPath)")
    print("   Make sure you run this script from your CPC directory!")
    exit(1)
}

print("")
print("✨ Fix Complete!")
print("  Fixed: \(fixedCount) projects")
print("  Skipped: \(skippedCount) projects (already correct)")
if errorCount > 0 {
    print("  Errors: \(errorCount) projects")
}

print("")
print("⚠️  Remember to restart Claude Desktop to see the changes!")
