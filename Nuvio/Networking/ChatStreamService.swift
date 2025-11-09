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
    @Published var inProgress: Bool = false
    
    @Published var error: StreamError?
    
    @Published var accumulatedTextForSpeech: [String] = []
    // Buffer to accumulate partial SSE chunks across callbacks
    private var sseBuffer: String = ""

    let chatCompletionURL = "http://142.44.242.207:3035/v1/responses"
    
    func startStream(messages: [AiMessageChunk]) {
        print("Start stream with messages \(messages)")
        
        // Get the user token on the main actor
        let userToken = AppData.shared.userToken ?? ""
        
        // Move the request creation to a nonisolated context
        let openAIRequest = self.createOpenAIRequest(from: messages, userToken: userToken)
        
        // Perform the network request on the main actor
        self.performStreamRequest(with: openAIRequest, userToken: userToken)
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
        // Append incoming chunk to the SSE buffer, preserving partial events across callbacks
        guard let chunkString = String(data: data, encoding: .utf8) else {
            throw StreamError.apiError(description: "Invalid encoding")
        }
        // Normalize CRLF to LF to ensure robust SSE splitting
        let normalizedChunk = chunkString.replacingOccurrences(of: "\r\n", with: "\n")
        print("Chunk string: \(normalizedChunk)")
        // Accumulate chunk
        sseBuffer += normalizedChunk

        // Process complete events from buffer
        while true {
            // Find the next complete event (event + data + double newline)
            let eventPattern = "event: ([^\n]+)\ndata: ([^\n]+(?:\n(?!event:)[^\n]*)*)\n\n"
            let regex = try! NSRegularExpression(pattern: eventPattern, options: [.dotMatchesLineSeparators])
            let range = NSRange(sseBuffer.startIndex..<sseBuffer.endIndex, in: sseBuffer)
            
            guard let match = regex.firstMatch(in: sseBuffer, options: [], range: range) else {
                // No complete event found, wait for more data
                break
            }
            
            // Extract event and data
            let eventRange = Range(match.range(at: 1), in: sseBuffer)!
            let dataRange = Range(match.range(at: 2), in: sseBuffer)!
            let event = String(sseBuffer[eventRange])
            let dataPayload = String(sseBuffer[dataRange])
            
            // For delta events, validate JSON before processing
            if event == "response.output_text.delta" {
                // Always remove any loading placeholder before handling deltas
                self.messages.removeAll(where: { $0.role == "loading" })
                
                if let jsonData = dataPayload.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
                   let dict = jsonObject as? [String: Any],
                   let delta = dict["delta"] as? String {
                    
                    print("Processing SSE event: \(event)")
                    print("Delta content received: \(delta)")
                    
                    // Process the delta immediately
                    if let index = self.messages.firstIndex(where: { $0.id == id }) {
                        self.messages[index].content += delta
                    } else {
                        let chunk = AiMessageChunk(id: id, role: "assistant", content: delta, type: "output_text")
                        self.messages.append(chunk)
                    }
                    
                    print("Message appended, current content length: \(self.messages.last?.content.count ?? 0)")
                    self.processMessages()
                }
            } else {
                // Process other events normally but don't throw for ignored ones
                do {
                    try processServerSentEvent(event: event, data: dataPayload, chatId: id)
                } catch StreamError.ignoredEvent {
                    // Silently ignore these events
                }
            }
            
            // Remove the processed event from buffer
            let matchRange = Range(match.range, in: sseBuffer)!
            sseBuffer.removeSubrange(matchRange)
        }
    }
    
    @MainActor
    private func processServerSentEvent(event: String, data: String, chatId: String) throws {
        // print("Event: \(event), Data: \(data)")
        // Handle different SSE event types
        switch event {
        case "response.created":
            // Stream initialization - silently ignore
            throw StreamError.ignoredEvent
            
        case "response.in_progress":
            // Stream in progress - silently ignore
            let chunk = AiMessageChunk(id: chatId, role: "loading", content: "", type: "input_text")
            self.messages.append(chunk)
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
            print("🚨 NOT Processing SSE event 🚨 : \(event)")
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

