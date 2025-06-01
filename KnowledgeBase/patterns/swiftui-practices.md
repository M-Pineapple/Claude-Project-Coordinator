# SwiftUI Patterns and Best Practices

## View Composition

### Basic View Structure
```swift
struct ContentView: View {
    @State private var isPresented = false
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                headerView
                contentSection
                actionButtons
            }
            .navigationTitle("My App")
            .toolbar {
                toolbarContent
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        Text("Welcome")
            .font(.largeTitle)
            .padding()
    }
    
    private var contentSection: some View {
        // Your content here
        EmptyView()
    }
    
    private var actionButtons: some View {
        HStack {
            Button("Cancel") { }
            Button("Save") { }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Add") { }
        }
    }
}
```

## State Management

### Using @StateObject with ViewModels
```swift
class ContentViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    @MainActor
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await fetchItems()
        } catch {
            self.error = error
        }
    }
    
    private func fetchItems() async throws -> [Item] {
        // Fetch logic here
        return []
    }
}
```

### Environment Values
```swift
// Define custom environment value
private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.standard
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// Usage
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.theme, .dark)
        }
    }
}
```

## Navigation Patterns

### NavigationStack with Path
```swift
struct NavigationExample: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                Button("Go to Detail") {
                    path.append(DetailDestination(id: 1))
                }
            }
            .navigationDestination(for: DetailDestination.self) { destination in
                DetailView(item: destination)
            }
        }
    }
}

struct DetailDestination: Hashable {
    let id: Int
}
```

## Animation Patterns

### Smooth Transitions
```swift
struct AnimatedView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.blue)
                .frame(height: isExpanded ? 200 : 100)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
            
            Button("Toggle") {
                isExpanded.toggle()
            }
        }
    }
}
```

### Matched Geometry Effect
```swift
struct MatchedGeometryExample: View {
    @Namespace private var animation
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            if !isExpanded {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue)
                    .matchedGeometryEffect(id: "shape", in: animation)
                    .frame(width: 100, height: 100)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue)
                    .matchedGeometryEffect(id: "shape", in: animation)
                    .frame(width: 200, height: 200)
            }
        }
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
    }
}
```

## Performance Optimization

### Lazy Loading
```swift
struct OptimizedList: View {
    let items: [Item]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(items) { item in
                    ItemRow(item: item)
                        .task {
                            // Load additional data if needed
                            await item.loadDetails()
                        }
                }
            }
        }
    }
}
```

### View Identity
```swift
// Use stable IDs for better performance
ForEach(items, id: \.id) { item in
    ItemView(item: item)
}

// Avoid recreating views unnecessarily
struct ItemView: View, Equatable {
    let item: Item
    
    static func == (lhs: ItemView, rhs: ItemView) -> Bool {
        lhs.item.id == rhs.item.id && 
        lhs.item.lastModified == rhs.item.lastModified
    }
    
    var body: some View {
        // View content
    }
}
```

## Common Pitfalls to Avoid

1. **Don't use @StateObject in child views** - Pass down as @ObservedObject
2. **Avoid heavy computation in body** - Use computed properties or cache results
3. **Don't ignore task cancellation** - Check for cancellation in async operations
4. **Be careful with GeometryReader** - It can cause layout issues if overused
5. **Use .task instead of .onAppear** for async work - It handles cancellation automatically
