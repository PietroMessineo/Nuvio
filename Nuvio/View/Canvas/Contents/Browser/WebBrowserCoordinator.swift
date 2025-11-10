import Foundation
import WebKit
import SwiftUI
import Combine

@MainActor
class WebBrowserCoordinator: NSObject, ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var currentURL = ""
    @Published var title = ""
    @Published var estimatedProgress: Double = 0
    
    private var webView: WKWebView?
    private var progressObservation: NSKeyValueObservation?
    private var titleObservation: NSKeyValueObservation?
    private var urlObservation: NSKeyValueObservation?
    
    override init() {
        super.init()
    }
    
    deinit {
        progressObservation?.invalidate()
        titleObservation?.invalidate()
        urlObservation?.invalidate()
    }
    
    func configure(webView: WKWebView) {
        self.webView = webView
        webView.navigationDelegate = self
        
        // Observe progress
        progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] _, change in
            DispatchQueue.main.async {
                self?.estimatedProgress = change.newValue ?? 0
            }
        }
        
        // Observe title
        titleObservation = webView.observe(\.title, options: .new) { [weak self] _, change in
            DispatchQueue.main.async {
                self?.title = (change.newValue ?? "") ?? ""
            }
        }
        
        // Observe URL
        urlObservation = webView.observe(\.url, options: .new) { [weak self] _, change in
            DispatchQueue.main.async {
                self?.currentURL = change.newValue??.absoluteString ?? ""
            }
        }
    }
    
    private func updateNavigationState() {
        guard let webView = webView else {
            canGoBack = false
            canGoForward = false
            return
        }
        
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
    
    // MARK: - Navigation Actions
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func stopLoading() {
        webView?.stopLoading()
    }
    
    func load(urlString: String) {
        let trimmedText = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let url = makeURL(from: trimmedText) {
            webView?.load(URLRequest(url: url))
        } else if let searchURL = searchURL(for: trimmedText) {
            webView?.load(URLRequest(url: searchURL))
        }
    }
    
    // MARK: - URL Handling
    
    private func makeURL(from text: String) -> URL? {
        guard !text.isEmpty else { return nil }
        
        // Check if it's already a valid URL
        if let url = URL(string: text), url.scheme != nil {
            return url
        }
        
        // Try adding https://
        if let url = URL(string: "https://\(text)") {
            return url
        }
        
        return nil
    }
    
    private func searchURL(for query: String) -> URL? {
        guard !query.isEmpty else { return nil }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return URL(string: "https://www.google.com/search?q=\(encoded)")
    }
}

// MARK: - WKNavigationDelegate

extension WebBrowserCoordinator: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        updateNavigationState()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        updateNavigationState()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        updateNavigationState()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        updateNavigationState()
        print("Navigation failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        updateNavigationState()
        print("Provisional navigation failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        updateNavigationState()
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
}
