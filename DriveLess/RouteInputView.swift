//
//  RouteInputView.swift
//  DriveLess
//
//  Route input interface for planning multi-stop routes
//

import SwiftUI

struct RouteInputView: View {
    // State for route inputs
    @State private var startLocation: String = ""
    @State private var endLocation: String = ""
    @State private var savedEndLocation: String = "" // Store the original end location
    @State private var stops: [String] = [""] // Start with one empty stop
    @State private var isRoundTrip: Bool = false
    @State private var considerTraffic: Bool = true
    
    // Reference to location manager
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack {
                Text("Plan Your Route")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Add stops and optimize your journey")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 15) {
                    
                    // Start Location Input with Autocomplete
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.green)
                            Text("Starting Location")
                                .font(.headline)
                        }
                        
                        InlineAutocompleteTextField(
                            text: $startLocation,
                            placeholder: "Enter starting address",
                            icon: "location.fill",
                            iconColor: .green,
                            currentLocation: locationManager.location,
                            onPlaceSelected: { place in
                                print("🏠 Selected start: \(place.formattedAddress ?? "")")
                                // Auto-update end location if round trip is enabled
                                if isRoundTrip {
                                    endLocation = startLocation
                                }
                            }
                        )
                        
                        // Use current location button
                        Button(action: useCurrentLocationForStart) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                Text("Use Current Location")
                                    .font(.caption)
                            }
                        }
                        .disabled(locationManager.location == nil)
                    }
                    
                    // Round Trip Toggle
                    Toggle("Round Trip (return to start)", isOn: $isRoundTrip)
                        .onChange(of: isRoundTrip) { _, newValue in
                            if newValue {
                                // Save current end location and set to start location
                                savedEndLocation = endLocation
                                endLocation = startLocation
                            } else {
                                // Restore previous end location
                                endLocation = savedEndLocation
                            }
                        }
                    
                    // Traffic Toggle
                    Toggle("Consider current traffic", isOn: $considerTraffic)
                    
                    // Stops Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.blue)
                            Text("Stops")
                                .font(.headline)
                        }
                        
                        ForEach(stops.indices, id: \.self) { index in
                            HStack {
                                InlineAutocompleteTextField(
                                    text: $stops[index],
                                    placeholder: "Enter stop address",
                                    icon: "mappin",
                                    iconColor: .blue,
                                    currentLocation: locationManager.location,
                                    onPlaceSelected: { place in
                                        print("🏠 Selected stop: \(place.formattedAddress ?? "")")
                                    }
                                )
                                
                                if stops.count > 1 {
                                    Button(action: { removeStop(at: index) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        
                        Button(action: addStop) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                Text("Add Another Stop")
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    // End Location Input (always visible, disabled if round trip)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: "flag.checkered")
                                .foregroundColor(.red)
                            Text("Ending Location")
                                .font(.headline)
                            
                            if isRoundTrip {
                                Text("(same as start)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        InlineAutocompleteTextField(
                            text: $endLocation,
                            placeholder: isRoundTrip ? "Will return to starting location" : "Enter ending address",
                            icon: "flag.checkered",
                            iconColor: .red,
                            currentLocation: locationManager.location,
                            onPlaceSelected: { place in
                                print("🏠 Selected end: \(place.formattedAddress ?? "")")
                                if !isRoundTrip {
                                    savedEndLocation = endLocation
                                }
                            }
                        )
                        .disabled(isRoundTrip)
                        .opacity(isRoundTrip ? 0.6 : 1.0)
                    }
                    
                    // Optimize Route Button - Direct NavigationLink
                    NavigationLink(destination: RouteResultsView(routeData: createRouteData())) {
                        HStack {
                            Image(systemName: "map")
                            Text("Optimize Route")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canOptimizeRoute ? Color.green : Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(!canOptimizeRoute)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
    
    // MARK: - Helper Functions
    
    private func useCurrentLocationForStart() {
        if let location = locationManager.location {
            // For now, just use coordinates - later we'll reverse geocode to address
            let locationString = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
            startLocation = locationString
            if isRoundTrip {
                endLocation = locationString
            }
        }
    }
    
    private func addStop() {
        stops.append("")
    }
    
    private func removeStop(at index: Int) {
        stops.remove(at: index)
    }
    
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
    NavigationView {
        RouteInputView(locationManager: LocationManager())
    }
}
