//
//  LocationManager.swift
//  DriveLess
//
//  Handles location services and GPS functionality
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    // Published properties that SwiftUI views can observe
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Core Location manager instance
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        
        print("🗺️ LocationManager: Initializing...")
        
        // Configure the location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        
        // Set initial authorization status
        authorizationStatus = locationManager.authorizationStatus
        print("🗺️ LocationManager: Initial auth status: \(authorizationStatus)")
    }
    
    // Request location permission from user
    func requestLocationPermission() {
        print("🗺️ LocationManager: Requesting location permission...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Start getting current location (one-time request)
    func getCurrentLocation() {
        print("🗺️ LocationManager: getCurrentLocation() called")
        print("🗺️ LocationManager: Current auth status: \(authorizationStatus)")
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("❌ LocationManager: Location access denied")
            errorMessage = "Location access denied. Please enable in Settings."
            return
        }
        
        print("🗺️ LocationManager: Starting location request...")
        isLoading = true
        errorMessage = nil
        locationManager.requestLocation()
    }
    
    // Start continuous location updates
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    // Stop location updates
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    // Called when authorization status changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🗺️ LocationManager: Authorization changed to: \(status)")
        
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ LocationManager: Permission granted!")
            break
        case .denied, .restricted:
            print("❌ LocationManager: Permission denied/restricted")
            DispatchQueue.main.async {
                self.errorMessage = "Location access is required for route optimization."
            }
        case .notDetermined:
            print("⏳ LocationManager: Permission not determined yet")
            break
        @unknown default:
            print("⚠️ LocationManager: Unknown authorization status")
            break
        }
    }
    
    // Called when location is successfully obtained
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("🎯 LocationManager: Got \(locations.count) location(s)")
        
        guard let newLocation = locations.last else {
            print("❌ LocationManager: No valid location in array")
            return
        }
        
        print("📍 LocationManager: New location: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        print("📍 LocationManager: Accuracy: \(newLocation.horizontalAccuracy)m")
        
        DispatchQueue.main.async {
            self.location = newLocation
            self.isLoading = false
            self.errorMessage = nil
            print("✅ LocationManager: Location updated in UI")
        }
    }
    
    // Called when location request fails
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ LocationManager: Location request failed with error: \(error)")
        print("❌ LocationManager: Error details: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
        }
    }
}
