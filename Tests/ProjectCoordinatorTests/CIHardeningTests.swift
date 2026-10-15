import Foundation
import Testing

/// Guard for the CI hardening in issue #13: read-only token and SHA-pinned actions.
@Suite struct CIHardeningTests {
    static func workflow() throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try String(contentsOf: root.appendingPathComponent(".github/workflows/ci.yml"), encoding: .utf8)
    }

    @Test func workflowSetsReadOnlyPermissions() throws {
        let wf = try Self.workflow()
        #expect(wf.range(of: #"(?m)^permissions:\s*\n\s+contents:\s*read"#, options: .regularExpression) != nil)
    }

    @Test func actionsArePinnedToCommitSHAs() throws {
        let lines = try Self.workflow().split(separator: "\n").filter { $0.contains("uses:") }
        #expect(!lines.isEmpty)
        for line in lines {
            let ref = line.split(separator: "@").last.map { String($0.split(separator: " ").first ?? "") } ?? ""
            #expect(ref.range(of: #"^[0-9a-f]{40}$"#, options: .regularExpression) != nil, "\(line)")
        }
    }
}
