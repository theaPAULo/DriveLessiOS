//
//  SettingsManager.swift
//  DriveLess
//
//  Manages user preferences and settings throughout the app
//

import SwiftUI

// MARK: - Distance Unit Enum
enum DistanceUnit: String, CaseIterable {
    case miles = "miles"
    case kilometers = "kilometers"
    
    var displayName: String {
        switch self {
        case .miles: return "Miles"
        case .kilometers: return "Kilometers"
        }
    }
}

class SettingsManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var defaultRoundTrip: Bool {
        didSet {
            UserDefaults.standard.set(defaultRoundTrip, forKey: "defaultRoundTrip")
        }
    }
    
    @Published var defaultTrafficEnabled: Bool {
        didSet {
            UserDefaults.standard.set(defaultTrafficEnabled, forKey: "defaultTrafficEnabled")
        }
    }
    
    @Published var distanceUnit: DistanceUnit {
        didSet {
            UserDefaults.standard.set(distanceUnit.rawValue, forKey: "distanceUnit")
        }
    }
    
    @Published var autoSaveRoutes: Bool {
        didSet {
            UserDefaults.standard.set(autoSaveRoutes, forKey: "autoSaveRoutes")
        }
    }
    
    // MARK: - Initialization
    init() {
        // Load saved preferences from UserDefaults with sensible defaults
        self.defaultRoundTrip = UserDefaults.standard.object(forKey: "defaultRoundTrip") as? Bool ?? false
        self.defaultTrafficEnabled = UserDefaults.standard.object(forKey: "defaultTrafficEnabled") as? Bool ?? true
        self.autoSaveRoutes = UserDefaults.standard.object(forKey: "autoSaveRoutes") as? Bool ?? true
        
        // Load distance unit
        if let savedUnit = UserDefaults.standard.object(forKey: "distanceUnit") as? String,
           let unit = DistanceUnit(rawValue: savedUnit) {
            self.distanceUnit = unit
        } else {
            self.distanceUnit = .miles // Default to miles
        }
        
        print("📱 SettingsManager: Loaded settings - Round Trip: \(defaultRoundTrip), Traffic: \(defaultTrafficEnabled), Unit: \(distanceUnit.displayName)")
    }
    
    // MARK: - Convenience Methods
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        defaultRoundTrip = false
        defaultTrafficEnabled = true
        autoSaveRoutes = true
        distanceUnit = .miles
    }
    
    /// Get formatted distance string based on user preference
    func formatDistance(_ meters: Double) -> String {
        switch distanceUnit {
        case .miles:
            let miles = meters * 0.000621371
            if miles < 0.1 {
                let feet = meters * 3.28084
                return String(format: "%.0f ft", feet)
            } else {
                return String(format: "%.1f mi", miles)
            }
        case .kilometers:
            let kilometers = meters / 1000.0
            if kilometers < 0.1 {
                return String(format: "%.0f m", meters)
            } else {
                return String(format: "%.1f km", kilometers)
            }
        }
    }
    
    /// Get short unit symbol
    var distanceUnitSymbol: String {
        switch distanceUnit {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }
}
