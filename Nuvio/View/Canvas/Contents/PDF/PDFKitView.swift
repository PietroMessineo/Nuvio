import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Don't start/stop access here since it's managed by CanvasDataManager
        // Just attempt to load the document
        guard let pdfDocument = PDFDocument(url: url) else {
            print("Failed to load PDF document from URL: \(url.path)")
            // Create an empty document or show error state
            uiView.document = nil
            return
        }
        
        uiView.document = pdfDocument
    }
}

#Preview {
    Text("PDFKitView Preview")
}

#Preview {
    Text("PDFKitView Preview")
}
