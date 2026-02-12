//
//  FileContentView.swift
//  OpenCodeClient
//

import SwiftUI

struct FileContentView: View {
    @Bindable var state: AppState
    let filePath: String
    @State private var content: String?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var showPreview = true  // true = Markdown preview, false = raw/editor

    private var isMarkdown: Bool {
        filePath.lowercased().hasSuffix(".md") || filePath.lowercased().hasSuffix(".markdown")
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = loadError {
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(err))
            } else if let text = content {
                contentView(text: text)
            } else {
                ContentUnavailableView("No content", systemImage: "doc.text")
            }
        }
        .navigationTitle(filePath.split(separator: "/").last.map(String.init) ?? filePath)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isMarkdown {
                ToolbarItem(placement: .primaryAction) {
                    Button(showPreview ? "Markdown" : "Preview") {
                        showPreview.toggle()
                    }
                }
            }
        }
        .onAppear {
            loadContent()
        }
        .refreshable {
            loadContent()
        }
    }

    @ViewBuilder
    private func contentView(text: String) -> some View {
        if isMarkdown && showPreview {
            MarkdownPreviewView(text: text)
        } else {
            CodeView(text: text, path: filePath)
        }
    }

    private func loadContent() {
        isLoading = true
        loadError = nil
        print("[FileContentView] loadContent path=\(filePath)")
        Task {
            do {
                let fc = try await state.loadFileContent(path: filePath)
                await MainActor.run {
                    content = fc.text ?? fc.content
                    isLoading = false
                    print("[FileContentView] loaded type=\(fc.type) contentLen=\(content?.count ?? 0)")
                    if content == nil && fc.type == "binary" {
                        loadError = "Binary file"
                    }
                }
            } catch {
                await MainActor.run {
                    loadError = error.localizedDescription
                    isLoading = false
                    print("[FileContentView] load failed: \(error)")
                }
            }
        }
    }
}

/// Simple code view with line numbers
struct CodeView: View {
    let text: String
    let path: String

    private var lines: [String] {
        text.components(separatedBy: .newlines)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(i + 1)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .trailing)
                            Text(line)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

/// Markdown preview. Native AttributedString 不支持 tables，复杂内容可能解析失败。
///
/// Key insight: SwiftUI's `.full` Markdown parsing treats single \n as soft breaks
/// (standard Markdown spec). To preserve visible line breaks, we convert single \n
/// to Markdown hard breaks (two trailing spaces + \n), while keeping \n\n as paragraph breaks.
struct MarkdownPreviewView: View {
    let text: String

    /// Pre-process: convert single newlines to Markdown hard breaks, preserve paragraph breaks.
    private var processedMarkdown: String {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        // Split by paragraph breaks (double newline), process each paragraph separately
        let paragraphs = normalized.components(separatedBy: "\n\n")
        let processed = paragraphs.map { paragraph in
            // Within each paragraph, convert single \n to hard break (two spaces + \n)
            paragraph.replacingOccurrences(of: "\n", with: "  \n")
        }
        return processed.joined(separator: "\n\n")
    }

    var body: some View {
        ScrollView {
            Group {
                // Try full Markdown parsing with pre-processed hard breaks
                if let attr = try? AttributedString(markdown: processedMarkdown, options: .init(interpretedSyntax: .full)) {
                    Text(attr)
                        .textSelection(.enabled)
                // Fallback: inline-only preserving whitespace (no block formatting but line breaks work)
                } else if let attr = try? AttributedString(markdown: processedMarkdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                    Text(attr)
                        .textSelection(.enabled)
                } else {
                    // 最终回退：按行渲染
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(text.components(separatedBy: .newlines).enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}
