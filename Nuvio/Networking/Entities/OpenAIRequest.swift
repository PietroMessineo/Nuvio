//
//  OpenAIRequest.swift
//  Alfry Ai Vision
//
//  Created by Pietro Messineo on 09/02/24.
//

import Foundation

struct OpenAIRequest: Encodable, Sendable {
    let model: String
    let messages: [AiMessage]
    let n: Int
    let temperature: Int
    let user: String
    let stream: Bool
    let max_tokens: Int
}

struct AiMessage: Codable, Sendable {
    let role: String
    let content: [Content]
}

struct Content: Codable, Sendable {
    let type: String?
    let text: String?
    let image_url: AiImage?
}

struct AiImage: Codable, Sendable {
    let url: String?
}

struct AiMessageChunk: Equatable, Codable, Hashable, Identifiable, Sendable {
    let id: String
    let role: String
    var content: String
    let type: String?
}

struct ChatCompletionStream: Identifiable, Equatable, Codable, Hashable, Sendable {
    let id: String?
    let object: String?
    let choices: [StreamChoice]?
}

struct StreamChoice: Equatable, Codable, Hashable, Sendable {
    let delta: Delta?
}

struct Delta: Equatable, Codable, Hashable, Sendable {
    let content: String?
}
