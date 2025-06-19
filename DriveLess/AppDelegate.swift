//
//  AppDelegate.swift
//  DriveLess
//
//  Configure Google Maps SDK
//

import UIKit
import GoogleMaps
import GooglePlaces

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        let apiKey = "AIzaSyCancy_vwbDbYZavxDjtpL7NW4lYl8Tkmk"
        
        // Configure Google Maps and Places
        GMSServices.provideAPIKey(apiKey)
        GMSPlacesClient.provideAPIKey(apiKey)
        
        print("🗺️ Google Maps SDK configured with API key: \(String(apiKey.prefix(10)))...")
        
        return true
    }
}
