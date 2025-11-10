//
//  CanvasNotesView.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import SwiftUI

struct CanvasNotesView: View {
    @Binding var notes: String
    var isPreview = false
    
    var body: some View {
        TextEditor(text: $notes)
            .font(.system(size: isPreview ? 7 : 20))
            .padding(isPreview ? 8 : 24)
            .scrollContentBackground(.hidden)
            .background(Color(hex: "F1F1F1"))
            .clipShape(RoundedRectangle(cornerRadius: isPreview ? 10 : 48))
    }
}
