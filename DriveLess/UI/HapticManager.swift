//
//  HapticManager.swift
//  DriveLess
//
//  Created by Paul Soni on 6/23/25.
//


//
//  HapticManager.swift
//  DriveLess
//
//  Manages haptic feedback throughout the app
//

import UIKit
import SwiftUI

class HapticManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "hapticsEnabled")
        }
    }
    
    // MARK: - Initialization
    init() {
        // Load saved preference from UserDefaults (default to true)
        self.isEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }
    
    // MARK: - Haptic Types
    enum HapticType {
        case light
        case medium
        case heavy
        case success
        case warning
        case error
        case selection
        case routeComplete
        case buttonTap
    }
    
    // MARK: - Public Methods
    
    /// Trigger haptic feedback of specified type
    func impact(_ type: HapticType) {
        guard isEnabled else { return }
        
        switch type {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
            
        case .routeComplete:
            // Special celebration haptic - double success
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                generator.notificationOccurred(.success)
            }
            
        case .buttonTap:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    /// Convenience method for button taps
    func buttonTap() {
        impact(.buttonTap)
    }
    
    /// Convenience method for successful actions
    func success() {
        impact(.success)
    }
    
    /// Convenience method for errors
    func error() {
        impact(.error)
    }
    
    /// Convenience method for route completion celebration
    func routeComplete() {
        impact(.routeComplete)
    }
    
    /// Convenience method for menu navigation
    func menuNavigation() {
        impact(.selection)
    }
    
    /// Convenience method for toggle switches
    func toggle() {
        impact(.light)
    }
}