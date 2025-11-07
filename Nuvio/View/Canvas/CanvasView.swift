//
//  CanvasView.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/6/25.
//

import SwiftUI
import UniformTypeIdentifiers

enum CanvasContentType { case empty, pdf, notes, browser }

struct CanvasPane: View {
    @Binding var contentType: CanvasContentType
    @Binding var selectedPDF: URL?
    @Binding var notes: String
    @Binding var browserAddress: String
    @Binding var browserNavigate: Bool

    var onPickDocument: () -> Void
    var onOpenNotes: () -> Void
    var onOpenBrowser: () -> Void

    var body: some View {
        ZStack {
            switch contentType {
            case .empty:
                CanvasOverlayMenu(
                    onPickDocument: onPickDocument,
                    onOpenNotes: onOpenNotes,
                    onOpenBrowser: onOpenBrowser
                )
            case .pdf:
                if let url = selectedPDF {
                    PDFKitView(url: url)
                        .clipShape(RoundedRectangle(cornerRadius: 48))
                }
            case .notes:
                CanvasNotesView(notes: $notes)
            case .browser:
                CanvasBrowserView(browserAddress: $browserAddress, browserNavigate: $browserNavigate)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "F1F1F1"))
        .clipShape(RoundedRectangle(cornerRadius: 48))
        .overlay(alignment: .topTrailing) {
            HStack {
                Button {
                    // TODO: - Switch item
                } label: {
                    Image(systemName: "checkmark.rectangle.stack")
                        .foregroundStyle(Color.primary)
                }
                .padding()
                .glassEffect(.regular.interactive(), in: Circle())
            }
            .padding()
        }
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 48))
    }
}

struct CanvasBrowserView: View {
    @Binding var browserAddress: String
    @Binding var browserNavigate: Bool
    
    var body: some View {
        ZStack(alignment: .bottom) {
            WebBrowserView(urlString: $browserAddress, navigateTrigger: $browserNavigate)
                .clipShape(RoundedRectangle(cornerRadius: 48))

            HStack {
                TextField("Search or enter website name", text: $browserAddress, onCommit: {
                    browserNavigate = true
                })
                .keyboardType(.webSearch)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: .capsule)
            }
            .padding(16)
        }
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

struct CanvasView: View {
    @State var currentCanvas: Int = 0
    @State private var selectedPDF0: URL?
    @State private var selectedPDF1: URL?
    @State private var selectedPDF2: URL?
    @State private var showingImporter = false
    @State private var importingCanvasIndex: Int? = nil
    
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
    
    var body: some View {
        ZStack {
            GlassEffectContainer {
                HStack {
                    CanvasPane(
                        contentType: $contentType0,
                        selectedPDF: $selectedPDF0,
                        notes: $notes0,
                        browserAddress: $browserAddress0,
                        browserNavigate: $browserNavigate0,
                        onPickDocument: {
                            importingCanvasIndex = 0
                            showingImporter = true
                        },
                        onOpenNotes: { contentType0 = .notes },
                        onOpenBrowser: { contentType0 = .browser }
                    )
                    
                    if currentCanvas == 1 || currentCanvas == 2 {
                        CanvasPane(
                            contentType: $contentType1,
                            selectedPDF: $selectedPDF1,
                            notes: $notes1,
                            browserAddress: $browserAddress1,
                            browserNavigate: $browserNavigate1,
                            onPickDocument: {
                                importingCanvasIndex = 1
                                showingImporter = true
                            },
                            onOpenNotes: { contentType1 = .notes },
                            onOpenBrowser: { contentType1 = .browser }
                        )
                        
                        if currentCanvas == 2 {
                            CanvasPane(
                                contentType: $contentType2,
                                selectedPDF: $selectedPDF2,
                                notes: $notes2,
                                browserAddress: $browserAddress2,
                                browserNavigate: $browserNavigate2,
                                onPickDocument: {
                                    importingCanvasIndex = 2
                                    showingImporter = true
                                },
                                onOpenNotes: { contentType2 = .notes },
                                onOpenBrowser: { contentType2 = .browser }
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

