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
    @Environment(\.dismiss) private var dismiss
    
    // Add these new state variables for real route data
    @State private var routeLegs: [RouteLeg] = []
    @State private var routePolyline: String?
    @State private var waypointOrder: [Int] = []
    
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
        .navigationBarBackButtonHidden(true)
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    // Check if this is a right swipe (going back)
                    // Note: Using .width and .height instead of .x and .y
                    if gesture.translation.width > 100 && abs(gesture.translation.height) < 50 {
                        // Add haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        // Navigate back to RouteInputView
                        dismiss()
                    }
                }
        )
        .onAppear {
            calculateRealRoute()
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
        GoogleMapsView(routeData: createMapRouteData())
                .frame(height: 350) // Optimal height for mobile viewing
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        
    // Helper function to create map data from current route with real coordinates
    private func createMapRouteData() -> MapRouteData {
        var waypoints: [RouteStop] = []
        var coordinates: [CLLocationCoordinate2D] = []
        
        // If we have real route legs, use those coordinates
        if !routeLegs.isEmpty {
            print("📍 Using real coordinates from API response")
            
            // Add start location
            let firstLeg = routeLegs.first!
            waypoints.append(RouteStop(
                address: firstLeg.start_address,
                name: extractBusinessName(firstLeg.start_address),
                originalInput: firstLeg.start_address,
                type: .start,
                distance: nil,
                duration: nil
            ))
            coordinates.append(CLLocationCoordinate2D(
                latitude: firstLeg.start_location.lat,
                longitude: firstLeg.start_location.lng
            ))
            
            // Add intermediate stops
            for (index, leg) in routeLegs.enumerated() {
                if index < routeLegs.count - 1 { // Don't add final destination as stop
                    waypoints.append(RouteStop(
                        address: leg.end_address,
                        name: extractBusinessName(leg.end_address),
                        originalInput: leg.end_address,
                        type: .stop,
                        distance: leg.distance.text,
                        duration: leg.duration.text
                    ))
                    coordinates.append(CLLocationCoordinate2D(
                        latitude: leg.end_location.lat,
                        longitude: leg.end_location.lng
                    ))
                }
            }
            
            // Add end location
            let lastLeg = routeLegs.last!
            waypoints.append(RouteStop(
                address: lastLeg.end_address,
                name: extractBusinessName(lastLeg.end_address),
                originalInput: lastLeg.end_address,  // Added missing parameter
                type: .end,
                distance: nil,
                duration: nil
            ))
            coordinates.append(CLLocationCoordinate2D(
                latitude: lastLeg.end_location.lat,
                longitude: lastLeg.end_location.lng
            ))
            
            return MapRouteData(
                waypoints: waypoints,
                totalDistance: optimizedRoute.totalDistance,
                estimatedTime: optimizedRoute.estimatedTime,
                routeCoordinates: coordinates,
                encodedPolyline: routePolyline // Pass the real polyline
            )
            
        } else {
            print("📍 No route legs available, using fallback")
            // Fallback to mock data if no real route data
            return MapRouteData.mockRouteData(from: optimizedRoute)
        }
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
                        // Main text: Business name or best display name
                        Text(stop.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        // Subtitle: Always show the full address
                        Text(stop.displayAddress)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                        
                        // Distance and duration info
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
    
    private func calculateRealRoute() {
        print("🚀 Starting real route calculation...")
        
        // Use the real route calculator
        RouteCalculator.calculateOptimizedRoute(
            startLocation: routeData.startLocation,
            endLocation: routeData.endLocation,
            stops: routeData.stops,
            considerTraffic: routeData.considerTraffic
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let optimizedResult):
                    print("✅ Route calculation successful!")
                    
                    // Update the UI with real data, preserving business names from input
                    self.optimizedRoute.totalDistance = optimizedResult.totalDistance
                    self.optimizedRoute.estimatedTime = optimizedResult.estimatedTime

                    // IMPORTANT: Merge API results with original business names
                    // The API gives us accurate addresses and coordinates, but we want to keep
                    // the business names that the user originally selected for better UX
                    var mergedStops: [RouteStop] = []
                    let originalStops = self.optimizedRoute.optimizedStops // These have the business names

                    for (index, apiStop) in optimizedResult.optimizedStops.enumerated() {
                        if index < originalStops.count {
                            // Use business name from original input, but address from API
                            mergedStops.append(RouteStop(
                                address: apiStop.address,           // Accurate from API
                                name: originalStops[index].name,    // Business name from user input
                                originalInput: originalStops[index].originalInput, // Original user input
                                type: apiStop.type,                 // Type from API
                                distance: apiStop.distance,         // Distance from API
                                duration: apiStop.duration          // Duration from API
                            ))
                        } else {
                            // Fallback to API data if we don't have original data
                            mergedStops.append(apiStop)
                        }
                    }

                    self.optimizedRoute.optimizedStops = mergedStops
                    
                    // Store additional route data for map display
                    self.routeLegs = optimizedResult.legs
                    self.routePolyline = optimizedResult.routePolyline
                    self.waypointOrder = optimizedResult.waypointOrder
                    
                    // Extract real coordinates from the API response
                    print("📍 Extracting real coordinates from API response...")
                    for (index, leg) in optimizedResult.legs.enumerated() {
                        print("📍 Leg \(index): Start(\(leg.start_location.lat), \(leg.start_location.lng)) -> End(\(leg.end_location.lat), \(leg.end_location.lng))")
                    }
                    
                    withAnimation {
                        self.isLoading = false
                    }
                    
                case .failure(let error):
                    print("❌ Route calculation failed: \(error.localizedDescription)")
                    
                    // Show error to user and fall back to mock data
                    self.showErrorAndFallbackToMock(error: error)
                }
            }
        }
    }

    private func showErrorAndFallbackToMock(error: Error) {
        // For now, just log the error and show mock data
        // In production, you'd want to show an error message to the user
        print("⚠️ Falling back to mock data due to error: \(error.localizedDescription)")
        
        // Create fallback mock data
        var mockStops: [RouteStop] = []
        
        mockStops.append(RouteStop(
            address: routeData.startLocation,
            name: extractBusinessName(routeData.startLocation),
            originalInput: routeData.startLocation,  // Added missing parameter
            type: .start,
            distance: nil,
            duration: nil
        ))
        
        for stop in routeData.stops {
            if !stop.isEmpty {
                mockStops.append(RouteStop(
                    address: stop,
                    name: extractBusinessName(stop),
                    originalInput: stop,  // Added missing parameter
                    type: .stop,
                    distance: "10.5 mi",
                    duration: "15 min"
                ))
            }
        }
        
        mockStops.append(RouteStop(
            address: routeData.endLocation,
            name: extractBusinessName(routeData.endLocation),
            originalInput: routeData.endLocation,  // Added missing parameter
            type: .end,
            distance: nil,
            duration: nil
        ))
        
        optimizedRoute.optimizedStops = mockStops
        optimizedRoute.totalDistance = "25.0 miles"
        optimizedRoute.estimatedTime = "45 min"
        
        withAnimation {
            isLoading = false
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
        guard let url = generateGoogleMapsUrl() else {
            print("❌ Could not generate Google Maps URL")
            return
        }
        
        print("🗺️ Opening Google Maps with URL: \(url)")
        UIApplication.shared.open(url)
    }

    private func openAppleMaps() {
        guard let url = generateAppleMapsUrl() else {
            print("❌ Could not generate Apple Maps URL")
            return
        }
        
        print("🍎 Opening Apple Maps with URL: \(url)")
        UIApplication.shared.open(url)
    }

    private func generateGoogleMapsUrl() -> URL? {
        guard !optimizedRoute.optimizedStops.isEmpty else { return nil }
        
        let origin = optimizedRoute.optimizedStops.first!.address
        let destination = optimizedRoute.optimizedStops.last!.address
        let waypoints = Array(optimizedRoute.optimizedStops.dropFirst().dropLast())
            .map { $0.address }
            .joined(separator: "|")
        
        var urlString = "https://www.google.com/maps/dir/?api=1"
        urlString += "&origin=\(origin.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        urlString += "&destination=\(destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if !waypoints.isEmpty {
            urlString += "&waypoints=\(waypoints.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        urlString += "&travelmode=driving"
        
        return URL(string: urlString)
    }

    private func generateAppleMapsUrl() -> URL? {
        guard !optimizedRoute.optimizedStops.isEmpty else { return nil }
        
        let origin = optimizedRoute.optimizedStops.first!.address
        let destination = optimizedRoute.optimizedStops.last!.address
        
        var urlString = "http://maps.apple.com/?daddr=\(destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        urlString += "&saddr=\(origin.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        urlString += "&dirflg=d"
        
        return URL(string: urlString)
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
