//
//  ConfigurationManager.swift
//  DriveLess
//
//  Secure configuration management for sensitive app data
//

import Foundation
import FirebaseAuth

/// Manages secure access to configuration values stored in Info.plist
/// This prevents hardcoding sensitive data directly in source code
class ConfigurationManager {
    
    // MARK: - Singleton Instance
    static let shared = ConfigurationManager()
    private init() {}
    
    // MARK: - Google API Configuration
    
    /// Securely retrieves Google API key from Info.plist
    /// - Returns: Google API key string, or empty string if not found
    var googleAPIKey: String {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_API_KEY") as? String,
              !apiKey.isEmpty else {
            print("❌ WARNING: Google API Key not found in Info.plist")
            return ""
        }
        return apiKey
    }
    
    // MARK: - Admin Configuration
    
    /// Securely retrieves admin user IDs from Info.plist
    /// - Returns: Array of admin Firebase UIDs
    var adminUserIDs: [String] {
        guard let adminIDs = Bundle.main.object(forInfoDictionaryKey: "ADMIN_USER_IDS") as? [String] else {
            print("❌ WARNING: Admin User IDs not found in Info.plist")
            return []
        }
        return adminIDs
    }
    
    /// Checks if a given user ID is in the admin list
    /// - Parameter userID: Firebase UID to check
    /// - Returns: True if user is an admin
    func isAdminUser(_ userID: String) -> Bool {
        return adminUserIDs.contains(userID)
    }
    
    /// Checks if the currently authenticated user is an admin
    /// - Returns: True if current user is an admin
    func isCurrentUserAdmin() -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            return false
        }
        return isAdminUser(currentUser.uid)
    }
    
    // MARK: - Feedback Configuration
    
    /// Securely retrieves feedback email from Info.plist
    /// - Returns: Email address for feedback, or empty string if not found
    var feedbackEmail: String {
        guard let email = Bundle.main.object(forInfoDictionaryKey: "FEEDBACK_EMAIL") as? String,
              !email.isEmpty else {
            print("❌ WARNING: Feedback Email not found in Info.plist")
            return ""
        }
        return email
    }
    
    // MARK: - Validation Methods
    
    /// Validates that all required configuration values are present
    /// - Returns: True if all required config is available
    func validateConfiguration() -> Bool {
        let hasAPIKey = !googleAPIKey.isEmpty
        let hasAdminIDs = !adminUserIDs.isEmpty
        let hasFeedbackEmail = !feedbackEmail.isEmpty
        
        if !hasAPIKey {
            print("❌ Configuration Error: Missing Google API Key")
        }
        if !hasAdminIDs {
            print("⚠️ Configuration Warning: No admin users configured")
        }
        if !hasFeedbackEmail {
            print("⚠️ Configuration Warning: No feedback email configured")
        }
        
        return hasAPIKey // API key is required, others are optional
    }
}
