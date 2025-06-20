//
//  RouteLoader.swift
//  DriveLess
//
//  Created by Paul Soni on 6/20/25.
//


//
//  RouteLoader.swift
//  DriveLess
//
//  Manages loading saved routes back into the route input form
//

import Foundation
import SwiftUI

class RouteLoader: ObservableObject {
    @Published var routeToLoad: RouteData?
    @Published var shouldNavigateToSearch = false
    
    /// Loads a saved route and triggers navigation to Search tab
    /// - Parameter routeData: The route data to load
    func loadRoute(_ routeData: RouteData) {
        print("🔄 Loading route: \(routeData.startLocation) → \(routeData.endLocation)")
        
        // Store the route data
        self.routeToLoad = routeData
        
        // Trigger navigation to Search tab
        self.shouldNavigateToSearch = true
        
        // Add haptic feedback for better UX
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Clears the loaded route after it's been processed
    func clearLoadedRoute() {
        self.routeToLoad = nil
        self.shouldNavigateToSearch = false
    }
}