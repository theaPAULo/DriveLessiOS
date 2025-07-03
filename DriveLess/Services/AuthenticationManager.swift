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
import CoreData  // ADD THIS LINE
import FirebaseFirestore  // 🆕 ADD THIS


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
    private var reauthContinuation: CheckedContinuation<Void, Error>?  // ADD THIS LINE
    
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
            print("🔐 Firebase UID: \(firebaseUser.uid)") // ADD THIS LINE
            
            // Determine the provider based on Firebase provider data
            let provider: DriveLessUser.AuthProvider
            let providerString: String
            if firebaseUser.providerData.contains(where: { $0.providerID == "google.com" }) {
                provider = .google
                providerString = "Google"
            } else if firebaseUser.providerData.contains(where: { $0.providerID == "apple.com" }) {
                provider = .apple
                providerString = "Apple"
            } else {
                provider = .google // Default fallback
                providerString = "Google"
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
            
            // 🆕 NEW: Track user sign-in session to Firestore
            FirestoreAnalyticsService.shared.trackUserSignIn(signInMethod: providerString)
            
        } else {
            print("❌ User is signed out")
            
            // 🆕 NEW: Track sign-out to Firestore
            FirestoreAnalyticsService.shared.trackUserSignOut()
            
            self.user = nil
            self.isSignedIn = false
        }
        
        self.isLoading = false
        self.errorMessage = nil
    }
    
    // MARK: - Public Methods
    
    /// Signs out the current user
    /// Signs out the current user
    func signOut() {
        print("🚪 Signing out user...")
        isLoading = true
        
        do {
            // 🆕 NEW: End user session before signing out
            FirestoreAnalyticsService.shared.trackUserSignOut()
            
            try Auth.auth().signOut()
            print("✅ Successfully signed out")
        } catch {
            print("❌ Sign out error: \(error.localizedDescription)")
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Deletes the user's account and all associated data
        func deleteAccount() async {
            print("🗑️ Starting account deletion process...")
            
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            guard let currentUser = Auth.auth().currentUser else {
                await MainActor.run {
                    self.errorMessage = "No user is currently signed in"
                    self.isLoading = false
                }
                return
            }
            
            do {
                // Step 1: Clear all local Core Data
                print("🗑️ Clearing local data...")
                await clearAllUserData()
                
                // Step 2: Delete Firebase Auth account
                print("🗑️ Deleting Firebase account...")
                try await currentUser.delete()
                
                await MainActor.run {
                    print("✅ Account deletion successful")
                    self.user = nil
                    self.isSignedIn = false
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    print("❌ Account deletion failed: \(error.localizedDescription)")
                    self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
        
    /// Clears all user data from Core Data
    private func clearAllUserData() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let context = CoreDataManager.shared.backgroundContext()
            
            context.perform {
                do {
                    // Delete all SavedRoute entities
                    let routeRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SavedRoute")
                    let routeDeleteRequest = NSBatchDeleteRequest(fetchRequest: routeRequest)
                    try context.execute(routeDeleteRequest)
                    
                    // Delete all SavedAddress entities
                    let addressRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SavedAddress")
                    let addressDeleteRequest = NSBatchDeleteRequest(fetchRequest: addressRequest)
                    try context.execute(addressDeleteRequest)
                    
                    // Delete all UsageTracking entities
                    let usageRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "UsageTracking")
                    let usageDeleteRequest = NSBatchDeleteRequest(fetchRequest: usageRequest)
                    try context.execute(usageDeleteRequest)
                    
                    // Save the context
                    try context.save()
                    
                    print("✅ All local user data cleared")
                    continuation.resume()
                    
                } catch {
                    print("❌ Failed to clear local data: \(error.localizedDescription)")
                    continuation.resume()
                }
            }
        }
    }
    
    /// Reauthenticates the user and then deletes the account
        func reauthenticateAndDeleteAccount() async {
            print("🔐 Starting reauthentication for account deletion...")
            
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            guard let currentUser = user else {
                await MainActor.run {
                    self.errorMessage = "No user is currently signed in"
                    self.isLoading = false
                }
                return
            }
            
            do {
                // Step 1: Reauthenticate based on provider
                switch currentUser.provider {
                case .google:
                    print("🌐 Reauthenticating with Google...")
                    try await reauthenticateWithGoogle()
                case .apple:
                    print("🍎 Reauthenticating with Apple...")
                    try await reauthenticateWithApple()
                }
                
                // Step 2: Now delete the account (user is freshly authenticated)
                await deleteAccount()
                
            } catch {
                await MainActor.run {
                    print("❌ Reauthentication failed: \(error.localizedDescription)")
                    self.errorMessage = "Reauthentication failed: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
        
    /// Reauthenticates with Google
    private func reauthenticateWithGoogle() async throws {
        // Get the client ID from Firebase configuration
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Firebase client ID found"])
        }
        
        // Configure Google Sign-In
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find root view controller"])
        }
        
        await MainActor.run {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        
        // Use the async version of signIn
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Google user token"])
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        
        // Reauthenticate with Firebase
        try await Auth.auth().currentUser?.reauthenticate(with: credential)
        print("✅ Google reauthentication successful")
    }
        
        /// Reauthenticates with Apple
        private func reauthenticateWithApple() async throws {
            return try await withCheckedThrowingContinuation { continuation in
                Task { @MainActor in
                    // Generate a random nonce for security
                    let nonce = randomNonceString()
                    self.currentNonce = nonce
                    
                    // Create Apple Sign-In request
                    let request = ASAuthorizationAppleIDProvider().createRequest()
                    request.requestedScopes = [] // No scopes needed for reauthentication
                    request.nonce = sha256(nonce)
                    
                    // Store continuation for callback
                    self.reauthContinuation = continuation
                    
                    // Create authorization controller
                    let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                    authorizationController.delegate = self
                    authorizationController.presentationContextProvider = self
                    authorizationController.performRequests()
                }
            }
        }
    
    /// Signs in with Google
    func signInWithGoogle() {
        print("🌐 Starting Google Sign-In...")
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Get the client ID from Firebase configuration
                guard let clientID = FirebaseApp.app()?.options.clientID else {
                    await MainActor.run {
                        print("❌ No Firebase client ID found")
                        self.errorMessage = "Configuration error: No client ID"
                        self.isLoading = false
                    }
                    return
                }
                
                // Configure Google Sign-In
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController else {
                    await MainActor.run {
                        print("❌ Could not find root view controller")
                        self.errorMessage = "Unable to present sign-in"
                        self.isLoading = false
                    }
                    return
                }
                
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
                
                // Use the async version of signIn
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
                
                guard let idToken = result.user.idToken?.tokenString else {
                    await MainActor.run {
                        print("❌ Failed to get Google user token")
                        self.errorMessage = "Failed to get authentication token"
                        self.isLoading = false
                    }
                    return
                }
                
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )
                
                // Sign in to Firebase with Google credential
                try await Auth.auth().signIn(with: credential)
                
                await MainActor.run {
                    print("✅ Google Sign-In successful")
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    print("❌ Google Sign-In error: \(error.localizedDescription)")
                    self.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                    self.isLoading = false
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
                // Using SecRandomCopyBytes for cryptographically secure random generation
                // This is the correct approach for security-sensitive operations
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
                        if let continuation = self.reauthContinuation {
                            continuation.resume(throwing: NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple Sign-In failed: Invalid state"]))
                            self.reauthContinuation = nil
                        } else {
                            self.errorMessage = "Apple Sign-In failed: Invalid state"
                            self.isLoading = false
                        }
                    }
                    return
                }
                
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("❌ Unable to fetch identity token from Apple")
                    Task { @MainActor in
                        if let continuation = self.reauthContinuation {
                            continuation.resume(throwing: NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple Sign-In failed: No identity token"]))
                            self.reauthContinuation = nil
                        } else {
                            self.errorMessage = "Apple Sign-In failed: No identity token"
                            self.isLoading = false
                        }
                    }
                    return
                }
                
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("❌ Unable to serialize token string from data")
                    Task { @MainActor in
                        if let continuation = self.reauthContinuation {
                            continuation.resume(throwing: NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple Sign-In failed: Token serialization error"]))
                            self.reauthContinuation = nil
                        } else {
                            self.errorMessage = "Apple Sign-In failed: Token serialization error"
                            self.isLoading = false
                        }
                    }
                    return
                }
                
                // Initialize Firebase credential
                let credential = OAuthProvider.credential(providerID: AuthProviderID.apple,
                                                        idToken: idTokenString,
                                                        rawNonce: nonce)
                
                // Check if this is reauthentication or normal sign-in
                if let continuation = reauthContinuation {
                    // This is reauthentication for account deletion
                    Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                        Task { @MainActor in
                            if let error = error {
                                print("❌ Apple reauthentication failed: \(error.localizedDescription)")
                                continuation.resume(throwing: error)
                            } else {
                                print("✅ Apple reauthentication successful")
                                continuation.resume()
                            }
                            self.reauthContinuation = nil
                        }
                    }
                } else {
                    // This is normal sign-in
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
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            print("❌ Apple Sign-In error: \(error.localizedDescription)")
            
            Task { @MainActor in
                // Check if this is reauthentication
                if let continuation = self.reauthContinuation {
                    continuation.resume(throwing: error)
                    self.reauthContinuation = nil
                    return
                }
                
                // Handle different Apple Sign-In error cases for normal sign-in
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
                    case .notInteractive:
                        self.errorMessage = "Apple Sign-In not available in current context."
                    case .matchedExcludedCredential:
                        self.errorMessage = "Apple Sign-In credential excluded. Please try again."
                    case .credentialImport:
                        self.errorMessage = "Apple Sign-In credential import failed. Please try again."
                    case .credentialExport:
                        self.errorMessage = "Apple Sign-In credential export failed. Please try again."
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
