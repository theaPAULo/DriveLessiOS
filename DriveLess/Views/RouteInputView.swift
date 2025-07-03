//
//  RouteInputView.swift
//  DriveLess
//
//  Clean, modern route input interface with unified earthy theme
//

import SwiftUI
import CoreLocation
import GooglePlaces
import Foundation


struct RouteInputView: View {
    // MARK: - State Properties
    @State private var startLocation: String = ""
    @State private var endLocation: String = ""
    @State private var savedEndLocation: String = ""
    @State private var stops: [String] = [""] // Start with one empty stop
    @State private var isRoundTrip: Bool = false
    @State private var considerTraffic: Bool = true
    
    // MARK: - Usage Tracking
    @StateObject private var usageTracker = UsageTrackingManager()
    @State private var showingUsageLimitAlert = false

    // MARK: - Navigation State
    @State private var shouldNavigateToResults = false
    @State private var routeDataForNavigation: RouteData?
    
    // MARK: - State Properties for Business Names
    // Store business names separately for display purposes
    @State private var startLocationDisplayName: String = ""
    @State private var endLocationDisplayName: String = ""
    @State private var stopDisplayNames: [String] = [""] // Parallel array to stops for display names
    
    // Reference to managers
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var routeLoader: RouteLoader
    @StateObject private var savedAddressManager = SavedAddressManager()
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticManager: HapticManager

    // MARK: - Field Type Enum for Address Selection
    private enum AddressFieldType {
        case start
        case end
        case stop(index: Int)
    }
    
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
            .background(themeManager.background)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                // Load default settings
                loadDefaultSettings()
                
                // Check if there's a route to load
                print("🔍 RouteInputView onAppear - checking for route to load...")
                
                if let routeToLoad = routeLoader.routeToLoad {
                    print("📝 Found route to load: \(routeToLoad.startLocation) → \(routeToLoad.endLocation)")
                    print("🔍 OptimizedStops in routeToLoad: \(routeToLoad.optimizedStops.count)")
                    
                    // Add a small delay to ensure SwiftUI is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        loadSavedRoute(routeToLoad)
                        
                        // Clear the route after a slight delay to ensure loading completed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            routeLoader.clearLoadedRoute()
                            print("🧹 Cleared loaded route from RouteLoader")
                        }
                    }
                } else {
                    print("🔍 No route to load found")
                }
                
                // Refresh saved addresses
                savedAddressManager.loadSavedAddresses()
                print("🔄 Refreshed saved addresses on Search tab appear")
                
                // Refresh usage tracking
                usageTracker.loadTodayUsage()
                print("📊 Refreshed usage tracking on Search tab appear")
            }
            .onChange(of: settingsManager.defaultRoundTrip) { _, newValue in
                // Only apply if this is a settings change, not initial load
                if isRoundTrip != newValue {
                    isRoundTrip = newValue
                    
                    if isRoundTrip && !startLocation.isEmpty {
                        endLocation = startLocation
                        endLocationDisplayName = startLocationDisplayName
                    } else if !isRoundTrip && !savedEndLocation.isEmpty {
                        endLocation = savedEndLocation
                        endLocationDisplayName = extractBusinessName(savedEndLocation)
                    }
                }
            }
            .onChange(of: settingsManager.defaultTrafficEnabled) { _, newValue in
                considerTraffic = newValue
            }
            .navigationDestination(isPresented: $shouldNavigateToResults) {
                if let routeData = routeDataForNavigation {
                    RouteResultsView(routeData: routeData)
                }
            }
        }
    }
    
    // MARK: - Header Section (Themed)
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Plan Your Route")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textPrimary)
                
                Text("Drive Less, Save Time")
                    .font(.subheadline)
                    .foregroundColor(themeManager.textSecondary)
            }
            
            Spacer()
            
            // Usage indicator (themed)
            usageIndicator
        }
    }
    
    // MARK: - Usage Indicator (Themed)
    private var usageIndicator: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(usageTracker.todayUsage)/\(UserDefaults.standard.bool(forKey: "driveless_admin_mode") ? "∞" : "\(UsageTrackingManager.DAILY_LIMIT)")")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(themeManager.textPrimary)
            
            Text(UserDefaults.standard.bool(forKey: "driveless_admin_mode") ? "admin" : "routes today")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeManager.textSecondary)
            
            // Usage progress bar - hide for admins
            if !UserDefaults.standard.bool(forKey: "driveless_admin_mode") {
                ProgressView(value: usageTracker.getUsagePercentage())
                    .progressViewStyle(LinearProgressViewStyle(tint: usageIndicatorColor))
                    .frame(width: 60, height: 3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.secondaryBackground)
                .opacity(0.8)
        )
    }

    // MARK: - Usage Indicator Color Logic (Themed)
    private var usageIndicatorColor: Color {
        let percentage = usageTracker.getUsagePercentage()
        
        if percentage >= 1.0 {
            return .red // At or over limit
        } else if percentage >= 0.8 {
            return .orange // Warning zone (80%+)
        } else {
            return themeManager.primary // Normal usage
        }
    }
    
    // MARK: - Route Input Card (Themed)
    private var routeInputCard: some View {
        VStack(spacing: 20) {
            
            // Start Location with saved address chips
            VStack(alignment: .leading, spacing: 8) {
                // Saved address chips
                if !savedAddressManager.savedAddresses.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(savedAddressManager.savedAddresses.prefix(4), id: \.id) { address in
                                SavedAddressChip(address: address) {
                                    hapticManager.buttonTap()
                                    handleSavedAddressSelected(address, for: .start)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                InlineAutocompleteTextField(
                    text: $startLocationDisplayName,
                    placeholder: "Starting location",
                    icon: "location.circle",
                    iconColor: themeManager.primary,
                    currentLocation: locationManager.location,
                    onPlaceSelected: { place in
                        handleStartLocationSelected(place)
                    }
                )
                
                // Current location button (themed)
                if startLocationDisplayName.isEmpty {
                    Button(action: {
                        hapticManager.buttonTap()
                        useCurrentLocation(for: .start)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Use current location")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(themeManager.primary)
                    }
                    .padding(.leading, 4)
                }
            }
            
            // Visual connector line (themed)
            connectorLine
            
            // Stops Section
            stopsSection
            
            // Another connector line (themed)
            connectorLine
            
            // End Location with saved address chips
            VStack(alignment: .leading, spacing: 8) {
                // Saved address chips for end location
                if !savedAddressManager.savedAddresses.isEmpty && !isRoundTrip {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(savedAddressManager.savedAddresses.prefix(4), id: \.id) { address in
                                SavedAddressChip(address: address) {
                                    hapticManager.buttonTap()
                                    handleSavedAddressSelected(address, for: .end)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                InlineAutocompleteTextField(
                    text: $endLocationDisplayName,
                    placeholder: isRoundTrip ? "Return to start" : "Destination",
                    icon: "flag.checkered",
                    iconColor: themeManager.primary,
                    currentLocation: locationManager.location,
                    onPlaceSelected: { place in
                        handleEndLocationSelected(place)
                    }
                )
                .disabled(isRoundTrip)
                .opacity(isRoundTrip ? 0.6 : 1.0)
                
                // Current location button for end location (themed)
                if endLocationDisplayName.isEmpty && !isRoundTrip {
                    Button(action: {
                        hapticManager.buttonTap()
                        useCurrentLocation(for: .end)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Use current location")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(themeManager.primary)
                    }
                    .padding(.leading, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackground)
                .shadow(color: themeManager.cardShadow(), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Visual Connector Line (Themed)
    private var connectorLine: some View {
        HStack {
            Spacer()
                .frame(width: 28) // Align with icon position
            
            Rectangle()
                .fill(themeManager.textTertiary.opacity(0.3))
                .frame(width: 2, height: 20)
            
            Spacer()
        }
    }
    
    // MARK: - Stops Section (Themed)
    private var stopsSection: some View {
        VStack(spacing: 12) {
            ForEach(stops.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        InlineAutocompleteTextField(
                            text: Binding(
                                get: {
                                    index < stopDisplayNames.count ? stopDisplayNames[index] : ""
                                },
                                set: { newValue in
                                    while stopDisplayNames.count <= index {
                                        stopDisplayNames.append("")
                                    }
                                    stopDisplayNames[index] = newValue
                                }
                            ),
                            placeholder: "Stop \(index + 1)",
                            icon: "mappin.circle",
                            iconColor: themeManager.secondary,
                            currentLocation: locationManager.location,
                            onPlaceSelected: { place in
                                handleStopLocationSelected(place, at: index)
                            }
                        )
                        
                        // Remove stop button (themed)
                        if stops.count > 1 {
                            Button(action: {
                                hapticManager.buttonTap()
                                removeStop(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Current location button for stops (themed)
                    if index < stopDisplayNames.count && stopDisplayNames[index].isEmpty {
                        Button(action: {
                            hapticManager.buttonTap()
                            useCurrentLocation(for: .stop(index: index))
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Use current location")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(themeManager.secondary)
                        }
                        .padding(.leading, 4)
                    }
                }
                
                // Add connector line between stops if not the last stop
                if index < stops.count - 1 {
                    connectorLine
                }
            }
            
            // Add stop button (themed)
            if stops.count < 8 {
                HStack {
                    Button(action: {
                        hapticManager.buttonTap()
                        addStop()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.primary) // Changed from .accent to .primary for better visibility
                            
                            Text("Add Stop")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.primary) // Changed from .accent to .primary for better visibility
                        }
                    }
                    .padding(.leading, 4) // Same padding as "Use current location" buttons
                    
                    Spacer() // This pushes the button to the left
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Options Card (Themed)
    private var optionsCard: some View {
        VStack(spacing: 16) {
            
            // Round Trip Toggle
            toggleRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Round Trip",
                subtitle: "Return to starting location",
                isOn: $isRoundTrip,
                color: themeManager.primary
            )
            
            // Divider
            Rectangle()
                .fill(themeManager.textTertiary.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // Traffic Toggle
            toggleRow(
                icon: "car.fill",
                title: "Consider Traffic",
                subtitle: "Include current traffic conditions",
                isOn: $considerTraffic,
                color: themeManager.secondary
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackground)
                .shadow(color: themeManager.cardShadow(), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Toggle Row Component (Themed)
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
                    .foregroundColor(themeManager.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textSecondary)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(color)
                .onChange(of: isOn.wrappedValue) { _, newValue in
                    hapticManager.toggle()
                    
                    // Handle round trip logic specifically
                    if title == "Round Trip" {
                        handleRoundTripToggle(newValue)
                    }
                }
        }
    }
    
    // MARK: - Optimize Button (Themed)
    private var optimizeButton: some View {
        Button(action: handleOptimizeButtonTap) {
            HStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(optimizeButtonText)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(themeManager.buttonGradient(isPressed: !canOptimizeRoute))
            .cornerRadius(16)
            .shadow(color: themeManager.cardShadow(), radius: 8, x: 0, y: 4)
        }
        .disabled(!canOptimizeRoute)
        .opacity(canOptimizeRoute ? 1.0 : 0.6)
        .scaleEffect(canOptimizeRoute ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.2), value: canOptimizeRoute)
        .alert("Daily Limit Reached", isPresented: $showingUsageLimitAlert) {
            Button("OK") { }
        } message: {
            Text("You've used \(usageTracker.todayUsage) out of \(UsageTrackingManager.DAILY_LIMIT) route calculations today. Your limit will reset at midnight.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var optimizeButtonText: String {
        if !canOptimizeRoute {
            if startLocation.isEmpty || endLocation.isEmpty {
                return "Enter start and destination"
            } else if stops.allSatisfy({ $0.isEmpty }) {
                return "Add at least one stop"
            } else {
                return "Enter locations to optimize"
            }
        } else {
            return "Optimize Route"
        }
    }
    
    private var optimizeButtonColor: Color {
        return canOptimizeRoute ? themeManager.primary : themeManager.textTertiary
    }
    
    private var canOptimizeRoute: Bool {
        let hasStartAndEnd = !startLocation.isEmpty && !endLocation.isEmpty
        let hasAtLeastOneStop = stops.contains { !$0.isEmpty }
        return hasStartAndEnd && hasAtLeastOneStop
    }
    
    // MARK: - Helper Methods
    
    private func loadDefaultSettings() {
        isRoundTrip = settingsManager.defaultRoundTrip
        considerTraffic = settingsManager.defaultTrafficEnabled
    }
    
    private func handleSavedAddressSelected(_ address: SavedAddress, for fieldType: AddressFieldType) {
        let fullAddress = address.fullAddress ?? ""
        let displayName = address.label ?? ""
        
        print("📍 Selected saved address: '\(displayName)' at '\(fullAddress)'")
        
        // Populate the appropriate field
        switch fieldType {
        case .start:
            startLocation = fullAddress
            startLocationDisplayName = displayName
            
            // Auto-update end location if round trip is enabled
            if isRoundTrip {
                endLocation = fullAddress
                endLocationDisplayName = displayName
            }
            
        case .end:
            endLocation = fullAddress
            endLocationDisplayName = displayName
            
            // Save end location if not round trip
            if !isRoundTrip {
                savedEndLocation = fullAddress
            }
            
        case .stop(let index):
            // Ensure arrays are the right size
            while stops.count <= index {
                stops.append("")
            }
            while stopDisplayNames.count <= index {
                stopDisplayNames.append("")
            }
            
            stops[index] = fullAddress
            stopDisplayNames[index] = displayName
        }
    }
    
    private func handleStartLocationSelected(_ place: GMSPlace) {
        let businessName = place.name ?? ""
        let fullAddress = place.formattedAddress ?? ""
        
        // Store both for different purposes
        startLocation = fullAddress // Full address for API calls
        startLocationDisplayName = businessName.isEmpty ? extractBusinessName(fullAddress) : businessName
        
        // Auto-update end location if round trip is enabled
        if isRoundTrip {
            endLocation = fullAddress
            endLocationDisplayName = startLocationDisplayName
        }
        
        print("📍 Start location set: '\(startLocationDisplayName)' (Full: '\(startLocation)')")
    }
    
    private func handleEndLocationSelected(_ place: GMSPlace) {
        let businessName = place.name ?? ""
        let fullAddress = place.formattedAddress ?? ""
        
        // Store both for different purposes
        endLocation = fullAddress // Full address for API calls
        endLocationDisplayName = businessName.isEmpty ? extractBusinessName(fullAddress) : businessName
        
        // Save this as the saved end location for when round trip is disabled
        if !isRoundTrip {
            savedEndLocation = fullAddress
        }
        
        print("📍 End location set: '\(endLocationDisplayName)' (Full: '\(endLocation)')")
    }
    
    private func handleStopLocationSelected(_ place: GMSPlace, at index: Int) {
        let businessName = place.name ?? ""
        let fullAddress = place.formattedAddress ?? ""
        
        // Ensure arrays are the right size
        while stops.count <= index {
            stops.append("")
        }
        while stopDisplayNames.count <= index {
            stopDisplayNames.append("")
        }
        
        // Store both versions
        stops[index] = fullAddress
        stopDisplayNames[index] = businessName.isEmpty ? extractBusinessName(fullAddress) : businessName
        
        print("📍 Stop \(index + 1) set: '\(stopDisplayNames[index])' (Full: '\(stops[index])')")
    }
    
    private func useCurrentLocation(for fieldType: AddressFieldType) {
        // Check location permission status first
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("📍 Location permission not determined, requesting...")
            locationManager.requestLocationPermission()
            hapticManager.error()
            return
            
        case .denied, .restricted:
            print("❌ Location permission denied")
            hapticManager.error()
            // Could show an alert here to guide user to settings
            return
            
        case .authorizedWhenInUse, .authorizedAlways:
            break // Continue with location usage
            
        @unknown default:
            print("❌ Unknown location authorization status")
            hapticManager.error()
            return
        }
        
        // Check if we have a recent location (within last 5 minutes)
        if let location = locationManager.location,
           location.timestamp.timeIntervalSinceNow > -300 {
            print("📍 Using recent location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            populateLocationField(location, for: fieldType)
            return
        }
        
        // No recent location available, request fresh location
        print("📍 Requesting fresh location...")
        setLoadingState(for: fieldType, loading: true)
        
        // Request fresh location
        locationManager.getCurrentLocation()
        
        // Check for location after a reasonable delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let location = self.locationManager.location {
                print("📍 Got fresh location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                self.populateLocationField(location, for: fieldType)
            } else {
                print("❌ Still no location after 2 seconds, trying again...")
                // Try one more time with a longer delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if let location = self.locationManager.location {
                        print("📍 Got delayed location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                        self.populateLocationField(location, for: fieldType)
                    } else {
                        print("❌ Failed to get location after 5 total seconds")
                        self.setLoadingState(for: fieldType, loading: false)
                        self.hapticManager.error()
                    }
                }
            }
        }
    }
    
    private func setLoadingState(for fieldType: AddressFieldType, loading: Bool) {
        let displayText = loading ? "Getting location..." : ""
        
        switch fieldType {
        case .start:
            if loading {
                startLocationDisplayName = displayText
            } else {
                startLocationDisplayName = ""
            }
            
        case .end:
            if loading {
                endLocationDisplayName = displayText
            } else {
                endLocationDisplayName = ""
            }
            
        case .stop(let index):
            // Ensure arrays are the right size
            while stopDisplayNames.count <= index {
                stopDisplayNames.append("")
            }
            stopDisplayNames[index] = displayText
        }
    }
    
    private func populateLocationField(_ location: CLLocation, for fieldType: AddressFieldType) {
        let coordinates = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
        let displayName = "Current Location"
        
        print("✅ Using location: \(coordinates)")
        hapticManager.success()
        
        // Populate the appropriate field
        switch fieldType {
        case .start:
            startLocation = coordinates
            startLocationDisplayName = displayName
            
            // Auto-update end location if round trip is enabled
            if isRoundTrip {
                endLocation = coordinates
                endLocationDisplayName = displayName
            }
            
        case .end:
            endLocation = coordinates
            endLocationDisplayName = displayName
            
            // Save end location if not round trip
            if !isRoundTrip {
                savedEndLocation = coordinates
            }
            
        case .stop(let index):
            // Ensure arrays are the right size
            while stops.count <= index {
                stops.append("")
            }
            while stopDisplayNames.count <= index {
                stopDisplayNames.append("")
            }
            
            stops[index] = coordinates
            stopDisplayNames[index] = displayName
        }
    }
    
    private func addStop() {
        stops.append("")
        stopDisplayNames.append("")
    }
    
    private func removeStop(at index: Int) {
        if index < stops.count {
            stops.remove(at: index)
        }
        if index < stopDisplayNames.count {
            stopDisplayNames.remove(at: index)
        }
    }
    
    private func handleRoundTripToggle(_ enabled: Bool) {
        if enabled {
            // Save current end location before overwriting
            if !endLocation.isEmpty && endLocation != startLocation {
                savedEndLocation = endLocation
            }
            
            // Set end location to start location
            endLocation = startLocation
            endLocationDisplayName = startLocationDisplayName
        } else {
            // Restore saved end location if available
            if !savedEndLocation.isEmpty {
                endLocation = savedEndLocation
                endLocationDisplayName = extractBusinessName(savedEndLocation)
            } else {
                endLocation = ""
                endLocationDisplayName = ""
            }
        }
    }
    
    private func extractBusinessName(_ address: String) -> String {
        if address.contains(",") {
            let firstPart = address.components(separatedBy: ",").first ?? ""
            return firstPart.trimmingCharacters(in: .whitespaces)
        }
        return address
    }
    
    private func loadSavedRoute(_ routeData: RouteData) {
        print("🔄 Loading saved route into input fields...")
        
        // Clear existing data first
        clearAllFields()
        
        // Load basic route information
        startLocation = routeData.startLocation
        endLocation = routeData.endLocation
        considerTraffic = routeData.considerTraffic
        
        // Load display names from optimized stops if available
        if !routeData.optimizedStops.isEmpty {
            let startStop = routeData.optimizedStops.first!
            let endStop = routeData.optimizedStops.last!
            
            startLocationDisplayName = startStop.name
            endLocationDisplayName = endStop.name
            
            // Load intermediate stops (exclude start and end)
            let intermediateStops = Array(routeData.optimizedStops.dropFirst().dropLast())
            
            if !intermediateStops.isEmpty {
                stops = intermediateStops.map { $0.address }
                stopDisplayNames = intermediateStops.map { $0.name }
            }
        } else {
            // Fallback: extract from addresses
            startLocationDisplayName = extractBusinessName(routeData.startLocation)
            endLocationDisplayName = extractBusinessName(routeData.endLocation)
            
            if !routeData.stops.isEmpty {
                stops = routeData.stops
                stopDisplayNames = routeData.stops.map { extractBusinessName($0) }
            }
        }
        
        print("✅ Route loaded successfully:")
        print("   Start: '\(startLocationDisplayName)' (\(startLocation))")
        print("   End: '\(endLocationDisplayName)' (\(endLocation))")
        print("   Stops: \(stops.count)")
    }
    
    private func clearAllFields() {
        startLocation = ""
        endLocation = ""
        savedEndLocation = ""
        startLocationDisplayName = ""
        endLocationDisplayName = ""
        stops = [""]
        stopDisplayNames = [""]
        isRoundTrip = false
        considerTraffic = true
    }
    
    private func handleOptimizeButtonTap() {
        hapticManager.buttonTap()
        
        // Check usage limits first (unless admin)
        if !UserDefaults.standard.bool(forKey: "driveless_admin_mode") {
            if usageTracker.todayUsage >= UsageTrackingManager.DAILY_LIMIT {
                showingUsageLimitAlert = true
                return
            }
        }
        
        guard canOptimizeRoute else {
            print("❌ Cannot optimize route - missing required fields")
            return
        }
        
        print("🗺️ Starting route optimization...")
        print("   Start: \(startLocation) (Display: '\(startLocationDisplayName)')")
        print("   End: \(endLocation) (Display: '\(endLocationDisplayName)')")
        print("   Stops: \(stops.filter { !$0.isEmpty })")
        print("   Stop Display Names: \(stopDisplayNames)")
        print("   Round Trip: \(isRoundTrip)")
        print("   Consider Traffic: \(considerTraffic)")
        
        // Create RouteData with business names properly populated
        var routeData = RouteData(
            startLocation: startLocation,
            endLocation: endLocation,
            stops: stops.filter { !$0.isEmpty },
            isRoundTrip: isRoundTrip,
            considerTraffic: considerTraffic,
            totalDistance: "",
            estimatedTime: "",
            optimizedStops: []
        )
        
        // Create optimized stops with business names for proper display
        var preOptimizedStops: [RouteStop] = []
        
        // Add start location with business name
        preOptimizedStops.append(RouteStop(
            address: startLocation,
            name: startLocationDisplayName.isEmpty ? extractBusinessName(startLocation) : startLocationDisplayName,
            originalInput: startLocationDisplayName,
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
                name: displayName.isEmpty ? extractBusinessName(stop) : displayName,
                originalInput: displayName,
                type: .stop,
                distance: nil,
                duration: nil
            ))
        }
        
        // Add end location with business name
        preOptimizedStops.append(RouteStop(
            address: endLocation,
            name: endLocationDisplayName.isEmpty ? extractBusinessName(endLocation) : endLocationDisplayName,
            originalInput: endLocationDisplayName,
            type: .end,
            distance: nil,
            duration: nil
        ))
        
        // Set the optimized stops with business names
        routeData.optimizedStops = preOptimizedStops
        
        print("✅ Created RouteData with business names:")
        for (index, stop) in preOptimizedStops.enumerated() {
            print("   Stop \(index): '\(stop.name)' at '\(stop.address)'")
        }
        
        // Increment usage tracking (unless admin)
        if !UserDefaults.standard.bool(forKey: "driveless_admin_mode") {
            usageTracker.incrementUsage()
            print("📊 Usage incremented to \(usageTracker.todayUsage)")
        }
        
        // Navigate to results
        routeDataForNavigation = routeData
        shouldNavigateToResults = true
        
        print("✅ Navigating to RouteResultsView...")
    }
}

// MARK: - Saved Address Chip Component
struct SavedAddressChip: View {
    let address: SavedAddress
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: iconForAddressType)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.2))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color(red: 0.2, green: 0.4, blue: 0.2).opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(Color(red: 0.2, green: 0.4, blue: 0.2).opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper to get icon based on address type
    private var iconForAddressType: String {
        guard let addressType = address.addressType else { return "mappin.circle.fill" }
        
        switch addressType {
        case "home": return "house.fill"
        case "work": return "building.2.fill"
        default: return "mappin.circle.fill"
        }
    }
}

#Preview {
    RouteInputView(
        locationManager: LocationManager(),
        routeLoader: RouteLoader()
    )
    .environmentObject(SettingsManager())
    .environmentObject(HapticManager())
}
