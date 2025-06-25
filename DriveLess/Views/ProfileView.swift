//
//  ProfileView.swift
//  DriveLess
//
//  User profile with unified earthy theme system
//

import SwiftUI
import CoreData

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var routeLoader: RouteLoader
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticManager: HapticManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @StateObject private var routeHistoryManager = RouteHistoryManager()
    @State private var savedRoutes: [SavedRoute] = []
    @State private var showingRouteHistory = false
    @State private var showingAdminDashboard = false
    @State private var showingSignOutConfirmation = false
    @State private var showingSettings = false
    @State private var showingFavoriteRoutes = false
    @State private var showingFeedbackComposer = false
    
    // Saved addresses management
    @StateObject private var savedAddressManager = SavedAddressManager()
    @State private var showingAddressManager = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - Header Section
                headerSection
                
                // MARK: - Quick Stats Card
                quickStatsCard
                
                // MARK: - Menu Options
                menuOptionsSection
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(themeManager.background)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingRouteHistory) {
            RouteHistoryView(
                routeHistoryManager: routeHistoryManager,
                onRouteSelected: { routeData in
                    routeLoader.loadRoute(routeData)
                    showingRouteHistory = false
                }
            )
        }
        .sheet(isPresented: $showingAddressManager) {
            SavedAddressesView(savedAddressManager: savedAddressManager)
        }
        .sheet(isPresented: $showingFavoriteRoutes) {
            FavoriteRoutesView(
                routeHistoryManager: routeHistoryManager,
                onRouteSelected: { routeData in
                    routeLoader.loadRoute(routeData)
                    showingFavoriteRoutes = false
                })
        }
        .sheet(isPresented: $showingAdminDashboard) {
            AdminDashboardView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingFeedbackComposer) {
            FeedbackComposerView()
        }
        .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                confirmSignOut()
            }
        } message: {
            Text("Are you sure you want to sign out of DriveLess?")
        }
        .onAppear {
            loadRouteHistory()
        }
    }
    
    // MARK: - Header Section (Themed)
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Profile Avatar with theme gradient
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [themeManager.primary, themeManager.accent]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(color: themeManager.cardShadow(), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 4) {
                // Show user's name if available
                if let user = authManager.user {
                    Text("Hello, \(user.displayName ?? "User")!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimary)
                    
                    Text(user.email ?? "No email")
                        .font(.subheadline)
                        .foregroundColor(themeManager.textSecondary)
                } else {
                    Text("Welcome!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimary)
                    
                    Text("Signed in successfully")
                        .font(.subheadline)
                        .foregroundColor(themeManager.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Quick Stats Card (Enhanced with Environmental Impact)
    private var quickStatsCard: some View {
        VStack(spacing: 16) {
            Text("Your Stats")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // First Row: Basic Stats
            HStack(spacing: 20) {
                statItem(
                    icon: "map.fill",
                    value: "\(savedRoutes.count)",
                    label: "Total Routes"
                )
                
                statItem(
                    icon: "heart.fill",
                    value: "\(savedRoutes.filter { $0.isFavorite }.count)",
                    label: "Favorites"
                )
                
                statItem(
                    icon: "clock.fill",
                    value: calculateTimeSaved(),
                    label: "Time Saved"
                )
            }
            
            // Divider
            Rectangle()
                .fill(themeManager.textTertiary.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // Second Row: Environmental Impact
            HStack(spacing: 20) {
                impactStatItem(
                    icon: "leaf.fill",
                    title: "CO₂ Saved",
                    value: "\(calculateCO2Saved())",
                    subtitle: "lbs",
                    color: .green
                )
                
                impactStatItem(
                    icon: "road.lanes",
                    title: "Miles Saved",
                    value: calculateMilesSaved(),
                    subtitle: "miles",
                    color: themeManager.secondary
                )
                
                impactStatItem(
                    icon: "dollarsign.circle.fill",
                    title: "Fuel Saved",
                    value: calculateFuelSaved(),
                    subtitle: "gallons",
                    color: themeManager.accent
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackground)
                .shadow(color: themeManager.cardShadow(), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Stat Item Helper (Themed)
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(themeManager.primary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    /// Checks if current user is an admin
    private var isCurrentUserAdmin: Bool {
        guard let currentUser = authManager.user else { return false }
        
        // Check admin status securely through configuration
        let isAdmin = ConfigurationManager.shared.isAdminUser(currentUser.uid)
        
        if isAdmin {
            print("🔐 User \(currentUser.uid) is an admin")
            // Set admin mode for usage tracking
            UserDefaults.standard.set(true, forKey: "driveless_admin_mode")
        }
        
        return isAdmin
    }
    
    // MARK: - Menu Options Section (Themed)
    private var menuOptionsSection: some View {
        VStack(spacing: 16) {
            
            // Route Management Section
            menuSectionCard(title: "Your Routes") {
                VStack(spacing: 12) {
                    menuRow(
                        icon: "clock.arrow.circlepath",
                        title: "Route History",
                        subtitle: "View and reload past routes",
                        action: { showingRouteHistory = true }
                    )
                    
                    menuDivider
                    
                    menuRow(
                        icon: "heart.fill",
                        title: "Favorite Routes",
                        subtitle: "Quick access to saved routes",
                        action: { showingFavoriteRoutes = true }
                    )
                }
            }
            
            // Address Management Section
            menuSectionCard(title: "Your Addresses") {
                menuRow(
                    icon: "house.fill",
                    title: "Saved Addresses",
                    subtitle: "Manage home, work & custom locations",
                    action: { showingAddressManager = true }
                )
            }
            
            // App Settings Section
            menuSectionCard(title: "App Settings") {
                VStack(spacing: 12) {
                    menuRow(
                        icon: "gearshape.fill",
                        title: "Settings",
                        subtitle: "Preferences, themes & defaults",
                        action: { showingSettings = true }
                    )
                    
                    menuDivider
                    
                    menuRow(
                        icon: "envelope.fill",
                        title: "Send Feedback",
                        subtitle: "Help us improve DriveLess",
                        action: { showingFeedbackComposer = true }
                    )
                }
            }
            
            // Admin Section (if user is admin)
            if isCurrentUserAdmin {
                menuSectionCard(title: "Admin") {
                    menuRow(
                        icon: "shield.checkered",
                        title: "Admin Dashboard",
                        subtitle: "App statistics & management",
                        action: { showingAdminDashboard = true }
                    )
                }
            }
            
            // Account Section
            menuSectionCard(title: "Account") {
                menuRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Sign Out",
                    subtitle: "Sign out of your account",
                    isDestructive: true,
                    action: { showingSignOutConfirmation = true }
                )
            }
        }
    }
    
    // MARK: - Menu Section Card (Themed)
    private func menuSectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackground)
                .shadow(color: themeManager.cardShadow(), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Menu Row (Themed)
    private func menuRow(
        icon: String,
        title: String,
        subtitle: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            hapticManager.buttonTap()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon with themed background
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isDestructive ? Color.red : themeManager.primary,
                                isDestructive ? Color.red.opacity(0.8) : themeManager.secondary
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDestructive ? .red : themeManager.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textSecondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.textTertiary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Menu Divider (Themed)
    private var menuDivider: some View {
        Rectangle()
            .fill(themeManager.textTertiary.opacity(0.3))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }
    
    // MARK: - Enhanced stat item for environmental impact metrics
    private func impactStatItem(icon: String, title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textPrimary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textPrimary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(themeManager.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Calculation Methods
    
    /// Calculates estimated CO2 emissions saved through route optimization
    private func calculateCO2Saved() -> String {
        guard !savedRoutes.isEmpty else { return "0" }
        
        // Calculate total distance from all routes
        let totalDistance = savedRoutes.compactMap { route in
            Double(route.totalDistance?.replacingOccurrences(of: " miles", with: "") ?? "0")
        }.reduce(0, +)
        
        // Estimate 20% distance savings from optimization
        let optimizationSavingsPercent = 0.20
        let distanceSaved = totalDistance * optimizationSavingsPercent
        
        // Average car emits ~0.89 pounds of CO2 per mile
        let co2PerMile = 0.89
        let co2Saved = distanceSaved * co2PerMile
        
        if co2Saved >= 1.0 {
            return String(format: "%.1f", co2Saved)
        } else {
            return String(format: "%.2f", co2Saved)
        }
    }

    /// Calculates estimated miles saved through route optimization
    private func calculateMilesSaved() -> String {
        guard !savedRoutes.isEmpty else { return "0" }
        
        // Calculate total distance from all routes
        let totalDistance = savedRoutes.compactMap { route in
            Double(route.totalDistance?.replacingOccurrences(of: " miles", with: "") ?? "0")
        }.reduce(0, +)
        
        // Estimate 20% distance savings from optimization
        let optimizationSavingsPercent = 0.20
        let milesSaved = totalDistance * optimizationSavingsPercent
        
        return String(format: "%.1f", milesSaved)
    }
    
    /// Calculates estimated fuel saved through route optimization
    private func calculateFuelSaved() -> String {
        guard !savedRoutes.isEmpty else { return "0" }
        
        // Calculate miles saved first
        let milesSaved = Double(calculateMilesSaved()) ?? 0
        
        // Average car gets ~25 MPG
        let averageMPG = 25.0
        let fuelSaved = milesSaved / averageMPG
        
        return String(format: "%.1f", fuelSaved)
    }
    
    /// Calculates estimated time saved through route optimization
    private func calculateTimeSaved() -> String {
        guard !savedRoutes.isEmpty else { return "0h" }
        
        // Calculate miles saved
        let milesSaved = Double(calculateMilesSaved()) ?? 0
        
        // Estimate average speed of 30 mph in city driving
        let averageSpeed = 30.0
        let timeSavedHours = milesSaved / averageSpeed
        
        if timeSavedHours >= 1.0 {
            return String(format: "%.1fh", timeSavedHours)
        } else {
            let timeSavedMinutes = timeSavedHours * 60
            return String(format: "%.0fm", timeSavedMinutes)
        }
    }
    
    // MARK: - Helper Methods
    private func loadRouteHistory() {
        savedRoutes = routeHistoryManager.loadRouteHistory()
    }
    
    private func confirmSignOut() {
        print("🚪 Signing out user...")
        
        // Add haptic feedback
        hapticManager.buttonTap()
        
        // Clear admin status when signing out
        UserDefaults.standard.set(false, forKey: "driveless_admin_mode")
        UserDefaults.standard.removeObject(forKey: "driveless_admin_users")
        
        // Sign out through the authentication manager
        authManager.signOut()
        
        print("✅ User signed out successfully")
    }
}

#Preview {
    ProfileView()
}
