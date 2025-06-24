//  RouteResultsView.swift
//  DriveLess
//
//  Display optimized route results with map and directions
//

import SwiftUI
import GoogleMaps
import GooglePlaces  // <-- ADD THIS LINE
import CoreData  // <-- ADD THIS LINE

struct RouteResultsView: View {
    let routeData: RouteData
    @State private var isLoading = true
    @State private var optimizedRoute: RouteData
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var hapticManager: HapticManager  // ADD THIS LINE

    @State private var isFavorite: Bool = false  // ADD THIS LINE
    @State private var showingSaveConfirmation: Bool = false  // ADD THIS LINE
    @State private var showingNameRouteAlert: Bool = false  // ADD THIS LINE
    @State private var routeName: String = ""              // ADD THIS LINE
    
    // ADD THIS NEW STATE VARIABLE TO CACHE MAP DATA
    @State private var cachedMapRouteData: MapRouteData?

    
    // Add these new state variables for real route data
    @State private var routeLegs: [RouteLeg] = []
    @State private var routePolyline: String?
    @State private var waypointOrder: [Int] = []
    
    // MARK: - Usage Tracking
    @StateObject private var usageTracker = UsageTrackingManager()
    @State private var showingUsageLimitAlert = false
    
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
        // Check if this route is already favorited
            let routeHistoryManager = RouteHistoryManager()
            isFavorite = routeHistoryManager.isRouteFavorited(optimizedRoute)
            calculateRealRoute()
        }
        .alert("Daily Limit Reached", isPresented: $showingUsageLimitAlert) {
            Button("OK") {
                dismiss() // Go back to route input
            }
        } message: {
            Text("You've used \(usageTracker.todayUsage) out of \(UsageTrackingManager.DAILY_LIMIT) route calculations today. Your limit will reset at midnight.")
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
                        Text(formatDistanceForDisplay(optimizedRoute.totalDistance))
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
        Group {
            if let mapData = cachedMapRouteData {
                GoogleMapsView(routeData: mapData)
                    .frame(height: 350)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                // Fallback while loading
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 350)
                    .cornerRadius(12)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.2)
                    )
            }
        }
    }
        
    // Helper function to create map data from current route with real coordinates
    private func createMapRouteData() -> MapRouteData {
        var waypoints: [RouteStop] = []
        var coordinates: [CLLocationCoordinate2D] = []
        
        // If we have real route legs, use those coordinates
        if !routeLegs.isEmpty {
            print("📍 Using real coordinates from API response")
            
            // FIXED: Use the optimized route data (which has preserved business names)
            // instead of recreating from API legs
            
            for (index, optimizedStop) in optimizedRoute.optimizedStops.enumerated() {
                // Get coordinates from the corresponding leg
                let coordinate: CLLocationCoordinate2D
                if index == 0 {
                    // Start location - use start of first leg
                    coordinate = CLLocationCoordinate2D(
                        latitude: routeLegs.first?.start_location.lat ?? 0,
                        longitude: routeLegs.first?.start_location.lng ?? 0
                    )
                } else if index == optimizedRoute.optimizedStops.count - 1 {
                    // End location - use end of last leg
                    coordinate = CLLocationCoordinate2D(
                        latitude: routeLegs.last?.end_location.lat ?? 0,
                        longitude: routeLegs.last?.end_location.lng ?? 0
                    )
                } else {
                    // Middle stops - use end of corresponding leg
                    let legIndex = index - 1
                    if legIndex < routeLegs.count {
                        coordinate = CLLocationCoordinate2D(
                            latitude: routeLegs[legIndex].end_location.lat,
                            longitude: routeLegs[legIndex].end_location.lng
                        )
                    } else {
                        coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                    }
                }
                
                // Use the optimized stop data (which preserves business names)
                waypoints.append(optimizedStop)
                coordinates.append(coordinate)
                
                print("📍 MAP: Added waypoint \(index): '\(optimizedStop.name)' at \(coordinate.latitude), \(coordinate.longitude)")
            }
            
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
                                Text("📍 \(formatLegDistance(distance))")
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
            // Top row: Star button and Google Maps button
            HStack(spacing: 12) {
                // Star/Heart button to save as favorite
                Button(action: toggleFavorite) {
                    HStack {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .gray)
                        Text(isFavorite ? "Saved" : "Save Route")
                            .foregroundColor(isFavorite ? .red : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isFavorite ? Color.red.opacity(0.1) : Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isFavorite ? Color.red : Color.clear, lineWidth: 1)
                            )
                    )
                }
                
                // Google Maps button (now takes full width alongside save button)
                Button(action: openGoogleMaps) {
                    HStack {
                        Image(systemName: "map")
                        Text("Open in Google Maps")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
            }
        }
        .alert("Name Your Route", isPresented: $showingNameRouteAlert) {
            TextField("Route name", text: $routeName)
            Button("Save") {
                saveRouteWithName()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Give this route a custom name to make it easy to find later")
        }
        .alert("Route Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") { }
        } message: {
            Text("This route has been saved to your favorites for easy access!")
        }
    }
    
    // MARK: - Actions
    private func calculateRealRoute() {
        print("🚀 Starting real route calculation...")
        
        // MARK: - Check Usage Limits First
        if !usageTracker.canPerformRouteCalculation() {
            print("❌ Usage limit exceeded: \(usageTracker.todayUsage)/\(UsageTrackingManager.DAILY_LIMIT)")
            
            // Show usage limit alert instead of calculating route
            DispatchQueue.main.async {
                self.showingUsageLimitAlert = true
                self.isLoading = false
            }
            return
        }
        
        print("✅ Usage check passed: \(usageTracker.todayUsage)/\(UsageTrackingManager.DAILY_LIMIT)")
        
        // Extract business names from the optimized stops (preserves user's original search terms)
        let startDisplayName = routeData.optimizedStops.first?.name ?? ""
        let endDisplayName = routeData.optimizedStops.last?.name ?? ""
        let stopDisplayNames = Array(routeData.optimizedStops.dropFirst().dropLast()).map { $0.name }

        // ADD THIS DEBUG LOGGING:
        print("🔍 DEBUG: RouteData optimizedStops before API call:")
        for (index, stop) in routeData.optimizedStops.enumerated() {
            print("🔍   Stop \(index): name='\(stop.name)', address='\(stop.address)', originalInput='\(stop.originalInput)'")
        }

        print("🏪 Passing business names to API:")
        print("🏪 Start: '\(startDisplayName)'")
        print("🏪 End: '\(endDisplayName)'")
        print("🏪 Stops: \(stopDisplayNames)")
            

        // Use the real route calculator - NOW WITH BUSINESS NAMES
        RouteCalculator.calculateOptimizedRoute(
            startLocation: routeData.startLocation,
            endLocation: routeData.endLocation,
            stops: routeData.stops,
            considerTraffic: routeData.considerTraffic,
            // NEW: Pass the original business names the user searched for
            startLocationDisplayName: startDisplayName,
            endLocationDisplayName: endDisplayName,
            stopDisplayNames: stopDisplayNames
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let optimizedResult):
                    print("✅ Route calculation successful!")
                    
                    // MARK: - Increment Usage Counter (only on success)
                    self.usageTracker.incrementUsage()
                    print("📈 Usage incremented to: \(self.usageTracker.todayUsage)/\(UsageTrackingManager.DAILY_LIMIT)")
                    
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
                    
                    // CACHE THE MAP DATA HERE - ADD THIS NEW CODE
                    self.cachedMapRouteData = self.createMapRouteData()
                    print("📍 Cached map route data to prevent recreation")
                    
                    withAnimation {
                        self.isLoading = false
                    }
                    
                    // 📚 AUTO-SAVE ROUTE TO HISTORY (Only if setting is enabled)
                    if settingsManager.autoSaveRoutes {
                        let routeHistoryManager = RouteHistoryManager()
                        routeHistoryManager.saveRoute(self.optimizedRoute)
                        print("✅ Route auto-saved to history")
                    } else {
                        print("⏭️ Auto-save disabled - route not saved to history")
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
        
        // CACHE THE MOCK DATA TOO - ADD THIS LINE
        cachedMapRouteData = MapRouteData.mockRouteData(from: optimizedRoute)
        
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
    
    // MARK: - Distance Formatting

    
    // MARK: - Favorite Functionality

    // MARK: - Favorite Functionality

    // MARK: - Favorite Functionality

    /// Toggle favorite status and save/remove from favorites
    private func toggleFavorite() {
        let routeHistoryManager = RouteHistoryManager()
        
        if isFavorite {
            // Remove from favorites
            routeHistoryManager.removeFavorite(optimizedRoute)
            isFavorite = false
            hapticManager.impact(.light)
            print("💔 Route removed from favorites")
        } else {
            // Show naming dialog before saving
            routeName = generateSuggestedName()
            showingNameRouteAlert = true
        }
    }

    /// Actually save the route with the chosen name
    private func saveRouteWithName() {
        let routeHistoryManager = RouteHistoryManager()
        
        // Use the custom name if provided, otherwise use suggested name
        let finalName = routeName.isEmpty ? generateSuggestedName() : routeName
        
        // Save as favorite with custom name
        routeHistoryManager.saveFavoriteRoute(optimizedRoute, customName: finalName)
        isFavorite = true
        hapticManager.success()
        showingSaveConfirmation = true
        print("❤️ Route saved to favorites with name: '\(finalName)'")
    }

    /// Generate a suggested route name
    private func generateSuggestedName() -> String {
        let startName = optimizedRoute.optimizedStops.first?.name ?? "Start"
        let endName = optimizedRoute.optimizedStops.last?.name ?? "End"
        let stopCount = optimizedRoute.optimizedStops.count - 2 // Exclude start and end
        
        if stopCount > 0 {
            return "\(startName) → \(endName) (+\(stopCount) stops)"
        } else {
            return "\(startName) → \(endName)"
        }
    }
    
    /// Converts distance string from miles to user's preferred unit
    private func formatDistanceForDisplay(_ distanceString: String) -> String {
        // Extract the numeric value from strings like "25.0 miles" or "10.5 mi"
        let cleanString = distanceString.replacingOccurrences(of: " miles", with: "")
                                       .replacingOccurrences(of: " mi", with: "")
                                       .trimmingCharacters(in: .whitespaces)
        
        guard let milesValue = Double(cleanString) else {
            // If we can't parse it, return as-is
            return distanceString
        }
        
        // Convert to user's preferred unit
        switch settingsManager.distanceUnit {
        case .miles:
            return String(format: "%.1f mi", milesValue)
        case .kilometers:
            let kilometers = milesValue * 1.60934
            return String(format: "%.1f km", kilometers)
        }
    }

    /// Formats individual leg distances (like "10.5 mi" from route legs)
    private func formatLegDistance(_ legDistanceText: String) -> String {
        // Handle Google API distance format (e.g., "10.5 mi", "5.2 km")
        if legDistanceText.contains("mi") {
            let cleanValue = legDistanceText.replacingOccurrences(of: " mi", with: "")
                                           .trimmingCharacters(in: .whitespaces)
            if let miles = Double(cleanValue) {
                switch settingsManager.distanceUnit {
                case .miles:
                    return String(format: "%.1f mi", miles)
                case .kilometers:
                    let kilometers = miles * 1.60934
                    return String(format: "%.1f km", kilometers)
                }
            }
        }
        
        // If already in km or unrecognized format, return as-is for now
        return legDistanceText
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
