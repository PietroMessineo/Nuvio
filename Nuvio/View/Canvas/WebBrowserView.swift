import SwiftUI
import WebKit

struct WebBrowserView: UIViewRepresentable {
    @Binding var urlString: String
    @Binding var navigateTrigger: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var goBackTrigger: Bool
    @Binding var goForwardTrigger: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        let bg = UIColor(Color(hex: "#F1F1F1"))
        webView.backgroundColor = bg
        webView.scrollView.backgroundColor = bg
        webView.navigationDelegate = context.coordinator
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
        // Handle back/forward triggers
        if goBackTrigger {
            if webView.canGoBack { webView.goBack() }
            DispatchQueue.main.async {
                goBackTrigger = false
            }
        }
        if goForwardTrigger {
            if webView.canGoForward { webView.goForward() }
            DispatchQueue.main.async {
                goForwardTrigger = false
            }
        }
        context.coordinator.webView = webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(canGoBack: $canGoBack, canGoForward: $canGoForward)
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

    class Coordinator: NSObject, WKNavigationDelegate {
        var webView: WKWebView?
        private var canGoBackBinding: Binding<Bool>
        private var canGoForwardBinding: Binding<Bool>

        init(canGoBack: Binding<Bool>, canGoForward: Binding<Bool>) {
            self.canGoBackBinding = canGoBack
            self.canGoForwardBinding = canGoForward
        }

        private func updateNavState() {
            if let wv = webView {
                canGoBackBinding.wrappedValue = wv.canGoBack
                canGoForwardBinding.wrappedValue = wv.canGoForward
            } else {
                canGoBackBinding.wrappedValue = false
                canGoForwardBinding.wrappedValue = false
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.webView = webView
            updateNavState()
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            self.webView = webView
            updateNavState()
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            self.webView = webView
            updateNavState()
            decisionHandler(.allow)
        }
    }
}

#Preview {
    StatefulPreviewWrapper(("apple.com", false, false, false, false, false)) { urlBinding, triggerBinding, backBinding, forwardBinding, goBackTrigBinding, goForwardTrigBinding in
        WebBrowserView(
            urlString: urlBinding,
            navigateTrigger: triggerBinding,
            canGoBack: backBinding,
            canGoForward: forwardBinding,
            goBackTrigger: goBackTrigBinding,
            goForwardTrigger: goForwardTrigBinding
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Helper to preview bindings
struct StatefulPreviewWrapper<Value1, Value2, Value3, Value4, Value5, Value6, Content: View>: View {
    @State var value1: Value1
    @State var value2: Value2
    @State var value3: Value3
    @State var value4: Value4
    @State var value5: Value5
    @State var value6: Value6
    let content: (Binding<Value1>, Binding<Value2>, Binding<Value3>, Binding<Value4>, Binding<Value5>, Binding<Value6>) -> Content

    init(_ initial: (Value1, Value2, Value3, Value4, Value5, Value6), @ViewBuilder content: @escaping (Binding<Value1>, Binding<Value2>, Binding<Value3>, Binding<Value4>, Binding<Value5>, Binding<Value6>) -> Content) {
        _value1 = State(initialValue: initial.0)
        _value2 = State(initialValue: initial.1)
        _value3 = State(initialValue: initial.2)
        _value4 = State(initialValue: initial.3)
        _value5 = State(initialValue: initial.4)
        _value6 = State(initialValue: initial.5)
        self.content = content
    }

    var body: some View {
        content($value1, $value2, $value3, $value4, $value5, $value6)
    }
}
