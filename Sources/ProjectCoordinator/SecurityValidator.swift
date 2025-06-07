import Foundation

// MARK: - Security Validator

struct SecurityValidator {
    
    // MARK: - Configuration
    
    // Allowed project directory patterns (expandable)
    static let allowedBasePaths = [
        NSHomeDirectory() + "/Developer",
        NSHomeDirectory() + "/Documents", 
        NSHomeDirectory() + "/GitHub",
        NSHomeDirectory() + "/Projects",
        NSHomeDirectory() + "/Desktop/Development",
        NSHomeDirectory() + "/Xcode"
    ]
    
    // Maximum lengths to prevent DoS and maintain reasonable limits
    static let maxProjectNameLength = 100
    static let maxPathLength = 500
    static let maxDescriptionLength = 2000
    static let maxNotesLength = 10000
    static let maxSearchPatternLength = 300
    
    // MARK: - Path Validation
    
    /// Validates and sanitizes a project path
    static func validateProjectPath(_ path: String) throws -> String {
        // Basic length check
        guard !path.isEmpty else {
            throw SecurityError.emptyPath
        }
        
        guard path.count <= maxPathLength else {
            throw SecurityError.pathTooLong
        }
        
        // Expand tilde to home directory
        let expandedPath = path.replacingOccurrences(of: "~", with: NSHomeDirectory())
        
        // Normalize path (removes . and .. components safely)
        let normalizedPath = URL(fileURLWithPath: expandedPath).standardized.path
        
        // Check for obvious path traversal attempts
        let dangerousPatterns = ["../", "..\\", "/..", "\\..", "..%2F", "..%5C"]
        for pattern in dangerousPatterns {
            guard !path.contains(pattern) && !normalizedPath.contains(pattern) else {
                throw SecurityError.pathTraversalDetected
            }
        }
        
        // Verify it's within allowed directories
        let isAllowed = allowedBasePaths.contains { basePath in
            normalizedPath.hasPrefix(basePath) || basePath.hasPrefix(normalizedPath)
        }
        
        guard isAllowed else {
            throw SecurityError.pathNotAllowed(normalizedPath, allowedPaths: allowedBasePaths)
        }
        
        return normalizedPath
    }
    
    // MARK: - Project Name Validation
    
    /// Validates and sanitizes project name
    static func validateProjectName(_ name: String) throws -> String {
        // Check for empty name
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SecurityError.emptyProjectName
        }
        
        // Length check
        guard name.count <= maxProjectNameLength else {
            throw SecurityError.textTooLong("Project name", maxProjectNameLength)
        }
        
        // Allow alphanumeric characters, spaces, hyphens, underscores, and basic punctuation
        let allowedCharacterSet = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-_.()[]"))
        
        guard name.unicodeScalars.allSatisfy({ allowedCharacterSet.contains($0) }) else {
            throw SecurityError.invalidCharacters("Project name", "letters, numbers, spaces, hyphens, underscores, parentheses, and brackets")
        }
        
        // Prevent directory traversal in names
        guard !name.contains("..") && !name.contains("/") && !name.contains("\\") else {
            throw SecurityError.invalidFormat("Project name cannot contain path separators or parent directory references")
        }
        
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Text Content Validation
    
    /// Validates and sanitizes text input (descriptions, notes, status)
    static func validateText(_ text: String, maxLength: Int, fieldName: String) throws -> String {
        guard text.count <= maxLength else {
            throw SecurityError.textTooLong(fieldName, maxLength)
        }
        
        // Remove potentially dangerous content but keep most text intact
        var sanitized = text
        
        // Remove script-like content (basic XSS prevention)
        let scriptPatterns = ["<script", "</script>", "javascript:", "data:text/html", "vbscript:"]
        for pattern in scriptPatterns {
            sanitized = sanitized.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        
        // Remove null bytes and other control characters (except newlines and tabs)
        sanitized = sanitized.filter { char in
            let scalar = char.unicodeScalars.first!
            // Check for control characters manually for compatibility
            let value = scalar.value
            let isControlChar = (value < 32 && value != 9 && value != 10 && value != 13) || value == 127
            return !isControlChar
        }
        
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Search Pattern Validation
    
    /// Validates search patterns to prevent injection attacks
    static func validateSearchPattern(_ pattern: String) throws -> String {
        guard !pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SecurityError.emptySearchPattern
        }
        
        guard pattern.count <= maxSearchPatternLength else {
            throw SecurityError.textTooLong("Search pattern", maxSearchPatternLength)
        }
        
        // Check for potentially dangerous patterns
        let dangerousPatterns = [
            "$(", "`", "eval(", "exec(", "system(", "rm -", "del ", "format(",
            "$(IFS)", "${IFS}", "$IFS", "&&", "||", ";", "|", ">", "<"
        ]
        
        for dangerous in dangerousPatterns {
            guard !pattern.contains(dangerous) else {
                throw SecurityError.potentialInjection("Search pattern contains potentially dangerous content: \(dangerous)")
            }
        }
        
        return pattern.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - File Path Verification
    
    /// Additional verification that a path actually exists and is accessible
    static func verifyPathExists(_ path: String) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw SecurityError.pathDoesNotExist(path)
        }
        
        guard isDirectory.boolValue else {
            throw SecurityError.pathNotDirectory(path)
        }
        
        // Verify we can actually read the directory
        guard fileManager.isReadableFile(atPath: path) else {
            throw SecurityError.pathNotReadable(path)
        }
    }
}

// MARK: - Security Errors

enum SecurityError: LocalizedError {
    case emptyPath
    case pathTooLong
    case pathTraversalDetected
    case pathNotAllowed(String, allowedPaths: [String])
    case pathDoesNotExist(String)
    case pathNotDirectory(String)
    case pathNotReadable(String)
    case emptyProjectName
    case textTooLong(String, Int)
    case invalidCharacters(String, String)
    case invalidFormat(String)
    case emptySearchPattern
    case potentialInjection(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyPath:
            return "Project path cannot be empty"
        case .pathTooLong:
            return "Project path exceeds maximum allowed length of \(SecurityValidator.maxPathLength) characters"
        case .pathTraversalDetected:
            return "Path traversal attempt detected. Paths cannot contain '..' or similar patterns"
        case .pathNotAllowed(let path, let allowedPaths):
            return """
            Path '\(path)' is outside allowed directories.
            
            Allowed directories:
            \(allowedPaths.map { "  • \($0)" }.joined(separator: "\n"))
            
            To add a new allowed directory, update the SecurityValidator.allowedBasePaths array.
            """
        case .pathDoesNotExist(let path):
            return "The specified path does not exist: \(path)"
        case .pathNotDirectory(let path):
            return "The specified path is not a directory: \(path)"
        case .pathNotReadable(let path):
            return "Cannot read the specified directory: \(path)"
        case .emptyProjectName:
            return "Project name cannot be empty"
        case .textTooLong(let field, let maxLength):
            return "\(field) exceeds maximum length of \(maxLength) characters"
        case .invalidCharacters(let field, let allowed):
            return "\(field) contains invalid characters. Only \(allowed) are allowed"
        case .invalidFormat(let message):
            return "Invalid format: \(message)"
        case .emptySearchPattern:
            return "Search pattern cannot be empty"
        case .potentialInjection(let message):
            return "Security violation: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .pathNotAllowed(_, _):
            return "Move your project to one of the allowed directories, or update the security configuration to include your preferred directory."
        case .textTooLong(let field, let maxLength):
            return "Please shorten the \(field.lowercased()) to \(maxLength) characters or fewer."
        case .invalidCharacters:
            return "Please use only standard characters in the field."
        case .pathTraversalDetected:
            return "Use absolute paths or paths relative to your home directory without '..' components."
        default:
            return nil
        }
    }
}

// MARK: - Security Configuration

struct SecurityConfig: Codable {
    let allowedPaths: [String]
    let maxProjectNameLength: Int
    let maxDescriptionLength: Int
    let maxNotesLength: Int
    let maxSearchPatternLength: Int
    let enableValidation: Bool
    
    static let `default` = SecurityConfig(
        allowedPaths: SecurityValidator.allowedBasePaths,
        maxProjectNameLength: SecurityValidator.maxProjectNameLength,
        maxDescriptionLength: SecurityValidator.maxDescriptionLength,
        maxNotesLength: SecurityValidator.maxNotesLength,
        maxSearchPatternLength: SecurityValidator.maxSearchPatternLength,
        enableValidation: true
    )
    
    /// Load configuration from file, creating default if none exists
    static func load(from path: String) -> SecurityConfig {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let config = try? JSONDecoder().decode(SecurityConfig.self, from: data) else {
            // Create default config file
            let defaultConfig = SecurityConfig.default
            try? defaultConfig.save(to: path)
            return defaultConfig
        }
        return config
    }
    
    /// Save configuration to file
    func save(to path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: URL(fileURLWithPath: path))
    }
}
