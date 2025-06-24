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
    
    // Reference to location manager
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var routeLoader: RouteLoader
    @StateObject private var savedAddressManager = SavedAddressManager()
    @EnvironmentObject var settingsManager: SettingsManager  // ADD THIS LINE


    // MARK: - Field Type Enum for Address Selection
    private enum AddressFieldType {
        case start
        case end
        case stop(index: Int)
    }
    
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
                loadDefaultSettings()
                
                // ENHANCED: Check if there's a route to load with better timing
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
                
                // REFRESH SAVED ADDRESSES - NEW ADDITION
                // This ensures we see newly saved addresses when returning to Search tab
                savedAddressManager.loadSavedAddresses()
                print("🔄 Refreshed saved addresses on Search tab appear")
                
                // REFRESH USAGE TRACKING - NEW ADDITION
                // This ensures we see updated usage when returning from RouteResultsView
                usageTracker.loadTodayUsage()
                print("📊 Refreshed usage tracking on Search tab appear")
            }
            .onChange(of: settingsManager.defaultRoundTrip) { _, newValue in
                // Only apply if this is a fresh route (not loaded from history)
                if startLocation.isEmpty && endLocation.isEmpty && stops.allSatisfy({ $0.isEmpty }) {
                    isRoundTrip = newValue
                    print("🔧 Applied default round trip setting: \(newValue)")
                }
            }
            .onChange(of: settingsManager.defaultTrafficEnabled) { _, newValue in
                // Only apply if this is a fresh route (not loaded from history)
                if startLocation.isEmpty && endLocation.isEmpty && stops.allSatisfy({ $0.isEmpty }) {
                    considerTraffic = newValue
                    print("🔧 Applied default traffic setting: \(newValue)")
                }
            }
            .navigationDestination(isPresented: $shouldNavigateToResults) {
                if let routeData = routeDataForNavigation {
                    RouteResultsView(routeData: routeData)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                // App logo/title
                Text("DriveLess")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(primaryGreen)
                
                Spacer()
                
                // MARK: - Usage Indicator
                usageIndicatorView
            }
            
            Text("Drive less, save time")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Usage Indicator Component
    private var usageIndicatorView: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                // Usage icon
                Image(systemName: usageTracker.canPerformRouteCalculation() ? "chart.bar.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(usageIndicatorColor)
                
                // Usage text - show ∞ for admins
                if usageTracker.todayUsage == 0 && UserDefaults.standard.bool(forKey: "driveless_admin_mode") {
                    Text("∞/∞")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(primaryGreen)
                } else {
                    Text("\(usageTracker.todayUsage)/\(UsageTrackingManager.DAILY_LIMIT)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(usageIndicatorColor)
                }
            }
            
            Text(UserDefaults.standard.bool(forKey: "driveless_admin_mode") ? "admin" : "routes today")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            
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
                .fill(Color(.systemGray6))
                .opacity(0.8)
        )
    }

    // MARK: - Usage Indicator Color Logic
    private var usageIndicatorColor: Color {
        let percentage = usageTracker.getUsagePercentage()
        
        if percentage >= 1.0 {
            return .red // At or over limit
        } else if percentage >= 0.8 {
            return .orange // Warning zone (80%+)
        } else {
            return primaryGreen // Normal usage
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
    
    /// Handles when a saved address chip is tapped
    /// - Parameters:
    ///   - address: The saved address that was selected
    ///   - fieldType: Which field to populate (start, end, or specific stop)
    private func handleSavedAddressSelected(_ address: SavedAddress, for fieldType: AddressFieldType) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Get the address data
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
    
    // MARK: - Route Input Card
    private var routeInputCard: some View {
        VStack(spacing: 20) {
            
            // Start Location - Updated to show business name but store full address
            VStack(alignment: .leading, spacing: 8) {
                // SAVED ADDRESS CHIPS - NEW ADDITION
                if !savedAddressManager.savedAddresses.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(savedAddressManager.savedAddresses.prefix(4), id: \.id) { address in
                                SavedAddressChip(address: address) {
                                    // Handle chip tap - populate start location
                                    handleSavedAddressSelected(address, for: .start)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
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
                if true { // locationManager.location != nil {
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
                // SAVED ADDRESS CHIPS FOR END LOCATION - NEW ADDITION
                if !savedAddressManager.savedAddresses.isEmpty && !isRoundTrip {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(savedAddressManager.savedAddresses.prefix(4), id: \.id) { address in
                                SavedAddressChip(address: address) {
                                    // Handle chip tap - populate end location
                                    handleSavedAddressSelected(address, for: .end)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                InlineAutocompleteTextField(
                    text: $endLocationDisplayName, // Display the business name
                    placeholder: isRoundTrip ? "Return to start" : "Destination",
                    icon: "flag.checkered",
                    iconColor: primaryGreen,
                    currentLocation: locationManager.location,
                    onPlaceSelected: { place in
                        handleEndLocationSelected(place)
                    }
                )
                .disabled(isRoundTrip)
                .opacity(isRoundTrip ? 0.6 : 1.0)
                
                // ADD THIS BLOCK RIGHT AFTER THE ABOVE:
                // Use current location button for end location
                if !isRoundTrip {
                    Button(action: useCurrentLocationForEnd) {
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
                VStack(alignment: .leading, spacing: 8) {
                    // SAVED ADDRESS CHIPS FOR STOPS - NEW ADDITION
                        if !savedAddressManager.savedAddresses.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(savedAddressManager.savedAddresses.prefix(4), id: \.id) { address in
                                    SavedAddressChip(address: address) {
                                        // Handle chip tap - populate this specific stop
                                        handleSavedAddressSelected(address, for: .stop(index: index))
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 12) {
                            InlineAutocompleteTextField(
                                text: $stopDisplayNames[index], // Display the business name
                                placeholder: "Add stop",
                                icon: "mappin.circle.fill",
                                iconColor: accentBrown,  // Changed from Color(.systemBlue) to match earthy theme
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
                        
                        // Use current location button for this stop
                        Button(action: { useCurrentLocationForStop(at: index) }) {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 14))
                                Text("Use current location")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(accentBrown)
                        }
                        .padding(.leading, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
        Button(action: handleOptimizeButtonTap) {
            HStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(optimizeButtonText)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56) // Larger touch target
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [optimizeButtonColor, optimizeButtonColor.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: optimizeButtonColor.opacity(0.3), radius: 8, x: 0, y: 4)
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

    // MARK: - Optimize Button Helper Methods
    private func handleOptimizeButtonTap() {
        // Check usage limits before navigating
        if !usageTracker.canPerformRouteCalculation() {
            showingUsageLimitAlert = true
            return
        }
        
        // Prepare route data and trigger navigation
        routeDataForNavigation = createRouteData()
        shouldNavigateToResults = true
    }

    private var optimizeButtonText: String {
        if !usageTracker.canPerformRouteCalculation() {
            return "Daily Limit Reached"
        }
        return "Find Best Route"
    }

    private var optimizeButtonColor: Color {
        if !usageTracker.canPerformRouteCalculation() {
            return .gray
        }
        return primaryGreen
    }
    
    
    private func useCurrentLocationForStart() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Check location authorization status
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("📍 Requesting location permission...")
            locationManager.requestLocationPermission()
            // Show user feedback
            startLocationDisplayName = "Requesting location access..."
            
            // Try again after a short delay to see if permission was granted
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                    useCurrentLocationForStart() // Retry
                } else {
                    startLocationDisplayName = ""
                    // Show alert about location access
                    showLocationPermissionAlert()
                }
            }
            
        case .denied, .restricted:
            print("❌ Location access denied")
            showLocationPermissionAlert()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Check if we have a current location
            guard let location = locationManager.location else {
                print("📍 Getting current location...")
                startLocationDisplayName = "Getting location..."
                locationManager.getCurrentLocation()
                
                // Wait a moment for location to be acquired
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.5) {
                    if let location = locationManager.location {
                        reverseGeocodeLocation(location)
                    } else {
                        startLocationDisplayName = ""
                        showLocationTimeoutAlert()
                    }
                }
                return
            }
            
            // We have location, reverse geocode it
            reverseGeocodeLocation(location)
            
        @unknown default:
            print("⚠️ Unknown location authorization status")
            showLocationPermissionAlert()
        }
    }
    
    private func useCurrentLocationForEnd() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Check location authorization status
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("📍 Requesting location permission for end location...")
            locationManager.requestLocationPermission()
            // Show user feedback
            endLocationDisplayName = "Requesting location access..."
            
            // Try again after a short delay to see if permission was granted
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                    useCurrentLocationForEnd() // Retry
                } else {
                    endLocationDisplayName = ""
                    showLocationPermissionAlert()
                }
            }
            
        case .denied, .restricted:
            print("❌ Location access denied for end location")
            showLocationPermissionAlert()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Check if we have a current location
            guard let location = locationManager.location else {
                print("📍 Getting current location for end...")
                endLocationDisplayName = "Getting location..."
                locationManager.getCurrentLocation()
                
                // Wait a moment for location to be acquired
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.5) {
                    if let location = locationManager.location {
                        reverseGeocodeLocationForEnd(location)
                    } else {
                        endLocationDisplayName = ""
                        showLocationTimeoutAlert()
                    }
                }
                return
            }
            
            // We have location, reverse geocode it
            reverseGeocodeLocationForEnd(location)
            
        @unknown default:
            print("⚠️ Unknown location authorization status for end location")
            showLocationPermissionAlert()
        }
    }

    // Helper function for reverse geocoding end location
    private func reverseGeocodeLocationForEnd(_ location: CLLocation) {
        print("📍 Reverse geocoding end location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Reverse geocoding failed for end location: \(error.localizedDescription)")
                    // Fallback to coordinates if reverse geocoding fails
                    let coordinateString = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
                    endLocation = coordinateString
                    endLocationDisplayName = "Current Location"
                    return
                }
                
                if let placemark = placemarks?.first {
                    // Build readable address from placemark
                    var addressComponents: [String] = []
                    
                    if let streetNumber = placemark.subThoroughfare {
                        addressComponents.append(streetNumber)
                    }
                    if let streetName = placemark.thoroughfare {
                        addressComponents.append(streetName)
                    }
                    if let city = placemark.locality {
                        addressComponents.append(city)
                    }
                    if let state = placemark.administrativeArea {
                        addressComponents.append(state)
                    }
                    if let zipCode = placemark.postalCode {
                        addressComponents.append(zipCode)
                    }
                    
                    let fullAddress = addressComponents.joined(separator: ", ")
                    print("✅ Reverse geocoded end location to: \(fullAddress)")
                    
                    // Store both full address and display name for end location
                    endLocation = fullAddress
                    endLocationDisplayName = "Current Location"
                    
                    // Save end location if not round trip
                    if !isRoundTrip {
                        savedEndLocation = fullAddress
                    }
                }
            }
        }
    }

    private func useCurrentLocationForStop(at index: Int) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Ensure arrays are the right size
        while stops.count <= index {
            stops.append("")
        }
        while stopDisplayNames.count <= index {
            stopDisplayNames.append("")
        }
        
        // Check location authorization status
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("📍 Requesting location permission for stop \(index)...")
            locationManager.requestLocationPermission()
            // Show user feedback
            stopDisplayNames[index] = "Requesting location access..."
            
            // Try again after a short delay to see if permission was granted
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                    useCurrentLocationForStop(at: index) // Retry
                } else {
                    stopDisplayNames[index] = ""
                    showLocationPermissionAlert()
                }
            }
            
        case .denied, .restricted:
            print("❌ Location access denied for stop \(index)")
            showLocationPermissionAlert()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Check if we have a current location
            guard let location = locationManager.location else {
                print("📍 Getting current location for stop \(index)...")
                stopDisplayNames[index] = "Getting location..."
                locationManager.getCurrentLocation()
                
                // Wait longer for initial GPS fix
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if let location = locationManager.location {
                        reverseGeocodeLocationForStop(location, at: index)
                    } else {
                        stopDisplayNames[index] = ""
                        showLocationTimeoutAlert()
                    }
                }
                return
            }
            
            // We have location, reverse geocode it
            reverseGeocodeLocationForStop(location, at: index)
            
        @unknown default:
            print("⚠️ Unknown location authorization status for stop \(index)")
            showLocationPermissionAlert()
        }
    }

    // Helper function for reverse geocoding stop location
    private func reverseGeocodeLocationForStop(_ location: CLLocation, at index: Int) {
        print("📍 Reverse geocoding stop \(index) location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                // Ensure arrays are still the right size
                while stops.count <= index {
                    stops.append("")
                }
                while stopDisplayNames.count <= index {
                    stopDisplayNames.append("")
                }
                
                if let error = error {
                    print("❌ Reverse geocoding failed for stop \(index): \(error.localizedDescription)")
                    // Fallback to coordinates if reverse geocoding fails
                    let coordinateString = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
                    stops[index] = coordinateString
                    stopDisplayNames[index] = "Current Location"
                    return
                }
                
                if let placemark = placemarks?.first {
                    // Build readable address from placemark
                    var addressComponents: [String] = []
                    
                    if let streetNumber = placemark.subThoroughfare {
                        addressComponents.append(streetNumber)
                    }
                    if let streetName = placemark.thoroughfare {
                        addressComponents.append(streetName)
                    }
                    if let city = placemark.locality {
                        addressComponents.append(city)
                    }
                    if let state = placemark.administrativeArea {
                        addressComponents.append(state)
                    }
                    if let zipCode = placemark.postalCode {
                        addressComponents.append(zipCode)
                    }
                    
                    let fullAddress = addressComponents.joined(separator: ", ")
                    print("✅ Reverse geocoded stop \(index) to: \(fullAddress)")
                    
                    // Store both full address and display name for this stop
                    stops[index] = fullAddress
                    stopDisplayNames[index] = "Current Location"
                }
            }
        }
    }
    // Helper function for reverse geocoding
    private func reverseGeocodeLocation(_ location: CLLocation) {
        print("📍 Reverse geocoding location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Reverse geocoding failed: \(error.localizedDescription)")
                    // Fallback to coordinates if reverse geocoding fails
                    let coordinateString = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
                    startLocation = coordinateString
                    startLocationDisplayName = "Current Location"
                    return
                }
                
                if let placemark = placemarks?.first {
                    // Build readable address from placemark
                    var addressComponents: [String] = []
                    
                    if let streetNumber = placemark.subThoroughfare {
                        addressComponents.append(streetNumber)
                    }
                    if let streetName = placemark.thoroughfare {
                        addressComponents.append(streetName)
                    }
                    if let city = placemark.locality {
                        addressComponents.append(city)
                    }
                    if let state = placemark.administrativeArea {
                        addressComponents.append(state)
                    }
                    if let zipCode = placemark.postalCode {
                        addressComponents.append(zipCode)
                    }
                    
                    let fullAddress = addressComponents.joined(separator: ", ")
                    print("✅ Reverse geocoded to: \(fullAddress)")
                    
                    // Store both full address and display name
                    startLocation = fullAddress
                    startLocationDisplayName = "Current Location"
                    
                    // Auto-update end location if round trip is enabled
                    if isRoundTrip {
                        endLocation = fullAddress
                        endLocationDisplayName = "Current Location"
                    }
                }
            }
        }
    }

    // Helper function to show location permission alert
    private func showLocationPermissionAlert() {
        // For now, just update the field with a message
        // Later we can add a proper alert
        print("❌ Location permission needed")
        startLocationDisplayName = ""
    }

    // Helper function to show location timeout alert
    private func showLocationTimeoutAlert() {
        print("⏰ Location request timed out")
        startLocationDisplayName = ""
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

        // ADD THIS DEBUG LOGGING:
        print("🔍 DEBUG: RouteInputView creating RouteData:")
        print("🔍   Start: '\(startLocation)' (display: '\(startLocationDisplayName)')")
        print("🔍   End: '\(endLocation)' (display: '\(endLocationDisplayName)')")
        for (index, stop) in stops.enumerated() {
            let displayName = index < stopDisplayNames.count ? stopDisplayNames[index] : ""
            print("🔍   Stop \(index): '\(stop)' (display: '\(displayName)')")
        }
        print("🔍 PreOptimizedStops:")
        for (index, stop) in preOptimizedStops.enumerated() {
            print("🔍   Stop \(index): name='\(stop.name)', address='\(stop.address)', originalInput='\(stop.originalInput)'")
        }

        return routeData
    }
    /// Populates the form with data from a saved route
    /// - Parameter routeData: The route data to load into the form

    // MARK: - Enhanced Route Loading Fix
    // Replace the existing loadSavedRoute function in RouteInputView.swift

    /// Populates the form with data from a saved route
    /// - Parameter routeData: The route data to load into the form
    private func loadSavedRoute(_ routeData: RouteData) {
        print("📝 Loading saved route into form...")
        print("🔍 DEBUG: RouteData received:")
        print("🔍   Start: '\(routeData.startLocation)'")
        print("🔍   End: '\(routeData.endLocation)'")
        print("🔍   Stops: \(routeData.stops)")
        print("🔍   OptimizedStops count: \(routeData.optimizedStops.count)")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // ENHANCED: Use display names from optimizedStops if available
        if !routeData.optimizedStops.isEmpty {
            let startStop = routeData.optimizedStops.first!
            let endStop = routeData.optimizedStops.last!
            
            print("🔍 DEBUG: Loading from optimizedStops:")
            print("🔍   Start Stop: address='\(startStop.address)', name='\(startStop.name)', type=\(startStop.type)")
            print("🔍   End Stop: address='\(endStop.address)', name='\(endStop.name)', type=\(endStop.type)")
            
            // Load start location with saved display name
            startLocation = startStop.address
            startLocationDisplayName = startStop.name.isEmpty ?
                extractBusinessName(startStop.address) : startStop.name
            
            // Load end location with saved display name - ENHANCED ERROR CHECKING
            endLocation = endStop.address
            endLocationDisplayName = endStop.name.isEmpty ?
                extractBusinessName(endStop.address) : endStop.name
            
            // DEFENSIVE: Double-check that endLocation was set correctly
            if endLocation.isEmpty {
                print("⚠️ WARNING: endLocation is empty after loading from optimizedStops!")
                print("🔧 FALLBACK: Using routeData.endLocation instead")
                endLocation = routeData.endLocation
                endLocationDisplayName = extractBusinessName(routeData.endLocation)
            }
            
            // Load intermediate stops (excluding start and end)
            let intermediateStops = Array(routeData.optimizedStops.dropFirst().dropLast())
            stops = intermediateStops.isEmpty ? [""] : intermediateStops.map { $0.address }
            stopDisplayNames = intermediateStops.isEmpty ? [""] : intermediateStops.map { $0.name.isEmpty ? extractBusinessName($0.address) : $0.name }
            
            print("✅ Loaded from optimizedStops: '\(startLocationDisplayName)' → '\(endLocationDisplayName)'")
            print("🔍 FINAL CHECK: endLocation = '\(endLocation)'")
            
        } else {
            print("⚠️ WARNING: optimizedStops is empty, using fallback method")
            
            // Fallback if no optimized stops saved
            startLocation = routeData.startLocation
            endLocation = routeData.endLocation
            startLocationDisplayName = extractBusinessName(routeData.startLocation)
            endLocationDisplayName = extractBusinessName(routeData.endLocation)
            
            // DEFENSIVE: Ensure endLocation is not empty
            if endLocation.isEmpty {
                print("❌ ERROR: endLocation is empty in fallback mode!")
                print("🔍 RouteData.endLocation = '\(routeData.endLocation)'")
            }
            
            // Load stops
            stops = routeData.stops.isEmpty ? [""] : routeData.stops
            stopDisplayNames = routeData.stops.isEmpty ? [""] : routeData.stops.map { extractBusinessName($0) }
            
            print("✅ Loaded with extracted names: '\(startLocationDisplayName)' → '\(endLocationDisplayName)'")
            print("🔍 FINAL CHECK: endLocation = '\(endLocation)'")
        }
        
        // Ensure we have at least one stop input
        if stops.isEmpty {
            stops = [""]
            stopDisplayNames = [""]
        }
        
        // Load preferences
        considerTraffic = routeData.considerTraffic
        isRoundTrip = routeData.isRoundTrip
        
        // DEFENSIVE: Final verification that all required fields are populated
        print("🔍 FINAL VERIFICATION:")
        print("🔍   startLocation: '\(startLocation)' (display: '\(startLocationDisplayName)')")
        print("🔍   endLocation: '\(endLocation)' (display: '\(endLocationDisplayName)')")
        print("🔍   stops: \(stops)")
        print("🔍   stopDisplayNames: \(stopDisplayNames)")
        
        // Force UI update to ensure fields are populated
        DispatchQueue.main.async {
            // SwiftUI will automatically update when @State variables change
            print("🔄 UI will refresh automatically with @State changes")
        }
    }
    
    /// Load user's default settings when view appears
    private func loadDefaultSettings() {
        // Only load defaults if this is a fresh view (not loading from history)
        guard startLocation.isEmpty && endLocation.isEmpty && stops.allSatisfy({ $0.isEmpty }) else {
            print("🔧 Skipping default settings - route already loaded")
            return
        }
        
        // Load user's preferences from Settings
        isRoundTrip = settingsManager.defaultRoundTrip
        considerTraffic = settingsManager.defaultTrafficEnabled
        
        print("🔧 Loaded default settings - Round Trip: \(isRoundTrip), Traffic: \(considerTraffic), Units: \(settingsManager.distanceUnit.displayName)")
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
// MARK: - Saved Address Chip Component
struct SavedAddressChip: View {
    let address: SavedAddress
    let onTap: () -> Void
    
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    
    var body: some View {
        Button(action: onTap) {
            // Just the icon - no text for cleaner look
            Image(systemName: iconForAddressType)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(primaryGreen)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(primaryGreen.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(primaryGreen.opacity(0.3), lineWidth: 1)
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
    RouteInputView(locationManager: LocationManager(),
    routeLoader: RouteLoader()
)
}
