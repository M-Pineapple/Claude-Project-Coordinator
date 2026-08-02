import Foundation

public enum CoordinatorError: LocalizedError, Sendable {
    case invalidArguments
    case unknownTool
    case projectNotFound
    case fileSystemError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidArguments:
            return "Invalid arguments provided"
        case .unknownTool:
            return "Unknown tool requested"
        case .projectNotFound:
            return "Project not found"
        case .fileSystemError(let message):
            return "File system error: \(message)"
        }
    }
}
