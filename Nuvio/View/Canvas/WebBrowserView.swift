import SwiftUI
import WebKit

struct WebBrowserView: UIViewRepresentable {
    @Binding var urlString: String
    @Binding var navigateTrigger: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        let bg = UIColor(Color(hex: "#F1F1F1"))
        webView.backgroundColor = bg
        webView.scrollView.backgroundColor = bg
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if navigateTrigger {
            let text = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            if let url = Self.makeURL(from: text) {
                webView.load(URLRequest(url: url))
            } else if let url = Self.searchURL(for: text) {
                webView.load(URLRequest(url: url))
            }
            let bg = UIColor(Color(hex: "#F1F1F1"))
            webView.isOpaque = false
            webView.backgroundColor = bg
            webView.scrollView.backgroundColor = bg
            DispatchQueue.main.async {
                navigateTrigger = false
            }
        }
    }

    private static func makeURL(from text: String) -> URL? {
        guard !text.isEmpty else { return nil }
        if let url = URL(string: text), url.scheme != nil { return url }
        // Prepend https if missing
        if let url = URL(string: "https://\(text)") { return url }
        return nil
    }

    private static func searchURL(for query: String) -> URL? {
        guard !query.isEmpty else { return nil }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return URL(string: "https://www.google.com/search?q=\(encoded)")
    }
}

#Preview {
    StatefulPreviewWrapper(("apple.com", false)) { urlBinding, triggerBinding in
        WebBrowserView(urlString: urlBinding, navigateTrigger: triggerBinding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Helper to preview bindings
struct StatefulPreviewWrapper<Value1, Value2, Content: View>: View {
    @State var value1: Value1
    @State var value2: Value2
    let content: (Binding<Value1>, Binding<Value2>) -> Content

    init(_ initial: (Value1, Value2), @ViewBuilder content: @escaping (Binding<Value1>, Binding<Value2>) -> Content) {
        _value1 = State(initialValue: initial.0)
        _value2 = State(initialValue: initial.1)
        self.content = content
    }

    var body: some View {
        content($value1, $value2)
    }
}
