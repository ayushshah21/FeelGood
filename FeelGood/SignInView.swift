//
//  SignInView.swift
//  FeelGood
//
//  Created for FeelGood.
//

import SwiftUI
import Firebase

struct SignInView: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    
    var body: some View {
        ZStack {
            // Background using the user's chosen theme color
            Color(userModel.activeTheme.mainColor)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // App logo/title
                VStack(spacing: 10) {
                    // Simple logo avatar - same as in onboarding
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.9))
                            .frame(width: 100, height: 100)
                            .shadow(color: .black.opacity(0.1), radius: 10)
                        
                        VStack(spacing: 2) {
                            // Simple smiley face
                            HStack(spacing: 30) {
                                Circle()
                                    .fill(.black)
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .fill(.black)
                                    .frame(width: 8, height: 8)
                            }
                            
                            // Smile
                            Image(systemName: "mouth.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30)
                                .foregroundColor(.orange)
                                .offset(y: 5)
                        }
                    }
                    
                    Text("Welcome to VybeCheck")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.top, 50)
                
                // Sign in form
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("you@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        SecureField("Your password", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    
                    // Error message (if any)
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    }
                    
                    // Sign in button
                    Button(action: {
                        authViewModel.signIn(email: email, password: password, userModel: userModel)
                    }) {
                        HStack {
                            if authViewModel.isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: userModel.activeTheme.mainColor))
                                    .padding(.trailing, 5)
                            }
                            
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(userModel.activeTheme.mainColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                    }
                    .padding(.top, 10)
                    .disabled(authViewModel.isAuthenticating)
                    
                    // Toggle to sign up view
                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("Don't have an account? Sign Up")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .underline()
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(userModel)
                .environmentObject(authViewModel)
        }
    }
}
