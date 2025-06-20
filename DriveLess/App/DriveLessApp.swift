//
//  DriveLessApp.swift
//  DriveLess
//

import SwiftUI

@main
struct DriveLessApp: App {
    // Register AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Core Data manager instance
    let coreDataManager = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataManager.viewContext)
                .environmentObject(coreDataManager)
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
