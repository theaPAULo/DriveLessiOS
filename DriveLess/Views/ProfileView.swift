//
//  ProfileView.swift
//  DriveLess
//
//  User profile, settings, and route history
//

import SwiftUI
import CoreData  // <-- ADD THIS LINE

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var routeLoader: RouteLoader  // <-- ADD THIS LINE

    
    @StateObject private var routeHistoryManager = RouteHistoryManager()
    @State private var savedRoutes: [SavedRoute] = []
    @State private var showingRouteHistory = false
    @State private var showingAdminDashboard = false
    @State private var showingSignOutConfirmation = false
    @State private var showingSettings = false
    @State private var showingFavoriteRoutes = false  // ADD THIS LINE




    
    // ADD THESE LINES FOR SAVED ADDRESSES:
    @StateObject private var savedAddressManager = SavedAddressManager()
    @State private var showingAddressManager = false
    @EnvironmentObject var hapticManager: HapticManager  // ADD THIS LINE


    // MARK: - Color Theme (Earthy - matching app theme)
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2) // Dark forest green
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2) // Rich brown
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7) // Soft green
    
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
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingRouteHistory) {
            RouteHistoryView(
                routeHistoryManager: routeHistoryManager,
                savedRoutes: savedRoutes,
                onRouteSelected: { routeData in
                    // Use RouteLoader to navigate to Search tab with this route
                    routeLoader.loadRoute(routeData)
                    
                    // Close the route history sheet
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
                    // Use RouteLoader to navigate to Search tab with this route
                    routeLoader.loadRoute(routeData)
                
                // Close the favorite routes sheet
                showingFavoriteRoutes = false
            })
        }
        .sheet(isPresented: $showingAdminDashboard) {
            AdminDashboardView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
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
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Profile Avatar Placeholder
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [primaryGreen, lightGreen]),
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
            
            VStack(spacing: 4) {
                // Show user's name if available
                if let user = authManager.user {
                    Text("Hello, \(user.displayName ?? "User")!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(user.email ?? "No email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Show sign-in provider (Google only for now)
                    HStack {
                        Image(systemName: "globe")
                            .font(.system(size: 12))
                        Text("Signed in with Google")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                } else {
                    Text("Welcome Back!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Loading user info...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // REMOVED: Sign Out Button (keeping only the one in menu)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Quick Stats Card
    private var quickStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(primaryGreen)
                Text("Your Impact")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 20) {
                statItem(
                    icon: "map.fill",
                    title: "Routes",
                    value: "\(savedRoutes.count)",
                    subtitle: "Optimized"
                )
                
                Divider()
                    .frame(height: 40)
                
                statItem(
                    icon: "clock.fill",
                    title: timeAgo(savedRoutes.first?.createdDate),
                    value: "Recent",
                    subtitle: "Last route"
                )
                
                Divider()
                    .frame(height: 40)
                
                statItem(
                    icon: "location.fill",
                    title: "Locations",
                    value: "\(uniqueLocationsCount)",
                    subtitle: "Visited"
                )
            }
            
            // MARK: - Environmental Impact Row
            HStack(spacing: 20) {
                impactStatItem(
                    icon: "timer",
                    title: "Time Saved",
                    value: calculateTimeSaved(),
                    subtitle: "Minutes",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 40)
                
                impactStatItem(
                    icon: "leaf.fill",
                    title: "CO₂ Saved",
                    value: calculateEmissionsSaved(),
                    subtitle: "Pounds",
                    color: .green
                )
                
                Divider()
                    .frame(height: 40)
                
                impactStatItem(
                    icon: "fuelpump.fill",
                    title: "Miles Saved",
                    value: calculateMilesSaved(),
                    subtitle: "Distance",
                    color: .orange
                )
            }
            .padding(.top, 12)
            
            // REMOVED: Route History Button (keeping only the one in menu)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Menu Options Section
    private var menuOptionsSection: some View {
        VStack(spacing: 0) {
            
            menuItem(
                icon: "clock.arrow.circlepath",
                title: "Route History",
                subtitle: "View your recent routes",
                action: {
                    hapticManager.menuNavigation()  // ADD THIS LINE
                    print("📋 Route history tapped")
                    showingRouteHistory = true
                }
            )
            
            Divider()
                .padding(.leading, 50)
            
            // ADD THIS NEW MENU ITEM:
            menuItem(
                icon: "heart.fill",
                title: "Favorite Routes",
                subtitle: "Your saved favorite routes",
                action: {
                    hapticManager.menuNavigation()
                    showingFavoriteRoutes = true
                }
            )

            Divider()
                .padding(.leading, 50)
            
            menuItem(
                icon: "house.fill",
                title: "Saved Locations",
                subtitle: "Home, work, and favorites",
                action: {
                    hapticManager.menuNavigation()  // ADD THIS LINE
                    showingAddressManager = true
                }
            )
            
            Divider()
                .padding(.leading, 50)
            
            menuItem(
                icon: "gearshape.fill",
                title: "Settings",
                subtitle: "Preferences and options",
                action: {
                    hapticManager.menuNavigation()  // ADD THIS LINE
                    showingSettings = true
                }
            )
            
            Divider()
                .padding(.leading, 50)
            
            menuItem(
                icon: "questionmark.circle.fill",
                title: "Help & Support",
                subtitle: "Contact us for assistance",
                action: {
                    hapticManager.menuNavigation()  // ADD THIS LINE
                    print("❓ Help tapped - Coming in Phase 2!")
                }
            )
            
            // Only show admin panel if user is actually an admin
            if isCurrentUserAdmin() {
                Divider()
                    .padding(.leading, 50)
                
                menuItem(
                    icon: "shield.lefthalf.filled",
                    title: "Admin Dashboard",
                    subtitle: "Analytics & app management",
                    action: {
                        hapticManager.menuNavigation()  // ADD THIS LINE
                        showingAdminDashboard = true
                    }
                )
            }
            
            Divider()
                .padding(.leading, 50)
            
            menuItem(
                icon: "rectangle.portrait.and.arrow.right",
                title: "Sign Out",
                subtitle: "Return to login screen",
                action: {
                    hapticManager.menuNavigation()  // ADD THIS LINE
                    // TODO: Implement proper logout with confirmation
                    print("🚪 Sign out tapped")
                    signOutUser()

                }
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Components
    
    private func statItem(icon: String, title: String, value: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(primaryGreen)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func menuItem(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(primaryGreen)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle()) // Makes entire area tappable
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties for Stats

    /// Count of unique locations visited across all routes
    private var uniqueLocationsCount: Int {
        let allLocations = savedRoutes.flatMap { route in
            var locations = [route.startLocation, route.endLocation].compactMap { $0 }
            
            // Add stops if they exist
            if let stopsString = route.stops,
               let stopsData = stopsString.data(using: .utf8),
               let stops = try? JSONDecoder().decode([String].self, from: stopsData) {
                locations.append(contentsOf: stops)
            }
            
            return locations
        }
        
        return Set(allLocations).count
    }

    /// Formats a date to show how long ago it was
    private func timeAgo(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Lifecycle

    private func loadRouteHistory() {
        savedRoutes = routeHistoryManager.loadRouteHistory()
    }
    
    // MARK: - Environmental Impact Calculations

    /// Calculates estimated time saved through route optimization
    private func calculateTimeSaved() -> String {
        guard !savedRoutes.isEmpty else { return "0" }
        
        // Calculate total distance from all routes
        let totalDistance = savedRoutes.compactMap { route in
            Double(route.totalDistance?.replacingOccurrences(of: " miles", with: "") ?? "0")
        }.reduce(0, +)
        
        // Estimate 20% time savings from optimization (conservative estimate)
        let optimizationSavingsPercent = 0.20
        let averageSpeedMph = 35.0 // Average city driving speed
        
        let unoptimizedTimeHours = totalDistance / averageSpeedMph
        let timeSavedHours = unoptimizedTimeHours * optimizationSavingsPercent
        let timeSavedMinutes = timeSavedHours * 60
        
        if timeSavedMinutes >= 60 {
            let hours = Int(timeSavedHours)
            return "\(hours)h"
        } else {
            return "\(Int(timeSavedMinutes))"
        }
    }

    /// Calculates estimated CO2 emissions saved through route optimization
    private func calculateEmissionsSaved() -> String {
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

    /// Enhanced stat item for environmental impact metrics
    private func impactStatItem(icon: String, title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    
    /// Signs out the current user with proper feedback
    private func signOutUser() {
        // Show confirmation dialog instead of signing out immediately
        showingSignOutConfirmation = true
    }

    /// Actually performs the sign out after confirmation
    private func confirmSignOut() {
        print("🚪 Signing out user...")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Clear admin status when signing out
        UserDefaults.standard.set(false, forKey: "driveless_admin_mode")
        UserDefaults.standard.removeObject(forKey: "driveless_admin_users")
        
        // Sign out through the authentication manager
        authManager.signOut()
        
        print("✅ User signed out successfully")
    }
    // MARK: - Helper Functions

    /// Checks if current user is an admin
    private func isCurrentUserAdmin() -> Bool {
        guard let currentUser = authManager.user else { return false }
        
        // List of admin Firebase UIDs - add your UID and any other admins here
        let adminUIDs = [
            "X4bKhg8XgfUAvAOgK97eMweHCz33", // Your current UID from the logs
            // Add other admin UIDs here as needed
            // "another-admin-uid-here",
        ]
        
        let isAdmin = adminUIDs.contains(currentUser.uid)
        
        if isAdmin {
            print("🔐 User \(currentUser.uid) is an admin")
            // Set admin mode for usage tracking
            UserDefaults.standard.set(true, forKey: "driveless_admin_mode")
        }
        
        return isAdmin
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthenticationManager())  // <-- ADD THIS IF MISSING
            .environmentObject(RouteLoader())  // <-- ADD THIS LINE
    }
}
