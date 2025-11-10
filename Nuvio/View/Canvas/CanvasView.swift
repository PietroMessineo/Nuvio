//
//  CanvasView.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/6/25.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine
import CoreData

struct CanvasData {
    var contentType: CanvasContentType = .empty
    var pdfData: Data? = nil
    var pdfFileName: String? = nil
    var pdfTemporaryURL: URL? = nil  // For PDFKit display
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
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let canvas: Canvas?
    
    @StateObject private var canvasDataManager: CanvasDataManager
    @State private var canvasTitle: String = ""
    @State var currentCanvas: Int = 0
    @State private var isNewCanvas: Bool = false
    
    // PDF data for each canvas
    @State private var pdfData0: Data?
    @State private var pdfFileName0: String?
    @State private var pdfTemporaryURL0: URL?
    @State private var pdfData1: Data?
    @State private var pdfFileName1: String?
    @State private var pdfTemporaryURL1: URL?
    @State private var pdfData2: Data?
    @State private var pdfFileName2: String?
    @State private var pdfTemporaryURL2: URL?
    @State private var showingImporter = false
    @State private var importingCanvasIndex: Int? = nil
    @State private var showingSaveDialog = false
    
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
    
    @Namespace var transition
    
    // MARK: - Initializers
    
    init(canvas: Canvas? = nil, context: NSManagedObjectContext) {
        self.canvas = canvas
        self._canvasDataManager = StateObject(wrappedValue: CanvasDataManager(context: context))
    }
    
    // MARK: - Save Methods
    
    private func saveCanvas() {
        // If we have an existing canvas, make sure it's valid
        let targetCanvas: Canvas
        if let existingCanvas = canvas {
            // Use the new method to ensure canvas is properly loaded
            if let validCanvas = canvasDataManager.ensureCanvasLoaded(existingCanvas) {
                targetCanvas = validCanvas
            } else {
                print("Canvas could not be loaded for saving - creating new canvas")
                targetCanvas = canvasDataManager.createNewCanvas()
            }
        } else {
            targetCanvas = canvasDataManager.createNewCanvas()
        }
        
        let canvasData = SavedCanvasData(
            title: canvasTitle.isEmpty ? "Untitled Canvas" : canvasTitle,
            currentCanvas: currentCanvas,
            canvas0Data: SavedCanvasData.CanvasData(
                contentType: contentType0,
                notes: notes0,
                browserAddress: browserAddress0,
                pdfData: pdfData0,
                pdfFileName: pdfFileName0,
                messageContent: messageContent0
            ),
            canvas1Data: SavedCanvasData.CanvasData(
                contentType: contentType1,
                notes: notes1,
                browserAddress: browserAddress1,
                pdfData: pdfData1,
                pdfFileName: pdfFileName1,
                messageContent: messageContent1
            ),
            canvas2Data: SavedCanvasData.CanvasData(
                contentType: contentType2,
                notes: notes2,
                browserAddress: browserAddress2,
                pdfData: pdfData2,
                pdfFileName: pdfFileName2,
                messageContent: messageContent2
            )
        )
        
        canvasDataManager.saveCanvasData(canvas: targetCanvas, canvasData: canvasData)
    }
    
    private func loadCanvasData() {
        guard let canvas = canvas else { 
            canvasTitle = "New Canvas"
            isNewCanvas = true
            return 
        }
        
        // Use the new method to ensure canvas is properly loaded
        guard let validCanvas = canvasDataManager.ensureCanvasLoaded(canvas) else {
            print("Canvas could not be loaded - treating as new canvas")
            canvasTitle = "New Canvas"
            isNewCanvas = true
            return
        }
        
        isNewCanvas = false
        let canvasData = canvasDataManager.loadCanvasData(from: validCanvas)
        
        canvasTitle = canvasData.title
        currentCanvas = canvasData.currentCanvas
        
        // Load Canvas 0 data
        contentType0 = canvasData.canvas0Data.contentType
        notes0 = canvasData.canvas0Data.notes
        browserAddress0 = canvasData.canvas0Data.browserAddress
        messageContent0 = canvasData.canvas0Data.messageContent
        pdfData0 = canvasData.canvas0Data.pdfData
        pdfFileName0 = canvasData.canvas0Data.pdfFileName
        if let pdfData = pdfData0, let fileName = pdfFileName0 {
            pdfTemporaryURL0 = canvasDataManager.createTemporaryURL(for: pdfData, fileName: fileName)
        }
        
        // Load Canvas 1 data
        contentType1 = canvasData.canvas1Data.contentType
        notes1 = canvasData.canvas1Data.notes
        browserAddress1 = canvasData.canvas1Data.browserAddress
        messageContent1 = canvasData.canvas1Data.messageContent
        pdfData1 = canvasData.canvas1Data.pdfData
        pdfFileName1 = canvasData.canvas1Data.pdfFileName
        if let pdfData = pdfData1, let fileName = pdfFileName1 {
            pdfTemporaryURL1 = canvasDataManager.createTemporaryURL(for: pdfData, fileName: fileName)
        }
        
        // Load Canvas 2 data
        contentType2 = canvasData.canvas2Data.contentType
        notes2 = canvasData.canvas2Data.notes
        browserAddress2 = canvasData.canvas2Data.browserAddress
        messageContent2 = canvasData.canvas2Data.messageContent
        pdfData2 = canvasData.canvas2Data.pdfData
        pdfFileName2 = canvasData.canvas2Data.pdfFileName
        if let pdfData = pdfData2, let fileName = pdfFileName2 {
            pdfTemporaryURL2 = canvasDataManager.createTemporaryURL(for: pdfData, fileName: fileName)
        }
    }
    
    // Helper methods for PDF access management
    private func cleanupPDFAccess() {
        // Clean up temporary PDF files instead of managing security access
        canvasDataManager.cleanupTemporaryPDFs()
    }
    
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
                pdfData: pdfData0,
                pdfFileName: pdfFileName0,
                pdfTemporaryURL: pdfTemporaryURL0,
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
                pdfData: pdfData1,
                pdfFileName: pdfFileName1,
                pdfTemporaryURL: pdfTemporaryURL1,
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
                pdfData: pdfData2,
                pdfFileName: pdfFileName2,
                pdfTemporaryURL: pdfTemporaryURL2,
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
            pdfData0 = data.pdfData
            pdfFileName0 = data.pdfFileName
            pdfTemporaryURL0 = data.pdfTemporaryURL
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
            pdfData1 = data.pdfData
            pdfFileName1 = data.pdfFileName
            pdfTemporaryURL1 = data.pdfTemporaryURL
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
            pdfData2 = data.pdfData
            pdfFileName2 = data.pdfFileName
            pdfTemporaryURL2 = data.pdfTemporaryURL
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
                        pdfTemporaryURL: $pdfTemporaryURL0,
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
                    .matchedTransitionSource(id: "sheet", in: transition)
                    
                    if currentCanvas == 1 || currentCanvas == 2 {
                        CanvasPane(
                            canvasIndex: 1,
                            contentType: $contentType1,
                            pdfTemporaryURL: $pdfTemporaryURL1,
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
                        .matchedTransitionSource(id: "sheet", in: transition)
                        
                        if currentCanvas == 2 {
                            CanvasPane(
                                canvasIndex: 2,
                                contentType: $contentType2,
                                pdfTemporaryURL: $pdfTemporaryURL2,
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
                            .matchedTransitionSource(id: "sheet", in: transition)
                        }
                    }
                }
            }
            .padding()
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    
                    // Load PDF data immediately
                    let (pdfData, fileName) = canvasDataManager.loadPDFData(from: url)
                    
                    if let data = pdfData {
                        // Create temporary URL for display
                        let tempURL = canvasDataManager.createTemporaryURL(for: data, fileName: fileName)
                        
                        switch importingCanvasIndex {
                        case 0:
                            pdfData0 = data
                            pdfFileName0 = fileName
                            pdfTemporaryURL0 = tempURL
                            contentType0 = .pdf
                        case 1:
                            pdfData1 = data
                            pdfFileName1 = fileName
                            pdfTemporaryURL1 = tempURL
                            contentType1 = .pdf
                        case 2:
                            pdfData2 = data
                            pdfFileName2 = fileName
                            pdfTemporaryURL2 = tempURL
                            contentType2 = .pdf
                        default:
                            break
                        }
                    } else {
                        print("Failed to load PDF data from \(url)")
                    }
                    
                case .failure(let error):
                    print("File import failed: \(error)")
                }
            }
            .sheet(item: $switchingFromCanvasIndex, content: { sourceIndex in
                CanvasSwitcherView(
                    sourceCanvasIndex: sourceIndex,
                    contentTypes: [contentType0, contentType1, contentType2],
                    notes: [notes0, notes1, notes2],
                    pdfFileNames: [pdfFileName0, pdfFileName1, pdfFileName2],
                    browserAddresses: [browserAddress0, browserAddress1, browserAddress2],
                    onSwitch: { targetIndex in
                        switchCanvases(from: sourceIndex, to: targetIndex)
                    }
                )
                .navigationTransition(.zoom(sourceID: "sheet", in: transition))
            })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadCanvasData()
        }
        .onDisappear {
            // Clean up PDF access when leaving the canvas
            cleanupPDFAccess()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    saveCanvas()
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Save", action: saveCanvas)
                    Button("Save & Close") {
                        saveCanvas()
                        dismiss()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            
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
        CanvasView(context: PersistenceController.preview.container.viewContext)
    }
}
