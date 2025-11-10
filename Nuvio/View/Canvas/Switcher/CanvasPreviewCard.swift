//
//  CanvasPreviewCard.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import SwiftUI

struct CanvasPreviewCard: View {
    let canvasIndex: Int
    let contentType: CanvasContentType
    let notes: String
    let pdfFileName: String?
    let browserAddress: String
    let isSource: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Canvas preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#F1F1F1"))
                        .frame(height: 120)
                    
                    // Preview content based on canvas type
                    Group {
                        switch contentType {
                        case .empty:
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text("Empty")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        case .pdf:
                            VStack {
                                Image(systemName: "document")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "80C5FB"))
                                Text("Document")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        case .notes:
                            VStack {
                                Image(systemName: "pencil.and.scribble")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "FBD680"))
                                Text("Notes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !notes.isEmpty {
                                    Text(notes.prefix(20) + (notes.count > 20 ? "..." : ""))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        case .browser:
                            VStack {
                                Image(systemName: "globe")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "A8D2D1"))
                                Text("Browser")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !browserAddress.isEmpty {
                                    Text(browserAddress)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        case .ai:
                            VStack {
                                Image(systemName: "brain")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "#A080FB"))
                                Text("AI")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Source indicator
                    if isSource {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white, .blue)
                                    .font(.title2)
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                
                // Canvas label
                Text("Canvas \(canvasIndex + 1)")
                    .font(.headline)
                    .foregroundStyle(isSource ? .blue : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSource ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSource)
    }
}
