import Foundation

/// Resolves the on-disk KnowledgeBase directory for CPC.
public enum KnowledgeBasePaths {
    /// Environment override used by tests and custom installs.
    public static let environmentKey = "CPC_KNOWLEDGE_BASE"

    /// Resolve KnowledgeBase path.
    /// Order: `CPC_KNOWLEDGE_BASE` → walk up from executable for Package.swift/KnowledgeBase → cwd.
    public static func resolve(fileManager: FileManager = .default) -> String {
        if let override = ProcessInfo.processInfo.environment[environmentKey],
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (override as NSString).expandingTildeInPath
        }

        if let fromExecutable = locateNearExecutable(fileManager: fileManager) {
            return fromExecutable
        }

        let cwd = fileManager.currentDirectoryPath
        let cwdKB = (cwd as NSString).appendingPathComponent("KnowledgeBase")
        if fileManager.fileExists(atPath: cwdKB) {
            return cwdKB
        }

        return cwdKB
    }

    private static func locateNearExecutable(fileManager: FileManager) -> String? {
        guard let executablePath = Bundle.main.executablePath else { return nil }

        var url = URL(fileURLWithPath: executablePath).deletingLastPathComponent()
        for _ in 0..<6 {
            let candidate = url.appendingPathComponent("KnowledgeBase").path
            let packageSwift = url.appendingPathComponent("Package.swift").path
            if fileManager.fileExists(atPath: candidate) || fileManager.fileExists(atPath: packageSwift) {
                if !fileManager.fileExists(atPath: candidate) {
                    try? fileManager.createDirectory(atPath: candidate, withIntermediateDirectories: true)
                }
                return candidate
            }
            let parent = url.deletingLastPathComponent()
            if parent.path == url.path { break }
            url = parent
        }
        return nil
    }
}
