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
            .navigationBarHidden(true)
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
        }
    }
    
    private func removeStop(at index: Int) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        let _ = withAnimation(.easeInOut(duration: 0.3)) {
            stops.remove(at: index)
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
        } else {
            // Restore previous end location
            endLocation = savedEndLocation
        }
    }
    
    // MARK: - Computed Properties
    private var canOptimizeRoute: Bool {
        !startLocation.isEmpty &&
        !endLocation.isEmpty &&
        stops.contains { !$0.isEmpty }
    }
    
    private func createRouteData() -> RouteData {
        return RouteData(
            startLocation: startLocation,
            endLocation: endLocation,
            stops: stops.filter { !$0.isEmpty },
            isRoundTrip: isRoundTrip,
            considerTraffic: considerTraffic
        )
    }
}

#Preview {
    RouteInputView(locationManager: LocationManager())
}
