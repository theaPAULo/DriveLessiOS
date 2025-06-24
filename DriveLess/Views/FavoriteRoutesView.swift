//
//  FavoriteRoutesView.swift
//  DriveLess
//
//  Displays saved favorite routes with ability to reload and unfavorite routes
//

import SwiftUI
import CoreData

struct FavoriteRoutesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var routeHistoryManager: RouteHistoryManager
    
    // MAKE THIS @State INSTEAD OF LET TO ALLOW UPDATES
    @State private var favoriteRoutes: [SavedRoute] = []
    
    let onRouteSelected: (RouteData) -> Void  // Callback when user selects a route
    
    // MARK: - Color Theme (Earthy - matching app theme)
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2)
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // MARK: - Header Stats
                if !favoriteRoutes.isEmpty {
                    headerStatsView
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                }
                
                // MARK: - Route List
                if favoriteRoutes.isEmpty {
                    emptyStateView
                } else {
                    routeListView
                }
            }
            .navigationTitle("Favorite Routes")
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
        .onAppear {
            loadFavoriteRoutes()
        }
    }
    
    // MARK: - Header Stats
    private var headerStatsView: some View {
        HStack {
            VStack {
                Text("\(favoriteRoutes.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryGreen)
                Text("Saved Routes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 30)
            
            VStack {
                Text(totalFavoriteDistance)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryGreen)
                Text("Total Distance")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 30)
            
            VStack {
                Text(mostRecentFavorite)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryGreen)
                Text("Most Recent")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Route List
    private var routeListView: some View {
        List {
            ForEach(favoriteRoutes, id: \.id) { route in
                FavoriteRouteRow(
                    route: route,
                    onTap: {
                        // Convert saved route back to RouteData and call callback
                        let routeData = routeHistoryManager.convertToRouteData(route)
                        onRouteSelected(routeData)
                        dismiss()
                    },
                    onUnfavorite: {
                        unfavoriteRoute(route)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "heart.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Favorite Routes")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Save routes you use frequently by tapping the ❤️ button when viewing route results")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadFavoriteRoutes() {
        favoriteRoutes = routeHistoryManager.loadFavoriteRoutes()
        print("🔄 Loaded \(favoriteRoutes.count) favorite routes")
    }
    
    // FIXED: Properly handle unfavorite with immediate UI update
    private func unfavoriteRoute(_ route: SavedRoute) {
        print("💔 Unfavoriting route: \(route.routeName ?? "Unnamed")")
        
        // FIXED: Directly unfavorite the SavedRoute object instead of searching for it
        routeHistoryManager.removeFavoriteByRoute(route)
        
        // IMMEDIATELY update the UI by refreshing the list
        loadFavoriteRoutes()
        
        print("✅ Route unfavorited and UI updated")
    }
    
    // MARK: - Computed Properties
    
    private var totalFavoriteDistance: String {
        let totalMiles = favoriteRoutes.compactMap { route in
            Double(route.totalDistance?.replacingOccurrences(of: " miles", with: "") ?? "0")
        }.reduce(0, +)
        
        return String(format: "%.1f mi", totalMiles)
    }
    
    private var mostRecentFavorite: String {
        guard let mostRecent = favoriteRoutes.first?.createdDate else { return "None" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: mostRecent, relativeTo: Date())
    }
}

// MARK: - Favorite Route Row Component
struct FavoriteRouteRow: View {
    let route: SavedRoute
    let onTap: () -> Void
    let onUnfavorite: () -> Void
    
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    
    var body: some View {
        HStack(spacing: 12) {
            // Heart icon (always filled for favorites) - now just decorative
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.red)
                )
            
            // Route details - tappable area for loading route
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.customName ?? route.routeName ?? "Unnamed Route")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(route.totalDistance ?? "0 miles")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(route.estimatedTime ?? "0 min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    if let createdDate = route.createdDate {
                        Text(formatDate(createdDate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // FIXED: More prominent unfavorite button with better styling
            Button(action: onUnfavorite) {
                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.red)
                            .shadow(color: .red.opacity(0.3), radius: 2, x: 0, y: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    FavoriteRoutesView(
        routeHistoryManager: RouteHistoryManager(),
        onRouteSelected: { _ in }
    )
}
