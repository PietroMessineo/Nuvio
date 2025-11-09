import SwiftUI

struct CanvasOverlayMenu: View {
    let onPickDocument: () -> Void
    let onOpenNotes: () -> Void
    let onOpenBrowser: () -> Void
    let onOpenAi: () -> Void
    init(onPickDocument: @escaping () -> Void = {}, onOpenNotes: @escaping () -> Void = {}, onOpenBrowser: @escaping () -> Void = {}, onOpenAi: @escaping () -> Void = {}) {
        self.onPickDocument = onPickDocument
        self.onOpenNotes = onOpenNotes
        self.onOpenBrowser = onOpenBrowser
        self.onOpenAi = onOpenAi
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Button {
                onPickDocument()
            } label: {
                CanvasItemView(
                    image: "document",
                    title: "Document",
                    backgroundColor: Color(hex: "#BBE2FF"),
                    mainColor: Color(hex: "#14598B"),
                    circleColor: Color(hex: "#80C5FB")
                )
            }

            Button {
                onOpenNotes()
            } label: {
                CanvasItemView(
                    image: "pencil.and.scribble",
                    title: "Notes",
                    backgroundColor: Color(hex: "#FFEABB"),
                    mainColor: Color(hex: "#8F7434"),
                    circleColor: Color(hex: "#FBD680")
                )
            }
            
            Button {
                onOpenBrowser()
            } label: {
                CanvasItemView(
                    image: "globe",
                    title: "Browser",
                    backgroundColor: Color(hex: "#D9E6E6"),
                    mainColor: Color(hex: "#366D6C"),
                    circleColor: Color(hex: "#A8D2D1")
                )
            }
            
            Button {
                onOpenAi()
            } label: {
                CanvasItemView(
                    image: "brain",
                    title: "AI",
                    backgroundColor: Color(hex: "#CDBBFF"),
                    mainColor: Color(hex: "#34148B"),
                    circleColor: Color(hex: "#A080FB")
                )
            }
        }
    }
}

struct CanvasItemView: View {
    let image: String
    let title: String
    let backgroundColor: Color
    let mainColor: Color
    let circleColor: Color
    
    var body: some View {
        VStack {
            Image(systemName: image)
                .foregroundStyle(mainColor)
                .font(.system(size: 42, weight: .semibold))
                .padding(16)
                .background(circleColor)
                .clipShape(Circle())
            
            Text(title)
                .foregroundStyle(mainColor)
                .fontWeight(.semibold)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 31))
        .padding(.horizontal, 22)
    }
}

#Preview {
    CanvasOverlayMenu(onPickDocument: {}, onOpenNotes: {}, onOpenBrowser: {})
}
