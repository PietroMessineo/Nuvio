//
//  CanvasPane.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import SwiftUI

enum CanvasContentType { case empty, pdf, notes, browser, ai }

// Extend CanvasContentType to be compatible with CoreData
extension CanvasContentType: CaseIterable, RawRepresentable {
    public var rawValue: String {
        switch self {
        case .empty: return "empty"
        case .pdf: return "pdf"
        case .notes: return "notes"
        case .browser: return "browser"
        case .ai: return "ai"
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "empty": self = .empty
        case "pdf": self = .pdf
        case "notes": self = .notes
        case "browser": self = .browser
        case "ai": self = .ai
        default: return nil
        }
    }
}

struct CanvasPane: View {
    let canvasIndex: Int
    @Binding var contentType: CanvasContentType
    @Binding var pdfTemporaryURL: URL?
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
                if let url = pdfTemporaryURL {
                    PDFKitView(url: url)
                        .clipShape(RoundedRectangle(cornerRadius: 48))
                } else {
                    // Show loading state or error
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Loading PDF...")
                            .foregroundColor(.secondary)
                    }
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
