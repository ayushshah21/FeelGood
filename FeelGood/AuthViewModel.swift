//
//  AuthViewModel.swift
//  FeelGood
//
//  Created for FeelGood.
//

import SwiftUI
import Firebase
import FirebaseAuth

class AuthViewModel: ObservableObject {
    // Authentication state
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    @Published var user: User?
    @Published var errorMessage: String?
    
    // Initialize and check if user is already signed in
    init() {
        // Set up authentication state listener
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    // Sign in with email and password
    func signIn(email: String, password: String, userModel: UserModel? = nil) {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter both email and password"
            return
        }
        
        self.isAuthenticating = true
        self.errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            self?.isAuthenticating = false
            
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            // Sign-in successful
            self?.user = result?.user
            self?.isAuthenticated = true
            
            // Update userId in UserModel if provided
            if let userModel = userModel, let uid = result?.user.uid {
                userModel.userId = uid
                userModel.savePreferences()
            }
        }
    }
    
    // Create a new account
    func signUp(email: String, password: String, userModel: UserModel? = nil) {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter both email and password"
            return
        }
        
        self.isAuthenticating = true
        self.errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            self?.isAuthenticating = false
            
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            // Account creation successful
            self?.user = result?.user
            self?.isAuthenticated = true
            
            // Update userId in UserModel if provided
            if let userModel = userModel, let uid = result?.user.uid {
                userModel.userId = uid
                userModel.savePreferences()
            }
            
            // Create a user document in Firestore (will implement later)
            self?.createUserDocument()
        }
    }
    
    // Sign out the current user
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // Create a user document in Firestore
    private func createUserDocument() {
        // We'll implement this later when we connect to Firestore
        // This will store user-specific data like preferences
    }
}
