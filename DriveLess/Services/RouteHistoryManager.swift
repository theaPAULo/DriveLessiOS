//
//  RouteHistoryManager.swift
//  DriveLess
//
//  Created by Paul Soni on 6/20/25.
//


//
//  RouteHistoryManager.swift
//  DriveLess
//
//  Manages saving and loading route history using Core Data
//

import Foundation
import CoreData

class RouteHistoryManager: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    
    // MARK: - Save Route to History
    
    /// Saves a completed route to history
    /// - Parameter routeData: The optimized route data to save
    func saveRoute(_ routeData: RouteData) {
        let context = coreDataManager.viewContext
        
        // Create new SavedRoute entity
        let savedRoute = SavedRoute(context: context)
        
        // Set the properties
        savedRoute.id = UUID()
        savedRoute.startLocation = routeData.startLocation
        savedRoute.endLocation = routeData.endLocation
        savedRoute.totalDistance = routeData.totalDistance
        savedRoute.estimatedTime = routeData.estimatedTime
        savedRoute.createdDate = Date()
        savedRoute.considerTraffic = routeData.considerTraffic
        
        // Convert stops array to JSON string for storage
        if !routeData.stops.isEmpty {
            do {
                let stopsData = try JSONEncoder().encode(routeData.stops)
                savedRoute.stops = String(data: stopsData, encoding: .utf8)
            } catch {
                print("❌ Failed to encode stops: \(error)")
                savedRoute.stops = routeData.stops.joined(separator: "|||") // Fallback
            }
        }
        
        // Generate route name if not provided
        savedRoute.routeName = generateRouteName(for: routeData)
        
        // Save waypoint order if available
        if !routeData.optimizedStops.isEmpty {
            let addresses = routeData.optimizedStops.map { $0.address }
            do {
                let waypointData = try JSONEncoder().encode(addresses)
                savedRoute.waypointOrder = String(data: waypointData, encoding: .utf8)
            } catch {
                print("❌ Failed to encode waypoint order: \(error)")
            }
        }
        
        // Save to Core Data
        coreDataManager.save()
        
        print("✅ Route saved to history: \(savedRoute.routeName ?? "Unnamed Route")")
    }
    
    // MARK: - Load Route History
    
    /// Fetches all saved routes, ordered by creation date (newest first)
    /// - Returns: Array of SavedRoute objects
    func loadRouteHistory() -> [SavedRoute] {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<SavedRoute> = SavedRoute.fetchRequest()
        
        // Sort by creation date, newest first
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedRoute.createdDate, ascending: false)]
        
        // Limit to last 50 routes to prevent performance issues
        request.fetchLimit = 50
        
        do {
            let routes = try context.fetch(request)
            print("📚 Loaded \(routes.count) routes from history")
            return routes
        } catch {
            print("❌ Failed to load route history: \(error)")
            return []
        }
    }
    
    // MARK: - Delete Route from History
    
    /// Deletes a specific route from history
    /// - Parameter route: The SavedRoute to delete
    func deleteRoute(_ route: SavedRoute) {
        let context = coreDataManager.viewContext
        context.delete(route)
        coreDataManager.save()
        
        print("🗑️ Deleted route: \(route.routeName ?? "Unnamed Route")")
    }
    
    // MARK: - Convert SavedRoute back to RouteData
    
    /// Converts a SavedRoute back to RouteData for reuse
    /// - Parameter savedRoute: The saved route to convert
    /// - Returns: RouteData object ready for route calculation
    func convertToRouteData(_ savedRoute: SavedRoute) -> RouteData {
        // Decode stops from JSON
        var stops: [String] = []
        if let stopsString = savedRoute.stops {
            // Try JSON decoding first
            if let stopsData = stopsString.data(using: .utf8),
               let decodedStops = try? JSONDecoder().decode([String].self, from: stopsData) {
                stops = decodedStops
            } else {
                // Fallback to simple split
                stops = stopsString.components(separatedBy: "|||").filter { !$0.isEmpty }
            }
        }
        
        // Create RouteData object
        return RouteData(
            startLocation: savedRoute.startLocation ?? "",
            endLocation: savedRoute.endLocation ?? "",
            stops: stops,
            isRoundTrip: false, // We'll enhance this later
            considerTraffic: savedRoute.considerTraffic
        )
    }
    
    // MARK: - Helper Methods
    
    /// Generates a user-friendly name for the route
    /// - Parameter routeData: The route data to name
    /// - Returns: A descriptive route name
    private func generateRouteName(for routeData: RouteData) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        // Try to extract business names for shorter display
        let startName = extractLocationName(routeData.startLocation)
        let endName = extractLocationName(routeData.endLocation)
        
        let routeName = "\(startName) → \(endName)"
        
        // Keep it under 50 characters
        if routeName.count > 50 {
            return "Route from \(formatter.string(from: Date()))"
        }
        
        return routeName
    }
    
    /// Extracts a short location name from a full address
    /// - Parameter address: Full address string
    /// - Returns: Shortened location name
    private func extractLocationName(_ address: String) -> String {
        let components = address.components(separatedBy: ",")
        
        if let firstComponent = components.first?.trimmingCharacters(in: .whitespaces) {
            // If it starts with a number, it's likely a street address
            if firstComponent.first?.isNumber == true {
                // Try to use the second component (likely city/area)
                if components.count > 1 {
                    return components[1].trimmingCharacters(in: .whitespaces)
                }
            }
            return firstComponent
        }
        
        return "Unknown"
    }
}