import Foundation

/// Single source of truth for the published DPC version.
public enum CPCVersion {
    public static let string = "2.0.2"
    /// Hosts still key on this name. Prefer `preferredServerName` in new configs.
    public static let serverName = "project-coordinator"
    public static let preferredServerName = "dev-project-coordinator"
    public static let displayName = "Dev Project Coordinator"
    public static let slug = "Dev-Project-Coordinator"
}
