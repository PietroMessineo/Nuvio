import SwiftUI
import SwiftUI
import WebKit

#Preview("Modern Browser") {
    ModernWebBrowserView(urlText: .constant(""))
}

// Helper to preview bindings
struct StatefulPreviewWrapper<Value1, Value2, Value3, Value4, Value5, Value6, Value7, Content: View>: View {
    @State var value1: Value1
    @State var value2: Value2
    @State var value3: Value3
    @State var value4: Value4
    @State var value5: Value5
    @State var value6: Value6
    @State var value7: Value7
    let content: (Binding<Value1>, Binding<Value2>, Binding<Value3>, Binding<Value4>, Binding<Value5>, Binding<Value6>, Binding<Value7>) -> Content

    init(_ initial: (Value1, Value2, Value3, Value4, Value5, Value6, Value7), @ViewBuilder content: @escaping (Binding<Value1>, Binding<Value2>, Binding<Value3>, Binding<Value4>, Binding<Value5>, Binding<Value6>, Binding<Value7>) -> Content) {
        _value1 = State(initialValue: initial.0)
        _value2 = State(initialValue: initial.1)
        _value3 = State(initialValue: initial.2)
        _value4 = State(initialValue: initial.3)
        _value5 = State(initialValue: initial.4)
        _value6 = State(initialValue: initial.5)
        _value7 = State(initialValue: initial.6)
        self.content = content
    }

    var body: some View {
        content($value1, $value2, $value3, $value4, $value5, $value6, $value7)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Modern Web Browser Implementation

struct ModernWebBrowserView: View {
    @StateObject private var coordinator = WebBrowserCoordinator()
    @Binding var urlText: String
    
    var body: some View {
        VStack(spacing: 0) {
            // WebView
            ModernWebView(coordinator: coordinator)
                .onAppear {
                    if !urlText.isEmpty {
                        coordinator.load(urlString: urlText)
                    }
                }
            
            // Navigation Bar
            navigationBar
            
            // Progress Bar
            if coordinator.isLoading {
                ProgressView(value: coordinator.estimatedProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .animation(.easeInOut(duration: 0.3), value: coordinator.estimatedProgress)
            }
        }
        .background(Color(hex: "#F1F1F1"))
    }
    
    private var navigationBar: some View {
        HStack(spacing: 8) {
            // Navigation Controls
            HStack {
                if coordinator.canGoBack {
                    Button(action: coordinator.goBack) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    .padding()
                    .glassEffect(.regular.interactive(), in: .circle)
                }
                
                if coordinator.canGoForward {
                    Button(action: coordinator.goForward) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.plain)
                    .padding()
                    .glassEffect(.regular.interactive(), in: .circle)
                }
            }
            .buttonStyle(.bordered)
            
            // URL Bar
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search or enter website name", text: $urlText)
                    .onSubmit {
                        coordinator.load(urlString: urlText)
                    }
                
                Group {
                    if coordinator.isLoading {
                        Button(action: coordinator.stopLoading) {
                            Image(systemName: "xmark")
                        }
                    } else {
                        Button(action: coordinator.reload) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .foregroundStyle(Color.primary)
            }
            .padding()
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .background(Color.clear)
        .padding()
        .onChange(of: coordinator.currentURL) { _, newURL in
            if !newURL.isEmpty && newURL != urlText {
                urlText = newURL
            }
        }
    }
}

struct ModernWebView: UIViewRepresentable {
    @ObservedObject var coordinator: WebBrowserCoordinator
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        
        // Configure WebView
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        let backgroundColor = UIColor(Color(hex: "#F1F1F1"))
        webView.backgroundColor = backgroundColor
        webView.scrollView.backgroundColor = backgroundColor
        
        // Configure the coordinator with this webView
        coordinator.configure(webView: webView)
        
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No need for trigger-based updates since we're using the coordinator pattern
        // The coordinator handles all navigation directly
    }
}
