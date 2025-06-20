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
    
    @StateObject private var routeHistoryManager = RouteHistoryManager()
    @State private var savedRoutes: [SavedRoute] = []
    @State private var showingRouteHistory = false

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
        .onAppear {
            loadRouteHistory()  // <-- ADD THIS LINE
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
            
            // Sign Out Button (working!)
            Button(action: {
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Sign out the user
                authManager.signOut()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .medium))
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(.red)
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Quick Stats Card
    private var quickStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(primaryGreen)
                Text("Your Stats")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 20) {
                statItem(
                    icon: "map.fill",
                    title: "Routes",
                    value: "\(savedRoutes.count)",  // <-- REAL DATA NOW
                    subtitle: "Optimized"
                )
                
                Divider()
                    .frame(height: 40)
                
                statItem(
                    icon: "clock.fill",
                    title: "Recent Route",
                    value: savedRoutes.isEmpty ? "None" : timeAgo(savedRoutes.first?.createdDate),  // <-- REAL DATA
                    subtitle: "Last used"
                )
                
                Divider()
                    .frame(height: 40)
                
                statItem(
                    icon: "location.fill",
                    title: "Locations",
                    value: "\(uniqueLocationsCount)",  // <-- REAL DATA
                    subtitle: "Visited"
                )
            }
            
            // ADD ROUTE HISTORY BUTTON
            Button(action: {
                showingRouteHistory = true
            }) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .medium))
                    Text("View Route History")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .foregroundColor(primaryGreen)
                .padding(.top, 12)
            }
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
                    print("📋 Route history tapped")
                }
            )
            
            Divider()
                .padding(.leading, 50)
            
            menuItem(
                icon: "house.fill",
                title: "Saved Locations",
                subtitle: "Home, work, and favorites",
                action: {
                    print("🏠 Saved locations tapped")
                }
            )
            
            Divider()
                .padding(.leading, 50)
            
            menuItem(
                icon: "gearshape.fill",
                title: "Settings",
                subtitle: "Preferences and options",
                action: {
                    print("⚙️ Settings tapped")
                }
            )
            
            Divider()
                .padding(.leading, 50)
            
            menuItem(
                icon: "questionmark.circle.fill",
                title: "Help & Support",
                subtitle: "Contact us for assistance",
                action: {
                    print("❓ Help tapped")
                }
            )
            
            Divider()
                .padding(.leading, 50)
            
            menuItem(
                icon: "rectangle.portrait.and.arrow.right",
                title: "Sign Out",
                subtitle: "Return to login screen",
                action: {
                    // TODO: Implement proper logout with confirmation
                    print("🚪 Sign out tapped")
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
}

#Preview {
    NavigationView {
        ProfileView()
    }
}
