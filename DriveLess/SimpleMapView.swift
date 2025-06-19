//
//  SimpleMapView.swift
//  DriveLess
//
//  Created by Paul Soni on 6/19/25.
//


//
//  SimpleMapView.swift
//  DriveLess
//
//  Simple Google Maps test to debug SDK issues
//

import SwiftUI
import GoogleMaps

struct SimpleMapView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> GMSMapView {
        // Minimal Google Maps setup
        let mapView = GMSMapView()
        
        // Set Houston as center
        let houston = CLLocationCoordinate2D(latitude: 29.7604, longitude: -95.3698)
        mapView.camera = GMSCameraPosition.camera(withTarget: houston, zoom: 10)
        
        // Add a simple marker to test
        let marker = GMSMarker()
        marker.position = houston
        marker.title = "Houston"
        marker.map = mapView
        
        print("🗺️ Simple map view created")
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Nothing to update for now
    }
}