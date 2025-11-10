//
//  CanvasBrowserView.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import SwiftUI

struct CanvasBrowserView: View {
    @Binding var browserAddress: String
    @Binding var browserNavigate: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var goBackTrigger: Bool
    @Binding var goForwardTrigger: Bool
    
    var isPreview: Bool = false
    
    var body: some View {
        ModernWebBrowserView(urlText: $browserAddress, isPreview: isPreview)
    }
}
