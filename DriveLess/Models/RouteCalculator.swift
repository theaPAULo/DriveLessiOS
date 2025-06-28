//
//  RouteCalculator.swift
//  DriveLess
//
//  Created by Paul Soni on 6/19/25.
//

//
//  RouteCalculator.swift
//  DriveLess
//
//  Real route optimization using Google Directions API - UPDATED to preserve business names
//

import Foundation
import GoogleMaps
import CoreLocation
import FirebaseAuth  // For ErrorTrackingService


// UPDATED: Enhanced struct to preserve original business names
struct OriginalRouteInputs {
    let startLocation: String
    let endLocation: String
    let stops: [String]
    // NEW: Add display names to preserve business names the user actually searched for
    let startLocationDisplayName: String
    let endLocationDisplayName: String
    let stopDisplayNames: [String]
}

class RouteCalculator: ObservableObject {
    
    // MARK: - Route Calculation
    
    /**
     * Calculate optimized route using Google Directions API
     * UPDATED: Now accepts business names to preserve user's original search terms
     */
    static func calculateOptimizedRoute(
        startLocation: String,
        endLocation: String,
        stops: [String],
        considerTraffic: Bool,
        // NEW: Add parameters for business names
        startLocationDisplayName: String = "",
        endLocationDisplayName: String = "",
        stopDisplayNames: [String] = [],
        completion: @escaping (Result<OptimizedRouteResult, Error>) -> Void
    ) {
        
        print("🗺️ Starting real route optimization...")
        print("📍 Start: \(startLocation) (Display: '\(startLocationDisplayName)')")
        print("📍 Stops: \(stops)")
        print("📍 Stop Display Names: \(stopDisplayNames)")
        print("📍 End: \(endLocation) (Display: '\(endLocationDisplayName)')")
        print("🚗 Consider traffic: \(considerTraffic)")
        
        // Create waypoints for Google Directions API
        var waypoints: [String] = []
        for stop in stops {
            if !stop.isEmpty {
                waypoints.append(stop)
            }
        }
        
        // Build the Google Directions API URL
        let baseURL = "https://maps.googleapis.com/maps/api/directions/json"
        let apiKey = ConfigurationManager.shared.googleAPIKey

        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "origin", value: startLocation),
            URLQueryItem(name: "destination", value: endLocation),
            URLQueryItem(name: "waypoints", value: "optimize:true|\(waypoints.joined(separator: "|"))"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        // Add traffic parameters if requested
        if considerTraffic {
            urlComponents.queryItems?.append(URLQueryItem(name: "departure_time", value: "now"))
            urlComponents.queryItems?.append(URLQueryItem(name: "traffic_model", value: "best_guess"))
        }
        
        guard let url = urlComponents.url else {
            completion(.failure(RouteCalculationError.invalidURL))
            return
        }
        
        print("🌐 Making API request to: \(url)")
        
        // Make the API request
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ API request failed: \(error.localizedDescription)")
                
                // 🆕 ADD THIS: Track network error
                ErrorTrackingService.shared.trackNetworkError(error, operation: "Google Directions API Request")
                
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                // 🆕 ADD THIS: Track API error
                let noDataError = RouteCalculationError.noData
                ErrorTrackingService.shared.trackGoogleAPIError(noDataError, endpoint: "directions/json")
                
                completion(.failure(noDataError))
                return
            }
            
            // Parse the response
            do {
                let result = try JSONDecoder().decode(DirectionsResponse.self, from: data)
                
                if result.status == "OK", !result.routes.isEmpty {
                    print("✅ Route calculation successful!")
                    
                    // UPDATED: Pass original business names to preserve them
                    let originalInputs = OriginalRouteInputs(
                        startLocation: startLocation,
                        endLocation: endLocation,
                        stops: stops,
                        startLocationDisplayName: startLocationDisplayName,
                        endLocationDisplayName: endLocationDisplayName,
                        stopDisplayNames: stopDisplayNames
                    )
                    let optimizedResult = processDirectionsResponse(result, considerTraffic: considerTraffic, originalInputs: originalInputs)
                    completion(.success(optimizedResult))
                } else {
                    print("❌ API returned error status: \(result.status)")
                    
                    // 🆕 ADD THIS: Track API error with status
                    let apiError = RouteCalculationError.apiError(result.status)
                    ErrorTrackingService.shared.trackGoogleAPIError(apiError, endpoint: "directions/json - Status: \(result.status)")
                    
                    completion(.failure(apiError))
                }
                
            } catch {
                print("❌ Failed to parse API response: \(error)")
                
                // 🆕 ADD THIS: Track parsing error
                ErrorTrackingService.shared.trackGoogleAPIError(error, endpoint: "directions/json - JSON parsing failed")
                
                completion(.failure(error))
            }
            
        }.resume()
    }
    
    // MARK: - Response Processing
    
    private static func processDirectionsResponse(
        _ response: DirectionsResponse,
        considerTraffic: Bool,
        originalInputs: OriginalRouteInputs
    ) -> OptimizedRouteResult {
        
        guard let route = response.routes.first else {
            fatalError("No routes in response")
        }
        
        let legs = route.legs
        
        // Calculate total distance and time
        var totalDistanceMeters = 0
        var totalDurationSeconds = 0
        
        for leg in legs {
            totalDistanceMeters += leg.distance.value
            
            // Use duration_in_traffic if available and traffic consideration is enabled
            if considerTraffic, let trafficDuration = leg.duration_in_traffic {
                totalDurationSeconds += trafficDuration.value
                print("🚗 Using traffic duration: \(trafficDuration.text) vs normal: \(leg.duration.text)")
            } else {
                totalDurationSeconds += leg.duration.value
            }
        }
        
        // Format results
        let totalDistanceMiles = String(format: "%.1f", Double(totalDistanceMeters) / 1609.34)
        let totalDurationMinutes = totalDurationSeconds / 60
        
        let durationText: String
        if totalDurationMinutes >= 60 {
            let hours = totalDurationMinutes / 60
            let minutes = totalDurationMinutes % 60
            durationText = "\(hours) hr \(minutes) min"
        } else {
            durationText = "\(totalDurationMinutes) min"
        }
        
        // UPDATED: Create optimized stops preserving original business names
        var optimizedStops: [RouteStop] = []
        
        // Get waypoint order for mapping optimized route back to original inputs
        let routeWaypointOrder = route.waypoint_order ?? []
        
        // Add start location - use original business name if available
        let startDisplayName = !originalInputs.startLocationDisplayName.isEmpty ?
            originalInputs.startLocationDisplayName :
            extractBusinessName(legs.first?.start_address ?? "")
        
        optimizedStops.append(RouteStop(
            address: legs.first?.start_address ?? "",
            name: startDisplayName,  // PRESERVE original business name
            originalInput: originalInputs.startLocationDisplayName,
            type: .start,
            distance: nil,
            duration: nil
        ))

        print("🏪 Added START with business name: '\(startDisplayName)'")

        // Add waypoints in optimized order - PRESERVE original business names
        for (legIndex, leg) in legs.enumerated() {
            if legIndex < legs.count - 1 { // Don't add the final destination as a stop
                // Map this leg back to the original input using waypoint order
                let originalStopIndex = legIndex < routeWaypointOrder.count ? routeWaypointOrder[legIndex] : legIndex
                
                // Get the original business name the user searched for
                let originalStopDisplayName: String
                if originalStopIndex < originalInputs.stopDisplayNames.count && !originalInputs.stopDisplayNames[originalStopIndex].isEmpty {
                    originalStopDisplayName = originalInputs.stopDisplayNames[originalStopIndex]
                    print("🏪 Using ORIGINAL business name for stop \(legIndex): '\(originalStopDisplayName)'")
                } else {
                    // Fallback to extracted name from address
                    originalStopDisplayName = extractBusinessName(leg.end_address)
                    print("⚠️ Using EXTRACTED name for stop \(legIndex): '\(originalStopDisplayName)'")
                }
                
                optimizedStops.append(RouteStop(
                    address: leg.end_address,
                    name: originalStopDisplayName,  // PRESERVE original business name
                    originalInput: originalStopIndex < originalInputs.stopDisplayNames.count ? originalInputs.stopDisplayNames[originalStopIndex] : "",
                    type: .stop,
                    distance: String(format: "%.1f mi", Double(leg.distance.value) / 1609.34),
                    duration: "\(leg.duration.value / 60) min"
                ))
            }
        }

        // Add end location - use original business name if available
        let endDisplayName = !originalInputs.endLocationDisplayName.isEmpty ?
            originalInputs.endLocationDisplayName :
            extractBusinessName(legs.last?.end_address ?? "")
        
        optimizedStops.append(RouteStop(
            address: legs.last?.end_address ?? "",
            name: endDisplayName,  // PRESERVE original business name
            originalInput: originalInputs.endLocationDisplayName,
            type: .end,
            distance: nil,
            duration: nil
        ))

        print("🏪 Added END with business name: '\(endDisplayName)'")
        
        return OptimizedRouteResult(
            totalDistance: "\(totalDistanceMiles) miles",
            estimatedTime: durationText,
            optimizedStops: optimizedStops,
            routePolyline: route.overview_polyline?.points,
            legs: legs,
            waypointOrder: routeWaypointOrder
        )
    }
    
    private static func extractBusinessName(_ address: String) -> String {
        guard address.contains(",") else { return "" }
        let name = address.components(separatedBy: ",").first ?? ""
        return name.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Data Models (unchanged)

struct OptimizedRouteResult {
    let totalDistance: String
    let estimatedTime: String
    let optimizedStops: [RouteStop]
    let routePolyline: String?
    let legs: [RouteLeg]
    let waypointOrder: [Int]
}

// MARK: - Google Directions API Response Models (unchanged)

struct DirectionsResponse: Codable {
    let status: String
    let routes: [DirectionsRoute]
}

struct DirectionsRoute: Codable {
    let legs: [RouteLeg]
    let overview_polyline: OverviewPolyline?
    let waypoint_order: [Int]?
}

struct RouteLeg: Codable {
    let distance: RouteDistance
    let duration: RouteDuration
    let duration_in_traffic: RouteDuration?
    let start_address: String
    let end_address: String
    let start_location: RouteLocation
    let end_location: RouteLocation
}

struct RouteDistance: Codable {
    let text: String
    let value: Int
}

struct RouteDuration: Codable {
    let text: String
    let value: Int
}

struct RouteLocation: Codable {
    let lat: Double
    let lng: Double
}

struct OverviewPolyline: Codable {
    let points: String
}

// MARK: - Error Types (unchanged)

enum RouteCalculationError: Error, LocalizedError {
    case invalidURL
    case noData
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from API"
        case .apiError(let status):
            return "API Error: \(status)"
        }
    }
}
