//
//  ContentView.swift
//  DriveLess
//
//  Created by Paul Soni on 6/19/25.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    // Create an instance of our LocationManager
    @StateObject private var locationManager = LocationManager()
    
    // State for navigation
    @State private var showRouteInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Header
                VStack {
                    Text("DriveLess")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Drive Less, Save Time")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top)
                
                Spacer()
                
                // Location Section
                VStack(spacing: 15) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Get Your Location")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Show current location if available
                    if let location = locationManager.location {
                        VStack(spacing: 5) {
                            Text("Current Location:")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Text("Lat: \(location.coordinate.latitude, specifier: "%.4f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Lng: \(location.coordinate.longitude, specifier: "%.4f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Show error message if any
                    if let errorMessage = locationManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    // Location button with debug logging
                    Button(action: {
                        print("Button tapped! Authorization status: \(locationManager.authorizationStatus)")
                        
                        if locationManager.authorizationStatus == .notDetermined {
                            print("Requesting location permission...")
                            locationManager.requestLocationPermission()
                        } else {
                            print("Getting current location...")
                            locationManager.getCurrentLocation()
                        }
                    }) {
                        HStack {
                            if locationManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Getting Location...")
                            } else {
                                Image(systemName: "location.fill")
                                Text(locationButtonText)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(locationManager.isLoading)
                }
                .padding()
                
                // Navigate to Route Planning Button
                if locationManager.location != nil {
                    NavigationLink(destination: RouteInputView(locationManager: locationManager)) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Start Route Planning")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Future sections placeholder (only show if no location yet)
                if locationManager.location == nil {
                    Text("Route optimization coming soon...")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // Computed property for button text based on authorization status
    private var locationButtonText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Enable Location Access"
        case .denied, .restricted:
            return "Location Access Denied"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Get My Location"
        @unknown default:
            return "Get Location"
        }
    }
}

#Preview {
    ContentView()
}
