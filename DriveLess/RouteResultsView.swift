//  RouteResultsView.swift
//  DriveLess
//
//  Display optimized route results with map and directions
//

import SwiftUI
import GoogleMaps
import GooglePlaces  // <-- ADD THIS LINE


struct RouteResultsView: View {
    let routeData: RouteData
    @State private var isLoading = true
    @State private var optimizedRoute: RouteData
    
    init(routeData: RouteData) {
        self.routeData = routeData
        self._optimizedRoute = State(initialValue: routeData)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                // Loading State
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Optimizing your route...")
                        .font(.headline)
                    
                    Text("Finding the best order for your stops")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                // Results Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Stats
                        routeStatsView
                        
                        // Google Maps View
                        interactiveMapView
                        
                        // Route Order List
                        routeOrderView
                        
                        // Action Buttons
                        actionButtonsView
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)

        .onAppear {
            simulateRouteCalculation()
        }
    }
    
    // MARK: - View Components
    
    private var routeStatsView: some View {
        HStack(spacing: 20) {
            VStack {
                HStack {
                    Image(systemName: "map")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Total Distance")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(optimizedRoute.totalDistance)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
            
            VStack {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Estimated Time")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(optimizedRoute.estimatedTime)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
    }
    

    private var interactiveMapView: some View {
        SimpleMapView()
                .frame(height: 350) // Optimal height for mobile viewing
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        
        // Helper function to convert optimized route back to RouteData format
        private func createRouteDataFromOptimized() -> RouteData {
            // Extract addresses from optimized route
            let startLocation = optimizedRoute.optimizedStops.first?.address ?? ""
            let endLocation = optimizedRoute.optimizedStops.last?.address ?? ""
            let stops = Array(optimizedRoute.optimizedStops.dropFirst().dropLast()).map { $0.address }
            
            return RouteData(
                startLocation: startLocation,
                endLocation: endLocation,
                stops: stops,
                isRoundTrip: false, // We'll enhance this later
                considerTraffic: true
            )
        }
    
    private var routeOrderView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(.primary)
                Text("Route Order")
                    .font(.headline)
            }
            .padding(.bottom, 10)
            
            ForEach(Array(optimizedRoute.optimizedStops.enumerated()), id: \.offset) { index, stop in
                HStack {
                    // Stop Number
                    Circle()
                        .fill(stop.type.color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    // Stop Details
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stop.name.isEmpty ? stop.address : stop.name)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(stop.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let distance = stop.distance, let duration = stop.duration {
                            HStack {
                                Text("📍 \(distance)")
                                Text("⏱️ \(duration)")
                            }
                            .font(.caption2)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    // Stop Type Badge
                    Text(stop.type.label)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(stop.type.color.opacity(0.2))
                        .foregroundColor(stop.type.color)
                        .cornerRadius(8)
                }
                .padding(.vertical, 8)
                
                if index < optimizedRoute.optimizedStops.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(10)
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: openGoogleMaps) {
                    HStack {
                        Image(systemName: "map")
                        Text("Google Maps")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: openAppleMaps) {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Apple Maps")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func simulateRouteCalculation() {
        // Simulate API call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Create mock optimized route
            var mockStops: [RouteStop] = []
            
            // Add start
            mockStops.append(RouteStop(
                address: routeData.startLocation,
                name: extractBusinessName(routeData.startLocation),
                type: .start,
                distance: nil,
                duration: nil
            ))
            
            // Add stops
            for (index, stop) in routeData.stops.enumerated() {
                if !stop.isEmpty {
                    mockStops.append(RouteStop(
                        address: stop,
                        name: extractBusinessName(stop),
                        type: .stop,
                        distance: "\(Float.random(in: 5...15).rounded(1)) mi",
                        duration: "\(Int.random(in: 10...25)) min"
                    ))
                }
            }
            
            // Add end
            mockStops.append(RouteStop(
                address: routeData.endLocation,
                name: extractBusinessName(routeData.endLocation),
                type: .end,
                distance: "\(Float.random(in: 3...12).rounded(1)) mi",
                duration: "\(Int.random(in: 8...20)) min"
            ))
            
            optimizedRoute.optimizedStops = mockStops
            optimizedRoute.totalDistance = "\(Float.random(in: 25...45).rounded(1)) miles"
            optimizedRoute.estimatedTime = "\(Int.random(in: 45...75)) min"
            
            withAnimation {
                isLoading = false
            }
        }
    }
    
    private func extractBusinessName(_ address: String) -> String {
        if address.contains(",") {
            let name = address.components(separatedBy: ",").first ?? ""
            return name.trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
    
    private func openGoogleMaps() {
        print("🗺️ Opening Google Maps...")
    }
    
    private func openAppleMaps() {
        print("🍎 Opening Apple Maps...")
    }
    
    private func goBack() {
        print("⬅️ Going back to route input...")
    }
}

// Extension for Float rounding
extension Float {
    func rounded(_ digits: Int) -> Float {
        let multiplier = pow(10.0, Float(digits))
        return (self * multiplier).rounded() / multiplier
    }
}

#Preview {
    NavigationView {
        RouteResultsView(
            routeData: RouteData(
                startLocation: "15206 Newport Bridge Court, Sugar Land, TX, USA",
                endLocation: "McDonalds, Commerce Street, Dallas, TX, USA",
                stops: ["Walmart Supercenter, Market Place Boulevard, Irving, TX, USA"],
                isRoundTrip: false,
                considerTraffic: true
            )
        )
    }
}
