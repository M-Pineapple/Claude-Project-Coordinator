import Foundation
import Testing
@testable import ProjectCoordinator

@Suite("SecurityValidator")
struct SecurityValidatorTests {
    private var home: String { NSHomeDirectory() }

    @Test("allows paths under configured base directories")
    func allowsUnderBase() throws {
        let path = home + "/Developer/SampleApp"
        let result = try SecurityValidator.validateProjectPath(path)
        #expect(result == URL(fileURLWithPath: path).resolvingSymlinksInPath().path)
    }

    @Test("allows tilde expansion into an allowed base")
    func allowsTilde() throws {
        let result = try SecurityValidator.validateProjectPath("~/GitHub/SampleApp")
        let prefix = URL(fileURLWithPath: home + "/GitHub").resolvingSymlinksInPath().path
        #expect(result == prefix || result.hasPrefix(prefix + "/"))
    }

    @Test("Desktop itself is not a default root")
    func rejectsDesktopByDefault() {
        #expect(throws: SecurityError.self) {
            _ = try SecurityValidator.validateProjectPath("~/Desktop/SampleApp")
        }
    }

    @Test("rejects the home directory itself")
    func rejectsHomeDirectory() {
        #expect(throws: SecurityError.self) {
            try SecurityValidator.validateProjectPath(home)
        }
    }

    @Test("rejects paths outside allowlist")
    func rejectsOutside() {
        #expect(throws: SecurityError.self) {
            try SecurityValidator.validateProjectPath("/tmp/evil-project")
        }
    }

    @Test("rejects path traversal attempts")
    func rejectsTraversal() {
        #expect(throws: SecurityError.self) {
            try SecurityValidator.validateProjectPath("~/Developer/../Documents/../../etc")
        }
    }

    @Test("rejects empty project names")
    func rejectsEmptyName() {
        #expect(throws: SecurityError.self) {
            try SecurityValidator.validateProjectName("   ")
        }
    }

    @Test("rejects injection-like search patterns")
    func rejectsInjection() {
        #expect(throws: SecurityError.self) {
            try SecurityValidator.validateSearchPattern("foo; rm -rf /")
        }
    }
}

@Suite("KnowledgeBasePaths", .serialized)
struct KnowledgeBasePathsTests {
    @Test("honours DPC_KNOWLEDGE_BASE override")
    func environmentOverride() {
        let override = NSTemporaryDirectory() + "dpc-kb-test-\(UUID().uuidString)"
        unsetenv(KnowledgeBasePaths.legacyEnvironmentKey)
        setenv(KnowledgeBasePaths.environmentKey, override, 1)
        defer { unsetenv(KnowledgeBasePaths.environmentKey) }

        let resolved = KnowledgeBasePaths.resolve()
        #expect(resolved == (override as NSString).expandingTildeInPath)
    }

    @Test("falls back to CPC_KNOWLEDGE_BASE")
    func legacyOverride() {
        let override = NSTemporaryDirectory() + "cpc-kb-test-\(UUID().uuidString)"
        unsetenv(KnowledgeBasePaths.environmentKey)
        setenv(KnowledgeBasePaths.legacyEnvironmentKey, override, 1)
        defer { unsetenv(KnowledgeBasePaths.legacyEnvironmentKey) }

        let resolved = KnowledgeBasePaths.resolve()
        #expect(resolved == (override as NSString).expandingTildeInPath)
    }

    @Test("prefers DPC_KNOWLEDGE_BASE when both are set")
    func prefersNewKey() {
        let dpc = NSTemporaryDirectory() + "dpc-pref-\(UUID().uuidString)"
        let cpc = NSTemporaryDirectory() + "cpc-pref-\(UUID().uuidString)"
        setenv(KnowledgeBasePaths.environmentKey, dpc, 1)
        setenv(KnowledgeBasePaths.legacyEnvironmentKey, cpc, 1)
        defer {
            unsetenv(KnowledgeBasePaths.environmentKey)
            unsetenv(KnowledgeBasePaths.legacyEnvironmentKey)
        }
        let resolved = KnowledgeBasePaths.resolve()
        #expect(resolved == (dpc as NSString).expandingTildeInPath)
    }
}

@Suite("Analytics migration")
struct AnalyticsMigrationTests {
    @Test("migrate-once respects on-disk analytics files")
    func migrateOnce() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("cpc-migrate-\(UUID().uuidString)", isDirectory: true)
        let kb = root.appendingPathComponent("KnowledgeBase", isDirectory: true)
        let projects = kb.appendingPathComponent("projects", isDirectory: true)
        try FileManager.default.createDirectory(at: projects, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let project = Project(
            name: "DemoApp",
            path: NSHomeDirectory() + "/Developer/DemoApp",
            description: "demo",
            status: "active",
            notes: nil,
            techStack: ["Swift"],
            lastModified: Date(timeIntervalSince1970: 1_700_000_000),
            currentTasks: []
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let projectURL = projects.appendingPathComponent("DemoApp.json")
        try encoder.encode(project).write(to: projectURL)

        let analytics = ProjectAnalytics(knowledgeBasePath: kb.path)
        let manager = ProjectManager(knowledgeBasePath: kb.path)

        await manager.initialize(analytics: analytics)
        await manager.initialize(analytics: analytics)

        let analyticsFile = projects.appendingPathComponent("DemoApp-analytics.json")
        #expect(FileManager.default.fileExists(atPath: analyticsFile.path))

        let data = try Data(contentsOf: analyticsFile)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let loaded = try decoder.decode(ProjectWithAnalytics.self, from: data)
        #expect(loaded.createdDate.timeIntervalSince1970 == 1_700_000_000)
    }
}

@Suite("Version")
struct VersionTests {
    @Test("version string is 2.0.1")
    func versionPin() {
        #expect(CPCVersion.string == "2.0.1")
        #expect(CPCVersion.serverName == "project-coordinator")
        #expect(CPCVersion.preferredServerName == "dev-project-coordinator")
        #expect(CPCVersion.displayName == "Dev Project Coordinator")
    }
}
