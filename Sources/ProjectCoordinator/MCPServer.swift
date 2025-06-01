import Foundation

// MARK: - MCP Protocol Types

struct MCPRequest: Codable {
    let jsonrpc: String
    let method: String
    let params: [String: AnyCodable]?
    let id: Int?  // Make id optional for notifications
}

struct MCPResponse: Codable {
    let jsonrpc: String
    let result: AnyCodable?
    let error: MCPError?
    let id: Int
    
    init(result: AnyCodable?, error: MCPError?, id: Int) {
        self.jsonrpc = "2.0"
        self.result = result
        self.error = error
        self.id = id
    }
}

struct MCPError: Codable {
    let code: Int
    let message: String
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let bool as Bool:
            try container.encode(bool)
        case let dict as [String: Any]:
            let codableDict = dict.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        case let array as [Any]:
            let codableArray = array.map { AnyCodable($0) }
            try container.encode(codableArray)
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Error Types

enum CoordinatorError: LocalizedError {
    case invalidArguments
    case unknownTool
    case projectNotFound
    case fileSystemError(String)
    
    var errorDescription: String? {
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

// MARK: - MCP Server

class MCPServer {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let projectManager = ProjectManager()
    
    init() {
        encoder.outputFormatting = .sortedKeys  // Remove prettyPrinted
    }
    
    func start() async throws {
        // Initialize project manager
        await projectManager.initialize()
        
        // Use stdin/stdout for MCP communication
        await handleStdioConnection()
    }
    
    private func handleStdioConnection() async {
        // Don't print anything to stderr during normal operation
        
        while let line = readLine() {
            do {
                let request = try decoder.decode(MCPRequest.self, from: Data(line.utf8))
                await handleRequest(request)
            } catch {
                // Only send error response if we can parse enough to get an ID
                if let data = line.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let id = json["id"] as? Int {
                    let errorResponse = MCPResponse(
                        result: nil,
                        error: MCPError(code: -32700, message: "Parse error: \(error)"),
                        id: id
                    )
                    sendResponse(errorResponse)
                }
            }
        }
    }
    
    private func handleRequest(_ request: MCPRequest) async {
        // Handle notifications (no id) without response
        guard let id = request.id else {
            // This is a notification, process but don't respond
            switch request.method {
            case "initialized":
                // Client is ready, we can now accept requests
                break
            case "notifications/cancelled":
                // Request was cancelled, ignore
                break
            default:
                break
            }
            return
        }
        
        // Handle requests (with id) that need responses
        let response: MCPResponse
        switch request.method {
        case "initialize":
            response = handleInitialize(request, id: id)
        case "tools/list":
            response = handleToolsList(request, id: id)
        case "tools/call":
            response = await handleToolCall(request, id: id)
        default:
            response = MCPResponse(
                result: nil,
                error: MCPError(code: -32601, message: "Method not found"),
                id: id
            )
        }
        
        sendResponse(response)
    }
    
    private func sendResponse(_ response: MCPResponse) {
        do {
            let responseData = try encoder.encode(response)
            if let responseString = String(data: responseData, encoding: .utf8) {
                print(responseString)
                fflush(stdout)
            }
        } catch {
            // If we can't encode the response, there's not much we can do
        }
    }
    
    private func handleInitialize(_ request: MCPRequest, id: Int) -> MCPResponse {
        let result: [String: Any] = [
            "protocolVersion": "2024-11-05",  // Match client's protocol version
            "capabilities": [
                "tools": [:],
                "resources": [:]
            ],
            "serverInfo": [
                "name": "project-coordinator",
                "version": "1.0.0"
            ]
        ]
        return MCPResponse(result: AnyCodable(result), error: nil, id: id)
    }
    
    private func handleToolsList(_ request: MCPRequest, id: Int) -> MCPResponse {
        let tools: [[String: Any]] = [
            [
                "name": "list_projects",
                "description": "List all Xcode projects being tracked",
                "inputSchema": [
                    "type": "object",
                    "properties": [:],
                    "required": []
                ]
            ],
            [
                "name": "get_project_status",
                "description": "Get the current status and details of a specific project",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "projectName": [
                            "type": "string",
                            "description": "Name of the project"
                        ]
                    ],
                    "required": ["projectName"]
                ]
            ],
            [
                "name": "search_code_patterns",
                "description": "Search for code patterns across all projects",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "pattern": [
                            "type": "string",
                            "description": "Code pattern or keyword to search for"
                        ]
                    ],
                    "required": ["pattern"]
                ]
            ],
            [
                "name": "add_project",
                "description": "Add a new Xcode project to track",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string", "description": "Project name"],
                        "path": ["type": "string", "description": "Path to project"],
                        "description": ["type": "string", "description": "Project description"]
                    ],
                    "required": ["name", "path"]
                ]
            ],
            [
                "name": "update_project_status",
                "description": "Update the status or notes for a project",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "projectName": ["type": "string", "description": "Name of the project"],
                        "status": ["type": "string", "description": "New status"],
                        "notes": ["type": "string", "description": "Additional notes"]
                    ],
                    "required": ["projectName"]
                ]
            ]
        ]
        
        return MCPResponse(
            result: AnyCodable(["tools": tools]),
            error: nil,
            id: id
        )
    }
    
    private func handleToolCall(_ request: MCPRequest, id: Int) async -> MCPResponse {
        guard let params = request.params,
              let name = params["name"]?.value as? String,
              let arguments = params["arguments"]?.value as? [String: Any] else {
            return MCPResponse(
                result: nil,
                error: MCPError(code: -32602, message: "Invalid params"),
                id: id
            )
        }
        
        do {
            let result = try await executeTool(name: name, arguments: arguments)
            return MCPResponse(
                result: AnyCodable(["content": [["type": "text", "text": result]]]),
                error: nil,
                id: id
            )
        } catch {
            return MCPResponse(
                result: nil,
                error: MCPError(code: -32603, message: error.localizedDescription),
                id: id
            )
        }
    }
    
    private func executeTool(name: String, arguments: [String: Any]) async throws -> String {
        switch name {
        case "list_projects":
            return try await projectManager.listProjects()
        case "get_project_status":
            guard let projectName = arguments["projectName"] as? String else {
                throw CoordinatorError.invalidArguments
            }
            return try await projectManager.getProjectStatus(projectName: projectName)
        case "search_code_patterns":
            guard let pattern = arguments["pattern"] as? String else {
                throw CoordinatorError.invalidArguments
            }
            return try await projectManager.searchCodePatterns(pattern: pattern)
        case "add_project":
            guard let projectName = arguments["name"] as? String,
                  let path = arguments["path"] as? String else {
                throw CoordinatorError.invalidArguments
            }
            let description = arguments["description"] as? String
            return try await projectManager.addProject(name: projectName, path: path, description: description)
        case "update_project_status":
            guard let projectName = arguments["projectName"] as? String else {
                throw CoordinatorError.invalidArguments
            }
            let status = arguments["status"] as? String
            let notes = arguments["notes"] as? String
            return try await projectManager.updateProjectStatus(projectName: projectName, status: status, notes: notes)
        default:
            throw CoordinatorError.unknownTool
        }
    }
}
