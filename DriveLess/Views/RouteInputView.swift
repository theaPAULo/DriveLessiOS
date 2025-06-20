//
//  RouteInputView.swift
//  DriveLess
//
//  Clean, modern route input interface optimized for mobile
//

import SwiftUI
import GooglePlaces

struct RouteInputView: View {
    // MARK: - State Properties
    @State private var startLocation: String = ""
    @State private var endLocation: String = ""
    @State private var savedEndLocation: String = ""
    @State private var stops: [String] = [""] // Start with one empty stop
    @State private var isRoundTrip: Bool = false
    @State private var considerTraffic: Bool = true
    
    // MARK: - State Properties for Business Names
    // Store business names separately for display purposes
    @State private var startLocationDisplayName: String = ""
    @State private var endLocationDisplayName: String = ""
    @State private var stopDisplayNames: [String] = [""] // Parallel array to stops for display names
    
    // Reference to location manager
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var routeLoader: RouteLoader

    
    // MARK: - Color Theme (Earthy)
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2) // Dark forest green
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2) // Rich brown
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7) // Soft green
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Header Section
                    headerSection
                    
                    // MARK: - Route Input Card
                    routeInputCard
                    
                    // MARK: - Options Card
                    optionsCard
                    
                    // MARK: - Optimize Button
                    optimizeButton
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarBackButtonHidden(true)
            .onAppear {
                // Check if there's a route to load
                if let routeToLoad = routeLoader.routeToLoad {
                    loadSavedRoute(routeToLoad)
                    routeLoader.clearLoadedRoute()
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                // App logo/title
                Text("DriveLess")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(primaryGreen)
                
                Spacer()
            }
            
            Text("Plan your route")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Actions and Handlers
        
        private func handleStartLocationSelected(_ place: GMSPlace) {
            // Extract both business name and full address
            let businessName = place.name ?? ""
            let fullAddress = place.formattedAddress ?? ""
            
            print("🏠 Selected start - Name: '\(businessName)', Address: '\(fullAddress)'")
            
            // Store the full address for API calls (this is what fixes the NOT_FOUND error)
            if !fullAddress.isEmpty {
                startLocation = fullAddress  // For API calls
                print("✅ Using full address for API: '\(fullAddress)'")
            } else if !businessName.isEmpty {
                startLocation = businessName  // Fallback
                print("⚠️ Using business name as fallback: '\(businessName)'")
            }
            
            // Store the business name for display (this is what shows in the UI)
            if !businessName.isEmpty {
                startLocationDisplayName = businessName  // For display
                print("✅ Using business name for display: '\(businessName)'")
            } else {
                startLocationDisplayName = fullAddress  // Fallback to address
                print("ℹ️ Using address for display (no business name)")
            }
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Auto-update end location if round trip is enabled
            if isRoundTrip {
                endLocation = startLocation
                endLocationDisplayName = startLocationDisplayName
            }
        }
        
        private func handleEndLocationSelected(_ place: GMSPlace) {
            // Extract both business name and full address
            let businessName = place.name ?? ""
            let fullAddress = place.formattedAddress ?? ""
            
            print("🏠 Selected end - Name: '\(businessName)', Address: '\(fullAddress)'")
            
            // Store the full address for API calls
            if !fullAddress.isEmpty {
                endLocation = fullAddress  // For API calls
                print("✅ Using full address for API: '\(fullAddress)'")
            } else if !businessName.isEmpty {
                endLocation = businessName  // Fallback
                print("⚠️ Using business name as fallback: '\(businessName)'")
            }
            
            // Store the business name for display
            if !businessName.isEmpty {
                endLocationDisplayName = businessName  // For display
                print("✅ Using business name for display: '\(businessName)'")
            } else {
                endLocationDisplayName = fullAddress  // Fallback to address
                print("ℹ️ Using address for display (no business name)")
            }
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            if !isRoundTrip {
                savedEndLocation = endLocation
            }
        }
        
        private func handleStopLocationSelected(_ place: GMSPlace, at index: Int) {
            // Extract both business name and full address
            let businessName = place.name ?? ""
            let fullAddress = place.formattedAddress ?? ""
            
            print("🏠 Selected stop \(index) - Name: '\(businessName)', Address: '\(fullAddress)'")
            
            // Ensure stops arrays are the right size
            while stops.count <= index {
                stops.append("")
            }
            while stopDisplayNames.count <= index {
                stopDisplayNames.append("")
            }
            
            // Store the full address for API calls
            if !fullAddress.isEmpty {
                stops[index] = fullAddress  // For API calls
                print("✅ Using full address for API: '\(fullAddress)'")
            } else if !businessName.isEmpty {
                stops[index] = businessName  // Fallback
                print("⚠️ Using business name as fallback: '\(businessName)'")
            }
            
            // Store the business name for display
            if !businessName.isEmpty {
                stopDisplayNames[index] = businessName  // For display
                print("✅ Using business name for display: '\(businessName)'")
            } else {
                stopDisplayNames[index] = fullAddress  // Fallback to address
                print("ℹ️ Using address for display (no business name)")
            }
        }
    
    // MARK: - Route Input Card
    private var routeInputCard: some View {
        VStack(spacing: 20) {
            
            // Start Location - Updated to show business name but store full address
            VStack(alignment: .leading, spacing: 8) {
                InlineAutocompleteTextField(
                    text: $startLocationDisplayName, // Display the business name
                    placeholder: "Start",
                    icon: "location.circle.fill",
                    iconColor: primaryGreen,
                    currentLocation: locationManager.location,
                    onPlaceSelected: { place in
                        handleStartLocationSelected(place)
                    }
                )
                
                // Use current location button
                if locationManager.location != nil {
                    Button(action: useCurrentLocationForStart) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                            Text("Use current location")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(primaryGreen)
                    }
                    .padding(.leading, 4)
                }
            }
            
            
            // Visual connector line
            connectorLine
            
            // Stops Section
            stopsSection
            
            // Another connector line
            connectorLine
            
            // End Location - Updated to show business name but store full address
            VStack(alignment: .leading, spacing: 8) {
                InlineAutocompleteTextField(
                    text: $endLocationDisplayName, // Display the business name
                    placeholder: isRoundTrip ? "Return to start" : "Destination",
                    icon: "flag.checkered",
                    iconColor: accentBrown,
                    currentLocation: locationManager.location,
                    onPlaceSelected: { place in
                        handleEndLocationSelected(place)
                    }
                )
                .disabled(isRoundTrip)
                .opacity(isRoundTrip ? 0.6 : 1.0)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Visual Connector Line
    private var connectorLine: some View {
        HStack {
            Spacer()
                .frame(width: 36) // Align with icon position
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 2, height: 20)
            
            Spacer()
        }
    }
    
    // MARK: - Stops Section
    private var stopsSection: some View {
        VStack(spacing: 16) {
            ForEach(stops.indices, id: \.self) { index in
                HStack(spacing: 12) {
                    InlineAutocompleteTextField(
                        text: $stopDisplayNames[index], // Display the business name
                        placeholder: "Add stop",
                        icon: "mappin.circle.fill",
                        iconColor: Color(.systemBlue),
                        currentLocation: locationManager.location,
                        onPlaceSelected: { place in
                            handleStopLocationSelected(place, at: index)
                        }
                    )
                    
                    // Remove stop button (only show if more than 1 stop)
                    if stops.count > 1 {
                        Button(action: { removeStop(at: index) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            // Add stop button
            Button(action: addStop) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Add stop")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(primaryGreen)
                .padding(.leading, 40) // Align with text field content
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Options Card
    private var optionsCard: some View {
        VStack(spacing: 16) {
            
            // Round Trip Toggle
            toggleRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Round trip",
                subtitle: "Return to starting location",
                isOn: $isRoundTrip,
                color: primaryGreen
            )
            .onChange(of: isRoundTrip) { _, newValue in
                handleRoundTripToggle(newValue)
            }
            
            Divider()
            
            // Traffic Toggle
            toggleRow(
                icon: "car.fill",
                title: "Consider traffic",
                subtitle: "Use real-time traffic data",
                isOn: $considerTraffic,
                color: .orange
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Toggle Row Component
    private func toggleRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        color: Color
    ) -> some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24)
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(color)
        }
    }
    
    // MARK: - Optimize Button
    private var optimizeButton: some View {
        NavigationLink(destination: RouteResultsView(routeData: createRouteData())) {
            HStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Find Best Route")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56) // Larger touch target
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [primaryGreen, primaryGreen.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: primaryGreen.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(!canOptimizeRoute)
        .opacity(canOptimizeRoute ? 1.0 : 0.6)
        .scaleEffect(canOptimizeRoute ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.2), value: canOptimizeRoute)
    }
    
    
    private func useCurrentLocationForStart() {
        guard let location = locationManager.location else { return }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // For now, use coordinates - later we'll reverse geocode
        let locationString = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
        startLocation = locationString
        
        if isRoundTrip {
            endLocation = locationString
        }
    }
    
    private func addStop() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            stops.append("")
            stopDisplayNames.append("") // Keep parallel arrays in sync
        }
    }
    
    private func removeStop(at index: Int) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            stops.remove(at: index)
            // Remove from display names array too, with bounds checking
            if index < stopDisplayNames.count {
                stopDisplayNames.remove(at: index)
            }
        }
    }
    
    private func handleRoundTripToggle(_ newValue: Bool) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if newValue {
            // Save current end location and set to start location
            savedEndLocation = endLocation
            endLocation = startLocation
            endLocationDisplayName = startLocationDisplayName // Also sync the display name
        } else {
            // Restore previous end location
            endLocation = savedEndLocation
            endLocationDisplayName = "" // Clear display name so user can re-enter
        }
    }
    
    // MARK: - Computed Properties
    private var canOptimizeRoute: Bool {
        !startLocation.isEmpty &&
        !endLocation.isEmpty &&
        stops.contains { !$0.isEmpty } // This checks the actual addresses for API calls
    }
    
    private func createRouteData() -> RouteData {
        // Create RouteData with full addresses for API calls
        var routeData = RouteData(
            startLocation: startLocation,
            endLocation: endLocation,
            stops: stops.filter { !$0.isEmpty },
            isRoundTrip: isRoundTrip,
            considerTraffic: considerTraffic
        )
        
        // Pre-populate optimizedStops with business names for better display
        // This preserves the business names the user selected before API processing
        var preOptimizedStops: [RouteStop] = []
        
        // Add start location with business name
        preOptimizedStops.append(RouteStop(
            address: startLocation,
            name: startLocationDisplayName.isEmpty ? "" : startLocationDisplayName, // Use business name
            originalInput: startLocationDisplayName.isEmpty ? startLocation : startLocationDisplayName,
            type: .start,
            distance: nil,
            duration: nil
        ))
        
        // Add stops with business names
        let validStops = stops.enumerated().filter { !$0.element.isEmpty }
        for (index, stop) in validStops {
            let displayName = index < stopDisplayNames.count ? stopDisplayNames[index] : ""
            preOptimizedStops.append(RouteStop(
                address: stop,
                name: displayName.isEmpty ? "" : displayName, // Use business name
                originalInput: displayName.isEmpty ? stop : displayName,
                type: .stop,
                distance: nil,
                duration: nil
            ))
        }
        
        // Add end location with business name
        preOptimizedStops.append(RouteStop(
            address: endLocation,
            name: endLocationDisplayName.isEmpty ? "" : endLocationDisplayName, // Use business name
            originalInput: endLocationDisplayName.isEmpty ? endLocation : endLocationDisplayName,
            type: .end,
            distance: nil,
            duration: nil
        ))
        
        // Store the pre-optimized stops with business names
        routeData.optimizedStops = preOptimizedStops
        
        return routeData
    }
    /// Populates the form with data from a saved route
    /// - Parameter routeData: The route data to load into the form
    private func loadSavedRoute(_ routeData: RouteData) {
        print("📝 Loading saved route into form...")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // ENHANCED: Use display names from optimizedStops if available
        if !routeData.optimizedStops.isEmpty {
            let startStop = routeData.optimizedStops.first!
            let endStop = routeData.optimizedStops.last!
            
            // Load start location with saved display name
            startLocation = startStop.address
            startLocationDisplayName = startStop.name.isEmpty ? extractBusinessName(startStop.address) : startStop.name
            
            // Load end location with saved display name
            endLocation = endStop.address
            endLocationDisplayName = endStop.name.isEmpty ? extractBusinessName(endStop.address) : endStop.name
            
            // Load stops with saved display names
            let stopRoutes = Array(routeData.optimizedStops.dropFirst().dropLast()) // Remove start and end
            stops = stopRoutes.isEmpty ? [""] : stopRoutes.map { $0.address }
            stopDisplayNames = stopRoutes.isEmpty ? [""] : stopRoutes.map { $0.name.isEmpty ? extractBusinessName($0.address) : $0.name }
            
            print("✅ Loaded with saved display names: '\(startLocationDisplayName)' → '\(endLocationDisplayName)'")
        } else {
            // Fallback to original logic
            startLocation = routeData.startLocation
            startLocationDisplayName = extractBusinessName(routeData.startLocation)
            
            endLocation = routeData.endLocation
            endLocationDisplayName = extractBusinessName(routeData.endLocation)
            
            stops = routeData.stops.isEmpty ? [""] : routeData.stops
            stopDisplayNames = routeData.stops.isEmpty ? [""] : routeData.stops.map { extractBusinessName($0) }
            
            print("✅ Loaded with extracted names: '\(startLocationDisplayName)' → '\(endLocationDisplayName)'")
        }
        
        // Ensure we have at least one stop input
        if stops.isEmpty {
            stops = [""]
            stopDisplayNames = [""]
        }
        
        // Load preferences
        considerTraffic = routeData.considerTraffic
        isRoundTrip = routeData.isRoundTrip
    }

    /// Extracts business name from full address for display
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

#Preview {
    RouteInputView(locationManager: LocationManager(),
    routeLoader: RouteLoader()
)
}
