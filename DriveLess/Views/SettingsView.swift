//
//  SettingsView.swift
//  DriveLess
//
//  Created by Paul Soni on 6/23/25.
//


//
//  SettingsView.swift
//  DriveLess
//
//  Settings and preferences screen
//

import SwiftUI
import MessageUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Settings State
    @AppStorage("themePreference") private var themePreference: ThemePreference = .system
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("defaultRoundTrip") private var defaultRoundTrip: Bool = false
    @AppStorage("defaultTrafficEnabled") private var defaultTrafficEnabled: Bool = true
    @AppStorage("distanceUnit") private var distanceUnit: DistanceUnit = .miles
    @AppStorage("autoSaveRoutes") private var autoSaveRoutes: Bool = true
    
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var showingMailComposer = false
    @State private var mailComposeResult: Result<MFMailComposeResult, Error>?
    
    // MARK: - Color Theme (matching app style)
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7)
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Appearance Section
                Section("Appearance") {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(primaryGreen)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Theme")
                                .font(.system(size: 16, weight: .medium))
                            Text("Choose your preferred appearance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Picker("Theme", selection: $themePreference) {
                            ForEach(ThemePreference.allCases, id: \.self) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - Haptics Section
                Section("Haptic Feedback") {
                    HStack {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .foregroundColor(primaryGreen)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Haptic Feedback")
                                .font(.system(size: 16, weight: .medium))
                            Text("Feel vibrations for button taps and events")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $hapticsEnabled)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - Route Defaults Section
                Section("Route Defaults") {
                    // Round Trip Toggle
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(primaryGreen)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Default Round Trip")
                                .font(.system(size: 16, weight: .medium))
                            Text("Return to starting location by default")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $defaultRoundTrip)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                    
                    // Traffic Toggle
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(primaryGreen)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Consider Traffic")
                                .font(.system(size: 16, weight: .medium))
                            Text("Include current traffic in route calculations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $defaultTrafficEnabled)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                    
                    // Distance Units
                    HStack {
                        Image(systemName: "ruler.fill")
                            .foregroundColor(primaryGreen)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Distance Units")
                                .font(.system(size: 16, weight: .medium))
                            Text("Choose your preferred measurement")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Picker("Units", selection: $distanceUnit) {
                            ForEach(DistanceUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - Privacy & Data Section
                Section("Privacy & Data") {
                    // Auto-save Routes
                    HStack {
                        Image(systemName: "externaldrive.fill")
                            .foregroundColor(primaryGreen)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Save Routes")
                                .font(.system(size: 16, weight: .medium))
                            Text("Automatically save completed routes to history")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $autoSaveRoutes)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                    
                    // Location Permissions
                    Button(action: openLocationSettings) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(primaryGreen)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Location Permissions")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Manage location access settings")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // MARK: - About Section
                Section("About") {
                    // App Version
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(primaryGreen)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Version")
                                .font(.system(size: 16, weight: .medium))
                            Text("DriveLess for iOS")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    // Terms & Conditions
                    Button(action: { showingTerms = true }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(primaryGreen)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Terms & Conditions")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("View terms of service")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Privacy Policy
                    Button(action: { showingPrivacy = true }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(primaryGreen)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Privacy Policy")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("How we handle your data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Rate App
                    Button(action: rateApp) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(primaryGreen)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rate DriveLess")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Rate us on the App Store")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryGreen)
                }
            }
        }
        .sheet(isPresented: $showingTerms) {
            TermsView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyView()
        }
    }
    
    // MARK: - Helper Functions
    
    private func openLocationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func rateApp() {
        // TODO: Replace with your actual App Store ID when published
        let appStoreURL = "https://apps.apple.com/app/id123456789"
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Enums

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
}

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

// MARK: - Placeholder Views for Terms & Privacy

struct TermsView: View {
    @Environment(\.dismiss) private var dismiss
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms & Conditions")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Group {
                        Text("Last updated: June 2025")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        Text("1. Acceptance of Terms")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("By using DriveLess, you agree to these terms and conditions. If you do not agree, please do not use our service.")
                        
                        Text("2. Description of Service")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("DriveLess is a route optimization application that helps users find efficient routes for multiple stops using Google Maps services.")
                        
                        Text("3. User Responsibilities")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Users are responsible for ensuring safe driving practices and following all traffic laws. DriveLess is not responsible for driving decisions or route accuracy.")
                        
                        Text("4. Limitation of Liability")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("DriveLess provides route suggestions as-is. We are not liable for any damages resulting from route recommendations or app usage.")
                    }
                }
                .padding()
            }
            .navigationTitle("Terms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryGreen)
                }
            }
        }
    }
}

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Group {
                        Text("Last updated: June 2025")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        Text("1. Information We Collect")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("We collect location data for route optimization and user authentication information through Google Sign-In.")
                        
                        Text("2. How We Use Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Location data is used solely for calculating optimal routes. We do not sell or share your personal information with third parties.")
                        
                        Text("3. Data Storage")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Route history and saved addresses are stored locally on your device and in Firebase for synchronization across devices.")
                        
                        Text("4. Your Rights")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("You can delete your account and all associated data at any time. Contact us for data deletion requests.")
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryGreen)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}