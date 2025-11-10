//
//  PDFDebugView.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import SwiftUI

/// A debug view to help troubleshoot PDF loading issues
struct PDFDebugView: View {
    let url: URL?
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            if let url = url {
                Group {
                    Text("URL: \(url.path)")
                    Text("Scheme: \(url.scheme ?? "nil")")
                    Text("Host: \(url.host ?? "nil")")
                    Text("Is File URL: \(url.isFileURL ? "Yes" : "No")")
                    Text("File Exists: \(FileManager.default.fileExists(atPath: url.path) ? "Yes" : "No")")
                }
                .onAppear {
                    if url.isFileURL {
                        do {
                            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                            if let fileSize = resourceValues.fileSize {
                                print("File size: \(fileSize) bytes")
                            }
                            if let modDate = resourceValues.contentModificationDate {
                                print("Modified: \(modDate)")
                            }
                        } catch {
                            print("Resource Error: \(error.localizedDescription)")
                        }
                    }
                }
                .font(.caption)
                .padding(.leading)
            } else {
                Text("No URL")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    PDFDebugView(
        url: URL(string: "file:///private/var/mobile/Library/Mobile%20Documents/com~apple~Preview/Documents/Scanned%20Document%202.pdf"),
        title: "Debug PDF"
    )
}
