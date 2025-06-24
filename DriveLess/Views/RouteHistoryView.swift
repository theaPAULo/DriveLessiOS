//
//  RouteHistoryView.swift
//  DriveLess
//
//  Displays saved route history with ability to reload routes
//

import SwiftUI
import CoreData

struct RouteHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var routeHistoryManager: RouteHistoryManager
    
    // FIXED: Make this @State instead of let to allow updates
    @State private var savedRoutes: [SavedRoute] = []
    @State private var refreshCounter = 0  // NEW: Force refresh trigger
    
    let onRouteSelected: (RouteData) -> Void  // Callback when user selects a route
    
    // MARK: - Color Theme (Earthy - matching app theme)
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2)
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // MARK: - Header Stats (Updated to use state)
                if !savedRoutes.isEmpty {
                    headerStatsView
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                }
                
                // MARK: - Route List
                if savedRoutes.isEmpty {
                    emptyStateView
                } else {
                    routeListView
                }
            }
            .navigationTitle("Route History")
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
            loadRouteHistory()
        }
    }
    
    // MARK: - Header Stats (Now uses dynamic state)
    private var headerStatsView: some View {
        HStack {
            VStack {
                Text("\(savedRoutes.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryGreen)
                Text("Total Routes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 30)
            
            VStack {
                Text(totalDistanceSaved)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryGreen)
                Text("Miles Optimized")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 30)
            
            VStack {
                Text(mostRecentRoute)
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
            ForEach(savedRoutes, id: \.id) { route in
                RouteHistoryRow(
                    route: route,
                    onTap: {
                        // Convert saved route back to RouteData and call callback
                        let routeData = routeHistoryManager.convertToRouteData(route)
                        onRouteSelected(routeData)
                        dismiss()
                    },
                    onFavoriteToggle: {
                        toggleFavorite(route)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: deleteRoutes)
        }
        .listStyle(PlainListStyle())
        .id(refreshCounter)  // NEW: Force refresh when counter changes
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "map.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Routes Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Your optimized routes will appear here after you create them")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    // FIXED: Proper route deletion with immediate UI update
    private func deleteRoutes(offsets: IndexSet) {
        print("🗑️ Deleting \(offsets.count) route(s)")
        
        // Delete from Core Data first
        for index in offsets {
            let routeToDelete = savedRoutes[index]
            print("🗑️ Deleting route: \(routeToDelete.routeName ?? "Unnamed")")
            routeHistoryManager.deleteRoute(routeToDelete)
        }
        
        // IMMEDIATELY update the UI state
        savedRoutes.remove(atOffsets: offsets)
        
        print("✅ Routes deleted and UI updated. Remaining: \(savedRoutes.count)")
    }
    
    // NEW: Function to refresh data from Core Data
    private func loadRouteHistory() {
        savedRoutes = routeHistoryManager.loadRouteHistory()
        print("🔄 Loaded \(savedRoutes.count) routes from history")
    }
    
    // NEW: Toggle favorite status for a route
    private func toggleFavorite(_ route: SavedRoute) {
        // Store current state before changing
        let wasAlreadyFavorited = route.isFavorite
        
        // Persist to Core Data first
        if wasAlreadyFavorited {
            print("💔 Unfavoriting route from history: \(route.routeName ?? "Unnamed")")
            routeHistoryManager.removeFavoriteByRoute(route)
        } else {
            print("❤️ Favoriting route from history: \(route.routeName ?? "Unnamed")")
            routeHistoryManager.addFavoriteByRoute(route)
        }
        
        // FIXED: Force immediate UI update by reloading data and incrementing refresh counter
        loadRouteHistory()
        refreshCounter += 1  // This forces SwiftUI to completely refresh the list
        
        print("✅ Route favorite status toggled and UI updated immediately (refresh #\(refreshCounter))")
    }
    
    // MARK: - Computed Properties (Now use state instead of parameter)
    
    private var totalDistanceSaved: String {
        let totalMiles = savedRoutes.compactMap { route in
            Double(route.totalDistance?.replacingOccurrences(of: " miles", with: "") ?? "0")
        }.reduce(0, +)
        
        return String(format: "%.1f", totalMiles)
    }
    
    private var mostRecentRoute: String {
        guard let mostRecent = savedRoutes.first?.createdDate else { return "None" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: mostRecent, relativeTo: Date())
    }
}

// MARK: - Route History Row Component
struct RouteHistoryRow: View {
    let route: SavedRoute
    let onTap: () -> Void
    let onFavoriteToggle: () -> Void  // NEW: Callback for favorite toggle
    
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    
    var body: some View {
        HStack(spacing: 12) {
            // Route Icon
            Circle()
                .fill(primaryGreen.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "map.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(primaryGreen)
                )
            
            // Route Details - tappable area for loading route
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.routeName ?? "Unnamed Route")
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
            
            // UPDATED: Heart icon for favorite toggle instead of chevron
            Button(action: onFavoriteToggle) {
                Image(systemName: route.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(route.isFavorite ? .red : .gray)
                    .padding(8)
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
    RouteHistoryView(
        routeHistoryManager: RouteHistoryManager(),
        onRouteSelected: { _ in }
    )
}
