//
//  CanvasView.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/6/25.
//

import SwiftUI

struct CanvasView: View {
    @State var currentCanvas: Int = 0
    
    var body: some View {
        ZStack {
            GlassEffectContainer {
                HStack {
                    RoundedRectangle(cornerRadius: 48)
                        .fill(Color(hex: "F1F1F1"))
                        .overlay(alignment: .bottomTrailing) {
                            HStack {
                                Button {
                                    // TODO: - Switch item
                                } label: {
                                    Image(systemName: "checkmark.rectangle.stack")
                                        .foregroundStyle(Color.primary)
                                }
                                .padding()
                                .glassEffect(.regular.interactive(), in: Circle())
                            }
                            .padding()
                        }
                        .glassEffect(.clear.tint(Color("F1F1F1")), in: RoundedRectangle(cornerRadius: 48))
                    
                    if currentCanvas == 1 || currentCanvas == 2 {
                        RoundedRectangle(cornerRadius: 48)
                            .fill(Color(hex: "F1F1F1"))
                            .overlay(alignment: .bottomTrailing) {
                                HStack {
                                    Button {
                                        // TODO: - Switch item
                                    } label: {
                                        Image(systemName: "checkmark.rectangle.stack")
                                            .foregroundStyle(Color.primary)
                                    }
                                    .padding()
                                    .glassEffect(.regular.interactive(), in: Circle())
                                }
                                .padding()
                            }
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 48))
                        
                        if currentCanvas == 2 {
                            RoundedRectangle(cornerRadius: 48)
                                .fill(Color(hex: "F1F1F1"))
                                .overlay(alignment: .bottomTrailing) {
                                    HStack {
                                        Button {
                                            // TODO: - Switch item
                                        } label: {
                                            Image(systemName: "checkmark.rectangle.stack")
                                                .foregroundStyle(Color.primary)
                                        }
                                        .padding()
                                        .glassEffect(.regular.interactive(), in: Circle())
                                    }
                                    .padding()
                                }
                                .glassEffect(.clear.tint(Color("F1F1F1")), in: RoundedRectangle(cornerRadius: 48))
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Button {
                        withAnimation {
                            currentCanvas = 0
                        }
                    } label: {
                        Image(systemName: currentCanvas == 0 ? "rectangle.fill" : "rectangle")
                            .foregroundStyle(currentCanvas == 0 ? .blue : .primary)
                    }
                    
                    Button {
                        withAnimation {
                            currentCanvas = 1
                        }
                    } label: {
                        Image(systemName: currentCanvas == 1 ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                            .foregroundStyle(currentCanvas == 1 ? .blue : .primary)
                    }
                    
                    Button {
                        withAnimation {
                            currentCanvas = 2
                        }
                    } label: {
                        Image(systemName: currentCanvas == 2 ? "rectangle.split.3x1.fill" : "rectangle.split.3x1")
                            .foregroundStyle(currentCanvas == 2 ? .blue : .primary)
                    }
                }
                .padding()
                .glassEffect(.regular, in: Capsule())
            }
        }
    }
}

#Preview {
    NavigationStack {
        CanvasView()
    }
}
