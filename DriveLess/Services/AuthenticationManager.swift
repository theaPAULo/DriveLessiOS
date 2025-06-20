//
//  AuthenticationManager.swift
//  DriveLess
//
//  Handles Firebase authentication with Google Sign-In
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

// MARK: - User Model
struct DriveLessUser {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let provider: AuthProvider
    
    enum AuthProvider {
        case google
    }
}

// MARK: - Authentication Manager
@MainActor
class AuthenticationManager: ObservableObject {
    // Published properties that SwiftUI views can observe
    @Published var user: DriveLessUser?
    @Published var isSignedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {
        print("🔐 AuthenticationManager: Initializing...")
        
        // Listen for authentication state changes
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.updateUserState(user)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Updates the user state when Firebase auth state changes
    private func updateUserState(_ firebaseUser: User?) {
        if let firebaseUser = firebaseUser {
            print("✅ User is signed in: \(firebaseUser.email ?? "No email")")
            
            // Create our user model (Google only for now)
            self.user = DriveLessUser(
                uid: firebaseUser.uid,
                email: firebaseUser.email,
                displayName: firebaseUser.displayName,
                photoURL: firebaseUser.photoURL,
                provider: .google
            )
            self.isSignedIn = true
        } else {
            print("❌ User is signed out")
            self.user = nil
            self.isSignedIn = false
        }
        
        self.isLoading = false
        self.errorMessage = nil
    }
    
    // MARK: - Public Methods
    
    /// Signs out the current user
    func signOut() {
        print("🚪 Signing out user...")
        isLoading = true
        
        do {
            try Auth.auth().signOut()
            print("✅ Successfully signed out")
        } catch {
            print("❌ Sign out error: \(error.localizedDescription)")
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Signs in with Google
    func signInWithGoogle() {
        print("🌐 Starting Google Sign-In...")
        isLoading = true
        errorMessage = nil
        
        // Get the client ID from Firebase configuration
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ No Firebase client ID found")
            errorMessage = "Configuration error: No client ID"
            isLoading = false
            return
        }
        
        // Configure Google Sign-In
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Could not find root view controller")
            errorMessage = "Unable to present sign-in"
            isLoading = false
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            Task { @MainActor in
                if let error = error {
                    print("❌ Google Sign-In error: \(error.localizedDescription)")
                    self?.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                    self?.isLoading = false
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    print("❌ Failed to get Google user token")
                    self?.errorMessage = "Failed to get authentication token"
                    self?.isLoading = false
                    return
                }
                
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )
                
                // Sign in to Firebase with Google credential
                Auth.auth().signIn(with: credential) { authResult, error in
                    Task { @MainActor in
                        if let error = error {
                            print("❌ Firebase Google Sign-In error: \(error.localizedDescription)")
                            self?.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                        } else {
                            print("✅ Google Sign-In successful")
                        }
                        self?.isLoading = false
                    }
                }
            }
        }
    }
}
