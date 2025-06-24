//
//  ThemeManager.swift
//  DriveLess
//
//  Manages app-wide theme settings and appearance
//

import SwiftUI
import UIKit

// MARK: - Theme Preference Enum
enum ThemePreference: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "Follow System"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "gear"
        }
    }
    
    var description: String {
        switch self {
        case .light: return "Always use light appearance"
        case .dark: return "Always use dark appearance"
        case .system: return "Match system setting"
        }
    }
}

class ThemeManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentTheme: ThemePreference = .system {
        didSet {
            applyTheme()
        }
    }
    
    @Published var isDarkMode: Bool = false
    
    // MARK: - Initialization
    init() {
        // Load saved preference from UserDefaults
        if let savedTheme = UserDefaults.standard.object(forKey: "themePreference") as? String,
           let theme = ThemePreference(rawValue: savedTheme) {
            currentTheme = theme
        }
        
        // Apply the initial theme
        applyTheme()
        
        // Listen for system theme changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemThemeChanged),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    // MARK: - Theme Application
    private func applyTheme() {
        DispatchQueue.main.async {
            // Save preference
            UserDefaults.standard.set(self.currentTheme.rawValue, forKey: "themePreference")
            
            // Determine if we should use dark mode
            let shouldUseDarkMode = self.shouldUseDarkMode()
            self.isDarkMode = shouldUseDarkMode
            
            // Apply to all windows
            self.applyToAllWindows(darkMode: shouldUseDarkMode)
        }
    }
    
    private func shouldUseDarkMode() -> Bool {
        switch currentTheme {
        case .light:
            return false
        case .dark:
            return true
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
    
    private func applyToAllWindows(darkMode: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        for window in windowScene.windows {
            window.overrideUserInterfaceStyle = darkMode ? .dark : .light
        }
    }
    
    // MARK: - System Theme Change Detection
    @objc private func systemThemeChanged() {
        if currentTheme == .system {
            applyTheme()
        }
    }
    
    // MARK: - Public Methods
    func setTheme(_ theme: ThemePreference) {
        currentTheme = theme
    }
    
    func toggleTheme() {
        switch currentTheme {
        case .light:
            setTheme(.dark)
        case .dark:
            setTheme(.light)
        case .system:
            // If system, switch to opposite of current system setting
            let isCurrentlyDark = UITraitCollection.current.userInterfaceStyle == .dark
            setTheme(isCurrentlyDark ? .light : .dark)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
