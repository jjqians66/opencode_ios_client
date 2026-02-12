//
//  ContentView.swift
//  OpenCodeClient
//

import SwiftUI

struct ContentView: View {
    @State private var state = AppState()

    var body: some View {
        TabView {
            ChatTabView(state: state)
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }

            FilesTabView(state: state)
                .tabItem {
                    Label("Files", systemImage: "folder")
                }

            SettingsTabView(state: state)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .task {
            await state.refresh()
            if state.isConnected {
                state.connectSSE()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await state.refresh()
                if state.isConnected {
                    state.connectSSE()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            state.disconnectSSE()
        }
    }
}

#Preview {
    ContentView()
}
