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
                            print("Error handling stream data \(error.localizedDescription) AND Data \(String(data: data, encoding: .utf8))")
                            
                            if let stringData = String(data: data, encoding: .utf8), stringData.contains("[DONE]") {
                                if (self?.messages.count ?? 0) >= 2 {
                                    // TODO: - Store message in our backend
                                    /*self?.storaDataManager.fetchStoreData(response: StoreResult(
                                        _id: "",
                                        userId: AppData.shared.uniqueUserId,
                                        prompt: self?.messages[(self?.messages.count ?? 0)-2].content ?? "",
                                        result: self?.messages.last?.content ?? "",
                                        totalTokens:  0,
                                        date: Double(Date().timeIntervalSinceReferenceDate),
                                        sharableResult: userDefaults.bool(forKey: UserDefaultsConstants.shouldShareResults.rawValue),
                                        searchOnWeb: false,
                                        likes: nil,
                                        isSummary: false
                                    ))*/
                                }
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
        print("Handle stream data with Data \(String(data: data, encoding: .utf8))")
        
        guard let jsonString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw StreamError.apiError(description: "Invalid encoding")
        }
        
        if jsonString.contains("context_length_exceeded") {
            throw StreamError.apiError(description: "Context length exceeded.")
        } else if jsonString.contains("error\":") {
            throw StreamError.apiError(description: jsonString)
        }
        
        // Use "\n\n" to separate between multiple messages or chunks,
        // and replace any occurrences of duplicated "data: " prefixes
        let cleanedString = jsonString.replacingOccurrences(of: "data: data: ", with: "data: ")
        let dataBlocks = cleanedString.components(separatedBy: "\n\n")

        for block in dataBlocks {
            // Further clean up to ensure only one "data: " prefix remains for decoding.
            let subBlocks = block.components(separatedBy: "\n").filter { $0.hasPrefix("data: ") }
            
            for subBlock in subBlocks {
                let chunkJsonString = subBlock.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if chunkJsonString.isEmpty { continue }
                
                guard let cleanedData = chunkJsonString.data(using: .utf8) else {
                    throw StreamError.apiError(description: "Data cleaning error")
                }
                
                do {
                    let decoder = JSONDecoder()
                    print("Decoding \(chunkJsonString) for data \(String(data: data, encoding: .utf8)) And cleaned string \(cleanedString) and data blocks \(dataBlocks)")
                    let chatCompletionChunk = try decoder.decode(ChatCompletionStream.self, from: cleanedData)
                    
                    if let index = self.messages.firstIndex(where: {$0.id == id}) {
                        if let content = chatCompletionChunk.choices?.first?.delta?.content {
                            self.messages[index].content += content
                        }
                    } else {
                        // New message, create and assign ID
                        if let content = chatCompletionChunk.choices?.first?.delta?.content {
                            let chunk: AiMessageChunk = AiMessageChunk(id: id, role: "assistant", content: content, type: "input_text")
                            self.messages.append(chunk)
                        }
                    }
                    
                    print("Message appended full \(self.messages)")
                    self.processMessages()
                } catch {
                    throw StreamError.parsingError(description: error.localizedDescription)
                }
            }
        }
    }
        
    @MainActor
    private func processMessages() {
        if let lastMessage = messages.last {
            let content = lastMessage.content // Assuming lastMessage is the text content

            // Use NSRegularExpression to match sentence-ending punctuation followed by space or end of the string.
            let pattern = "[^.!?]*[.!?]+"
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let nsrange = NSRange(content.startIndex..<content.endIndex, in: content)
            
            // Find matches in the content and map them to Swift String.
            let matches = regex.matches(in: content, options: [], range: nsrange)
            let sentences = matches.map { (match) -> String in
                let range = Range(match.range, in: content)!
                return String(content[range])
            }
            
            // Filter out and append sentences that are not already in the accumulatedTextForSpeech.
            for sentence in sentences {
                let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !accumulatedTextForSpeech.contains(trimmedSentence) {
                    accumulatedTextForSpeech.append(trimmedSentence)
                    print("I got full sentence \(trimmedSentence)")
                }
            }
        }
    }
}

enum StreamError: Error {
    case parsingError(description: String)
    case networkError(description: String)
    case apiError(description: String)
}
