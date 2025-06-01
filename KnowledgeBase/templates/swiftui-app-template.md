# SwiftUI App Template

## Project Structure

```
MyApp/
├── MyApp.swift                 # App entry point
├── ContentView.swift           # Main view
├── Models/
│   ├── DataModel.swift        # Core data models
│   └── NetworkModels.swift    # API response models
├── Views/
│   ├── Components/            # Reusable view components
│   ├── Screens/              # Full screen views
│   └── Modifiers/            # Custom view modifiers
├── ViewModels/
│   └── ContentViewModel.swift # Business logic
├── Services/
│   ├── NetworkService.swift   # API calls
│   └── DataService.swift      # Local data management
├── Resources/
│   ├── Assets.xcassets       # Images and colors
│   └── Localizable.strings   # Localization
└── Utilities/
    ├── Extensions/           # Swift extensions
    └── Helpers/             # Utility functions
```

## Base App Structure

```swift
// MyApp.swift
import SwiftUI

@main
struct MyApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    await appState.initialize()
                }
        }
    }
}

// AppState.swift
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    
    @MainActor
    func initialize() async {
        // App initialization logic
    }
}
```

## Basic Service Pattern

```swift
// NetworkService.swift
actor NetworkService {
    static let shared = NetworkService()
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    
    private init() {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }
    
    func fetch<T: Decodable>(_ type: T.Type, from endpoint: Endpoint) async throws -> T {
        let (data, response) = try await session.data(from: endpoint.url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.invalidResponse
        }
        
        return try decoder.decode(T.self, from: data)
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        }
    }
}
```

## ViewModel Template

```swift
// ContentViewModel.swift
@MainActor
class ContentViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText = ""
    
    private var loadTask: Task<Void, Never>?
    
    var filteredItems: [Item] {
        guard !searchText.isEmpty else { return items }
        return items.filter { 
            $0.title.localizedCaseInsensitiveContains(searchText) 
        }
    }
    
    func loadItems() {
        loadTask?.cancel()
        loadTask = Task {
            await performLoad()
        }
    }
    
    private func performLoad() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedItems = try await NetworkService.shared.fetch(
                [Item].self, 
                from: .items
            )
            
            // Check if task was cancelled
            if !Task.isCancelled {
                self.items = fetchedItems
            }
        } catch {
            if !Task.isCancelled {
                self.error = error
            }
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await performLoad()
    }
}
```

## View Template

```swift
// ContentView.swift
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var showingDetail = false
    @State private var selectedItem: Item?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.items.isEmpty {
                    emptyStateView
                } else {
                    itemsList
                }
            }
            .navigationTitle("My App")
            .searchable(text: $viewModel.searchText)
            .refreshable {
                await viewModel.refresh()
            }
            .toolbar {
                toolbarContent
            }
            .task {
                viewModel.loadItems()
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No Items")
                .font(.title2)
            Text("Pull to refresh or add new items")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var itemsList: some View {
        List(viewModel.filteredItems) { item in
            ItemRow(item: item)
                .onTapGesture {
                    selectedItem = item
                    showingDetail = true
                }
        }
        .sheet(isPresented: $showingDetail) {
            if let item = selectedItem {
                ItemDetailView(item: item)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                // Add action
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}
```

## Common Extensions

```swift
// View+Extensions.swift
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), 
            to: nil, 
            from: nil, 
            for: nil
        )
    }
    
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool, 
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Color+Extensions.swift
extension Color {
    static let theme = Color.Theme()
    
    struct Theme {
        let primary = Color("PrimaryColor")
        let secondary = Color("SecondaryColor")
        let background = Color("BackgroundColor")
        let surface = Color("SurfaceColor")
    }
}
```

## App Configuration

```swift
// Configuration.swift
enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }
    
    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw Error.missingKey
        }
        
        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}

// Usage:
// let apiKey: String = try Configuration.value(for: "API_KEY")
```

## Testing Template

```swift
// ContentViewModelTests.swift
import XCTest
@testable import MyApp

@MainActor
final class ContentViewModelTests: XCTestCase {
    var viewModel: ContentViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ContentViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testLoadItems() async {
        // Given
        XCTAssertTrue(viewModel.items.isEmpty)
        
        // When
        await viewModel.performLoad()
        
        // Then
        XCTAssertFalse(viewModel.items.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
}
```

This template provides a solid foundation for a SwiftUI app with proper architecture, error handling, and testing setup.
