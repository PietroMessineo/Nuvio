import SwiftUI

struct CanvasOverlayMenu: View {
    let onPickDocument: () -> Void
    init(onPickDocument: @escaping () -> Void = {}) {
        self.onPickDocument = onPickDocument
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button {
                onPickDocument()
            } label: {
                Label("Document", systemImage: "folder.fill")
            }

            Button {
                // TODO: - Open Files App and import PDF
            } label: {
                Label("Text", systemImage: "text.redaction")
            }
            
            Button {
                // TODO: - Open Files App and import PDF
            } label: {
                Label("Browser", systemImage: "safari")
            }
            
            Button {
                // TODO: - Open Files App and import PDF
            } label: {
                Label("AI", systemImage: "brain")
            }
        }
    }
}

#Preview {
    CanvasOverlayMenu(onPickDocument: {})
}
