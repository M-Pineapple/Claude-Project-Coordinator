import Foundation

// MARK: - Analytics Models

/// Tracks status changes over time
struct StatusHistory: Codable {
    let status: String
    let startDate: Date
    var endDate: Date?
    
    /// Duration in this status (seconds)
    var duration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }
    
    /// Human-readable duration
    var formattedDuration: String {
        let days = Int(duration / 86400)
        let hours = Int((duration.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        var parts: [String] = []
        if days > 0 { parts.append("\(days) day\(days == 1 ? "" : "s")") }
        if hours > 0 { parts.append("\(hours) hour\(hours == 1 ? "" : "s")") }
        if minutes > 0 && days == 0 { parts.append("\(minutes) minute\(minutes == 1 ? "" : "s")") }
        
        return parts.isEmpty ? "Just started" : parts.joined(separator: ", ")
    }
}

/// Tracks project activity events
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

/// Project health scoring
struct ProjectHealth {
    let score: Int // 0-100
    let factors: [HealthFactor]
    let recommendations: [String]
    
    struct HealthFactor {
        enum FactorType: String {
            case activity = "Activity Level"
            case momentum = "Progress Momentum"
            case documentation = "Documentation Quality"
            case staleness = "Freshness"
            case completion = "Task Completion"
        }
        
        let type: FactorType
        let score: Int // 0-100
        let description: String
    }
}

/// Technology usage analytics
struct TechnologyStats: Codable {
    var frameworkCounts: [String: Int] = [:]
    var lastUsed: [String: Date] = [:]
    var projectsUsing: [String: [String]] = [:] // tech -> [projectNames]
    
    mutating func recordTechnology(_ tech: String, for project: String) {
        frameworkCounts[tech] = (frameworkCounts[tech] ?? 0) + 1
        lastUsed[tech] = Date()
        
        if var projects = projectsUsing[tech] {
            if !projects.contains(project) {
                projects.append(project)
                projectsUsing[tech] = projects
            }
        } else {
            projectsUsing[tech] = [project]
        }
    }
}

/// Enhanced project model with analytics
struct ProjectWithAnalytics: Codable {
    // Original project fields
    let name: String
    let path: String
    var description: String?
    var status: String?
    var notes: String?
    var techStack: [String]
    var lastModified: Date
    var currentTasks: [String]
    
    // New analytics fields
    var statusHistory: [StatusHistory] = []
    var activityLog: [ActivityEvent] = []
    var createdDate: Date = Date()
    var completedTasks: [String] = []
    
    // Convert from old Project model
    init(from project: Project) {
        self.name = project.name
        self.path = project.path
        self.description = project.description
        self.status = project.status
        self.notes = project.notes
        self.techStack = project.techStack
        self.lastModified = project.lastModified
        self.currentTasks = project.currentTasks
        
        // FIX: Use project's lastModified as createdDate for migration
        // This preserves the original project date instead of using current time
        self.createdDate = project.lastModified
        
        // Initialize status history with current status
        if let currentStatus = project.status {
            self.statusHistory = [StatusHistory(status: currentStatus, startDate: project.lastModified)]
        }
    }
    
    // Direct initializer for new projects
    init(name: String, path: String, description: String?, status: String?, notes: String?, 
         techStack: [String], lastModified: Date, currentTasks: [String]) {
        self.name = name
        self.path = path
        self.description = description
        self.status = status
        self.notes = notes
        self.techStack = techStack
        self.lastModified = lastModified
        self.currentTasks = currentTasks
        self.createdDate = Date()
        
        // Initialize status history
        if let currentStatus = status {
            self.statusHistory = [StatusHistory(status: currentStatus, startDate: Date())]
        }
    }
}

// MARK: - Analytics Engine

actor ProjectAnalytics {
    private var projects: [String: ProjectWithAnalytics] = [:]
    private var globalTechStats = TechnologyStats()
    private let knowledgeBasePath: String
    
    init(knowledgeBasePath: String) {
        self.knowledgeBasePath = knowledgeBasePath
    }
    
    // Default initializer for compatibility
    init() {
        // Get the executable's directory and construct KnowledgeBase path relative to it
        let executablePath = Bundle.main.executablePath ?? ""
        let executableDir = URL(fileURLWithPath: executablePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path
        self.knowledgeBasePath = "\(executableDir)/KnowledgeBase"
    }
    
    // MARK: - Time Tracking
    
    func getStatusDuration(for projectName: String) async -> String? {
        guard let project = projects[projectName] else { return nil }
        
        var result = "## Status Timeline for \(projectName)\n\n"
        
        if let currentStatus = project.status,
           let currentHistory = project.statusHistory.last {
            result += "**Current Status**: \(currentStatus) (for \(currentHistory.formattedDuration))\n\n"
        }
        
        if project.statusHistory.count > 1 {
            result += "### Previous Statuses:\n"
            for (index, history) in project.statusHistory.dropLast().enumerated().reversed() {
                result += "- **\(history.status)**: \(history.formattedDuration)\n"
            }
        }
        
        // Calculate total project age
        let projectAge = Date().timeIntervalSince(project.createdDate)
        let ageHistory = StatusHistory(status: "Total", startDate: project.createdDate)
        result += "\n**Total Project Age**: \(ageHistory.formattedDuration)"
        
        return result
    }
    
    // MARK: - Activity Heat Map
    
    func getActivityHeatMap(days: Int = 7) async -> String {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        var projectScores: [(name: String, score: Int, events: [String])] = []
        
        for (name, project) in projects {
            let recentEvents = project.activityLog.filter { event in
                event.timestamp > startDate
            }
            
            let score = calculateActivityScore(events: recentEvents)
            let eventDescriptions = recentEvents.map { "\($0.type.rawValue)" }
            
            projectScores.append((name: name, score: score, events: eventDescriptions))
        }
        
        // Sort by activity score
        projectScores.sort { $0.score > $1.score }
        
        var result = "## Project Activity Heat Map (Past \(days) Days)\n\n"
        
        for (project, score, events) in projectScores {
            let heat = getHeatEmoji(score: score)
            result += "\(heat) **\(project)** (\(score) activity points"
            if !events.isEmpty {
                result += " - \(events.count) events"
            }
            result += ")\n"
        }
        
        // Find most active day
        result += "\n### Daily Activity Breakdown:\n"
        var dailyActivity: [Date: Int] = [:]
        
        for project in projects.values {
            for event in project.activityLog {
                if event.timestamp > startDate {
                    let day = calendar.startOfDay(for: event.timestamp)
                    dailyActivity[day] = (dailyActivity[day] ?? 0) + 1
                }
            }
        }
        
        let sortedDays = dailyActivity.sorted { $0.key < $1.key }
        for (day, count) in sortedDays {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            result += "- \(formatter.string(from: day)): \(count) events\n"
        }
        
        return result
    }
    
    // MARK: - Technology Trends
    
    func getTechnologyTrends() async -> String {
        var result = "## Technology Analysis\n\n"
        
        // Sort technologies by usage
        let sortedTech = globalTechStats.frameworkCounts.sorted { $0.value > $1.value }
        
        if !sortedTech.isEmpty {
            result += "### Framework Usage:\n"
            let total = projects.count
            
            for (tech, count) in sortedTech {
                let percentage = total > 0 ? (count * 100) / total : 0
                let projectList = globalTechStats.projectsUsing[tech] ?? []
                result += "- **\(tech)**: \(percentage)% of projects (\(count)/\(total))\n"
                if projectList.count <= 3 {
                    result += "  - Used in: \(projectList.joined(separator: ", "))\n"
                }
            }
        }
        
        // Identify emerging technologies (used in 1-2 projects)
        let emergingTech = sortedTech.filter { $0.value <= 2 && $0.value > 0 }
        if !emergingTech.isEmpty {
            result += "\n### Emerging Technologies:\n"
            for (tech, _) in emergingTech {
                if let projects = globalTechStats.projectsUsing[tech] {
                    result += "- **\(tech)** (exploring in: \(projects.joined(separator: ", ")))\n"
                }
            }
        }
        
        // Technology adoption timeline
        result += "\n### Recent Technology Adoptions:\n"
        let recentTech = globalTechStats.lastUsed.sorted { $0.value > $1.value }.prefix(5)
        for (tech, date) in recentTech {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            result += "- \(tech): Last used \(formatter.string(from: date))\n"
        }
        
        return result
    }
    
    // MARK: - Project Health Scoring
    
    func getProjectHealthReport() async -> String {
        var healthScores: [(name: String, health: ProjectHealth)] = []
        
        for (name, project) in projects {
            let health = calculateProjectHealth(project)
            healthScores.append((name: name, health: health))
        }
        
        // Sort by health score
        healthScores.sort { $0.health.score > $1.health.score }
        
        var result = "## Project Health Report\n\n"
        
        // Group by health categories
        let critical = healthScores.filter { $0.health.score < 40 }
        let needsAttention = healthScores.filter { $0.health.score >= 40 && $0.health.score < 70 }
        let healthy = healthScores.filter { $0.health.score >= 70 }
        
        if !critical.isEmpty {
            result += "### 🚨 Critical (Needs Immediate Attention):\n"
            for (name, health) in critical {
                result += formatHealthReport(name: name, health: health)
            }
        }
        
        if !needsAttention.isEmpty {
            result += "\n### ⚠️ Needs Attention:\n"
            for (name, health) in needsAttention {
                result += formatHealthReport(name: name, health: health)
            }
        }
        
        if !healthy.isEmpty {
            result += "\n### ✅ Healthy Projects:\n"
            for (name, health) in healthy {
                result += "- **\(name)** (Health: \(health.score)/100)\n"
            }
        }
        
        return result
    }
    
    // MARK: - Helper Methods
    
    func updateProject(_ project: ProjectWithAnalytics) async {
        projects[project.name] = project
        
        // Update global tech stats
        for tech in project.techStack {
            globalTechStats.recordTechnology(tech, for: project.name)
        }
    }
    
    func migrateProject(_ oldProject: Project) async -> ProjectWithAnalytics {
        let newProject = ProjectWithAnalytics(from: oldProject)
        await updateProject(newProject)
        return newProject
    }
    
    func recordActivity(for projectName: String, type: ActivityEvent.EventType, description: String? = nil) async {
        guard var project = projects[projectName] else { return }
        
        let event = ActivityEvent(timestamp: Date(), type: type, description: description)
        project.activityLog.append(event)
        project.lastModified = Date()
        
        await updateProject(project)
    }
    
    func updateStatus(for projectName: String, newStatus: String) async {
        guard var project = projects[projectName] else { return }
        
        // Close current status history
        if !project.statusHistory.isEmpty {
            project.statusHistory[project.statusHistory.count - 1].endDate = Date()
        }
        
        // Add new status
        project.statusHistory.append(StatusHistory(status: newStatus, startDate: Date()))
        project.status = newStatus
        
        // Record activity
        let event = ActivityEvent(timestamp: Date(), type: .statusChange, description: "Status changed to: \(newStatus)")
        project.activityLog.append(event)
        project.lastModified = Date()
        
        await updateProject(project)
    }
    
    // MARK: - Private Helpers
    
    private func calculateActivityScore(events: [ActivityEvent]) -> Int {
        // Weight different event types
        var score = 0
        for event in events {
            switch event.type {
            case .statusChange: score += 5
            case .noteAdded: score += 3
            case .taskAdded: score += 2
            case .taskCompleted: score += 4
            case .accessed: score += 1
            case .searched: score += 1
            }
        }
        return score
    }
    
    private func getHeatEmoji(score: Int) -> String {
        switch score {
        case 0: return "💤"
        case 1...5: return "🔥"
        case 6...15: return "🔥🔥"
        default: return "🔥🔥🔥"
        }
    }
    
    private func calculateProjectHealth(_ project: ProjectWithAnalytics) -> ProjectHealth {
        var factors: [ProjectHealth.HealthFactor] = []
        
        // Activity score (based on recent events)
        let recentEvents = project.activityLog.filter { 
            $0.timestamp > Calendar.current.date(byAdding: .day, value: -30, to: Date())! 
        }
        let activityScore = min(100, calculateActivityScore(events: recentEvents) * 5)
        factors.append(ProjectHealth.HealthFactor(
            type: .activity,
            score: activityScore,
            description: "\(recentEvents.count) events in last 30 days"
        ))
        
        // Staleness score (time since last update)
        let daysSinceUpdate = Date().timeIntervalSince(project.lastModified) / 86400
        let stalenessScore = max(0, 100 - Int(daysSinceUpdate * 10))
        factors.append(ProjectHealth.HealthFactor(
            type: .staleness,
            score: stalenessScore,
            description: "Last updated \(Int(daysSinceUpdate)) days ago"
        ))
        
        // Documentation score
        let hasDescription = project.description != nil
        let hasNotes = project.notes != nil && !project.notes!.isEmpty
        let docScore = (hasDescription ? 50 : 0) + (hasNotes ? 50 : 0)
        factors.append(ProjectHealth.HealthFactor(
            type: .documentation,
            score: docScore,
            description: hasDescription && hasNotes ? "Well documented" : "Needs more documentation"
        ))
        
        // Task completion score
        let totalTasks = project.currentTasks.count + project.completedTasks.count
        let completionScore = totalTasks > 0 ? (project.completedTasks.count * 100) / totalTasks : 50
        factors.append(ProjectHealth.HealthFactor(
            type: .completion,
            score: completionScore,
            description: "\(project.completedTasks.count)/\(totalTasks) tasks completed"
        ))
        
        // Calculate overall score
        let overallScore = factors.reduce(0) { $0 + $1.score } / factors.count
        
        // Generate recommendations
        var recommendations: [String] = []
        if activityScore < 30 { recommendations.append("Increase project activity") }
        if stalenessScore < 50 { recommendations.append("Update project status") }
        if docScore < 50 { recommendations.append("Add project documentation") }
        if completionScore < 30 && totalTasks > 0 { recommendations.append("Focus on completing tasks") }
        
        return ProjectHealth(score: overallScore, factors: factors, recommendations: recommendations)
    }
    
    private func formatHealthReport(name: String, health: ProjectHealth) -> String {
        var result = "#### \(name) (Health: \(health.score)/100)\n"
        
        for factor in health.factors {
            let emoji = factor.score >= 70 ? "✅" : factor.score >= 40 ? "⚠️" : "❌"
            result += "  - \(emoji) \(factor.type.rawValue): \(factor.score)/100 - \(factor.description)\n"
        }
        
        if !health.recommendations.isEmpty {
            result += "  - **Recommendations**: \(health.recommendations.joined(separator: ", "))\n"
        }
        
        result += "\n"
        return result
    }
    
    // MARK: - Persistence
    
    func saveAnalytics() async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        // Save individual project analytics
        for (name, project) in projects {
            let data = try encoder.encode(project)
            let filePath = "\(knowledgeBasePath)/projects/\(name)-analytics.json"
            try data.write(to: URL(fileURLWithPath: filePath))
        }
        
        // Save global tech stats
        let techData = try encoder.encode(globalTechStats)
        let techPath = "\(knowledgeBasePath)/analytics/global-tech-stats.json"
        try techData.write(to: URL(fileURLWithPath: techPath))
    }
    
    func hasAnalytics(for projectName: String) async -> Bool {
        return projects[projectName] != nil
    }
    
    func loadAnalytics() async {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Create analytics directory if needed
        let analyticsPath = "\(knowledgeBasePath)/analytics"
        try? FileManager.default.createDirectory(
            atPath: analyticsPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Load project analytics
        let projectsPath = "\(knowledgeBasePath)/projects"
        if let files = try? FileManager.default.contentsOfDirectory(atPath: projectsPath) {
            for file in files where file.hasSuffix("-analytics.json") {
                let filePath = "\(projectsPath)/\(file)"
                if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
                   let project = try? decoder.decode(ProjectWithAnalytics.self, from: data) {
                    projects[project.name] = project
                }
            }
        }
        
        // Load global tech stats
        let techPath = "\(knowledgeBasePath)/analytics/global-tech-stats.json"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: techPath)),
           let stats = try? decoder.decode(TechnologyStats.self, from: data) {
            globalTechStats = stats
        }
    }
}
