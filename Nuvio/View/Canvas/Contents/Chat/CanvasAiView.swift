//
//  CanvasAiView.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import SwiftUI

struct CanvasAiView: View {
    @StateObject private var chatStreamService = ChatStreamService()
    
    @State var promptText: String = ""
    @Binding var messageContent: [AiMessageChunk]
    
    var body: some View {
        VStack(alignment: .leading) {
            List(chatStreamService.messages) { message in
                Section {
                    // Show progress indicator on left side
                    if message.role == "loading" {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if message.role == "assistant" {
                        Text(message.content)
                            .multilineTextAlignment(.leading)
                    } else {
                        ZStack {
                            Text(message.content)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 19)
                        .background(Color.init(uiColor: .systemGray4))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.leading, 160)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            
            HStack(alignment: .bottom) {
                TextField(text: $promptText, axis: .vertical) {
                    Text("Ask anything")
                }
                
                Button {
                    chatStreamService.messages.append(AiMessageChunk(id: UUID().uuidString, role: "user", content: promptText, type: "input_text"))
                    messageContent = chatStreamService.messages
                    chatStreamService.startStream(messages: messageContent)
                    promptText = ""
                } label: {
                    Image(systemName: "arrow.up")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 16)
                .background(Color.blue)
                .clipShape(Capsule())
                .disabled(promptText.isEmpty || promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity((promptText.isEmpty || promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.5 : 1)
            }
            .padding(.leading, 21)
            .padding(.trailing, 7)
            .padding(.vertical, 7)
            .background(Color.init(uiColor: .systemGray4))
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .padding(20)
        .background(Color(hex: "F1F1F1"))
        .onAppear {
            // Initialize the chat service with existing messages
            chatStreamService.messages = messageContent
        }
        .onChange(of: chatStreamService.messages) { _, newMessages in
            // Sync local chat service changes back to the binding
            messageContent = newMessages
        }
    }
}
