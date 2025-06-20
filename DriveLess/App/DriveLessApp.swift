//
//  DriveLessApp.swift
//  DriveLess
//

import SwiftUI

@main
struct DriveLessApp: App {
    // Register AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Hide navigation bars globally while keeping swipe gestures
                    UINavigationBar.appearance().isHidden = true
                    
                    // Also hide the back button indicator
                    UINavigationBar.appearance().backIndicatorImage = UIImage()
                    UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage()
                }
        }
    }
}
