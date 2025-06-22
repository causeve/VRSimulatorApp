//
//  LoginView.swift
//  VRSimulator
//
//  Created by Dhanalakshmi on 21/05/25.
//

import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var isLoggingIn: Bool = false
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        VStack {
            // Header Section
            VStack(spacing: 8) {
                Text("VR Simulator")
                    .font(.system(size: 48, weight: .bold))
                
                Text("Sign in to access the control panel")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 40)
            
            // Login Form Section
            VStack(spacing: 16) {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                if showError {
                    Text("Invalid username or password")
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }
                
                Button(action: login) {
                    if isLoggingIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("SIGN IN")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .disabled(isLoggingIn)
                .padding()
                
                Text("Default credentials: admin / 123")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Company Branding Footer
            VStack(spacing: 4) {
                Text("Powered by")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Causeve Technologies")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 20)
        }
        .padding()
        .frame(maxWidth: 400)
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
    }
    
    func login() {
        isLoggingIn = true
        showError = false
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if username == "admin" && password == "123" {
                authService.login()
            } else {
                showError = true
            }
            isLoggingIn = false
        }
    }
}
