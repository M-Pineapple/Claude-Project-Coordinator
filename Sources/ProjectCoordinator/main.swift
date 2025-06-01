import Foundation

// Simple main entry point without ArgumentParser
let server = MCPServer()

// Use a semaphore to keep the process alive
let semaphore = DispatchSemaphore(value: 0)

Task {
    do {
        try await server.start()
    } catch {
        if let data = "Error: \(error)\n".data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
        exit(1)
    }
}

// Keep the process running
semaphore.wait()
