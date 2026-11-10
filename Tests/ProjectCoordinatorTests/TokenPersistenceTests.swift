import Foundation
import Testing
@testable import ProjectCoordinator
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// #29: the write token persists across desk restarts. Rotation stays explicit.
@Suite("Desk write token persistence", .serialized)
struct TokenPersistenceTests {
    private func makeServer(_ kb: URL, onMove: @escaping @Sendable (String, String) throws -> Void = { _, _ in }) throws -> DeskServer {
        try DeskServer(
            knowledgeBasePath: kb.path,
            bindHost: "127.0.0.1",
            port: 0,
            htmlProvider: { "<html></html>" },
            onMove: onMove,
            onAdd: { _, _ in }
        )
    }

    private func tokenFile(_ kb: URL) -> URL {
        kb.appendingPathComponent("desk/.write-token")
    }

    private func perms(_ url: URL) throws -> Int16? {
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        return (attrs[.posixPermissions] as? NSNumber)?.int16Value
    }

    private func signInCookie(_ server: DeskServer) throws -> String {
        let code = try #require(server.currentSignInCode())
        let response = server.handleForTests(
            HTTPRequest(method: "GET", path: "/?signin=\(code)", headers: ["host": "127.0.0.1:\(server.port)"], body: Data())
        )
        #expect(response.status == 303)
        let header = try #require(response.headers["Set-Cookie"])
        return String(try #require(header.split(separator: ";").first))
    }

    private func move(_ server: DeskServer, cookie: String) -> HTTPResponse {
        let origin = "http://127.0.0.1:\(server.port)"
        return server.handleForTests(
            HTTPRequest(
                method: "POST",
                path: "/api/cards/move",
                headers: ["host": "127.0.0.1:\(server.port)", "origin": origin, "cookie": cookie],
                body: Data(#"{"id":"c1","column":"done"}"#.utf8)
            )
        )
    }

    @Test("restart keeps the token and a cookie from before the restart still writes")
    func restartKeepsToken() throws {
        let desk = try TempDesk.make()
        defer { desk.cleanup() }
        let first = try makeServer(desk.kb)
        try first.start()
        let cookie = try signInCookie(first)
        #expect(move(first, cookie: cookie).status == 200)
        let original = first.token
        first.stop()

        let moves = MoveCounter()
        let second = try makeServer(desk.kb, onMove: { _, _ in moves.bump() })
        try second.start()
        defer { second.stop() }
        #expect(second.token == original)
        #expect(move(second, cookie: cookie).status == 200)
        #expect(moves.value == 1)
        #expect(try perms(tokenFile(desk.kb)) == 0o600)
    }

    @Test("missing token file mints a 0600 token")
    func missingFileMints() throws {
        let desk = try TempDesk.make()
        defer { desk.cleanup() }
        #expect(DeskServer.loadTokenFile(url: tokenFile(desk.kb)) == .missing)
        let server = try makeServer(desk.kb)
        #expect(server.token.count == 64)
        #expect(try perms(tokenFile(desk.kb)) == 0o600)
        #expect(DeskServer.loadTokenFile(url: tokenFile(desk.kb)) == .valid(server.token))
    }

    @Test("wide permissions are rejected and the file is replaced with a fresh 0600 token")
    func widePermsReplaced() throws {
        let desk = try TempDesk.make()
        defer { desk.cleanup() }
        let first = try makeServer(desk.kb)
        let exposed = first.token
        let url = tokenFile(desk.kb)
        #expect(chmod(url.path, 0o644) == 0)
        #expect(DeskServer.loadTokenFile(url: url) == .rejected(.insecurePermissions))
        let second = try makeServer(desk.kb)
        #expect(second.token != exposed)
        #expect(try perms(url) == 0o600)
        #expect(DeskServer.loadTokenFile(url: url) == .valid(second.token))
    }

    @Test("malformed token files are rejected and replaced")
    func malformedReplaced() throws {
        let samples = ["", "short", String(repeating: "A", count: 64), String(repeating: "g", count: 64), String(repeating: "a", count: 65), String(repeating: "a", count: 64) + "\n\n"]
        for sample in samples {
            let desk = try TempDesk.make()
            defer { desk.cleanup() }
            let url = tokenFile(desk.kb)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(sample.utf8).write(to: url)
            #expect(chmod(url.path, 0o600) == 0)
            #expect(DeskServer.loadTokenFile(url: url) == .rejected(.malformed))
            let server = try makeServer(desk.kb)
            #expect(server.token != sample)
            #expect(DeskServer.loadTokenFile(url: url) == .valid(server.token))
        }
    }

    @Test("one trailing newline is tolerated")
    func trailingNewline() throws {
        let desk = try TempDesk.make()
        defer { desk.cleanup() }
        let url = tokenFile(desk.kb)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let value = String(repeating: "0123456789abcdef", count: 4)
        try Data((value + "\n").utf8).write(to: url)
        #expect(chmod(url.path, 0o600) == 0)
        let server = try makeServer(desk.kb)
        #expect(server.token == value)
    }

    @Test("a symlinked token file is never followed or trusted")
    func symlinkRejected() throws {
        let desk = try TempDesk.make()
        defer { desk.cleanup() }
        let url = tokenFile(desk.kb)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let target = desk.root.appendingPathComponent("elsewhere-token")
        let planted = String(repeating: "ab", count: 32)
        try Data(planted.utf8).write(to: target)
        #expect(chmod(target.path, 0o600) == 0)
        try FileManager.default.createSymbolicLink(at: url, withDestinationURL: target)
        #expect(DeskServer.loadTokenFile(url: url) == .rejected(.notRegularFile))
        let server = try makeServer(desk.kb)
        #expect(server.token != planted)
        #expect(try String(contentsOf: target, encoding: .utf8) == planted)
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        #expect(attrs[.type] as? FileAttributeType == .typeRegular)
    }

    @Test("a directory in place of the token file fails start safely")
    func directoryRejected() throws {
        let desk = try TempDesk.make()
        defer { desk.cleanup() }
        let url = tokenFile(desk.kb)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        #expect(DeskServer.loadTokenFile(url: url) == .rejected(.notRegularFile))
        #expect(throws: DeskServerError.tokenFileFailed) {
            _ = try makeServer(desk.kb)
        }
    }

    @Test("explicit rotation replaces the persisted token and the old cookie stops working")
    func rotationStillInvalidates() throws {
        let desk = try TempDesk.make()
        defer { desk.cleanup() }
        let server = try makeServer(desk.kb)
        try server.start()
        defer { server.stop() }
        let cookie = try signInCookie(server)
        try server.rotateToken()
        #expect(move(server, cookie: cookie).status == 401)
        #expect(DeskServer.loadTokenFile(url: tokenFile(desk.kb)) == .valid(server.token))
    }

    @Test("startDeskServer keeps the token on a fresh start and rotates only when asked")
    func managerFreshStartRotation() async throws {
        let desk = try TempDesk.make()
        defer { desk.cleanup() }
        let url = tokenFile(desk.kb)
        let (firstManager, first) = try await startManager(desk: desk, rotate: false)
        #expect(!first.contains("Write token rotated."))
        let initial = try #require(token(at: url))
        await firstManager.stopDeskServer()
        let (secondManager, _) = try await startManager(desk: desk, rotate: false)
        #expect(token(at: url) == initial)
        await secondManager.stopDeskServer()
        let (thirdManager, rotated) = try await startManager(desk: desk, rotate: true)
        #expect(rotated.contains("Write token rotated."))
        let after = try #require(token(at: url))
        #expect(after != initial)
        await thirdManager.stopDeskServer()
    }

    @Test("a rotate start that cannot bind leaves the token file alone")
    func rotateAfterBindOnly() async throws {
        let desk = try TempDesk.make()
        defer { desk.cleanup() }
        let url = tokenFile(desk.kb)
        let (running, _) = try await startManager(desk: desk, rotate: false)
        let live = try #require(token(at: url))
        let config = SecurityConfig.load(from: desk.kb.appendingPathComponent("security-config.json").path)
        let busyPort = try #require(config.deskPort)
        let analytics = ProjectAnalytics(knowledgeBasePath: desk.kb.path)
        let second = ProjectManager(knowledgeBasePath: desk.kb.path, extraAllowedBases: [desk.work.path])
        await second.initialize(analytics: analytics)
        await #expect(throws: DeskServerError.portInUse(busyPort)) {
            _ = try await second.startDeskServer(rotate: true)
        }
        #expect(token(at: url) == live)
        await running.stopDeskServer()
    }

    @Test("modes other than exactly 0600 are rejected")
    func exactModeOnly() throws {
        for mode: mode_t in [0o400, 0o500, 0o700, 0o640, 0o604] {
            let desk = try TempDesk.make()
            defer { desk.cleanup() }
            let first = try makeServer(desk.kb)
            let url = tokenFile(desk.kb)
            #expect(chmod(url.path, mode) == 0)
            #expect(DeskServer.loadTokenFile(url: url) == .rejected(.insecurePermissions))
            let second = try makeServer(desk.kb)
            #expect(second.token != first.token)
            #expect(try perms(url) == 0o600)
        }
    }

    @Test("a new desk directory is created 0700")
    func newDeskDirectoryPrivate() throws {
        let desk = try TempDesk.make()
        defer { desk.cleanup() }
        _ = try makeServer(desk.kb)
        let deskDir = desk.kb.appendingPathComponent("desk")
        #expect(try perms(deskDir) == 0o700)
        #expect(DeskServer.deskDirectoryWarning(deskDir) == nil)
    }

    @Test("a symlinked or group writable desk directory is reported")
    func unsafeDeskDirectoryWarned() throws {
        let desk = try TempDesk.make()
        defer { desk.cleanup() }
        let deskDir = desk.kb.appendingPathComponent("desk")
        let real = desk.root.appendingPathComponent("real-desk")
        try FileManager.default.createDirectory(at: real, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: deskDir, withDestinationURL: real)
        #expect(DeskServer.deskDirectoryWarning(deskDir) == "is a symlink")

        let other = try TempDesk.make()
        defer { other.cleanup() }
        let otherDesk = other.kb.appendingPathComponent("desk")
        try FileManager.default.createDirectory(at: otherDesk, withIntermediateDirectories: true)
        #expect(chmod(otherDesk.path, 0o775) == 0)
        #expect(DeskServer.deskDirectoryWarning(otherDesk) == "is writable by group or others")
        #expect(chmod(otherDesk.path, 0o755) == 0)
        #expect(DeskServer.deskDirectoryWarning(otherDesk) == nil)
    }

    private func token(at url: URL) -> String? {
        if case .valid(let value) = DeskServer.loadTokenFile(url: url) { return value }
        return nil
    }

    /// Each call is a separate manager, as a separate process would be. Ports are random to avoid clashes.
    private func startManager(desk: TempDesk, rotate: Bool) async throws -> (ProjectManager, String) {
        var lastError: Error?
        for _ in 0..<8 {
            let port = UInt16.random(in: 49_100...49_700)
            let config = SecurityConfig(
                allowedPaths: [desk.work.path],
                maxProjectNameLength: 100,
                maxDescriptionLength: 2000,
                maxNotesLength: 10_000,
                maxSearchPatternLength: 300,
                enableValidation: true,
                deskPort: port
            )
            try config.save(to: desk.kb.appendingPathComponent("security-config.json").path)
            let analytics = ProjectAnalytics(knowledgeBasePath: desk.kb.path)
            let manager = ProjectManager(knowledgeBasePath: desk.kb.path, extraAllowedBases: [desk.work.path])
            await manager.initialize(analytics: analytics)
            do {
                return (manager, try await manager.startDeskServer(rotate: rotate))
            } catch let error as DeskServerError {
                if case .portInUse = error {
                    lastError = error
                    continue
                }
                throw error
            }
        }
        throw lastError ?? DeskServerError.portInUse(0)
    }
}

final class MoveCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    func bump() { lock.lock(); count += 1; lock.unlock() }
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
}
