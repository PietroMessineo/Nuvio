//
//  CanvasSwitcherView.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import SwiftUI

struct CanvasSwitcherView: View {
    let sourceCanvasIndex: Int
    
    // Canvas data for preview
    let contentTypes: [CanvasContentType]
    let notes: [String]
    let pdfFileNames: [String?]  // Show filenames instead of URLs
    let browserAddresses: [String]
    
    let onSwitch: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Switch Canvas \(sourceCanvasIndex + 1)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Tap a canvas to switch positions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(0..<3, id: \.self) { index in
                        CanvasPreviewCard(
                            canvasIndex: index,
                            contentType: contentTypes[index],
                            notes: notes[index],
                            pdfFileName: pdfFileNames[index],
                            browserAddress: browserAddresses[index],
                            isSource: index == sourceCanvasIndex,
                            onTap: {
                                if index != sourceCanvasIndex {
                                    onSwitch(index)
                                    dismiss()
                                }
                            }
                        )
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Canvas Switcher")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
