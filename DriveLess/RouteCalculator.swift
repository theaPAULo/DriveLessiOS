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
//  Real route optimization using Google Directions API
//

import Foundation
import GoogleMaps
import CoreLocation

class RouteCalculator: ObservableObject {
    
    // MARK: - Route Calculation
    
    /**
     * Calculate optimized route using Google Directions API
     * This mimics the web app's calculateOptimizedRoute function
     */
    static func calculateOptimizedRoute(
        startLocation: String,
        endLocation: String, 
        stops: [String],
        considerTraffic: Bool,
        completion: @escaping (Result<OptimizedRouteResult, Error>) -> Void
    ) {
        
        print("🗺️ Starting real route optimization...")
        print("📍 Start: \(startLocation)")
        print("📍 Stops: \(stops)")
        print("📍 End: \(endLocation)")
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
        let apiKey = "AIzaSyCancy_vwbDbYZavxDjtpL7NW4lYl8Tkmk"
        
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
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(RouteCalculationError.noData))
                return
            }
            
            // Parse the response
            do {
                let result = try JSONDecoder().decode(DirectionsResponse.self, from: data)
                
                if result.status == "OK", let route = result.routes.first {
                    print("✅ Route calculation successful!")
                    
                    // Process the route data
                    let optimizedResult = processDirectionsResponse(result, considerTraffic: considerTraffic)
                    completion(.success(optimizedResult))
                } else {
                    print("❌ API returned error status: \(result.status)")
                    completion(.failure(RouteCalculationError.apiError(result.status)))
                }
                
            } catch {
                print("❌ Failed to parse API response: \(error)")
                completion(.failure(error))
            }
            
        }.resume()
    }
    
    // MARK: - Response Processing
    
    private static func processDirectionsResponse(
        _ response: DirectionsResponse,
        considerTraffic: Bool
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
        
        // Create optimized stops in the correct order
        var optimizedStops: [RouteStop] = []
        
        // Add start location
        optimizedStops.append(RouteStop(
            address: legs.first?.start_address ?? "",
            name: extractBusinessName(legs.first?.start_address ?? ""),
            type: .start,
            distance: nil,
            duration: nil
        ))
        
        // Add waypoints in optimized order
        let waypointOrder = route.waypoint_order ?? []
        for (index, leg) in legs.enumerated() {
            if index < legs.count - 1 { // Don't add the final destination as a stop
                optimizedStops.append(RouteStop(
                    address: leg.end_address,
                    name: extractBusinessName(leg.end_address),
                    type: .stop,
                    distance: String(format: "%.1f mi", Double(leg.distance.value) / 1609.34),
                    duration: "\(leg.duration.value / 60) min"
                ))
            }
        }
        
        // Add end location
        optimizedStops.append(RouteStop(
            address: legs.last?.end_address ?? "",
            name: extractBusinessName(legs.last?.end_address ?? ""),
            type: .end,
            distance: nil,
            duration: nil
        ))
        
        return OptimizedRouteResult(
            totalDistance: "\(totalDistanceMiles) miles",
            estimatedTime: durationText,
            optimizedStops: optimizedStops,
            routePolyline: route.overview_polyline?.points,
            legs: legs,
            waypointOrder: waypointOrder
        )
    }
    
    private static func extractBusinessName(_ address: String) -> String {
        guard address.contains(",") else { return "" }
        let name = address.components(separatedBy: ",").first ?? ""
        return name.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Data Models

struct OptimizedRouteResult {
    let totalDistance: String
    let estimatedTime: String
    let optimizedStops: [RouteStop]
    let routePolyline: String?
    let legs: [RouteLeg]
    let waypointOrder: [Int]
}

// MARK: - Google Directions API Response Models

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

// MARK: - Error Types

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