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

        // ENHANCED: Store display names from optimized stops
        if !routeData.optimizedStops.isEmpty {
            // Extract display names from the optimized stops
            let startStop = routeData.optimizedStops.first
            let endStop = routeData.optimizedStops.last
            
            savedRoute.startLocationDisplayName = startStop?.name ?? extractBusinessName(routeData.startLocation)
            savedRoute.endLocationDisplayName = endStop?.name ?? extractBusinessName(routeData.endLocation)
            
            // Save stop display names as JSON
            let stopDisplayNames = routeData.optimizedStops
                .dropFirst()  // Remove start
                .dropLast()   // Remove end
                .map { $0.name ?? extractBusinessName($0.address) }
            
            if !stopDisplayNames.isEmpty {
                do {
                    let displayNamesData = try JSONEncoder().encode(stopDisplayNames)
                    savedRoute.stopDisplayNames = String(data: displayNamesData, encoding: .utf8)
                } catch {
                    print("❌ Failed to encode stop display names: \(error)")
                }
            }
        } else {
            // Fallback: extract from addresses
            savedRoute.startLocationDisplayName = extractBusinessName(routeData.startLocation)
            savedRoute.endLocationDisplayName = extractBusinessName(routeData.endLocation)
        }

        print("💾 Saved with display names: '\(savedRoute.startLocationDisplayName ?? "")' → '\(savedRoute.endLocationDisplayName ?? "")'")
        
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
        
        // Decode stop display names from JSON
        var stopDisplayNames: [String] = []
        if let stopDisplayNamesString = savedRoute.stopDisplayNames {
            if let displayNamesData = stopDisplayNamesString.data(using: .utf8),
               let decodedDisplayNames = try? JSONDecoder().decode([String].self, from: displayNamesData) {
                stopDisplayNames = decodedDisplayNames
            }
        }
        
        // Create RouteData object
        var routeData = RouteData(
            startLocation: savedRoute.startLocation ?? "",
            endLocation: savedRoute.endLocation ?? "",
            stops: stops,
            isRoundTrip: false, // We'll enhance this later
            considerTraffic: savedRoute.considerTraffic
        )
        
        // ENHANCED: Create optimizedStops with saved display names
        var optimizedStops: [RouteStop] = []
        
        // Add start location with saved display name
        optimizedStops.append(RouteStop(
            address: savedRoute.startLocation ?? "",
            name: savedRoute.startLocationDisplayName ?? extractBusinessName(savedRoute.startLocation ?? ""),
            originalInput: savedRoute.startLocationDisplayName ?? extractBusinessName(savedRoute.startLocation ?? ""),
            type: .start,
            distance: nil,
            duration: nil
        ))
        
        // Add stops with saved display names
        for (index, stop) in stops.enumerated() {
            let displayName = index < stopDisplayNames.count ?
                stopDisplayNames[index] :
                extractBusinessName(stop)
            
            optimizedStops.append(RouteStop(
                address: stop,
                name: displayName,
                originalInput: displayName,
                type: .stop,
                distance: nil,
                duration: nil
            ))
        }
        
        // Add end location with saved display name
        optimizedStops.append(RouteStop(
            address: savedRoute.endLocation ?? "",
            name: savedRoute.endLocationDisplayName ?? extractBusinessName(savedRoute.endLocation ?? ""),
            originalInput: savedRoute.endLocationDisplayName ?? extractBusinessName(savedRoute.endLocation ?? ""),
            type: .end,
            distance: nil,
            duration: nil
        ))
        
        // Set the optimized stops with display names
        routeData.optimizedStops = optimizedStops
        
        print("🔄 Converted saved route with display names: '\(savedRoute.startLocationDisplayName ?? "")' → '\(savedRoute.endLocationDisplayName ?? "")'")
        
        return routeData
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
    /// Extracts a business name from a full address (same logic as in RouteInputView)
    /// - Parameter address: Full address string
    /// - Returns: Business name or first part of address
    private func extractBusinessName(_ address: String) -> String {
        if address.contains(",") {
            let firstPart = address.components(separatedBy: ",").first ?? ""
            return firstPart.trimmingCharacters(in: .whitespaces)
        }
        return address
    }
}
