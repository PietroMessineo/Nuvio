//
//  UserManager.swift
//  PiadinaExample
//
//  Created by Pietro Messineo on 5/25/25.
//

import Foundation
import Piadina
import SwiftUI
import Combine

@MainActor
class UserManager: ObservableObject {
    // MARK: - init
    static let userConfig = NetworkConfiguration(
        scheme: "http",
        host: "142.44.242.207",
        port: 3034,
        defaultHeaders: ["Content-Type": "application/json"]
    )
    
    static let plantConfig = NetworkConfiguration(
        scheme: "http",
        host: "142.44.242.207",
        port: 3035,
        defaultHeaders: ["Content-Type": "application/json"]
    )
    
    static let userClient = DefaultHTTPClient(configuration: userConfig)
    static let plantClient = DefaultHTTPClient(configuration: plantConfig)
    
    let userService: UserService
    let plantService: UserService
    
    // MARK: - Published Properties
    @Published var selectedImage: UIImage? = nil
    @Published var uploadedImageUrl: String?
    @Published var errorMessage: String?
    @Published var showErrorMessage: Bool = false
    @Published var plantDetails: PlantDetailsResponse?
    
    // Loading status
    @Published var isImageUploading: Bool = false
    @Published var isPlantAnalyzing: Bool = false
    
    init() {
        self.userService = UserService(client: Self.userClient)
        self.plantService = UserService(client: Self.plantClient)
    }
    
    /// Create user
    func createUser() async throws {
        let userCreation = try await userService.createUser()
        print("User creation status - \(userCreation.message)")
    }
    
    /// Get plant details
    func getPlantDetails(imgUrl: String) async throws {
        // Set loading state update
        self.isPlantAnalyzing = true
        // Reset plant details
        self.plantDetails = nil
        
        do {
            let chatCompletion = try await plantService.getPlantDetails(imgUrl: imgUrl)
            print("I GOT CONTENT \(chatCompletion.choices.first?.message.content)")
            if let messageContent = chatCompletion.choices.first?.message.content.data(using: .utf8) {
                // Decode the content into our JSON
                let plantDetailsResponse = try JSONDecoder().decode(PlantDetailsResponse.self, from: messageContent)
                self.plantDetails = plantDetailsResponse
                print("I got plant details \(plantDetailsResponse)")
            } else {
                errorMessage = "Failed to get food nutrients. Go back and try again."
                self.showErrorMessage = true
            }
            print("Retrieved plant details for \(plantDetails?.name)")
        } catch {
            errorMessage = "Failed to get plant details. Please try again."
            showErrorMessage = true
            print("Plant analysis error: \(error)")
        }
        
        isPlantAnalyzing = false
    }
} 
