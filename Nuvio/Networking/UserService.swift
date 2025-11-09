//
//  UserService.swift
//  PiadinaExample
//
//  Created by Pietro Messineo on 5/25/25.
//

import Piadina
import Foundation

class UserService: BaseService {
    let client: HTTPClient
    
    var decoder: JSONDecoder? {
        return JSONDecoder()
    }
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func createUser() async throws -> CreateUserResponse {
        return try await perform(UserEndpoint.createUser, responseType: CreateUserResponse.self)
    }
    
    func getPlantDetails(imgUrl: String) async throws -> ChatCompletionResponse {
        return try await perform(UserEndpoint.getPlantDetails(message: imgUrl), responseType: ChatCompletionResponse.self)
    }
} 
