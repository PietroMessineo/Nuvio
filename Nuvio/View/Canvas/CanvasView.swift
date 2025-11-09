//
//  CanvasView.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/6/25.
//

import SwiftUI
import UniformTypeIdentifiers

enum CanvasContentType { case empty, pdf, notes, browser, ai }

struct CanvasPane: View {
    let canvasIndex: Int
    @Binding var contentType: CanvasContentType
    @Binding var selectedPDF: URL?
    @Binding var notes: String
    @Binding var browserAddress: String
    @Binding var browserNavigate: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var goBackTrigger: Bool
    @Binding var goForwardTrigger: Bool
    @Binding var messageContent: [AiMessageChunk]

    var onPickDocument: () -> Void
    var onOpenNotes: () -> Void
    var onOpenBrowser: () -> Void
    var onSwitchCanvas: (Int) -> Void
    var onOpenAi: () -> Void

    var body: some View {
        ZStack {
            switch contentType {
            case .empty:
                CanvasOverlayMenu(
                    onPickDocument: onPickDocument,
                    onOpenNotes: onOpenNotes,
                    onOpenBrowser: onOpenBrowser,
                    onOpenAi: onOpenAi
                )
            case .pdf:
                if let url = selectedPDF {
                    PDFKitView(url: url)
                        .clipShape(RoundedRectangle(cornerRadius: 48))
                }
            case .notes:
                CanvasNotesView(notes: $notes)
            case .browser:
                CanvasBrowserView(
                    browserAddress: $browserAddress,
                    browserNavigate: $browserNavigate,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    goBackTrigger: $goBackTrigger,
                    goForwardTrigger: $goForwardTrigger
                )
            case .ai:
                CanvasAiView(messageContent: $messageContent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "F1F1F1"))
        .clipShape(RoundedRectangle(cornerRadius: 48))
        .overlay(alignment: .topTrailing) {
            HStack {
                Button {
                    onSwitchCanvas(canvasIndex)
                } label: {
                    Image(systemName: "checkmark.rectangle.stack")
                        .foregroundStyle(Color.primary)
                        .padding()
                        .glassEffect(.regular.interactive(), in: Circle())
                }
            }
            .padding()
        }
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 48))
    }
}

struct CanvasBrowserView: View {
    @Binding var browserAddress: String
    @Binding var browserNavigate: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var goBackTrigger: Bool
    @Binding var goForwardTrigger: Bool
    
    var body: some View {
        ModernWebBrowserView(urlText: $browserAddress)
    }
}

struct CanvasNotesView: View {
    @Binding var notes: String
    
    var body: some View {
        TextEditor(text: $notes)
            .font(.system(size: 20))
            .padding(24)
            .scrollContentBackground(.hidden)
            .background(Color(hex: "F1F1F1"))
            .clipShape(RoundedRectangle(cornerRadius: 48))
    }
}

struct CanvasAiView: View {
    @StateObject private var chatStreamService = ChatStreamService()
    
    @State var promptText: String = ""
    @Binding var messageContent: [AiMessageChunk]
    
    var body: some View {
        VStack(alignment: .leading) {
            List(chatStreamService.messages) { message in
                Section {
                    // Show progress indicator on left side
                    if message.role == "loading" {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if message.role == "assistant" {
                        Text(message.content)
                            .multilineTextAlignment(.leading)
                    } else {
                        ZStack {
                            Text(message.content)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 19)
                        .background(Color.init(uiColor: .systemGray4))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.leading, 160)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            
            HStack(alignment: .bottom) {
                TextField(text: $promptText, axis: .vertical) {
                    Text("Ask anything")
                }
                
                Button {
                    chatStreamService.messages.append(AiMessageChunk(id: UUID().uuidString, role: "user", content: promptText, type: "input_text"))
                    messageContent = chatStreamService.messages
                    chatStreamService.startStream(messages: messageContent)
                    promptText = ""
                } label: {
                    Image(systemName: "arrow.up")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 16)
                .background(Color.blue)
                .clipShape(Capsule())
                .disabled(promptText.isEmpty || promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity((promptText.isEmpty || promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.5 : 1)
            }
            .padding(.leading, 21)
            .padding(.trailing, 7)
            .padding(.vertical, 7)
            .background(Color.init(uiColor: .systemGray4))
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .padding(20)
        .background(Color(hex: "F1F1F1"))
        .onAppear {
            // Initialize the chat service with existing messages
            chatStreamService.messages = messageContent
        }
        .onChange(of: chatStreamService.messages) { _, newMessages in
            // Sync local chat service changes back to the binding
            messageContent = newMessages
        }
    }
}

struct CanvasSwitcherView: View {
    let sourceCanvasIndex: Int
    
    // Canvas data for preview
    let contentTypes: [CanvasContentType]
    let notes: [String]
    let selectedPDFs: [URL?]
    let browserAddresses: [String]
    
    let onSwitch: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Switch Canvas \(sourceCanvasIndex + 1)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Tap a canvas to switch positions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(0..<3, id: \.self) { index in
                        CanvasPreviewCard(
                            canvasIndex: index,
                            contentType: contentTypes[index],
                            notes: notes[index],
                            selectedPDF: selectedPDFs[index],
                            browserAddress: browserAddresses[index],
                            isSource: index == sourceCanvasIndex,
                            onTap: {
                                if index != sourceCanvasIndex {
                                    onSwitch(index)
                                    dismiss()
                                }
                            }
                        )
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Canvas Switcher")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CanvasPreviewCard: View {
    let canvasIndex: Int
    let contentType: CanvasContentType
    let notes: String
    let selectedPDF: URL?
    let browserAddress: String
    let isSource: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Canvas preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#F1F1F1"))
                        .frame(height: 120)
                    
                    // Preview content based on canvas type
                    Group {
                        switch contentType {
                        case .empty:
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text("Empty")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        case .pdf:
                            VStack {
                                Image(systemName: "document")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "80C5FB"))
                                Text("Document")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        case .notes:
                            VStack {
                                Image(systemName: "pencil.and.scribble")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "FBD680"))
                                Text("Notes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !notes.isEmpty {
                                    Text(notes.prefix(20) + (notes.count > 20 ? "..." : ""))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        case .browser:
                            VStack {
                                Image(systemName: "globe")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "A8D2D1"))
                                Text("Browser")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !browserAddress.isEmpty {
                                    Text(browserAddress)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        case .ai:
                            VStack {
                                Image(systemName: "brain")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "#A080FB"))
                                Text("AI")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Source indicator
                    if isSource {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white, .blue)
                                    .font(.title2)
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                
                // Canvas label
                Text("Canvas \(canvasIndex + 1)")
                    .font(.headline)
                    .foregroundStyle(isSource ? .blue : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSource ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSource)
    }
}

struct CanvasData {
    var contentType: CanvasContentType = .empty
    var selectedPDF: URL? = nil
    var notes: String = ""
    var browserAddress: String = ""
    var browserNavigate: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var goBackTrigger: Bool = false
    var goForwardTrigger: Bool = false
    var messageContent: [AiMessageChunk] = []
}

struct CanvasView: View {
    @State var currentCanvas: Int = 0
    @State private var selectedPDF0: URL?
    @State private var selectedPDF1: URL?
    @State private var selectedPDF2: URL?
    @State private var showingImporter = false
    @State private var importingCanvasIndex: Int? = nil
    
    // Canvas switcher state
    @State private var showingCanvasSwitcher = false
    @State private var switchingFromCanvasIndex: Int? = nil
    
    @State private var contentType0: CanvasContentType = .empty
    @State private var contentType1: CanvasContentType = .empty
    @State private var contentType2: CanvasContentType = .empty
    @State private var notes0: String = ""
    @State private var notes1: String = ""
    @State private var notes2: String = ""
    @State private var browserAddress0: String = ""
    @State private var browserAddress1: String = ""
    @State private var browserAddress2: String = ""
    @State private var browserNavigate0: Bool = false
    @State private var browserNavigate1: Bool = false
    @State private var browserNavigate2: Bool = false
    @State private var canGoBack0: Bool = false
    @State private var canGoForward0: Bool = false
    @State private var canGoBack1: Bool = false
    @State private var canGoForward1: Bool = false
    @State private var canGoBack2: Bool = false
    @State private var canGoForward2: Bool = false
    
    @State private var goBackTrigger0: Bool = false
    @State private var goForwardTrigger0: Bool = false
    @State private var goBackTrigger1: Bool = false
    @State private var goForwardTrigger1: Bool = false
    @State private var goBackTrigger2: Bool = false
    @State private var goForwardTrigger2: Bool = false
    
    @State private var messageContent0: [AiMessageChunk] = []
    @State private var messageContent1: [AiMessageChunk] = []
    @State private var messageContent2: [AiMessageChunk] = []
    
    // Helper methods for canvas switching
    private func switchCanvases(from sourceIndex: Int, to targetIndex: Int) {
        // Store source canvas data
        let sourceData = getCanvasData(at: sourceIndex)
        let targetData = getCanvasData(at: targetIndex)
        
        // Switch the data
        setCanvasData(at: sourceIndex, data: targetData)
        setCanvasData(at: targetIndex, data: sourceData)
    }
    
    private func getCanvasData(at index: Int) -> CanvasData {
        switch index {
        case 0:
            return CanvasData(
                contentType: contentType0,
                selectedPDF: selectedPDF0,
                notes: notes0,
                browserAddress: browserAddress0,
                browserNavigate: browserNavigate0,
                canGoBack: canGoBack0,
                canGoForward: canGoForward0,
                goBackTrigger: goBackTrigger0,
                goForwardTrigger: goForwardTrigger0,
                messageContent: messageContent0
            )
        case 1:
            return CanvasData(
                contentType: contentType1,
                selectedPDF: selectedPDF1,
                notes: notes1,
                browserAddress: browserAddress1,
                browserNavigate: browserNavigate1,
                canGoBack: canGoBack1,
                canGoForward: canGoForward1,
                goBackTrigger: goBackTrigger1,
                goForwardTrigger: goForwardTrigger1,
                messageContent: messageContent1
            )
        case 2:
            return CanvasData(
                contentType: contentType2,
                selectedPDF: selectedPDF2,
                notes: notes2,
                browserAddress: browserAddress2,
                browserNavigate: browserNavigate2,
                canGoBack: canGoBack2,
                canGoForward: canGoForward2,
                goBackTrigger: goBackTrigger2,
                goForwardTrigger: goForwardTrigger2,
                messageContent: messageContent2
            )
        default:
            return CanvasData()
        }
    }
    
    private func setCanvasData(at index: Int, data: CanvasData) {
        switch index {
        case 0:
            contentType0 = data.contentType
            selectedPDF0 = data.selectedPDF
            notes0 = data.notes
            browserAddress0 = data.browserAddress
            browserNavigate0 = data.browserNavigate
            canGoBack0 = data.canGoBack
            canGoForward0 = data.canGoForward
            goBackTrigger0 = data.goBackTrigger
            goForwardTrigger0 = data.goForwardTrigger
            messageContent0 = data.messageContent
        case 1:
            contentType1 = data.contentType
            selectedPDF1 = data.selectedPDF
            notes1 = data.notes
            browserAddress1 = data.browserAddress
            browserNavigate1 = data.browserNavigate
            canGoBack1 = data.canGoBack
            canGoForward1 = data.canGoForward
            goBackTrigger1 = data.goBackTrigger
            goForwardTrigger1 = data.goForwardTrigger
            messageContent1 = data.messageContent
        case 2:
            contentType2 = data.contentType
            selectedPDF2 = data.selectedPDF
            notes2 = data.notes
            browserAddress2 = data.browserAddress
            browserNavigate2 = data.browserNavigate
            canGoBack2 = data.canGoBack
            canGoForward2 = data.canGoForward
            goBackTrigger2 = data.goBackTrigger
            goForwardTrigger2 = data.goForwardTrigger
            messageContent2 = data.messageContent
        default:
            break
        }
    }
    
    var body: some View {
        ZStack {
            GlassEffectContainer {
                HStack {
                    CanvasPane(
                        canvasIndex: 0,
                        contentType: $contentType0,
                        selectedPDF: $selectedPDF0,
                        notes: $notes0,
                        browserAddress: $browserAddress0,
                        browserNavigate: $browserNavigate0,
                        canGoBack: $canGoBack0,
                        canGoForward: $canGoForward0,
                        goBackTrigger: $goBackTrigger0,
                        goForwardTrigger: $goForwardTrigger0,
                        messageContent: $messageContent0,
                        onPickDocument: {
                            importingCanvasIndex = 0
                            showingImporter = true
                        },
                        onOpenNotes: { contentType0 = .notes },
                        onOpenBrowser: { contentType0 = .browser },
                        onSwitchCanvas: { canvasIndex in
                            switchingFromCanvasIndex = canvasIndex
                            showingCanvasSwitcher = true
                        },
                        onOpenAi: {
                            contentType0 = .ai
                        }
                    )
                    
                    if currentCanvas == 1 || currentCanvas == 2 {
                        CanvasPane(
                            canvasIndex: 1,
                            contentType: $contentType1,
                            selectedPDF: $selectedPDF1,
                            notes: $notes1,
                            browserAddress: $browserAddress1,
                            browserNavigate: $browserNavigate1,
                            canGoBack: $canGoBack1,
                            canGoForward: $canGoForward1,
                            goBackTrigger: $goBackTrigger1,
                            goForwardTrigger: $goForwardTrigger1,
                            messageContent: $messageContent1,
                            onPickDocument: {
                                importingCanvasIndex = 1
                                showingImporter = true
                            },
                            onOpenNotes: { contentType1 = .notes },
                            onOpenBrowser: { contentType1 = .browser },
                            onSwitchCanvas: { canvasIndex in
                                switchingFromCanvasIndex = canvasIndex
                                showingCanvasSwitcher = true
                            },
                            onOpenAi: {
                                contentType1 = .ai
                            }
                        )
                        
                        if currentCanvas == 2 {
                            CanvasPane(
                                canvasIndex: 2,
                                contentType: $contentType2,
                                selectedPDF: $selectedPDF2,
                                notes: $notes2,
                                browserAddress: $browserAddress2,
                                browserNavigate: $browserNavigate2,
                                canGoBack: $canGoBack2,
                                canGoForward: $canGoForward2,
                                goBackTrigger: $goBackTrigger2,
                                goForwardTrigger: $goForwardTrigger2,
                                messageContent: $messageContent2,
                                onPickDocument: {
                                    importingCanvasIndex = 2
                                    showingImporter = true
                                },
                                onOpenNotes: { contentType2 = .notes },
                                onOpenBrowser: { contentType2 = .browser },
                                onSwitchCanvas: { canvasIndex in
                                    switchingFromCanvasIndex = canvasIndex
                                    showingCanvasSwitcher = true
                                },
                                onOpenAi: {
                                    contentType2 = .ai
                                }
                            )
                        }
                    }
                }
            }
            .padding()
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let started = url.startAccessingSecurityScopedResource()
                    defer {
                        if started {
                            // Do not stop immediately to allow rendering; you can manage stopping when clearing/replacing
                            // url.stopAccessingSecurityScopedResource()
                        }
                    }
                    switch importingCanvasIndex {
                    case 0:
                        selectedPDF0 = url
                        contentType0 = .pdf
                    case 1:
                        selectedPDF1 = url
                        contentType1 = .pdf
                    case 2:
                        selectedPDF2 = url
                        contentType2 = .pdf
                    default:
                        break
                    }
                case .failure:
                    break
                }
            }
            .sheet(item: $switchingFromCanvasIndex, content: { sourceIndex in
                CanvasSwitcherView(
                    sourceCanvasIndex: sourceIndex,
                    contentTypes: [contentType0, contentType1, contentType2],
                    notes: [notes0, notes1, notes2],
                    selectedPDFs: [selectedPDF0, selectedPDF1, selectedPDF2],
                    browserAddresses: [browserAddress0, browserAddress1, browserAddress2],
                    onSwitch: { targetIndex in
                        switchCanvases(from: sourceIndex, to: targetIndex)
                    }
                )
            })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Button {
                        withAnimation {
                            currentCanvas = 0
                        }
                    } label: {
                        Image(systemName: currentCanvas == 0 ? "rectangle.fill" : "rectangle")
                            .foregroundStyle(currentCanvas == 0 ? .blue : .primary)
                    }
                    
                    Button {
                        withAnimation {
                            currentCanvas = 1
                        }
                    } label: {
                        Image(systemName: currentCanvas == 1 ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                            .foregroundStyle(currentCanvas == 1 ? .blue : .primary)
                    }
                    
                    Button {
                        withAnimation {
                            currentCanvas = 2
                        }
                    } label: {
                        Image(systemName: currentCanvas == 2 ? "rectangle.split.3x1.fill" : "rectangle.split.3x1")
                            .foregroundStyle(currentCanvas == 2 ? .blue : .primary)
                    }
                }
                .padding()
                .glassEffect(.regular, in: Capsule())
            }
        }
    }
}

#Preview {
    NavigationStack {
        CanvasView()
    }
}
