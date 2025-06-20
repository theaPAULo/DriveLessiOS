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
        
        // Your API key for Google Maps
        let apiKey = "AIzaSyCancy_vwbDbYZavxDjtpL7NW4lYl8Tkmk"
        
        // Configure Google Maps and Places - ONLY ONCE
        GMSServices.provideAPIKey(apiKey)
        GMSPlacesClient.provideAPIKey(apiKey)
        print("🗺️ Google Maps SDK configured with API key: \(String(apiKey.prefix(10)))...")
        
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
