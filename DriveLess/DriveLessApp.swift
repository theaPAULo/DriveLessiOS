//
//  DriveLessApp.swift
//  DriveLess
//
//  Created by Paul Soni on 6/19/25.
//

import SwiftUI

@main
struct DriveLessApp: App {
    // Register AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
