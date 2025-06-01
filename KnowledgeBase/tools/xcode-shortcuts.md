# Essential Xcode Shortcuts & Tips

## Navigation Shortcuts

### File Navigation
- **Cmd + Shift + O**: Open Quickly (search for any file, type, or symbol)
- **Cmd + Control + ←/→**: Navigate back/forward through file history
- **Cmd + Shift + J**: Reveal current file in navigator
- **Cmd + 1-9**: Switch between navigator tabs
- **Cmd + 0**: Show/hide navigator
- **Cmd + Option + 0**: Show/hide inspector

### Code Navigation
- **Cmd + Click**: Jump to definition
- **Control + 6**: Show document items (methods/properties menu)
- **Cmd + L**: Go to line number
- **Cmd + Shift + F**: Find in project
- **Cmd + E**: Use selection for find
- **Cmd + G**: Find next
- **Cmd + Shift + G**: Find previous

## Editing Shortcuts

### Code Editing
- **Cmd + /**: Comment/uncomment line
- **Control + I**: Re-indent selected code
- **Cmd + ]**: Indent right
- **Cmd + [**: Indent left
- **Option + Cmd + [/]**: Move line up/down
- **Cmd + D**: Duplicate line
- **Control + K**: Delete to end of line

### Multi-cursor Editing
- **Control + Shift + Click**: Add cursor
- **Control + Shift + ↑/↓**: Add cursor above/below
- **Option + Drag**: Column selection

### Refactoring
- **Cmd + Shift + A**: Show actions menu
- **Control + Cmd + E**: Edit all in scope
- **Cmd + Option + E**: Rename everywhere
- **Control + Cmd + ↑**: Extract to method/variable

## Build & Run

- **Cmd + B**: Build
- **Cmd + R**: Run
- **Cmd + .**: Stop
- **Cmd + Shift + K**: Clean build folder
- **Cmd + U**: Run tests
- **Cmd + Shift + B**: Analyze

## Debugging

- **Cmd + \**: Toggle breakpoint
- **Cmd + Y**: Toggle breakpoint enable/disable
- **Cmd + Option + \**: Add symbolic breakpoint
- **F6**: Step over
- **F7**: Step into
- **F8**: Step out
- **Control + Cmd + Y**: Continue

## Interface Builder

- **Cmd + =**: Size to fit content
- **Cmd + Option + =**: Update frames
- **Control + Drag**: Create outlets/actions
- **Option + Drag**: Duplicate view
- **Cmd + Delete**: Delete selected view

## Testing

- **Cmd + U**: Run all tests
- **Control + Option + Cmd + U**: Run current test
- **Control + Option + Cmd + G**: Run last test again

## Window Management

- **Cmd + Shift + Y**: Show/hide debug area
- **Cmd + Option + Enter**: Show assistant editor
- **Cmd + Enter**: Show standard editor
- **Cmd + Option + Shift + Enter**: Show version editor
- **Control + Cmd + F**: Enter/exit full screen

## Productivity Tips

### Quick Actions
1. **Fix All Issues**: Control + Option + Cmd + F
2. **Jump Bar Navigation**: Control + 1-6 for different sections
3. **Open in Assistant**: Option + Click on file
4. **Quick Help**: Option + Click on symbol

### Code Snippets
Create custom snippets:
1. Select code
2. Right-click → Create Code Snippet
3. Assign shortcut text
4. Use by typing shortcut + Tab

### Behaviors
Set up custom behaviors in Preferences → Behaviors:
- "Testing Starts" → Show debug navigator + console
- "Build Fails" → Show issue navigator + play sound
- Custom behavior with keyboard shortcut

### Build Time Optimization
1. **Show build times**: 
   - Add `-Xfrontend -debug-time-function-bodies` to Other Swift Flags
2. **Parallel builds**: 
   - Preferences → Locations → Advanced → Custom
3. **Derived Data**: 
   - Clean regularly: `rm -rf ~/Library/Developer/Xcode/DerivedData`

### Debugging Tips
1. **LLDB Commands**:
   - `po variableName`: Print object
   - `p variableName`: Print primitive
   - `expr variableName = newValue`: Change value
   - `bt`: Backtrace
   - `frame variable`: Show all variables

2. **Breakpoint Actions**:
   - Add log message
   - Play sound
   - Run debugger command
   - Continue after evaluating

3. **View Debugging**:
   - Debug → View Debugging → Capture View Hierarchy
   - Inspect view properties and constraints

### Performance
1. **Instruments Shortcuts**:
   - Cmd + I: Profile in Instruments
   - Common templates: Time Profiler, Allocations, Leaks

2. **Memory Graph**:
   - Debug → Debug Memory Graph
   - Find retain cycles and memory leaks

Remember: You can customize any shortcut in Xcode → Preferences → Key Bindings
