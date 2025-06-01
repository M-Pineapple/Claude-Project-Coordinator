# Swift Code Patterns

## Async/Await Patterns

### Basic Async Function
```swift
func fetchData() async throws -> [DataModel] {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([DataModel].self, from: data)
}
```

### Task Groups
```swift
await withTaskGroup(of: Result<Data, Error>.self) { group in
    for url in urls {
        group.addTask {
            await self.fetchItem(from: url)
        }
    }
}
```

## Error Handling

### Custom Error Types
```swift
enum AppError: LocalizedError {
    case networkError(String)
    case decodingError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError:
            return "Failed to decode response"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}
```