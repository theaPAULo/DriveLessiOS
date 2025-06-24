//
//  AuthenticationManager.swift
//  DriveLess
//
//  Handles Firebase authentication with Google Sign-In AND Apple Sign-In
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices  // ADD: Import for Apple Sign-In
import CryptoKit  // ADD: Import for Apple Sign-In crypto

// MARK: - User Model
struct DriveLessUser {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let provider: AuthProvider
    
    enum AuthProvider {
        case google
        case apple  // ADD: Apple provider
    }
}

// MARK: - Authentication Manager
@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    // Published properties that SwiftUI views can observe
    @Published var user: DriveLessUser?
    @Published var isSignedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // ADD: Apple Sign-In specific properties
    private var currentNonce: String?
    
    override init() {
        super.init()
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
            
            // Determine the provider based on Firebase provider data
            let provider: DriveLessUser.AuthProvider
            if firebaseUser.providerData.contains(where: { $0.providerID == "google.com" }) {
                provider = .google
            } else if firebaseUser.providerData.contains(where: { $0.providerID == "apple.com" }) {
                provider = .apple
            } else {
                provider = .google // Default fallback
            }
            
            // Create our user model
            self.user = DriveLessUser(
                uid: firebaseUser.uid,
                email: firebaseUser.email,
                displayName: firebaseUser.displayName,
                photoURL: firebaseUser.photoURL,
                provider: provider
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
    
    // ADD: Apple Sign-In method
    /// Signs in with Apple
    func signInWithApple() {
        print("🍎 Starting Apple Sign-In...")
        isLoading = true
        errorMessage = nil
        
        // Generate a random nonce for security
        let nonce = randomNonceString()
        currentNonce = nonce
        
        // Create Apple Sign-In request
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        // Create authorization controller
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // ADD: Helper methods for Apple Sign-In crypto
    
    /// Generates a random nonce for Apple Sign-In security
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    /// Creates SHA256 hash of the input string
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// ADD: Apple Sign-In delegate extensions
extension AuthenticationManager: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 Apple Sign-In completed successfully")
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                print("❌ Invalid state: A login callback was received, but no login request was sent.")
                Task { @MainActor in
                    self.errorMessage = "Apple Sign-In failed: Invalid state"
                    self.isLoading = false
                }
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("❌ Unable to fetch identity token from Apple")
                Task { @MainActor in
                    self.errorMessage = "Apple Sign-In failed: No identity token"
                    self.isLoading = false
                }
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("❌ Unable to serialize token string from data")
                Task { @MainActor in
                    self.errorMessage = "Apple Sign-In failed: Token serialization error"
                    self.isLoading = false
                }
                return
            }
            
            // Initialize Firebase credential
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                    idToken: idTokenString,
                                                    rawNonce: nonce)
            
            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { authResult, error in
                Task { @MainActor in
                    if let error = error {
                        print("❌ Firebase Apple Sign-In error: \(error.localizedDescription)")
                        self.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                    } else {
                        print("✅ Apple Sign-In successful")
                        
                        // Update display name if this is the first time signing in
                        if let user = authResult?.user, user.displayName == nil {
                            let changeRequest = user.createProfileChangeRequest()
                            let fullName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                                .compactMap { $0 }
                                .joined(separator: " ")
                            
                            if !fullName.isEmpty {
                                changeRequest.displayName = fullName
                                changeRequest.commitChanges { error in
                                    if let error = error {
                                        print("❌ Error updating display name: \(error.localizedDescription)")
                                    } else {
                                        print("✅ Display name updated to: \(fullName)")
                                    }
                                }
                            }
                        }
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign-In error: \(error.localizedDescription)")
        
        Task { @MainActor in
            // Handle different Apple Sign-In error cases
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    print("🍎 User canceled Apple Sign-In")
                    self.errorMessage = nil // Don't show error for user cancellation
                case .failed:
                    self.errorMessage = "Apple Sign-In failed. Please try again."
                case .invalidResponse:
                    self.errorMessage = "Invalid response from Apple. Please try again."
                case .notHandled:
                    self.errorMessage = "Apple Sign-In not handled. Please try again."
                case .unknown:
                    self.errorMessage = "Unknown Apple Sign-In error. Please try again."
                @unknown default:
                    self.errorMessage = "Apple Sign-In error. Please try again."
                }
            } else {
                self.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
            }
            
            self.isLoading = false
        }
    }
}

// ADD: Apple Sign-In presentation context provider
extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("Unable to get window for Apple Sign-In")
        }
        return window
    }
}
