//
//  AppDelegate.swift
//  DriveLess
//

import UIKit
import GoogleMaps
import GooglePlaces
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase FIRST - this must come before other Google services
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
        
        // Get API key securely from configuration
        let apiKey = ConfigurationManager.shared.googleAPIKey
        
        // Validate that we have an API key (required for app to function)
        if apiKey.isEmpty {
            print("❌ CRITICAL: Google API Key is missing! App may not function properly.")
            // Continue anyway to prevent crash, but log the issue
        } else {
            print("✅ Google API Key loaded successfully")
        }
        
        // Validate other configuration (these are optional, so just warn)
        if ConfigurationManager.shared.adminUserIDs.isEmpty {
            print("⚠️ No admin users configured")
        } else {
            print("✅ Admin users configured: \(ConfigurationManager.shared.adminUserIDs.count)")
        }
        
        if ConfigurationManager.shared.feedbackEmail.isEmpty {
            print("⚠️ No feedback email configured")
        } else {
            print("✅ Feedback email configured")
        }
        
        // Configure Google Maps and Places - Use API key even if empty (will fail gracefully)
        GMSServices.provideAPIKey(apiKey)
        GMSPlacesClient.provideAPIKey(apiKey)
        print("🗺️ Google Maps SDK configured with key: \(apiKey.isEmpty ? "MISSING" : "✅ Present")")
        
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("❌ Could not get Google Sign-In client ID from GoogleService-Info.plist")
            return true
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        print("🌐 Google Sign-In configured with client ID: \(String(clientId.prefix(10)))...")
        
        return true
    }
    
    // Handle URL schemes for Google Sign-In
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handle Google Sign-In URL
        if GIDSignIn.sharedInstance.handle(url) {
            print("🌐 Handled Google Sign-In URL")
            return true
        }
        
        // Handle other URLs if needed
        return false
    }
}
