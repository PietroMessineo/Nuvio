//
//  Networking.swift
//  Alfred3
//
//  Created by Pietro Messineo on 16/12/23.
//

import Foundation
import Alamofire
import SwiftUI
import Combine
import Piadina

// Define the ObservableObject
class ChatStreamService: ObservableObject, @unchecked Sendable {
    
    @Published var messages: [AiMessageChunk] = []
    
    @Published var error: StreamError?
    
    @Published var accumulatedTextForSpeech: [String] = []

    let chatCompletionURL = "http://142.44.242.207:3035/v1/responses"
    
    func startStream(messages: [AiMessageChunk]) {
        print("Start stream with messages \(messages)")
        
        Task {
            // Get the user token on the main actor
            let userToken = AppData.shared.userToken ?? ""
            
            // Move the request creation to a nonisolated context
            let openAIRequest = await self.createOpenAIRequest(from: messages, userToken: userToken)
            
            // Perform the network request on the main actor
            await self.performStreamRequest(with: openAIRequest, userToken: userToken)
        }
    }
    
    private nonisolated func createOpenAIRequest(from messages: [AiMessageChunk], userToken: String) -> OpenAIRequest {
        // Apply system message
        var editedMessages = messages
        let content = "You are Nuvio, an iOS App used from students to learn or speedup their learning path."
        
        // Insert system message
        editedMessages.insert(AiMessageChunk(id: "", role: "system", content: content, type: "input_text"), at: 0)
        
        let openAIRequest = OpenAIRequest(
            model: "gpt-5-nano",
            input: editedMessages.filter({$0.role != "loader"}).map({ message in
                if message.type == "input_text" {
                    return AiMessage(role: message.role, content: [Content(type: message.type, text: message.content, image_url: nil)])
                } else if message.type == "image_url" {
                    return AiMessage(role: message.role, content: [Content(type: message.type, text: nil, image_url: AiImage(url: message.content))])
                    // data:image/jpeg;base64,{ENCODED_IMAGE}
                } else {
                    return AiMessage(role: message.role, content: [Content(type: message.type, text: message.content, image_url: nil)])
                }
            }),
            user: userToken,
            stream: true
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(openAIRequest)
        print("JSON PAYLOAD \(String(data: data, encoding: .utf8))")
        
        return openAIRequest
    }
    
    @MainActor
    private func performStreamRequest(with openAIRequest: OpenAIRequest, userToken: String) {
        // Encode the request to Data manually to avoid Sendable/MainActor isolation issues
        guard let requestData = try? JSONEncoder().encode(openAIRequest) else {
            self.error = .apiError(description: "Failed to encode request")
            return
        }
        
        // Create URLRequest manually
        guard let url = URL(string: chatCompletionURL) else {
            self.error = .apiError(description: "Invalid URL")
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(userToken, forHTTPHeaderField: "userid")
        urlRequest.setValue("Nuvio", forHTTPHeaderField: "user-agent")
        urlRequest.httpBody = requestData
        
        let streamingRequest = AF.streamRequest(urlRequest)
        
        print("Streaming request")
        
        let chatId: String = UUID().uuidString
        
        streamingRequest.responseStream { [weak self] (stream: DataStreamRequest.Stream<Data, Never>) throws in
            switch stream.event {
            case .stream(let result):
                Task { @MainActor in
                    self?.messages.removeAll(where: { $0.role == "loader" })
                    
                    switch result {
                    case .success(let data):
                        do {
                            try self?.handleStreamData(data, with: chatId)
                        } catch {
                            // Check for stream completion first
                            if let stringData = String(data: data, encoding: .utf8), 
                               stringData.contains("response.completed") {
                                if (self?.messages.count ?? 0) >= 2 {
                                    // TODO: - Store message in our backend
                                    print("✅ Stream completed, message count: \(self?.messages.count ?? 0)")
                                }
                                return // Don't treat completion as an error
                            }
                            
                            // Only log actual errors, not ignored event types
                            if let streamError = error as? StreamError {
                                // Don't log errors for normal SSE events that we just ignore
                                if case .ignoredEvent = streamError {
                                    return
                                }
                                print("⚠️ Stream error: \(streamError)")
                                self?.error = streamError
                            }
                        }
                    case .failure(let error):
                        self?.error = .networkError(description: error.localizedDescription)
                    }
                }
            case .complete(let completionStream):
                Task { @MainActor in
                    self?.messages.removeAll(where: { $0.role == "loader" })
                }
                print("Complete and completion stream \(completionStream.error) AND \(completionStream.response)")
                break
            }
        }
    }
    
    @MainActor
    private func handleStreamData(_ data: Data, with id: String) throws {
        guard let jsonString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw StreamError.apiError(description: "Invalid encoding")
        }
        
        // Parse Server-Sent Events format - events are separated by double newlines
        let eventBlocks = jsonString.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        
        for eventBlock in eventBlocks {
            let lines = eventBlock.components(separatedBy: "\n")
            var currentEvent: String?
            var currentData: String?
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if trimmedLine.hasPrefix("event: ") {
                    currentEvent = String(trimmedLine.dropFirst(7)) // Remove "event: "
                } else if trimmedLine.hasPrefix("data: ") {
                    currentData = String(trimmedLine.dropFirst(6)) // Remove "data: "
                }
            }
            
            // Process the data if we have both event and data
            if let event = currentEvent, let data = currentData, !data.isEmpty {
                // Check for error conditions in the actual JSON data only
                if data.contains("context_length_exceeded") {
                    throw StreamError.apiError(description: "Context length exceeded.")
                } else if data.contains("\"error\":") && !data.contains("\"error\":null") {
                    throw StreamError.apiError(description: data)
                }
                
                try processServerSentEvent(event: event, data: data, chatId: id)
            }
        }
    }
    
    @MainActor
    private func processServerSentEvent(event: String, data: String, chatId: String) throws {
        // Handle different SSE event types
        switch event {
        case "response.created":
            // Stream initialization - silently ignore
            throw StreamError.ignoredEvent
            
        case "response.in_progress":
            // Stream in progress - silently ignore
            throw StreamError.ignoredEvent
            
        case "response.output_item.added":
            // New output item added - silently ignore
            throw StreamError.ignoredEvent
            
        case "response.output_item.done":
            // Output item completed - silently ignore
            throw StreamError.ignoredEvent
            
        case "response.content_part.added":
            // Content part added - silently ignore
            throw StreamError.ignoredEvent
            
        case "response.content_part.done":
            // Content part done - silently ignore
            throw StreamError.ignoredEvent
            
        case "response.output_text.done":
            // Text output completed - silently ignore
            throw StreamError.ignoredEvent
            
        case "response.completed":
            // Stream completed - silently ignore (handled in error handling)
            throw StreamError.ignoredEvent
            
        case "response.output_text.delta":
            // This is the only event we actually need to process
            print("Processing SSE event: \(event)")
            
            guard let jsonData = data.data(using: .utf8) else {
                throw StreamError.apiError(description: "Failed to convert data to UTF8")
            }
            
            do {
                let decoder = JSONDecoder()
                let deltaEvent = try decoder.decode(OutputTextDelta.self, from: jsonData)
                
                // Extract the delta content
                guard let deltaContent = deltaEvent.delta, !deltaContent.isEmpty else { return }
                
                // Find existing message or create new one
                if let index = self.messages.firstIndex(where: { $0.id == chatId }) {
                    self.messages[index].content += deltaContent
                } else {
                    // New message, create and assign ID
                    let chunk = AiMessageChunk(id: chatId, role: "assistant", content: deltaContent, type: "input_text")
                    self.messages.append(chunk)
                }
                
                print("Message appended, current content length: \(self.messages.last?.content.count ?? 0)")
                self.processMessages()
                
            } catch {
                throw StreamError.parsingError(description: error.localizedDescription)
            }
            
        default:
            // Unknown event type - log it but don't treat as error
            print("ℹ️ Unknown SSE event type: \(event)")
            throw StreamError.ignoredEvent
        }
    }
        
    @MainActor
    private func processMessages() {
        if let lastMessage = messages.last {
            let content = lastMessage.content

            // Use NSRegularExpression to match sentence-ending punctuation
            let pattern = "[^.!?]*[.!?]+"
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let nsrange = NSRange(content.startIndex..<content.endIndex, in: content)
            
            // Find matches in the content and map them to Swift String
            let matches = regex.matches(in: content, options: [], range: nsrange)
            let sentences = matches.map { (match) -> String in
                let range = Range(match.range, in: content)!
                return String(content[range])
            }
            
            // Filter out and append sentences that are not already accumulated
            for sentence in sentences {
                let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !accumulatedTextForSpeech.contains(trimmedSentence) {
                    accumulatedTextForSpeech.append(trimmedSentence)
                    print("📝 New sentence ready for speech: \(trimmedSentence.prefix(50))...")
                }
            }
        }
    }
}

// MARK: - Stream Event Models
struct OutputTextDelta: Codable {
    let type: String
    let sequenceNumber: Int?
    let itemId: String?
    let outputIndex: Int?
    let contentIndex: Int?
    let delta: String?
    let logprobs: [String]?
    let obfuscation: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case sequenceNumber = "sequence_number"
        case itemId = "item_id"
        case outputIndex = "output_index"
        case contentIndex = "content_index"
        case delta
        case logprobs
        case obfuscation
    }
}

enum StreamError: Error {
    case parsingError(description: String)
    case networkError(description: String)
    case apiError(description: String)
    case ignoredEvent // For SSE events we don't need to process
}
