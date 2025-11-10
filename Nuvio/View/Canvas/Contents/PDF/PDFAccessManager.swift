//
//  PDFAccessManager.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import Foundation
import Combine

/// Manages security-scoped access to PDF files
class PDFAccessManager: ObservableObject {
    private var accessedURLs: Set<URL> = []
    
    /// Starts accessing a security-scoped resource and tracks it
    func startAccessing(_ url: URL) -> Bool {
        let success = url.startAccessingSecurityScopedResource()
        if success {
            accessedURLs.insert(url)
            print("Started accessing PDF: \(url.lastPathComponent)")
        } else {
            print("Failed to start accessing PDF: \(url.lastPathComponent)")
        }
        return success
    }
    
    /// Stops accessing a security-scoped resource and removes tracking
    func stopAccessing(_ url: URL) {
        if accessedURLs.contains(url) {
            url.stopAccessingSecurityScopedResource()
            accessedURLs.remove(url)
            print("Stopped accessing PDF: \(url.lastPathComponent)")
        }
    }
    
    /// Stops accessing all tracked URLs (useful for cleanup)
    func stopAccessingAll() {
        for url in accessedURLs {
            url.stopAccessingSecurityScopedResource()
            print("Stopped accessing PDF: \(url.lastPathComponent)")
        }
        accessedURLs.removeAll()
    }
    
    /// Check if a URL is currently being accessed
    func isAccessing(_ url: URL) -> Bool {
        return accessedURLs.contains(url)
    }
    
    deinit {
        stopAccessingAll()
    }
}
