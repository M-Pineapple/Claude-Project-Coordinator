import Foundation
import MCP

/// Boots the MCP server with CPC tools using the official Swift SDK.
public enum MCPBootstrap {
    public static func makeServer(
        projectManager: ProjectManager,
        analytics: ProjectAnalytics
    ) async -> Server {
        let server = Server(
            name: CPCVersion.serverName,
            version: CPCVersion.string,
            capabilities: .init(
                tools: .init(listChanged: false)
            )
        )

        await server.withMethodHandler(ListTools.self) { _ in
            .init(tools: Self.tools)
        }

        await server.withMethodHandler(CallTool.self) { params in
            do {
                let text = try await Self.executeTool(
                    name: params.name,
                    arguments: params.arguments ?? [:],
                    projectManager: projectManager,
                    analytics: analytics
                )
                return .init(
                    content: [.text(text: text, annotations: nil, _meta: nil)],
                    isError: false
                )
            } catch {
                return .init(
                    content: [.text(text: error.localizedDescription, annotations: nil, _meta: nil)],
                    isError: true
                )
            }
        }

        return server
    }

    public static func run() async throws {
        let knowledgeBasePath = KnowledgeBasePaths.resolve()
        let projectManager = ProjectManager(knowledgeBasePath: knowledgeBasePath)
        let analytics = ProjectAnalytics(knowledgeBasePath: knowledgeBasePath)

        await projectManager.initialize(analytics: analytics)

        let server = await makeServer(projectManager: projectManager, analytics: analytics)
        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }

    // MARK: - Tool catalogue

    private static var tools: [Tool] {
        [
            Tool(
                name: "list_projects",
                description: "List all Xcode projects being tracked",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([:]),
                    "required": .array([])
                ])
            ),
            Tool(
                name: "get_project_status",
                description: "Get the current status and details of a specific project",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "projectName": .object([
                            "type": .string("string"),
                            "description": .string("Name of the project")
                        ])
                    ]),
                    "required": .array([.string("projectName")])
                ])
            ),
            Tool(
                name: "search_code_patterns",
                description: "Search for code patterns across all projects",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "pattern": .object([
                            "type": .string("string"),
                            "description": .string("Code pattern or keyword to search for")
                        ])
                    ]),
                    "required": .array([.string("pattern")])
                ])
            ),
            Tool(
                name: "add_project",
                description: "Add a new Xcode project to track",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "name": .object([
                            "type": .string("string"),
                            "description": .string("Project name")
                        ]),
                        "path": .object([
                            "type": .string("string"),
                            "description": .string("Path to project")
                        ]),
                        "description": .object([
                            "type": .string("string"),
                            "description": .string("Project description")
                        ])
                    ]),
                    "required": .array([.string("name"), .string("path")])
                ])
            ),
            Tool(
                name: "update_project_status",
                description: "Update the status or notes for a project",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "projectName": .object([
                            "type": .string("string"),
                            "description": .string("Name of the project")
                        ]),
                        "status": .object([
                            "type": .string("string"),
                            "description": .string("New status")
                        ]),
                        "notes": .object([
                            "type": .string("string"),
                            "description": .string("Additional notes")
                        ])
                    ]),
                    "required": .array([.string("projectName")])
                ])
            ),
            Tool(
                name: "get_project_timeline",
                description: "Get status timeline and duration for a project",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "projectName": .object([
                            "type": .string("string"),
                            "description": .string("Name of the project")
                        ])
                    ]),
                    "required": .array([.string("projectName")])
                ])
            ),
            Tool(
                name: "get_activity_heatmap",
                description: "Show project activity heat map for recent days",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "days": .object([
                            "type": .string("integer"),
                            "description": .string("Number of days to analyze (default: 7)")
                        ])
                    ]),
                    "required": .array([])
                ])
            ),
            Tool(
                name: "get_technology_trends",
                description: "Analyze technology usage across all projects",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([:]),
                    "required": .array([])
                ])
            ),
            Tool(
                name: "get_project_health",
                description: "Get health scores and recommendations for all projects",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([:]),
                    "required": .array([])
                ])
            ),
        ]
    }

    // MARK: - Tool dispatch

    private static func executeTool(
        name: String,
        arguments: [String: Value],
        projectManager: ProjectManager,
        analytics: ProjectAnalytics
    ) async throws -> String {
        switch name {
        case "list_projects":
            return try await projectManager.listProjects()

        case "get_project_status":
            guard let projectName = arguments["projectName"]?.stringValue else {
                throw CoordinatorError.invalidArguments
            }
            return try await projectManager.getProjectStatusSecure(projectName: projectName)

        case "search_code_patterns":
            guard let pattern = arguments["pattern"]?.stringValue else {
                throw CoordinatorError.invalidArguments
            }
            return try await projectManager.searchCodePatternsSecure(pattern: pattern)

        case "add_project":
            guard let projectName = arguments["name"]?.stringValue,
                  let path = arguments["path"]?.stringValue else {
                throw CoordinatorError.invalidArguments
            }
            let description = arguments["description"]?.stringValue
            let result = try await projectManager.addProjectSecure(
                name: projectName,
                path: path,
                description: description
            )
            await analytics.recordActivity(for: projectName, type: .accessed)
            return result

        case "update_project_status":
            guard let projectName = arguments["projectName"]?.stringValue else {
                throw CoordinatorError.invalidArguments
            }
            let status = arguments["status"]?.stringValue
            let notes = arguments["notes"]?.stringValue

            if let newStatus = status {
                await analytics.updateStatus(for: projectName, newStatus: newStatus)
            }
            if notes != nil {
                await analytics.recordActivity(for: projectName, type: .noteAdded)
            }

            return try await projectManager.updateProjectStatusSecure(
                projectName: projectName,
                status: status,
                notes: notes
            )

        case "get_project_timeline":
            guard let projectName = arguments["projectName"]?.stringValue else {
                throw CoordinatorError.invalidArguments
            }
            return await analytics.getStatusDuration(for: projectName)
                ?? "No timeline data available for \(projectName)"

        case "get_activity_heatmap":
            let days = arguments["days"]?.intValue ?? 7
            return await analytics.getActivityHeatMap(days: days)

        case "get_technology_trends":
            return await analytics.getTechnologyTrends()

        case "get_project_health":
            return await analytics.getProjectHealthReport()

        default:
            throw CoordinatorError.unknownTool
        }
    }
}
