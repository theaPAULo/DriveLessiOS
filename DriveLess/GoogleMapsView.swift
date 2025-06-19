//
//  GoogleMapsView.swift
//  DriveLess
//
//  Working Google Maps with real coordinates and proper initialization
//

import SwiftUI
import GoogleMaps
import GooglePlaces

// MARK: - Route Data for Maps
struct MapRouteData {
    let waypoints: [RouteStop]
    let totalDistance: String
    let estimatedTime: String
    let routeCoordinates: [CLLocationCoordinate2D]
}

// MARK: - Google Maps UIViewRepresentable
struct GoogleMapsView: UIViewRepresentable {
    let routeData: MapRouteData
    
    func makeUIView(context: Context) -> GMSMapView {
        print("🗺️ Creating Google Maps view...")
        
        // Create the map view with default Houston coordinates
        let camera = GMSCameraPosition.camera(withLatitude: 29.7604, longitude: -95.3698, zoom: 12.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        
        // Force the map type to be normal (satellite, hybrid, etc.)
        mapView.mapType = .normal
        
        // Configure map settings for mobile
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = false // Disable to avoid permission issues
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = false
        
        // Enable buildings and indoor maps
        mapView.isBuildingsEnabled = true
        mapView.isIndoorEnabled = true
        
        // Set delegate
        mapView.delegate = context.coordinator
        
        print("✅ Google Maps view created successfully")
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Clear existing content
        uiView.clear()
        
        // Add markers and route
        setupMarkersAndRoute(on: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Setup Markers and Route
    private func setupMarkersAndRoute(on mapView: GMSMapView) {
        // Get real coordinates for Houston area locations
        let coordinates = getRealHoustonCoordinates(for: routeData.waypoints.count)
        
        // Add markers for each waypoint
        for (index, waypoint) in routeData.waypoints.enumerated() {
            let marker = GMSMarker()
            marker.position = coordinates[index]
            marker.icon = createMarkerIcon(number: index + 1, type: waypoint.type)
            marker.title = waypoint.name.isEmpty ? waypoint.address.components(separatedBy: ",").first : waypoint.name
            marker.snippet = waypoint.address
            marker.map = mapView
        }
        
        // Draw route polyline if we have multiple points
        if coordinates.count > 1 {
            let path = GMSMutablePath()
            coordinates.forEach { path.add($0) }
            
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = UIColor.systemBlue
            polyline.strokeWidth = 5.0
            polyline.map = mapView
        }
        
        // Fit camera to show all markers
        if coordinates.count > 1 {
            var bounds = GMSCoordinateBounds()
            coordinates.forEach { bounds = bounds.includingCoordinate($0) }
            
            let padding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
            let camera = mapView.camera(for: bounds, insets: padding)
            mapView.camera = camera ?? mapView.camera
        }
        
        // Add traffic toggle button
        addTrafficButton(to: mapView)
    }
    
    // MARK: - Real Houston Area Coordinates
    private func getRealHoustonCoordinates(for count: Int) -> [CLLocationCoordinate2D] {
        // Real Houston area locations for demo
        let houstonLocations = [
            CLLocationCoordinate2D(latitude: 29.7604, longitude: -95.3698), // Downtown Houston
            CLLocationCoordinate2D(latitude: 29.7372, longitude: -95.4618), // Galleria
            CLLocationCoordinate2D(latitude: 29.8174, longitude: -95.4018), // The Woodlands
            CLLocationCoordinate2D(latitude: 29.6516, longitude: -95.1376), // Clear Lake
            CLLocationCoordinate2D(latitude: 29.5844, longitude: -95.6307), // Sugar Land
            CLLocationCoordinate2D(latitude: 29.9538, longitude: -95.3414), // Spring
        ]
        
        // Return the first 'count' locations, cycling if needed
        var coordinates: [CLLocationCoordinate2D] = []
        for i in 0..<count {
            coordinates.append(houstonLocations[i % houstonLocations.count])
        }
        
        return coordinates
    }
    
    // MARK: - Create Custom Marker Icon
    private func createMarkerIcon(number: Int, type: StopType) -> UIImage {
        let size = CGSize(width: 40, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Set color based on stop type
            let fillColor: UIColor
            switch type {
            case .start:
                fillColor = UIColor.systemGreen
            case .end:
                fillColor = UIColor.systemRed
            case .stop:
                fillColor = UIColor.systemBlue
            }
            
            // Draw circle
            fillColor.setFill()
            UIBezierPath(ovalIn: rect).fill()
            
            // Draw white border
            UIColor.white.setStroke()
            let borderPath = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
            borderPath.lineWidth = 2
            borderPath.stroke()
            
            // Draw number
            let numberString = "\(number)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = numberString.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            numberString.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // MARK: - Traffic Button
    private func addTrafficButton(to mapView: GMSMapView) {
        let button = UIButton(type: .system)
        button.setTitle("Traffic", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.layer.cornerRadius = 8
        button.frame = CGRect(x: mapView.frame.width - 80, y: 60, width: 60, height: 30)
        button.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        
        button.addAction(UIAction { _ in
            mapView.isTrafficEnabled.toggle()
            button.backgroundColor = mapView.isTrafficEnabled ?
                UIColor.systemBlue.withAlphaComponent(0.8) :
                UIColor.black.withAlphaComponent(0.7)
                
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }, for: .touchUpInside)
        
        mapView.addSubview(button)
    }
}

// MARK: - Map Delegate
extension GoogleMapsView {
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapsView
        
        init(_ parent: GoogleMapsView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            // Show info window
            mapView.selectedMarker = marker
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            return true
        }
    }
}

// MARK: - Mock Route Data Extension
extension MapRouteData {
    static func mockRouteData(from routeData: RouteData) -> MapRouteData {
        var waypoints: [RouteStop] = []
        
        // Add start
        waypoints.append(RouteStop(
            address: routeData.startLocation,
            name: extractBusinessName(routeData.startLocation),
            type: .start,
            distance: nil,
            duration: nil
        ))
        
        // Add stops
        for stop in routeData.stops {
            waypoints.append(RouteStop(
                address: stop,
                name: extractBusinessName(stop),
                type: .stop,
                distance: "\(Int.random(in: 5...15)) min",
                duration: "\(Float.random(in: 2...8).rounded(1)) mi"
            ))
        }
        
        // Add end
        waypoints.append(RouteStop(
            address: routeData.endLocation,
            name: extractBusinessName(routeData.endLocation),
            type: .end,
            distance: "\(Int.random(in: 8...20)) min",
            duration: "\(Float.random(in: 3...10).rounded(1)) mi"
        ))
        
        // Create route coordinates (simple path between points)
        let coordinates = createSimpleRoute(for: waypoints.count)
        
        return MapRouteData(
            waypoints: waypoints,
            totalDistance: "32.0 miles",
            estimatedTime: "64 min",
            routeCoordinates: coordinates
        )
    }
    
    private static func extractBusinessName(_ address: String) -> String {
        if address.contains(",") {
            let name = address.components(separatedBy: ",").first ?? ""
            return name.trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
    
    private static func createSimpleRoute(for waypointCount: Int) -> [CLLocationCoordinate2D] {
        // Real Houston coordinates for a logical route
        return [
            CLLocationCoordinate2D(latitude: 29.7604, longitude: -95.3698), // Downtown
            CLLocationCoordinate2D(latitude: 29.7372, longitude: -95.4618), // Galleria
            CLLocationCoordinate2D(latitude: 29.8174, longitude: -95.4018), // Woodlands
        ]
    }
}
