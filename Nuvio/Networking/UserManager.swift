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
    
    static let userClient = DefaultHTTPClient(configuration: userConfig)
    
    let userService: UserService
    
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
    }
    
    /// Create user
    func createUser() async throws {
        let userCreation = try await userService.createUser()
        print("User creation status - \(userCreation.message)")
    }
} 
