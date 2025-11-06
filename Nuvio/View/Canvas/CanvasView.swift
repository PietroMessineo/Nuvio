//
//  CanvasView.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/6/25.
//

import SwiftUI
import UniformTypeIdentifiers

private enum CanvasContentType { case empty, pdf, notes }

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
    
    var body: some View {
        ZStack {
            GlassEffectContainer {
                HStack {
                    RoundedRectangle(cornerRadius: 48)
                        .fill(Color(hex: "F1F1F1"))
                        .overlay(content: {
                            CanvasOverlayMenu(onPickDocument: {
                                importingCanvasIndex = 0
                                showingImporter = true
                            }, onOpenNotes: {
                                contentType0 = .notes
                            })
                        })
                        .overlay(alignment: .center) {
                            if contentType0 == .pdf, let url = selectedPDF0 {
                                PDFKitView(url: url)
                                    .clipShape(RoundedRectangle(cornerRadius: 48))
                            } else if contentType0 == .notes {
                                TextEditor(text: $notes0)
                                    .font(.system(size: 20))
                                    .padding(24)
                                    .scrollContentBackground(.hidden)
                                    .background(Color(hex: "F1F1F1"))
                                    .clipShape(RoundedRectangle(cornerRadius: 48))
                            }
                        }
                        .overlay(alignment: .bottomTrailing) {
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
                    
                    if currentCanvas == 1 || currentCanvas == 2 {
                        RoundedRectangle(cornerRadius: 48)
                            .fill(Color(hex: "F1F1F1"))
                            .overlay(content: {
                                CanvasOverlayMenu(onPickDocument: {
                                    importingCanvasIndex = 1
                                    showingImporter = true
                                }, onOpenNotes: {
                                    contentType1 = .notes
                                })
                            })
                            .overlay(alignment: .center) {
                                if contentType1 == .pdf, let url = selectedPDF1 {
                                    PDFKitView(url: url)
                                        .clipShape(RoundedRectangle(cornerRadius: 48))
                                } else if contentType1 == .notes {
                                    TextEditor(text: $notes1)
                                        .font(.system(size: 20))
                                        .padding(24)
                                        .scrollContentBackground(.hidden)
                                        .background(Color(hex: "F1F1F1"))
                                        .clipShape(RoundedRectangle(cornerRadius: 48))
                                }
                            }
                            .overlay(alignment: .bottomTrailing) {
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
                        
                        if currentCanvas == 2 {
                            RoundedRectangle(cornerRadius: 48)
                                .fill(Color(hex: "F1F1F1"))
                                .overlay(content: {
                                    CanvasOverlayMenu(onPickDocument: {
                                        importingCanvasIndex = 2
                                        showingImporter = true
                                    }, onOpenNotes: {
                                        contentType2 = .notes
                                    })
                                })
                                .overlay(alignment: .center) {
                                    if contentType2 == .pdf, let url = selectedPDF2 {
                                        PDFKitView(url: url)
                                            .clipShape(RoundedRectangle(cornerRadius: 48))
                                    } else if contentType2 == .notes {
                                        TextEditor(text: $notes2)
                                            .font(.system(size: 20))
                                            .padding(24)
                                            .scrollContentBackground(.hidden)
                                            .background(Color(hex: "F1F1F1"))
                                            .clipShape(RoundedRectangle(cornerRadius: 48))
                                    }
                                }
                                .overlay(alignment: .bottomTrailing) {
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

