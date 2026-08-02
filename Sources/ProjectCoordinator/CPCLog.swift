import Foundation

/// Logging helpers that never write to stdout.
/// MCP stdio transport owns stdout for JSON-RPC frames.
public enum CPCLog {
    public static func info(_ message: String) {
        write(prefix: "INFO", message: message)
    }

    public static func warning(_ message: String) {
        write(prefix: "WARN", message: message)
    }

    public static func error(_ message: String) {
        write(prefix: "ERROR", message: message)
    }

    private static func write(prefix: String, message: String) {
        let line = "[CPC][\(prefix)] \(message)\n"
        if let data = line.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}
