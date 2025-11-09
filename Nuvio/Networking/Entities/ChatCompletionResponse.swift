//
//  ChatCompletionResponse.swift
//  NutriPix
//
//  Created by Pietro Messineo on 2/21/25.
//


// MARK: - Root Response
struct ChatCompletionResponse: Codable {
    let choices: [Choice]
}

// MARK: - Choice
struct Choice: Codable {
    let index: Int
    let message: Message
}

// MARK: - Message
struct Message: Codable {
    let role: String
    let content: String
    let refusal: String?
}
