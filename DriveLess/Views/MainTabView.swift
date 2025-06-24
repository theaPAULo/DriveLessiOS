//
//  MainTabView.swift
//  DriveLess
//
//  Created by Paul Soni on 6/20/25.
//


//
//  MainTabView.swift
//  DriveLess
//
//  Main tab container with Search and Profile tabs
//

import SwiftUI

struct MainTabView: View {
    // Reference to location manager (passed from parent)
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var themeManager: ThemeManager  // ADD THIS LINE
    @ObservedObject var hapticManager: HapticManager  // ADD THIS LINE
    @ObservedObject var settingsManager: SettingsManager  // ADD THIS LINE


    
    @StateObject private var routeLoader = RouteLoader()


    
    // Track selected tab for custom styling
    @State private var selectedTab = 0
    
    // MARK: - Color Theme (Earthy - matching app theme)
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2) // Dark forest green
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2) // Rich brown
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7) // Soft green
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // MARK: - Search Tab (Route Planning)
            NavigationStack {
                RouteInputView(locationManager: locationManager, routeLoader: routeLoader)
                    .environmentObject(settingsManager)  // ADD THIS LINE
                    .environmentObject(hapticManager)   // ADD THIS LINE
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "map.fill" : "map")
                Text("Search")
            }
            .tag(0)
            
            // MARK: - Profile Tab (User Settings & History)
            NavigationStack {
                ProfileView()
                    .environmentObject(authManager)
                    .environmentObject(routeLoader)  // <-- ADD THIS LINE
                    .environmentObject(themeManager)  // ADD THIS LINE
                    .environmentObject(hapticManager)  // ADD THIS LINE
                    .environmentObject(settingsManager)  // ADD THIS LINE




            }
            .tabItem {
                Image(systemName: selectedTab == 1 ? "person.fill" : "person")
                Text("Profile")
            }
            .tag(1)
        }
        .accentColor(primaryGreen) // Tab bar accent color
        .onChange(of: routeLoader.shouldNavigateToSearch) { _, shouldNavigate in
            if shouldNavigate {
                // Switch to Search tab (tab 0)
                selectedTab = 0
                
                // Clear the navigation flag
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    routeLoader.shouldNavigateToSearch = false
                }
            }
        }
        .onAppear {
            // Customize tab bar appearance for better theming
            configureTabBarAppearance()
        }
    }
    
    // MARK: - Configure Tab Bar Styling
    private func configureTabBarAppearance() {
        // Create custom tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        
        // Configure normal state
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        // Configure selected item color
        tabBarAppearance.selectionIndicatorTintColor = UIColor(primaryGreen)
        
        // Configure normal item appearance
        let normalItemAppearance = UITabBarItemAppearance()
        normalItemAppearance.normal.iconColor = UIColor.systemGray
        normalItemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        
        // Configure selected item appearance
        normalItemAppearance.selected.iconColor = UIColor(primaryGreen)
        normalItemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(primaryGreen),
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        
        // Apply item appearance
        tabBarAppearance.stackedLayoutAppearance = normalItemAppearance
        tabBarAppearance.inlineLayoutAppearance = normalItemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = normalItemAppearance
        
        // Apply to UITabBar
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

#Preview {
    MainTabView(
        locationManager: LocationManager(),
        authManager: AuthenticationManager(),
        themeManager: ThemeManager(),
        hapticManager: HapticManager(),  // ADD THIS LINE
        settingsManager: SettingsManager()  // ADD THIS LINE

    )
}
