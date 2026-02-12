//
//  FilesTabView.swift
//  OpenCodeClient
//

import SwiftUI

struct FilesTabView: View {
    @Bindable var state: AppState

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Files",
                systemImage: "folder",
                description: Text("File browsing coming in Phase 3")
            )
            .navigationTitle("Files")
        }
    }
}
