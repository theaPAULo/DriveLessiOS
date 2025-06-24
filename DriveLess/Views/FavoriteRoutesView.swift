//
//  FavoriteRoutesView.swift
//  DriveLess
//
//  View for managing and accessing favorite routes
//

import SwiftUI

struct FavoriteRoutesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var routeHistoryManager = RouteHistoryManager()
    @State private var favoriteRoutes: [SavedRoute] = []
    
    // Callback when route is selected
    let onRouteSelected: (RouteData) -> Void
    
    // MARK: - Color Theme
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if favoriteRoutes.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 16) {
                        // Header stats
                        headerStatsView
                        
                        // Route list
                        routeListView
                    }
                    .padding(.top, 16)
                }
            }
            .background(Color(.systemGroupedBackground))
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
        HStack(spacing: 20) {
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
    }
    
    private func unfavoriteRoute(_ route: SavedRoute) {
        let routeData = routeHistoryManager.convertToRouteData(route)
        routeHistoryManager.removeFavorite(routeData)
        loadFavoriteRoutes() // Refresh the list
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
            
            // Unfavorite button - separated and clearly clickable
            Button(action: onUnfavorite) {
                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.red)
                    .cornerRadius(10)
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
    FavoriteRoutesView(onRouteSelected: { _ in })
}
