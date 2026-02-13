# OpenCode iOS Client - Code Review

**Review Date**: 2026-02-13
**Reviewer**: AI Assistant
**Scope**: Full codebase review after Phase 3 completion

## 1. Architecture Overview

The codebase follows a reasonably clean architecture for a SwiftUI iOS application:

```
├── Models/           # Data models (Message, Session, TodoItem, ModelPreset)
├── Services/         # Network layer (APIClient, SSEClient, AudioRecorder, AIBuildersAudioClient)
├── Stores/           # State stores (SessionStore, MessageStore, FileStore, TodoStore)
├── Utils/            # Utilities (PathNormalizer, KeychainHelper)
├── Views/
│   ├── Chat/         # Chat-related views (MessageRowView, ToolPartView, etc.)
│   └── ...           # Other feature views
├── AppState.swift    # Main coordinator/observable state
└── ContentView.swift # Root view with platform-adaptive layout
```

### Key Patterns Used

- **MVVM-ish**: Views bind to `AppState` which acts as both model and view-model
- **Observation Framework**: Uses Swift's new `@Observable` macro (iOS 17+)
- **Store Pattern**: Extracted stores (`SessionStore`, `MessageStore`, etc.) for domain state
- **Actor-based Networking**: `APIClient` and `SSEClient` use `actor` for thread safety

---

## 2. Strengths

### 2.1 Clean State Management

The recent extraction of domain stores (`SessionStore`, `MessageStore`, `FileStore`, `TodoStore`) from `AppState` is a good architectural improvement:
- Clear separation of concerns
- `AppState` acts as a façade, exposing computed properties that delegate to stores
- Maintains backward compatibility with existing view bindings

### 2.2 Platform-Adaptive UI

The `ContentView.swift` handles iPhone/iPad differences cleanly:
- `horizontalSizeClass` determines split vs tab layout
- iPad uses `NavigationSplitView` with three columns
- iPhone uses traditional `TabView`

### 2.3 Robust Error Handling

- `APIError` enum covers common failure modes
- `PartStateBridge` handles flexible API response formats gracefully
- `loadMessages` has multiple fallback paths for decoding edge cases

### 2.4 Good Use of Modern Swift

- Async/await throughout
- Actors for concurrent access
- `@Observable` macro
- Structured concurrency with `Task`

---

## 3. Areas for Improvement

### 3.1 AppState Still Too Large

**Issue**: `AppState.swift` is ~500+ lines and handles too many responsibilities:
- Server configuration and validation
- Session management
- Message handling
- File operations
- Todo management
- SSE event processing
- Audio recording coordination
- UI state (selected tab, draft inputs, model selection)

**Recommendation**: Consider extracting into separate services/coordinators:
- `SessionCoordinator` - session CRUD, switching
- `MessageCoordinator` - message loading, sending, streaming
- `FileCoordinator` - file tree, content loading
- Keep `AppState` focused on UI state and coordination

### 3.2 Inconsistent Error Presentation

**Issue**: Errors are handled differently across the app:
- `connectionError` string in AppState
- Alert bindings in views (`showErrorAlert`)
- Inline error messages in some views
- Silent failures in some async methods

**Recommendation**: Establish a consistent error presentation pattern:
- Define an `AppError` enum with user-friendly descriptions
- Create a centralized `ErrorHandling` mechanism
- Consider a toast/banner system for transient errors

### 3.3 Magic Numbers and Strings

**Issue**: Hard-coded values scattered throughout:
- Column width fractions (`1/6`, `5/12`)
- Animation durations
- API paths
- Color opacity values

**Recommendation**: Extract to constants:
```swift
enum LayoutConstants {
    static let sidebarWidthFraction = 1.0 / 6.0
    static let previewWidthFraction = 5.0 / 12.0
}
```

### 3.4 Test Coverage Gaps

**Current Coverage**: Models and utilities are well-tested
**Missing**: 
- UI testing (only placeholder `OpenCodeClientUITests`)
- Integration tests for SSE handling
- ViewModel/Coordinator logic tests

**Recommendation**: Add tests for:
- `AppState` session switching behavior
- `PathNormalizer` edge cases (already good)
- SSE event parsing and state updates

### 3.5 View Decomposition Opportunities

Some views are large and could benefit from decomposition:

**`ChatTabView.swift`** (~460 lines):
- Contains toolbar logic, message list, input handling, recording
- Could extract: `ChatToolbar`, `MessageList`, `ChatInputArea`

**`MessageRowView.swift`**:
- Handles many part types inline
- Could extract part rendering to dedicated views (already partially done with `ToolPartView`, `PatchPartView`)

---

## 4. Specific Code Issues

### 4.1 Memory Leaks Risk

**Location**: `AppState.swift` - SSE connection handling

```swift
func connectSSE() {
    sseTask = Task { [weak self] in
        // ...
    }
}
```

**Issue**: The `[weak self]` is correct, but there's no explicit cancellation handling when `AppState` is deallocated.

**Recommendation**: Ensure `disconnectSSE()` is called in `deinit` or use `Task` cancellation more explicitly.

### 4.2 Race Condition Potential

**Location**: Session switching and message loading

```swift
func selectSession(_ session: Session) {
    // Synchronous state clearing
    messages = []
    partsByMessage = [:]
    currentSessionID = session.id
    // Then async loading
    Task {
        await loadMessages()
    }
}
```

**Issue**: If user rapidly switches sessions, multiple `loadMessages()` tasks could race.

**Recommendation**: Use a task ID or cancellation token:
```swift
private var loadTaskID = UUID()
func selectSession(_ session: Session) {
    loadTaskID = UUID()
    let currentID = loadTaskID
    Task {
        guard currentID == loadTaskID else { return }
        await loadMessages()
    }
}
```

### 4.3 Force-Unwrap in PathNormalizer

**Location**: `PathNormalizer.swift`

Generally safe in practice but consider adding guardrails for edge cases.

### 4.4 Hardcoded Default Server

**Location**: `APIClient.swift`

```swift
static let defaultServer = "192.168.180.128:4096"
```

**Issue**: Contains a specific LAN IP that may not be relevant for all users.

**Recommendation**: Use `localhost:4096` or make it configurable via build settings.

---

## 5. Refactoring Priorities

### High Priority

1. **Extract coordinators from AppState** - Reduces complexity and improves testability
2. **Add session switching race condition protection** - Prevents UI glitches
3. **Standardize error presentation** - Improves UX consistency

### Medium Priority

4. **Extract constants** - Improves maintainability
5. **Decompose ChatTabView** - Easier to test and modify
6. **Add integration tests** - Catches regressions

### Low Priority

7. **Review default server handling** - Minor DX improvement
8. **Consider dependency injection** - For better testability (may be overkill for current scope)

---

## 6. Positive Observations

- **Documentation**: PRD and RFC are well-maintained and synchronized with code
- **Incremental Progress**: Clear commit history following the documented phases
- **Consistent Naming**: Clear naming conventions throughout
- **Localization Ready**: Chinese UI text is centralized (could be extracted to Localizable.strings if needed)
- **Accessibility**: `.help()` modifiers on buttons, `.textSelection(.enabled)` where appropriate

---

## 7. Conclusion

The codebase is in good shape overall. The architecture is reasonable for the app's complexity, and recent improvements (store extraction, iPad three-column layout) show good iterative development practices.

The main recommendations are:
1. Continue extracting responsibilities from `AppState`
2. Add race condition protection for async operations
3. Establish consistent error handling patterns
4. Incrementally add test coverage for state management logic

No critical issues were found that require immediate attention. The code is production-ready for personal/small-team use.
