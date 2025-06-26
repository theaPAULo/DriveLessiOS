//
//  RouteResultsView.swift
//  DriveLess
//
//  Display optimized route results with unified earthy theme
//

import SwiftUI
import GoogleMaps
import GooglePlaces
import CoreData

struct RouteResultsView: View {
    let routeData: RouteData
    @State private var isLoading = true
    @State private var optimizedRoute: RouteData
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var hapticManager: HapticManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var isFavorite: Bool = false
    @State private var showingSaveConfirmation: Bool = false
    @State private var showingNameRouteAlert: Bool = false
    @State private var routeName: String = ""
    @State private var showingUsageLimitAlert: Bool = false
    
    // Map and route data
    @State private var cachedMapRouteData: MapRouteData?
    @State private var routeLegs: [RouteLeg] = []
    @State private var routePolyline: String?
    
    // Usage tracking
    @StateObject private var usageTracker = UsageTrackingManager()
    
    init(routeData: RouteData) {
        self.routeData = routeData
        self._optimizedRoute = State(initialValue: routeData)
    }
    
    var body: some View {
        ZStack {
                // Background
                themeManager.background
                    .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            // MARK: - Route Summary Card
                            routeSummaryCard
                            
                            // MARK: - Interactive Map
                            mapSection
                            
                            // MARK: - Route Order
                            routeOrderSection
                            
                            // MARK: - Action Buttons
                            actionButtonsSection
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }
            }
        .navigationTitle("Your Route")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    hapticManager.buttonTap()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeManager.primary)
                }
            }
        }
        .onAppear {
                calculateRealRoute()
                checkIfFavorite()
            }
            .alert("Daily Limit Reached", isPresented: $showingUsageLimitAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("You've used all \(UsageTrackingManager.DAILY_LIMIT) route calculations for today. Your limit will reset at midnight.")
            }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    // Check if this is a right swipe (going back)
                    if gesture.translation.width > 100 && abs(gesture.translation.height) < 50 {
                        // Add haptic feedback
                        hapticManager.impact(.medium)
                        
                        // Navigate back to RouteInputView
                        dismiss()
                    }
                }
        )
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Loading View (Themed)
    private var loadingView: some View {
        VStack(spacing: 20) {
            // Animated route icon
            Image(systemName: "map.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.primary)
                .scaleEffect(1.2)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isLoading)
            
            Text("Optimizing Your Route")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textPrimary)
            
            Text("Finding the most efficient path...")
                .font(.body)
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.primary))
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.background)
    }
    
    // MARK: - Route Summary Card (Themed)
    private var routeSummaryCard: some View {
        VStack(spacing: 16) {
            // Header with route info (REMOVED: Optimized badge)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimary)
                }
                
                Spacer()
                
                // REMOVED: Optimized badge
            }
            
            // Route metrics
            HStack(spacing: 20) {
                metricItem(
                    icon: "road.lanes",
                    title: "Distance",
                    value: optimizedRoute.totalDistance,
                    color: themeManager.primary
                )
                
                Divider()
                    .frame(height: 40)
                
                metricItem(
                    icon: "clock.fill",
                    title: "Time",
                    value: optimizedRoute.estimatedTime,
                    color: themeManager.secondary
                )
                
                Divider()
                    .frame(height: 40)
                
                metricItem(
                    icon: "mappin.circle.fill",
                    title: "Stops",
                    value: "\(optimizedRoute.optimizedStops.count)",
                    color: themeManager.accent
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackground)
                .shadow(color: themeManager.cardShadow(), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Metric Item Helper (Themed)
    private func metricItem(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Map Section (Themed)
    private var mapSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Route Map")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textPrimary)
                
                Spacer()
                
                // REMOVED: Car and location buttons
            }
            
            // Google Maps container
            if let mapData = cachedMapRouteData {
                GoogleMapsView(routeData: mapData)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .shadow(color: themeManager.cardShadow(), radius: 6, x: 0, y: 3)
            } else {
                // Map placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.secondaryBackground)
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(themeManager.textTertiary)
                            
                            Text("Loading map...")
                                .font(.subheadline)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    )
            }
        }
    }
    
    // MARK: - Route Order Section (Themed)
    private var routeOrderSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "list.number")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.primary)
                
                Text("Your Path")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                ForEach(Array(optimizedRoute.optimizedStops.enumerated()), id: \.offset) { index, stop in
                    routeStopRow(stop: stop, index: index + 1)
                    
                    if index < optimizedRoute.optimizedStops.count - 1 {
                        Rectangle()
                            .fill(themeManager.textTertiary.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackground)
                    .shadow(color: themeManager.cardShadow(), radius: 6, x: 0, y: 3)
            )
        }
    }
    
    // MARK: - Route Stop Row (Themed)
    private func routeStopRow(stop: RouteStop, index: Int) -> some View {
        HStack(spacing: 16) {
            // Stop number circle
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [stop.type.color, stop.type.color.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Text("\(index)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Stop details
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name.isEmpty ? extractBusinessName(stop.address) : stop.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(1)
                
                Text(stop.address)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textSecondary)
                    .lineLimit(2)
                
                if let distance = stop.distance, let duration = stop.duration {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "road.lanes")
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.accent)
                            Text(distance)
                                .font(.caption)
                                .foregroundColor(themeManager.accent)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.secondary)
                            Text(duration)
                                .font(.caption)
                                .foregroundColor(themeManager.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Stop type badge
            Text(stop.type.label)
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(stop.type.color.opacity(0.2))
                .foregroundColor(stop.type.color)
                .cornerRadius(8)
        }
        .padding(16)
    }
    
    // MARK: - Action Buttons Section (Themed) - REMOVED Apple Maps
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Single row: Favorite and Google Maps buttons only
            HStack(spacing: 12) {
                // Favorite button
                Button(action: {
                    hapticManager.buttonTap()
                    toggleFavorite()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(isFavorite ? "Saved" : "Save Route")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(isFavorite ? .white : themeManager.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isFavorite ?
                                LinearGradient(gradient: Gradient(colors: [.red, .red.opacity(0.8)]), startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(gradient: Gradient(colors: [themeManager.primary.opacity(0.1), themeManager.accent.opacity(0.1)]), startPoint: .leading, endPoint: .trailing)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isFavorite ? .red : themeManager.primary, lineWidth: 1)
                            )
                    )
                }
                
                // Google Maps button (themed)
                Button(action: {
                    hapticManager.buttonTap()
                    openGoogleMaps()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Google Maps")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(themeManager.buttonGradient())
                    .cornerRadius(12)
                    .shadow(color: themeManager.cardShadow(), radius: 6, x: 0, y: 3)
                }
            }
            
            // REMOVED: Apple Maps button
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
    
    // MARK: - Helper Methods
    
    private func extractBusinessName(_ address: String) -> String {
        if address.contains(",") {
            let firstPart = address.components(separatedBy: ",").first ?? ""
            return firstPart.trimmingCharacters(in: .whitespaces)
        }
        return address
    }
    
    private func calculateRealRoute() {
        print("🚀 Starting real route calculation...")
        
        // Check usage limits first (unless admin)
        if !UserDefaults.standard.bool(forKey: "driveless_admin_mode") {
            if !usageTracker.canPerformRouteCalculation() {
                print("❌ Usage limit exceeded: \(usageTracker.todayUsage)/\(UsageTrackingManager.DAILY_LIMIT)")
                showingUsageLimitAlert = true
                isLoading = false
                return
            }
        }
        
        print("🔐 Admin user - bypassing usage limits")
        print("✅ Usage check passed: \(usageTracker.todayUsage)/25")
        
        // Extract business names from optimized stops
        let startDisplayName = routeData.optimizedStops.first?.name ?? ""
        let endDisplayName = routeData.optimizedStops.last?.name ?? ""
        let stopDisplayNames = Array(routeData.optimizedStops.dropFirst().dropLast()).map { $0.name }
        
        print("🏪 Passing business names to API:")
        print("🏪 Start: '\(startDisplayName)'")
        print("🏪 End: '\(endDisplayName)'")
        print("🏪 Stops: \(stopDisplayNames)")
        
        // Use the real route calculator with business names
        RouteCalculator.calculateOptimizedRoute(
            startLocation: routeData.startLocation,
            endLocation: routeData.endLocation,
            stops: routeData.stops,
            considerTraffic: routeData.considerTraffic,
            startLocationDisplayName: startDisplayName,
            endLocationDisplayName: endDisplayName,
            stopDisplayNames: stopDisplayNames
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let optimizedResult):
                    print("✅ Route calculation successful!")
                    
                    // Increment usage counter (only on success)
                    if !UserDefaults.standard.bool(forKey: "driveless_admin_mode") {
                        self.usageTracker.incrementUsage()
                    } else {
                        print("🔐 Admin user - not incrementing usage")
                    }
                    print("📈 Usage incremented to: \(self.usageTracker.todayUsage)/\(UsageTrackingManager.DAILY_LIMIT)")
                    
                    // Update the UI with real data
                    self.optimizedRoute.totalDistance = optimizedResult.totalDistance
                    self.optimizedRoute.estimatedTime = optimizedResult.estimatedTime
                    self.optimizedRoute.optimizedStops = optimizedResult.optimizedStops
                    
                    // Store route data for map
                    self.routeLegs = optimizedResult.legs
                    self.routePolyline = optimizedResult.routePolyline
                    
                    // Create map data
                    self.createMapData()
                    
                    // Auto-save to history
                    self.saveToHistory()
                    
                    self.isLoading = false
                    
                case .failure(let error):
                    print("❌ Route calculation failed: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
    
    private func createMapData() {
        print("📍 Extracting real coordinates from API response...")
        
        var coordinates: [CLLocationCoordinate2D] = []
        
        // Extract coordinates from route legs
        for (index, leg) in routeLegs.enumerated() {
            coordinates.append(CLLocationCoordinate2D(
                latitude: leg.start_location.lat,
                longitude: leg.start_location.lng
            ))
            print("📍 Leg \(index): Start(\(leg.start_location.lat), \(leg.start_location.lng)) -> End(\(leg.end_location.lat), \(leg.end_location.lng))")
            
            // Add end coordinate for the last leg
            if index == routeLegs.count - 1 {
                coordinates.append(CLLocationCoordinate2D(
                    latitude: leg.end_location.lat,
                    longitude: leg.end_location.lng
                ))
            }
        }
        
        if coordinates.count == optimizedRoute.optimizedStops.count {
            print("📍 Using real coordinates from API response")
            
            // Create map route data with real coordinates
            cachedMapRouteData = MapRouteData(
                waypoints: optimizedRoute.optimizedStops,
                totalDistance: optimizedRoute.totalDistance,
                estimatedTime: optimizedRoute.estimatedTime,
                routeCoordinates: coordinates,
                encodedPolyline: routePolyline
            )
            
            // Log coordinates for debugging
            for (index, coord) in coordinates.enumerated() {
                print("📍 MAP: Added waypoint \(index): '\(optimizedRoute.optimizedStops[index].name)' at \(coord.latitude), \(coord.longitude)")
            }
            
            print("📍 Cached map route data to prevent recreation")
        } else {
            print("⚠️ Coordinate count mismatch: \(coordinates.count) coords vs \(optimizedRoute.optimizedStops.count) stops")
        }
    }
    
    private func saveToHistory() {
        let routeHistoryManager = RouteHistoryManager()
        routeHistoryManager.saveRoute(optimizedRoute)
        print("✅ Route auto-saved to history")
    }
    
    private func checkIfFavorite() {
        let routeHistoryManager = RouteHistoryManager()
        isFavorite = routeHistoryManager.isRouteFavorited(optimizedRoute)
    }
    
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
    
    private func generateSuggestedName() -> String {
        let startName = optimizedRoute.optimizedStops.first?.name ?? "Start"
        let endName = optimizedRoute.optimizedStops.last?.name ?? "End"
        return "\(startName) → \(endName)"
    }
    
    private func openGoogleMaps() {
        guard let url = generateGoogleMapsUrl() else {
            print("❌ Failed to generate Google Maps URL")
            return
        }
        
        print("🗺️ Opening Google Maps: \(url)")
        UIApplication.shared.open(url)
    }
    
    // REMOVED: openAppleMaps() function since Apple Maps button was removed
    
    private func generateGoogleMapsUrl() -> URL? {
        guard !optimizedRoute.optimizedStops.isEmpty else { return nil }
        
        let origin = optimizedRoute.optimizedStops.first!.address
        let destination = optimizedRoute.optimizedStops.last!.address
        
        // Build waypoints string
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
    
    // REMOVED: generateAppleMapsUrl() function since Apple Maps button was removed
}

#Preview {
    RouteResultsView(routeData: RouteData(
        startLocation: "123 Main St, City, State",
        endLocation: "456 Oak Ave, City, State",
        stops: ["789 Pine St, City, State"],
        isRoundTrip: false,
        considerTraffic: true,
        totalDistance: "12.5 miles",
        estimatedTime: "25 min",
        optimizedStops: []
    ))
}
