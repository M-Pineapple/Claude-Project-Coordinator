import Foundation
import ProjectCoordinator

@main
struct ProjectCoordinatorMain {
    static func main() async {
        do {
            try await MCPBootstrap.run()
        } catch {
            CPCLog.error("Fatal: \(error.localizedDescription)")
            exit(1)
        }
    }
}
