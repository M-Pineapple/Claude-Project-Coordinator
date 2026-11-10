import Foundation

public actor ProjectManager {
    private var projects: [String: Project] = [:]
    private let knowledgeBasePath: String
    private let fileManager = FileManager.default
    private var securityConfig: SecurityConfig
    private var analytics: ProjectAnalytics?
    private let extraAllowedBases: [String]
    private let cardStore: CardStore
    private var deskServer: DeskServer?

    public init(
        knowledgeBasePath: String = KnowledgeBasePaths.resolve(),
        extraAllowedBases: [String] = []
    ) {
        self.knowledgeBasePath = knowledgeBasePath
        self.extraAllowedBases = extraAllowedBases
        let configPath = "\(knowledgeBasePath)/security-config.json"
        self.securityConfig = SecurityConfig.load(from: configPath)
        self.cardStore = CardStore(knowledgeBasePath: knowledgeBasePath)
    }

    public func initialize(analytics: ProjectAnalytics) async {
        self.analytics = analytics
        let allowed = SecurityValidator.effectiveAllowedBasePaths(
            config: securityConfig,
            extra: extraAllowedBases
        )
        CPCLog.info("Allowed project roots: \(allowed.joined(separator: ", "))")
        if !securityConfig.enableValidation {
            CPCLog.warning("security-config.json has enableValidation=false; path checks are skipped. Treat this file as trusted input.")
        }
        createKnowledgeBaseStructure()
        await loadProjects()
        await analytics.loadAnalytics()
        do {
            try await cardStore.load()
        } catch {
            CPCLog.warning("Desk board not loaded: \(error.localizedDescription)")
        }
        try? await cardStore.migrateIfNeeded(from: Array(projects.values))

        var migratedAny = false
        for (_, project) in projects {
            let analyticsPath = "\(knowledgeBasePath)/projects/\(project.name)-analytics.json"
            let fileExists = fileManager.fileExists(atPath: analyticsPath)

            if !fileExists {
                CPCLog.info("Migrating \(project.name) to analytics system")
                _ = await analytics.migrateProject(project)
                migratedAny = true
            } else {
                CPCLog.info("Analytics file already exists for \(project.name), skipping migration")
            }
        }

        if migratedAny {
            CPCLog.info("Saving newly migrated analytics")
            try? await analytics.saveAnalytics()
        } else {
            CPCLog.info("No projects needed migration")
        }

        _ = try? await regenerateDesk()
    }

    private func createKnowledgeBaseStructure() {
        let directories = [
            knowledgeBasePath,
            "\(knowledgeBasePath)/projects",
            "\(knowledgeBasePath)/templates",
            "\(knowledgeBasePath)/tools",
            "\(knowledgeBasePath)/patterns",
            "\(knowledgeBasePath)/desk",
            "\(knowledgeBasePath)/analytics"
        ]
        for directory in directories {
            try? fileManager.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        createDefaultTemplates()
    }

    private func writeIfMissing(_ content: String, to path: String) {
        guard !fileManager.fileExists(atPath: path) else { return }
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func createDefaultTemplates() {
        let indexContent = """
        # Project Coordinator Index

        ## Active Projects

        <!-- Projects will be automatically updated here -->

        ## Quick Commands
        - Compact desk: `get_desk_summary`
        - List all projects: `list_projects`
        - Search: `search_desk [pattern]`
        - Update status: `update_project_status [project] [status]`
        """
        writeIfMissing(indexContent, to: "\(knowledgeBasePath)/project-index.md")

        let patternsContent = """
        # Code Patterns

        Add language-agnostic notes here. This file is created once and is not overwritten on start.
        """
        writeIfMissing(patternsContent, to: "\(knowledgeBasePath)/patterns/swift-patterns.md")

        let troubleshootingContent = """
        # Troubleshooting Guide

        Add local notes here. This file is created once and is not overwritten on start.
        """
        writeIfMissing(troubleshootingContent, to: "\(knowledgeBasePath)/tools/troubleshooting.md")
    }

    private func isProjectJSON(_ file: String) -> Bool {
        file.hasSuffix(".json")
            && !file.contains("EXAMPLE")
            && !file.hasSuffix("-analytics.json")
    }

    private func loadProjects() async {
        let projectsPath = "\(knowledgeBasePath)/projects"
        guard let files = try? fileManager.contentsOfDirectory(atPath: projectsPath) else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        for file in files where isProjectJSON(file) {
            let filePath = "\(projectsPath)/\(file)"
            if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
               let project = try? decoder.decode(Project.self, from: data) {
                projects[project.name] = project
            }
        }
    }

    public func allProjects() -> [Project] {
        Array(projects.values).sorted { $0.name < $1.name }
    }

    public func listProjects() async throws -> String {
        guard !projects.isEmpty else {
            return """
            No projects currently tracked.

            Prefer get_desk_summary after you add work.
            To add a project, use: add_project
            Example: add_project name:"WeatherApp" path:"~/Developer/WeatherApp" description:"weather application"
            """
        }

        var result = "# Tracked Projects\n\n"
        for project in allProjects() {
            result += "## \(project.name)\n"
            result += "- **Kind**: \(project.kind.rawValue)\n"
            if let path = project.path {
                result += "- **Path**: \(path)\n"
            }
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

    public func deskSummary(includeArchived: Bool = false) async throws -> String {
        let board = try await cardStore.snapshot()
        return DeskSummary.render(
            projects: allProjects(),
            board: board,
            includeArchived: includeArchived,
            archiveAfter: archiveInterval()
        )
    }

    private func archiveInterval() -> TimeInterval {
        CardArchive.interval(
            days: CardArchive.days(configDays: securityConfig.archiveDays)
        )
    }

    public func openDesk() async throws -> String {
        let url = try await regenerateDesk()
        return "Desk page: \(url.path)\nOpen that file from disk. Data never leaves this machine."
    }

    func getProjectStatus(projectName: String, includeArchived: Bool = false) async throws -> String {
        guard let project = projects[projectName] else {
            throw CoordinatorError.projectNotFound
        }

        var result = "# \(project.name) Status\n\n"
        result += "**Kind**: \(project.kind.rawValue)\n\n"
        if let path = project.path {
            result += "**Path**: \(path)\n\n"
        }
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
        result += try await cardSection(for: project.name, includeArchived: includeArchived)
        if let notes = project.notes {
            result += "## Notes\n\(notes)\n\n"
        }
        result += "**Last Updated**: \(formatDate(project.lastModified))"
        return result
    }

    private func cardSection(for projectName: String, includeArchived: Bool) async throws -> String {
        let board = try await cardStore.snapshot()
        let window = archiveInterval()
        let now = Date()
        let mine = board.cards.filter { $0.project == projectName }.sorted { $0.order < $1.order }
        let archived = mine.filter { $0.isArchived(now: now, archiveAfter: window) }
        let archivedIDs = Set(archived.map(\.id))
        let listed = includeArchived ? mine : mine.filter { !archivedIDs.contains($0.id) }
        var section = "## Cards\n"
        if listed.isEmpty {
            section += "None\n"
        } else {
            for card in listed {
                let title = card.title.replacingOccurrences(of: "\n", with: " ")
                let mark = archivedIDs.contains(card.id) ? " archived" : ""
                let evidence = card.note.map { " | \($0.replacingOccurrences(of: "\n", with: " "))" } ?? ""
                section += "- [\(card.column)] \(title) (\(card.id))\(evidence)\(mark)\n"
            }
        }
        section += "\nArchived: \(archived.count)\n\n"
        return section
    }

    func searchCodePatterns(pattern: String) async throws -> String {
        var results: [String] = []
        let needle = pattern.lowercased()

        let patternsPath = "\(knowledgeBasePath)/patterns"
        if let files = try? fileManager.contentsOfDirectory(atPath: patternsPath) {
            for file in files where file.hasSuffix(".md") {
                let filePath = "\(patternsPath)/\(file)"
                if let content = try? String(contentsOfFile: filePath, encoding: .utf8),
                   content.lowercased().contains(needle) {
                    results.append("Found in patterns/\(file)")
                }
            }
        }

        for (projectName, project) in projects {
            if project.kind.rawValue.lowercased().contains(needle) {
                results.append("\(projectName) kind \(project.kind.rawValue)")
            }
            if let notes = project.notes, notes.lowercased().contains(needle) {
                results.append("Found in project \(projectName) notes")
            }
            for tech in project.techStack where tech.lowercased().contains(needle) {
                results.append("\(projectName) uses \(tech)")
            }
        }

        let board = try await cardStore.snapshot()
        let window = archiveInterval()
        let now = Date()
        for card in board.cards {
            let titleHit = card.title.lowercased().contains(needle)
            let noteHit = card.note?.lowercased().contains(needle) ?? false
            guard titleHit || noteHit else { continue }
            let mark = card.isArchived(now: now, archiveAfter: window) ? " [archived]" : ""
            let evidence = card.note.map { " (\($0))" } ?? ""
            results.append("Card \(card.id) in \(card.project): \(card.title)\(evidence)\(mark)")
        }

        if results.isEmpty {
            return "No results found for pattern: \(pattern)"
        }
        return "# Search Results for '\(pattern)'\n\n" + results.map { "- \($0)" }.joined(separator: "\n")
    }

    func addProject(
        name: String,
        path: String?,
        description: String?,
        kind: ProjectKind?,
        repoURL: String? = nil,
        currentBranch: String? = nil,
        openPR: String? = nil
    ) async throws -> String {
        if let existing = NameMatcher.closest(to: name, in: Array(projects.keys)) {
            if NameMatcher.normalize(existing) == NameMatcher.normalize(name) {
                throw CoordinatorError.duplicateProject(existing)
            }
            throw CoordinatorError.nearDuplicate(existing)
        }

        var techStack: [String] = []
        var resolvedKind = kind ?? (path == nil ? .other : .coding)
        var resolvedPath = path

        if let path {
            let detection = ProjectDetector.detect(at: path, fileManager: fileManager)
            techStack = detection.tags.contains("unknown") ? [] : detection.tags
            if kind == nil {
                resolvedKind = detection.kind == .other ? .coding : detection.kind
            }
            resolvedPath = path
        } else if resolvedKind == .coding {
            throw CoordinatorError.codingRequiresPath
        }

        let project = Project(
            name: name,
            path: resolvedPath,
            description: description,
            status: "Active",
            notes: nil,
            techStack: techStack,
            lastModified: Date(),
            currentTasks: [],
            kind: resolvedKind,
            repoURL: repoURL,
            currentBranch: currentBranch,
            openPR: openPR
        )
        projects[name] = project
        try await saveProject(project)
        if let analytics {
            _ = await analytics.migrateProject(project)
            try? await analytics.saveAnalytics()
        }
        await updateProjectIndex()
        if let openPR, !openPR.isEmpty {
            _ = try await cardStore.addCard(
                project: name,
                title: "PR \(openPR)",
                column: "doing",
                linkedPR: openPR
            )
        } else {
            _ = try await cardStore.addCard(project: name, title: name, column: DeskColumns.fromStatus(project.status))
        }
        try await regenerateDesk()

        let stack = techStack.isEmpty ? "none" : techStack.joined(separator: ", ")
        return """
        Successfully added project: \(name)
        Kind: \(resolvedKind.rawValue)
        Path: \(resolvedPath ?? "(none)")
        Detected tech stack: \(stack)
        """
    }

    func updateProjectStatus(projectName: String, status: String?, notes: String?) async throws -> String {
        guard var project = projects[projectName] else {
            throw CoordinatorError.projectNotFound
        }
        if let status { project.status = status }
        if let notes { project.notes = notes }
        project.lastModified = Date()
        projects[projectName] = project
        try await saveProject(project)
        await updateProjectIndex()
        try await regenerateDesk()
        return "Successfully updated \(projectName)"
    }

    public func registerFromWorkspace(
        cwd: String,
        gitRemote: String? = nil,
        branch: String? = nil,
        openPR: String? = nil
    ) async throws -> String {
        let allowed = SecurityValidator.effectiveAllowedBasePaths(
            config: securityConfig,
            extra: extraAllowedBases
        )
        let validatedPath = try SecurityValidator.validateProjectPath(cwd, allowedBasePaths: allowed)
        try SecurityValidator.verifyPathExists(validatedPath)

        let info = WorkspaceProbe.probe(
            cwd: validatedPath,
            gitRemote: gitRemote,
            branch: branch,
            fileManager: fileManager
        )

        if let existingName = projects.first(where: { $0.value.path == info.path })?.key
            ?? projects[info.name].map({ $0.name }) {
            var project = projects[existingName]!
            project.repoURL = info.repoURL
            project.currentBranch = info.branch
            project.openPR = openPR ?? project.openPR
            if project.techStack.isEmpty { project.techStack = info.tags.filter { $0 != "unknown" } }
            project.lastModified = Date()
            projects[existingName] = project
            try await saveProject(project)
            if let openPR, !openPR.isEmpty {
                _ = try await cardStore.addCard(
                    project: existingName,
                    title: "PR \(openPR)",
                    column: "doing",
                    linkedPR: openPR
                )
            }
            try await regenerateDesk()
            return "Updated existing project \(existingName) from workspace \(info.path)"
        }

        return try await addProject(
            name: info.name,
            path: info.path,
            description: nil,
            kind: info.kind,
            repoURL: info.repoURL,
            currentBranch: info.branch,
            openPR: openPR
        )
    }

    public func fileUnderProject(
        name: String,
        kind: ProjectKind? = nil,
        description: String? = nil
    ) async throws -> String {
        if let existing = NameMatcher.closest(to: name, in: Array(projects.keys)) {
            return "Filed under existing project: \(existing)"
        }
        let resolvedKind = kind ?? .other
        _ = try await addProject(
            name: name,
            path: nil,
            description: description,
            kind: resolvedKind
        )
        return "Filed under new project: \(name)"
    }

    public func renameProject(from oldName: String, to newName: String) async throws -> String {
        let validatedNew = try SecurityValidator.validateProjectName(newName)
        guard let project = projects[oldName] else { throw CoordinatorError.projectNotFound }
        if projects[validatedNew] != nil { throw CoordinatorError.duplicateProject(validatedNew) }
        var renamed = project
        renamed.name = validatedNew
        renamed.lastModified = Date()
        projects.removeValue(forKey: oldName)
        projects[validatedNew] = renamed
        try await saveProject(renamed)
        let oldJSON = "\(knowledgeBasePath)/projects/\(oldName).json"
        let oldSummary = "\(knowledgeBasePath)/projects/\(oldName)-summary.md"
        try? fileManager.removeItem(atPath: oldJSON)
        try? fileManager.removeItem(atPath: oldSummary)
        if let analytics {
            await analytics.renameProject(from: oldName, to: validatedNew)
        }
        try await cardStore.reassignProject(from: oldName, to: validatedNew)
        await updateProjectIndex()
        try await regenerateDesk()
        return "Renamed \(oldName) to \(validatedNew)"
    }

    public func mergeProjects(source: String, into target: String) async throws -> String {
        guard let sourceProject = projects[source] else { throw CoordinatorError.projectNotFound }
        guard var targetProject = projects[target] else { throw CoordinatorError.projectNotFound }
        if targetProject.notes == nil { targetProject.notes = sourceProject.notes }
        if targetProject.path == nil { targetProject.path = sourceProject.path }
        if targetProject.techStack.isEmpty { targetProject.techStack = sourceProject.techStack }
        targetProject.lastModified = Date()
        projects[target] = targetProject
        projects.removeValue(forKey: source)
        try await saveProject(targetProject)
        try? fileManager.removeItem(atPath: "\(knowledgeBasePath)/projects/\(source).json")
        try? fileManager.removeItem(atPath: "\(knowledgeBasePath)/projects/\(source)-summary.md")
        if let analytics {
            await analytics.mergeProject(source: source, into: target)
        }
        try await cardStore.reassignProject(from: source, to: target)
        await updateProjectIndex()
        try await regenerateDesk()
        return "Merged \(source) into \(target)"
    }

    public func addCard(
        project: String,
        title: String,
        column: String? = nil,
        memoryRef: String? = nil,
        linkedPR: String? = nil,
        note: String? = nil
    ) async throws -> String {
        guard projects[project] != nil else { throw CoordinatorError.projectNotFound }
        let card = try await cardStore.addCard(
            project: project,
            title: title,
            column: column,
            memoryRef: memoryRef,
            linkedPR: linkedPR,
            note: note
        )
        if let analytics {
            await analytics.recordActivity(for: project, type: .taskAdded, description: title)
        }
        try await regenerateDesk()
        return "Added card \(card.id) on \(project) in \(card.column)"
    }

    public func moveCard(id: String, column: String, note: String? = nil) async throws -> String {
        let card = try await cardStore.moveCard(id: id, column: column, note: note)
        try await regenerateDesk()
        return "Moved card \(card.id) to \(card.column)"
    }

    public func updateCard(
        id: String,
        title: String? = nil,
        column: String? = nil,
        memoryRef: String? = nil,
        note: String? = nil
    ) async throws -> String {
        let card = try await cardStore.updateCard(
            id: id,
            title: title,
            column: column,
            memoryRef: memoryRef,
            note: note
        )
        try await regenerateDesk()
        return "Updated card \(card.id)"
    }

    public func renameColumn(from old: String, to newName: String) async throws -> String {
        try await cardStore.renameColumn(from: old, to: newName)
        try await regenerateDesk()
        return "Renamed column \(old) to \(newName)"
    }

    public func boardSnapshot() async throws -> Board {
        try await cardStore.snapshot()
    }

    public func startDeskServer(rotate: Bool = false) async throws -> String {
        // Once a desk server runs in this process it outlives any parent's lock, so stop trusting it.
        BoardLock.ignoreInheritedLock()
        if let deskServer, deskServer.isRunning {
            if rotate {
                try deskServer.rotateToken()
            } else {
                _ = deskServer.mintSignInCode()
            }
            return Self.deskServerMessage(server: deskServer, rotated: rotate)
        }
        let kb = knowledgeBasePath
        let box = ManagerHandle(self)
        let port = DeskServer.resolvePort(configPort: securityConfig.deskPort)
        let server = try DeskServer(
            knowledgeBasePath: kb,
            bindHost: "127.0.0.1",
            port: port,
            htmlProvider: {
                DeskPage.renderFromKnowledgeBase(knowledgeBasePath: kb, mode: .live)
            },
            onMove: { id, column in
                try box.run { manager in
                    _ = try await manager.moveCard(id: id, column: column)
                }
            },
            onAdd: { project, title in
                try box.run { manager in
                    _ = try await manager.addCard(project: project, title: title)
                }
            }
        )
        // Bind first. If the port is busy, the token file stays as the running server knows it.
        try server.start()
        // The token now persists across restarts (#29), so a fresh start only rotates when asked.
        if rotate {
            do {
                try server.rotateToken()
            } catch {
                server.stop()
                throw error
            }
        }
        deskServer = server
        try await regenerateDesk()
        return Self.deskServerMessage(server: server, rotated: rotate)
    }

    /// Stop this process's desk server if one is running. Used by tests.
    func stopDeskServer() {
        deskServer?.stop()
        deskServer = nil
    }

    static func deskServerMessage(server: DeskServer, rotated: Bool) -> String {
        let rotation = rotated ? "Write token rotated.\n" : ""
        return """
        \(rotation)\(server.plainURL)
        Sign-in URL (valid once, for 10 minutes): \(server.signInURL)
        Write token file: \(server.tokenFileURL.path) (mode 0600)
        Port is fixed. If it is busy, start fails. Set DPC_DESK_PORT or security-config deskPort.
        The session cookie is the write token. It persists in the token file, so a restart keeps signed-in sessions.
        Rotation writes a new token file and invalidates existing cookies.
        Writes accept that cookie or the X-DPC-Token header.
        Static KnowledgeBase/desk/index.html still works without this server.
        """
    }

    @discardableResult
    private func regenerateDesk() async throws -> URL {
        let board = try await cardStore.snapshot()
        if let analytics {
            try? await analytics.saveAnalytics()
        }
        let records = await analytics?.allRecords() ?? []
        return try DeskPage.write(
            knowledgeBasePath: knowledgeBasePath,
            projects: allProjects(),
            board: board,
            records: records
        )
    }

    private func saveProject(_ project: Project) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(project)
        let filePath = "\(knowledgeBasePath)/projects/\(project.name).json"
        try data.write(to: URL(fileURLWithPath: filePath))
        let summaryPath = "\(knowledgeBasePath)/projects/\(project.name)-summary.md"
        let summary = generateProjectSummary(project)
        try summary.write(to: URL(fileURLWithPath: summaryPath), atomically: true, encoding: .utf8)
    }

    private func generateProjectSummary(_ project: Project) -> String {
        var summary = "# \(project.name)\n\n"
        summary += "Kind: \(project.kind.rawValue)\n\n"
        if let description = project.description {
            summary += "\(description)\n\n"
        }
        if let path = project.path {
            summary += "## Location\n`\(path)`\n\n"
        }
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
        for project in allProjects() {
            index += "### \(project.name)\n"
            index += "- **Kind**: \(project.kind.rawValue)\n"
            if let path = project.path {
                index += "- **Location**: `\(path)`\n"
            }
            index += "- **Tech Stack**: \(project.techStack.joined(separator: ", "))\n"
            if let status = project.status {
                index += "- **Status**: \(status)\n"
            }
            index += "- **Last Modified**: \(formatDate(project.lastModified))\n\n"
        }
        index += """

        ## Quick Commands
        - Compact desk: `get_desk_summary`
        - List all projects: `list_projects`
        - Search: `search_desk [pattern]`
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

    public func addProjectSecure(
        name: String,
        path: String?,
        description: String?,
        kind: ProjectKind? = nil,
        repoURL: String? = nil,
        currentBranch: String? = nil,
        openPR: String? = nil
    ) async throws -> String {
        if securityConfig.enableValidation {
            let validatedName = try SecurityValidator.validateProjectName(name)
            var validatedPath: String?
            if let path {
                let allowed = SecurityValidator.effectiveAllowedBasePaths(
                    config: securityConfig,
                    extra: extraAllowedBases
                )
                validatedPath = try SecurityValidator.validateProjectPath(path, allowedBasePaths: allowed)
                try SecurityValidator.verifyPathExists(validatedPath!)
            }
            let validatedDescription = try description.map {
                try SecurityValidator.validateText($0, maxLength: securityConfig.maxDescriptionLength, fieldName: "description")
            }
            return try await addProject(
                name: validatedName,
                path: validatedPath,
                description: validatedDescription,
                kind: kind,
                repoURL: repoURL,
                currentBranch: currentBranch,
                openPR: openPR
            )
        } else {
            return try await addProject(
                name: name,
                path: path,
                description: description,
                kind: kind,
                repoURL: repoURL,
                currentBranch: currentBranch,
                openPR: openPR
            )
        }
    }

    public func updateProjectStatusSecure(projectName: String, status: String?, notes: String?) async throws -> String {
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

    public func searchCodePatternsSecure(pattern: String) async throws -> String {
        if securityConfig.enableValidation {
            let validatedPattern = try SecurityValidator.validateSearchPattern(pattern)
            return try await searchCodePatterns(pattern: validatedPattern)
        } else {
            return try await searchCodePatterns(pattern: pattern)
        }
    }

    public func getProjectStatusSecure(projectName: String, includeArchived: Bool = false) async throws -> String {
        if securityConfig.enableValidation {
            let validatedName = try SecurityValidator.validateProjectName(projectName)
            return try await getProjectStatus(projectName: validatedName, includeArchived: includeArchived)
        } else {
            return try await getProjectStatus(projectName: projectName, includeArchived: includeArchived)
        }
    }

    func getSecurityConfig() -> SecurityConfig {
        securityConfig
    }

    func updateSecurityConfig(_ newConfig: SecurityConfig) throws {
        self.securityConfig = newConfig
        let configPath = "\(knowledgeBasePath)/security-config.json"
        try newConfig.save(to: configPath)
    }

    public func attachAnalytics(_ analytics: ProjectAnalytics) async {
        self.analytics = analytics
    }

    func updateProjectWithAnalytics(projectName: String, status: String?, notes: String?) async throws {
        guard var project = projects[projectName] else {
            throw CoordinatorError.projectNotFound
        }
        if let analytics = analytics {
            if let newStatus = status, newStatus != project.status {
                await analytics.updateStatus(for: projectName, newStatus: newStatus)
            }
            if notes != nil {
                await analytics.recordActivity(for: projectName, type: .noteAdded)
            }
        }
        if let status { project.status = status }
        if let notes { project.notes = notes }
        project.lastModified = Date()
        projects[projectName] = project
        try await saveProject(project)
        await updateProjectIndex()
        try await regenerateDesk()
    }
}

/// Unchecked handle so the loopback server can hop onto the manager actor.
private final class ManagerHandle: @unchecked Sendable {
    let manager: ProjectManager

    init(_ manager: ProjectManager) {
        self.manager = manager
    }

    func run(_ body: @escaping @Sendable (ProjectManager) async throws -> Void) throws {
        let box = ErrorBox()
        let semaphore = DispatchSemaphore(value: 0)
        let manager = self.manager
        Task {
            do {
                try await body(manager)
            } catch {
                box.error = error
            }
            semaphore.signal()
        }
        semaphore.wait()
        if let error = box.error { throw error }
    }
}

private final class ErrorBox: @unchecked Sendable {
    var error: (any Error)?
}
