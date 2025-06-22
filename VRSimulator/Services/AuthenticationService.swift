//
//  AuthenticationService.swift
//  VRSimulator
//
//  Created by Dhanalakshmi on 21/05/25.
//

import Foundation
import Combine

class AuthenticationService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    
    func login() {
        isAuthenticated = true
    }
    
    func logout() {
        isAuthenticated = false
    }
}
