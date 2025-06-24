//
//  ThemeManager.swift
//  DriveLess
//
//  Enhanced theme manager with unified earthy color palette
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

// MARK: - Unified Color Palette
struct DriveLessColors {
    // MARK: - Core Earthy Palette
    static let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2) // Dark forest green
    static let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2) // Rich brown
    static let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7) // Soft green
    static let warmBeige = Color(red: 0.9, green: 0.87, blue: 0.8) // Warm beige
    static let forestGreen = Color(red: 0.13, green: 0.27, blue: 0.13) // Deep forest
    static let oliveGreen = Color(red: 0.5, green: 0.6, blue: 0.4) // Olive green
    
    // MARK: - Light Mode Colors
    struct Light {
        static let background = Color(.systemGroupedBackground)
        static let cardBackground = Color(.white)
        static let secondaryBackground = Color(.systemGray6)
        
        static let primary = primaryGreen
        static let secondary = accentBrown
        static let accent = lightGreen
        
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        
        // Gradient backgrounds
        static let gradientStart = forestGreen
        static let gradientMid = primaryGreen
        static let gradientAccent = oliveGreen
        static let gradientEnd = accentBrown
    }
    
    // MARK: - Dark Mode Colors
    struct Dark {
        static let background = Color(.systemGroupedBackground)
        static let cardBackground = Color(.systemGray6)
        static let secondaryBackground = Color(.systemGray5)
        
        static let primary = Color(red: 0.6, green: 0.7, blue: 0.6) // Darker, more muted green
        static let secondary = warmBeige
        static let accent = Color(red: 0.4, green: 0.5, blue: 0.3) // Darker olive
        
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        
        // Gradient backgrounds (darker variations)
        static let gradientStart = Color(red: 0.1, green: 0.2, blue: 0.1) // Darker forest
        static let gradientMid = Color(red: 0.15, green: 0.3, blue: 0.15) // Darker primary
        static let gradientAccent = Color(red: 0.25, green: 0.35, blue: 0.2) // Darker olive
        static let gradientEnd = Color(red: 0.3, green: 0.2, blue: 0.15) // Darker brown
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
    
    // MARK: - Computed Color Properties
    var colors: DriveLessColors.Type {
        return DriveLessColors.self
    }
    
    var background: Color {
        return isDarkMode ? DriveLessColors.Dark.background : DriveLessColors.Light.background
    }
    
    var cardBackground: Color {
        return isDarkMode ? DriveLessColors.Dark.cardBackground : DriveLessColors.Light.cardBackground
    }
    
    var secondaryBackground: Color {
        return isDarkMode ? DriveLessColors.Dark.secondaryBackground : DriveLessColors.Light.secondaryBackground
    }
    
    var primary: Color {
        return isDarkMode ? DriveLessColors.Dark.primary : DriveLessColors.Light.primary
    }
    
    var secondary: Color {
        return isDarkMode ? DriveLessColors.Dark.secondary : DriveLessColors.Light.secondary
    }
    
    var accent: Color {
        return isDarkMode ? DriveLessColors.Dark.accent : DriveLessColors.Light.accent
    }
    
    var textPrimary: Color {
        return isDarkMode ? DriveLessColors.Dark.textPrimary : DriveLessColors.Light.textPrimary
    }
    
    var textSecondary: Color {
        return isDarkMode ? DriveLessColors.Dark.textSecondary : DriveLessColors.Light.textSecondary
    }
    
    var textTertiary: Color {
        return isDarkMode ? DriveLessColors.Dark.textTertiary : DriveLessColors.Light.textTertiary
    }
    
    // MARK: - Gradient Colors
    var gradientColors: [Color] {
        if isDarkMode {
            return [
                DriveLessColors.Dark.gradientStart,
                DriveLessColors.Dark.gradientMid,
                DriveLessColors.Dark.gradientAccent,
                DriveLessColors.Dark.gradientEnd
            ]
        } else {
            return [
                DriveLessColors.Light.gradientStart,
                DriveLessColors.Light.gradientMid,
                DriveLessColors.Light.gradientAccent,
                DriveLessColors.Light.gradientEnd
            ]
        }
    }
    
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
    
    // MARK: - Convenience Methods for Common UI Patterns
    func buttonGradient(isPressed: Bool = false) -> LinearGradient {
        let opacity = isPressed ? 0.8 : 1.0
        return LinearGradient(
            gradient: Gradient(colors: [primary.opacity(opacity), secondary.opacity(opacity)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    func cardShadow() -> Color {
        return primary.opacity(isDarkMode ? 0.2 : 0.3)
    }
    
    func animatedGradient(offset: CGFloat = 0) -> LinearGradient {
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: gradientColors[0], location: 0.0 + offset),
                .init(color: gradientColors[1], location: 0.3 + offset),
                .init(color: gradientColors[2], location: 0.6 + offset),
                .init(color: gradientColors[3], location: 0.8 + offset)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
