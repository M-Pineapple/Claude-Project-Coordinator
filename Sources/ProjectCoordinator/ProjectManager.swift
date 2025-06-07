import Foundation

// MARK: - Project Model

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

// MARK: - Project Manager

actor ProjectManager {
    private var projects: [String: Project] = [:]
    private let knowledgeBasePath: String
    private let fileManager = FileManager.default
    private var securityConfig: SecurityConfig
    
    init() {
        // Get the executable's directory and construct KnowledgeBase path relative to it
        let executablePath = Bundle.main.executablePath ?? ""
        let executableDir = URL(fileURLWithPath: executablePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path
        self.knowledgeBasePath = "\(executableDir)/KnowledgeBase"
        
        // Load security configuration
        let configPath = "\(executableDir)/KnowledgeBase/security-config.json"
        self.securityConfig = SecurityConfig.load(from: configPath)
    }
    
    func initialize() async {
        // Create knowledge base structure
        createKnowledgeBaseStructure()
        
        // Load existing projects
        await loadProjects()
    }
    
    private func createKnowledgeBaseStructure() {
        let directories = [
            knowledgeBasePath,
            "\(knowledgeBasePath)/projects",
            "\(knowledgeBasePath)/templates",
            "\(knowledgeBasePath)/tools",
            "\(knowledgeBasePath)/patterns"
        ]
        
        for directory in directories {
            try? fileManager.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // Create default templates
        createDefaultTemplates()
    }
    
    private func createDefaultTemplates() {
        // Project index template
        let indexContent = """
        # Project Coordinator Index
        
        ## Active Projects
        
        <!-- Projects will be automatically updated here -->
        
        ## Common Patterns & Solutions
        
        ### Swift Patterns
        - Async/Await: See patterns/async-patterns.md
        - Error Handling: See patterns/error-handling.md
        - SwiftUI Best Practices: See patterns/swiftui-practices.md
        
        ### Xcode Tips
        - Debugging: See tools/debugging-guide.md
        - Performance: See tools/performance-optimization.md
        - Build Issues: See tools/troubleshooting.md
        
        ## Quick Commands
        - List all projects: `list_projects`
        - Search patterns: `search_code_patterns [pattern]`
        - Update status: `update_project_status [project] [status]`
        """
        
        try? indexContent.write(
            toFile: "\(knowledgeBasePath)/project-index.md",
            atomically: true,
            encoding: .utf8
        )
        
        // Swift patterns template
        let patternsContent = """
        # Swift Code Patterns
        
        ## Async/Await Patterns
        
        ### Basic Async Function
        ```swift
        func fetchData() async throws -> [DataModel] {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode([DataModel].self, from: data)
        }
        ```
        
        ### Task Groups
        ```swift
        await withTaskGroup(of: Result<Data, Error>.self) { group in
            for url in urls {
                group.addTask {
                    await self.fetchItem(from: url)
                }
            }
        }
        ```
        
        ## Error Handling
        
        ### Custom Error Types
        ```swift
        enum AppError: LocalizedError {
            case networkError(String)
            case decodingError
            case unauthorized
            
            var errorDescription: String? {
                switch self {
                case .networkError(let message):
                    return "Network error: \\(message)"
                case .decodingError:
                    return "Failed to decode response"
                case .unauthorized:
                    return "Unauthorized access"
                }
            }
        }
        ```
        """
        
        try? patternsContent.write(
            toFile: "\(knowledgeBasePath)/patterns/swift-patterns.md",
            atomically: true,
            encoding: .utf8
        )
        
        // Xcode troubleshooting template
        let troubleshootingContent = """
        # Xcode Troubleshooting Guide
        
        ## Common Build Errors
        
        ### "No such module" Error
        1. Clean build folder (Shift+Cmd+K)
        2. Delete derived data
        3. Close Xcode
        4. Run: `rm -rf ~/Library/Developer/Xcode/DerivedData`
        5. Reopen project
        
        ### Code Signing Issues
        1. Check Signing & Capabilities tab
        2. Ensure correct team selected
        3. Automatic signing recommended for development
        
        ### Simulator Issues
        - Reset simulator: Device > Erase All Content and Settings
        - Clean build after reset
        
        ## Performance Issues
        
        ### Slow Builds
        - Enable build timing: Product > Perform Action > Build With Timing Summary
        - Check for expensive type inference
        - Consider modularizing large projects
        
        ### Memory Issues
        - Use Instruments for memory profiling
        - Check for retain cycles in closures
        - Use weak/unowned appropriately
        """
        
        try? troubleshootingContent.write(
            toFile: "\(knowledgeBasePath)/tools/troubleshooting.md",
            atomically: true,
            encoding: .utf8
        )
    }
    
    private func loadProjects() async {
        let projectsPath = "\(knowledgeBasePath)/projects"
        guard let files = try? fileManager.contentsOfDirectory(atPath: projectsPath) else { return }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for file in files where file.hasSuffix(".json") && !file.contains("EXAMPLE") {
            let filePath = "\(projectsPath)/\(file)"
            if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
               let project = try? decoder.decode(Project.self, from: data) {
                projects[project.name] = project
            }
        }
    }
    
    func listProjects() async throws -> String {
        guard !projects.isEmpty else {
            return """
            No projects currently tracked.
            
            To add a project, use: add_project
            Example: add_project name:"WeatherApp" path:"~/Developer/WeatherApp" description:"iOS weather application"
            """
        }
        
        var result = "# Tracked Projects\n\n"
        
        for (_, project) in projects.sorted(by: { $0.key < $1.key }) {
            result += "## \(project.name)\n"
            result += "- **Path**: \(project.path)\n"
            if let description = project.description {
                result += "- **Description**: \(description)\n"
            }
            if let status = project.status {
                result += "- **Status**: \(status)\n"
            }
            result += "- **Tech Stack**: \(project.techStack.joined(separator: ", "))\n"
            result += "- **Last Modified**: \(formatDate(project.lastModified))\n"
            if !project.currentTasks.isEmpty {
                result += "- **Current Tasks**:\n"
                for task in project.currentTasks {
                    result += "  - \(task)\n"
                }
            }
            result += "\n"
        }
        
        return result
    }
    
    func getProjectStatus(projectName: String) async throws -> String {
        guard let project = projects[projectName] else {
            throw CoordinatorError.projectNotFound
        }
        
        var result = "# \(project.name) Status\n\n"
        result += "**Path**: \(project.path)\n\n"
        
        if let description = project.description {
            result += "## Description\n\(description)\n\n"
        }
        
        if let status = project.status {
            result += "## Current Status\n\(status)\n\n"
        }
        
        result += "## Tech Stack\n"
        for tech in project.techStack {
            result += "- \(tech)\n"
        }
        result += "\n"
        
        if !project.currentTasks.isEmpty {
            result += "## Current Tasks\n"
            for task in project.currentTasks {
                result += "- [ ] \(task)\n"
            }
            result += "\n"
        }
        
        if let notes = project.notes {
            result += "## Notes\n\(notes)\n\n"
        }
        
        result += "**Last Updated**: \(formatDate(project.lastModified))"
        
        return result
    }
    
    func searchCodePatterns(pattern: String) async throws -> String {
        var results: [String] = []
        
        // Search in patterns directory
        let patternsPath = "\(knowledgeBasePath)/patterns"
        if let files = try? fileManager.contentsOfDirectory(atPath: patternsPath) {
            for file in files where file.hasSuffix(".md") {
                let filePath = "\(patternsPath)/\(file)"
                if let content = try? String(contentsOfFile: filePath, encoding: .utf8),
                   content.lowercased().contains(pattern.lowercased()) {
                    results.append("Found in patterns/\(file)")
                }
            }
        }
        
        // Search in project summaries
        for (projectName, project) in projects {
            if let notes = project.notes,
               notes.lowercased().contains(pattern.lowercased()) {
                results.append("Found in project \(projectName) notes")
            }
            
            for tech in project.techStack {
                if tech.lowercased().contains(pattern.lowercased()) {
                    results.append("\(projectName) uses \(tech)")
                }
            }
        }
        
        if results.isEmpty {
            return "No results found for pattern: \(pattern)"
        }
        
        return "# Search Results for '\(pattern)'\n\n" + results.map { "- \($0)" }.joined(separator: "\n")
    }
    
    func addProject(name: String, path: String, description: String?) async throws -> String {
        // Detect tech stack by looking for common files
        var techStack: [String] = []
        let projectURL = URL(fileURLWithPath: path.replacingOccurrences(of: "~", with: NSHomeDirectory()))
        
        if fileManager.fileExists(atPath: projectURL.appendingPathComponent("Package.swift").path) {
            techStack.append("Swift Package Manager")
        }
        
        if let contents = try? fileManager.contentsOfDirectory(at: projectURL, includingPropertiesForKeys: nil) {
            for item in contents {
                if item.pathExtension == "xcodeproj" {
                    techStack.append("Xcode Project")
                } else if item.pathExtension == "xcworkspace" {
                    techStack.append("Xcode Workspace")
                }
            }
        }
        
        // Check for SwiftUI or UIKit
        if let swiftFiles = try? fileManager.subpathsOfDirectory(atPath: projectURL.path) {
            let hasSwiftUI = swiftFiles.contains { file in
                file.hasSuffix(".swift") && 
                (try? String(contentsOfFile: projectURL.appendingPathComponent(file).path))?.contains("import SwiftUI") ?? false
            }
            if hasSwiftUI {
                techStack.append("SwiftUI")
            }
        }
        
        let project = Project(
            name: name,
            path: path,
            description: description,
            status: "Active",
            notes: nil,
            techStack: techStack.isEmpty ? ["Swift"] : techStack,
            lastModified: Date(),
            currentTasks: []
        )
        
        projects[name] = project
        
        // Save project
        try await saveProject(project)
        
        // Update index
        await updateProjectIndex()
        
        return """
        Successfully added project: \(name)
        Path: \(path)
        Detected tech stack: \(techStack.joined(separator: ", "))
        
        You can now:
        - Update status: update_project_status projectName:"\(name)" status:"your status"
        - Add notes: update_project_status projectName:"\(name)" notes:"your notes"
        """
    }
    
    func updateProjectStatus(projectName: String, status: String?, notes: String?) async throws -> String {
        guard var project = projects[projectName] else {
            throw CoordinatorError.projectNotFound
        }
        
        if let status = status {
            project.status = status
        }
        
        if let notes = notes {
            project.notes = notes
        }
        
        project.lastModified = Date()
        projects[projectName] = project
        
        try await saveProject(project)
        await updateProjectIndex()
        
        return "Successfully updated \(projectName)"
    }
    
    private func saveProject(_ project: Project) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(project)
        let filePath = "\(knowledgeBasePath)/projects/\(project.name).json"
        
        try data.write(to: URL(fileURLWithPath: filePath))
        
        // Also create/update markdown summary
        let summaryPath = "\(knowledgeBasePath)/projects/\(project.name)-summary.md"
        let summary = generateProjectSummary(project)
        try summary.write(to: URL(fileURLWithPath: summaryPath), atomically: true, encoding: .utf8)
    }
    
    private func generateProjectSummary(_ project: Project) -> String {
        var summary = "# \(project.name)\n\n"
        
        if let description = project.description {
            summary += "\(description)\n\n"
        }
        
        summary += "## Location\n`\(project.path)`\n\n"
        
        summary += "## Tech Stack\n"
        for tech in project.techStack {
            summary += "- \(tech)\n"
        }
        summary += "\n"
        
        if let status = project.status {
            summary += "## Status\n\(status)\n\n"
        }
        
        if !project.currentTasks.isEmpty {
            summary += "## Current Tasks\n"
            for task in project.currentTasks {
                summary += "- [ ] \(task)\n"
            }
            summary += "\n"
        }
        
        if let notes = project.notes {
            summary += "## Notes\n\(notes)\n"
        }
        
        return summary
    }
    
    private func updateProjectIndex() async {
        var index = """
        # Project Coordinator Index
        
        Last Updated: \(formatDate(Date()))
        
        ## Active Projects
        
        """
        
        for (_, project) in projects.sorted(by: { $0.key < $1.key }) {
            index += "### \(project.name)\n"
            index += "- **Location**: `\(project.path)`\n"
            index += "- **Tech Stack**: \(project.techStack.joined(separator: ", "))\n"
            if let status = project.status {
                index += "- **Status**: \(status)\n"
            }
            index += "- **Last Modified**: \(formatDate(project.lastModified))\n"
            index += "\n"
        }
        
        index += """
        
        ## Common Patterns & Solutions
        
        ### Swift Patterns
        - Async/Await: See patterns/async-patterns.md
        - Error Handling: See patterns/error-handling.md
        - SwiftUI Best Practices: See patterns/swiftui-practices.md
        
        ### Xcode Tips
        - Debugging: See tools/debugging-guide.md
        - Performance: See tools/performance-optimization.md
        - Build Issues: See tools/troubleshooting.md
        
        ## Quick Commands
        - List all projects: `list_projects`
        - Search patterns: `search_code_patterns [pattern]`
        - Update status: `update_project_status [project] [status]`
        """
        
        try? index.write(
            toFile: "\(knowledgeBasePath)/project-index.md",
            atomically: true,
            encoding: .utf8
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Secure Methods (Phase 1 Security Implementation)
    
    /// Securely add a project with input validation
    func addProjectSecure(name: String, path: String, description: String?) async throws -> String {
        // Input validation if security is enabled
        if securityConfig.enableValidation {
            let validatedName = try SecurityValidator.validateProjectName(name)
            let validatedPath = try SecurityValidator.validateProjectPath(path)
            let validatedDescription = try description.map { 
                try SecurityValidator.validateText($0, maxLength: securityConfig.maxDescriptionLength, fieldName: "description")
            }
            
            // Verify the path actually exists and is accessible
            try SecurityValidator.verifyPathExists(validatedPath)
            
            // Call original method with validated inputs
            return try await addProject(name: validatedName, path: validatedPath, description: validatedDescription)
        } else {
            // Fallback to original method if validation is disabled
            return try await addProject(name: name, path: path, description: description)
        }
    }
    
    /// Securely update project status with input validation
    func updateProjectStatusSecure(projectName: String, status: String?, notes: String?) async throws -> String {
        if securityConfig.enableValidation {
            let validatedName = try SecurityValidator.validateProjectName(projectName)
            let validatedStatus = try status.map {
                try SecurityValidator.validateText($0, maxLength: 500, fieldName: "status")
            }
            let validatedNotes = try notes.map {
                try SecurityValidator.validateText($0, maxLength: securityConfig.maxNotesLength, fieldName: "notes")
            }
            
            return try await updateProjectStatus(projectName: validatedName, status: validatedStatus, notes: validatedNotes)
        } else {
            return try await updateProjectStatus(projectName: projectName, status: status, notes: notes)
        }
    }
    
    /// Securely search code patterns with input validation
    func searchCodePatternsSecure(pattern: String) async throws -> String {
        if securityConfig.enableValidation {
            let validatedPattern = try SecurityValidator.validateSearchPattern(pattern)
            return try await searchCodePatterns(pattern: validatedPattern)
        } else {
            return try await searchCodePatterns(pattern: pattern)
        }
    }
    
    /// Securely get project status with input validation
    func getProjectStatusSecure(projectName: String) async throws -> String {
        if securityConfig.enableValidation {
            let validatedName = try SecurityValidator.validateProjectName(projectName)
            return try await getProjectStatus(projectName: validatedName)
        } else {
            return try await getProjectStatus(projectName: projectName)
        }
    }
    
    /// Get current security configuration (for debugging/monitoring)
    func getSecurityConfig() -> SecurityConfig {
        return securityConfig
    }
    
    /// Update security configuration
    func updateSecurityConfig(_ newConfig: SecurityConfig) throws {
        self.securityConfig = newConfig
        let configPath = "\(knowledgeBasePath)/security-config.json"
        try newConfig.save(to: configPath)
    }
}
