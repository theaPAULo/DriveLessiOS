//
//  GoogleMapsView.swift
//  DriveLess
//
//  Interactive Google Maps with route visualization, custom markers, and animations
//

import SwiftUI
import GoogleMaps
import GooglePlaces

// MARK: - Route Data for Maps
struct MapRouteData {
    let waypoints: [RouteStop]
    let totalDistance: String
    let estimatedTime: String
    
    // Mock directions result for now - we'll replace with real API later
    let routeCoordinates: [CLLocationCoordinate2D]
}

// MARK: - Google Maps UIViewRepresentable
struct GoogleMapsView: UIViewRepresentable {
    let routeData: MapRouteData
    @State private var mapView: GMSMapView?
    @State private var currentInfoWindow: GMSMarker?
    
    // MARK: - Color Theme (Earthy)
    private let primaryGreen = UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1.0)
    private let accentBrown = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
    private let routeBlue = UIColor(red: 0.31, green: 0.53, blue: 0.90, alpha: 1.0) // iOS blue
    
    func makeUIView(context: Context) -> GMSMapView {
        // Create the map view with optimal settings for mobile
        let mapView = GMSMapView()
        
        // Configure map settings for better mobile experience
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = false // Disable 3D tilt for cleaner route view
        
        // Set delegate for marker interactions
        mapView.delegate = context.coordinator
        
        // Store reference for updates
        DispatchQueue.main.async {
            self.mapView = mapView
            self.setupRoute(on: mapView)
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Update map when data changes
        setupRoute(on: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Route Setup
    private func setupRoute(on mapView: GMSMapView) {
        // Clear existing markers and polylines
        mapView.clear()
        
        // Add custom markers for each waypoint
        addRouteMarkers(to: mapView)
        
        // Draw the route polyline with animation
        drawRoutePolyline(on: mapView)
        
        // Set up camera to show entire route
        fitRouteInView(mapView: mapView)
        
        // Add traffic layer (hidden by default)
        setupTrafficLayer(on: mapView)
    }
    
    // MARK: - Custom Markers
    private func addRouteMarkers(to mapView: GMSMapView) {
        for (index, waypoint) in routeData.waypoints.enumerated() {
            // Get coordinates for this waypoint (mock for now)
            let coordinate = getCoordinateForWaypoint(waypoint, index: index)
            
            // Create custom marker
            let marker = GMSMarker()
            marker.position = coordinate
            marker.map = mapView
            
            // Customize marker based on type
            marker.icon = createCustomMarkerIcon(
                number: index + 1,
                type: waypoint.type,
                size: CGSize(width: 40, height: 40)
            )
            
            // Store waypoint data for info window
            marker.userData = waypoint
            
            // Set marker title for accessibility
            marker.title = waypoint.name.isEmpty ? waypoint.address : waypoint.name
        }
    }
    
    // MARK: - Route Polyline with Animation
    private func drawRoutePolyline(on mapView: GMSMapView) {
        // Create the main route polyline
        let path = GMSMutablePath()
        
        // Add all route coordinates
        for coordinate in routeData.routeCoordinates {
            path.add(coordinate)
        }
        
        // Create animated polyline
        let polyline = GMSPolyline(path: path)
        polyline.strokeColor = routeBlue
        polyline.strokeWidth = 6.0
        polyline.map = mapView
        
        // Add direction arrows (similar to web app)
        addDirectionArrows(to: mapView, along: path)
        
        // Add animated route dash (similar to web app moving dots)
        addAnimatedRouteDash(to: mapView, along: path)
    }
    
    // MARK: - Direction Arrows
    private func addDirectionArrows(to mapView: GMSMapView, along path: GMSMutablePath) {
        let pathCount = path.count()
        guard pathCount > 1 else { return }
        
        // Add arrows every 20% of the route to avoid clutter
        let arrowSpacing = max(1, pathCount / 5)
        
        for i in stride(from: 0, to: Int(pathCount) - 1, by: arrowSpacing) {
            let startCoord = path.coordinate(at: UInt(i))
            let endCoord = path.coordinate(at: UInt(i + 1))
            
            // Calculate heading for arrow direction
            let heading = GMSGeometryHeading(from: startCoord, to: endCoord)
            
            // Create arrow marker
            let arrowMarker = GMSMarker()
            arrowMarker.position = GMSGeometryInterpolate(startCoord, endCoord, 0.5)
            arrowMarker.icon = createArrowIcon(heading: heading)
            arrowMarker.map = mapView
            arrowMarker.zIndex = 1 // Ensure arrows appear above route
        }
    }
    
    // MARK: - Animated Route Dash
    private func addAnimatedRouteDash(to mapView: GMSMapView, along path: GMSMutablePath) {
        // Create a dashed overlay for animation effect
        let dashedPolyline = GMSPolyline(path: path)
        dashedPolyline.strokeColor = UIColor.white
        dashedPolyline.strokeWidth = 3.0
        
        // Create dash pattern
        let dashPattern = [NSNumber(value: 10), NSNumber(value: 10)]
        dashedPolyline.strokePattern = dashPattern.map { GMSStrokeStyle.solidColor(UIColor.white).withLength($0) }
        
        dashedPolyline.map = mapView
        dashedPolyline.zIndex = 2 // Above main route
        
        // Animate the dash pattern (simplified version)
        animateDashPattern(polyline: dashedPolyline)
    }
    
    // MARK: - Traffic Layer
    private func setupTrafficLayer(on mapView: GMSMapView) {
        // Traffic layer will be toggled by user action
        // For now, we'll add a button to the map
        addTrafficToggleButton(to: mapView)
    }
    
    // MARK: - Helper Functions
    
    private func getCoordinateForWaypoint(_ waypoint: RouteStop, index: Int) -> CLLocationCoordinate2D {
        // Mock coordinates for Houston area - we'll replace with real geocoding
        let baseLatitude = 29.7604
        let baseLongitude = -95.3698
        
        // Spread waypoints around Houston area for demo
        let latOffset = Double(index) * 0.02 - 0.04
        let lngOffset = Double(index) * 0.015 - 0.03
        
        return CLLocationCoordinate2D(
            latitude: baseLatitude + latOffset,
            longitude: baseLongitude + lngOffset
        )
    }
    
    private func createCustomMarkerIcon(number: Int, type: StopType, size: CGSize) -> UIImage {
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
            
            // Draw circle background
            fillColor.setFill()
            UIBezierPath(ovalIn: rect).fill()
            
            // Draw white border
            UIColor.white.setStroke()
            let borderPath = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
            borderPath.lineWidth = 2
            borderPath.stroke()
            
            // Draw number text
            let numberString = "\(number)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: size.width * 0.4),
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
    
    private func createArrowIcon(heading: CLLocationDirection) -> UIImage {
        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Save the current graphics state
            context.cgContext.saveGState()
            
            // Move to center and rotate based on heading
            context.cgContext.translateBy(x: size.width / 2, y: size.height / 2)
            context.cgContext.rotate(by: CGFloat(heading * .pi / 180))
            
            // Draw arrow shape
            routeBlue.setFill()
            let arrowPath = UIBezierPath()
            arrowPath.move(to: CGPoint(x: 0, y: -8))
            arrowPath.addLine(to: CGPoint(x: -6, y: 6))
            arrowPath.addLine(to: CGPoint(x: 0, y: 2))
            arrowPath.addLine(to: CGPoint(x: 6, y: 6))
            arrowPath.close()
            arrowPath.fill()
            
            // Restore graphics state
            context.cgContext.restoreGState()
        }
    }
    
    private func fitRouteInView(mapView: GMSMapView) {
        guard !routeData.routeCoordinates.isEmpty else { return }
        
        // Create bounds that include all waypoints
        var bounds = GMSCoordinateBounds()
        
        for coordinate in routeData.routeCoordinates {
            bounds = bounds.includingCoordinate(coordinate)
        }
        
        // Update camera with padding for better mobile viewing
        let padding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
        let cameraUpdate = GMSCameraUpdate.fit(bounds, with: padding)
        mapView.animate(with: cameraUpdate)
    }
    
    private func addTrafficToggleButton(to mapView: GMSMapView) {
        // Create a custom traffic toggle button
        let button = UIButton(type: .system)
        button.setTitle("Traffic", for: .normal)
        button.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        button.layer.cornerRadius = 8
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 2
        
        // Position in top-right corner
        button.frame = CGRect(x: mapView.frame.width - 80, y: 20, width: 60, height: 40)
        button.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        
        // Add action
        button.addTarget(self, action: #selector(toggleTraffic), for: .touchUpInside)
        
        mapView.addSubview(button)
    }
    
    @objc private func toggleTraffic() {
        guard let mapView = mapView else { return }
        
        // Toggle traffic layer
        mapView.isTrafficEnabled.toggle()
        
        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        print("Traffic layer toggled: \(mapView.isTrafficEnabled)")
    }
    
    private func animateDashPattern(polyline: GMSPolyline) {
        // Simplified dash animation - can be enhanced later
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            // Animate by shifting the dash pattern
            // This creates the moving dots effect from the web app
            if let pattern = polyline.strokePattern as? [GMSStrokeStyle] {
                var newPattern = pattern
                if let first = newPattern.first {
                    newPattern.removeFirst()
                    newPattern.append(first)
                    polyline.strokePattern = newPattern
                }
            }
        }
    }
}

// MARK: - Map Delegate
extension GoogleMapsView {
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapsView
        
        init(_ parent: GoogleMapsView) {
            self.parent = parent
        }
        
        // Handle marker taps to show info windows
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            // Close previous info window
            if let currentWindow = parent.currentInfoWindow {
                currentWindow.map = nil
            }
            
            // Show info for this marker
            if let waypoint = marker.userData as? RouteStop {
                showInfoWindow(for: waypoint, marker: marker, on: mapView)
                parent.currentInfoWindow = marker
            }
            
            // Add haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            return true
        }
        
        private func showInfoWindow(for waypoint: RouteStop, marker: GMSMarker, on mapView: GMSMapView) {
            // Create custom info window similar to web app
            let infoView = createInfoWindowView(for: waypoint)
            
            // Position the info window above the marker
            let markerScreenPoint = mapView.projection.point(for: marker.position)
            let infoWindowPoint = CGPoint(
                x: markerScreenPoint.x,
                y: markerScreenPoint.y - 60
            )
            
            infoView.center = infoWindowPoint
            mapView.addSubview(infoView)
            
            // Add animation
            infoView.alpha = 0
            infoView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3) {
                infoView.alpha = 1
                infoView.transform = .identity
            }
            
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                UIView.animate(withDuration: 0.2) {
                    infoView.alpha = 0
                } completion: { _ in
                    infoView.removeFromSuperview()
                }
            }
        }
        
        private func createInfoWindowView(for waypoint: RouteStop) -> UIView {
            let containerView = UIView()
            containerView.backgroundColor = UIColor.systemBackground
            containerView.layer.cornerRadius = 12
            containerView.layer.shadowOpacity = 0.3
            containerView.layer.shadowRadius = 4
            containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
            
            // Add content
            let nameLabel = UILabel()
            nameLabel.text = waypoint.name.isEmpty ? waypoint.address.components(separatedBy: ",").first : waypoint.name
            nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
            nameLabel.textColor = UIColor.label
            
            let addressLabel = UILabel()
            addressLabel.text = waypoint.address
            addressLabel.font = UIFont.systemFont(ofSize: 12)
            addressLabel.textColor = UIColor.secondaryLabel
            addressLabel.numberOfLines = 2
            
            let typeLabel = UILabel()
            typeLabel.text = waypoint.type.label
            typeLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
            typeLabel.textColor = waypoint.type.color.toUIColor()
            typeLabel.backgroundColor = waypoint.type.color.toUIColor().withAlphaComponent(0.2)
            typeLabel.layer.cornerRadius = 4
            typeLabel.textAlignment = .center
            typeLabel.clipsToBounds = true
            
            // Layout
            containerView.addSubview(nameLabel)
            containerView.addSubview(addressLabel)
            containerView.addSubview(typeLabel)
            
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            addressLabel.translatesAutoresizingMaskIntoConstraints = false
            typeLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
                nameLabel.trailingAnchor.constraint(equalTo: typeLabel.leadingAnchor, constant: -8),
                
                typeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                typeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
                typeLabel.widthAnchor.constraint(equalToConstant: 40),
                
                addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
                addressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
                addressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
                addressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
                
                containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 250)
            ])
            
            return containerView
        }
    }
}

// MARK: - Color Extension
extension Color {
    func toUIColor() -> UIColor {
        UIColor(self)
    }
}

// MARK: - Mock Route Data Generator
extension MapRouteData {
    static func mockRouteData(from routeData: RouteData) -> MapRouteData {
        // Convert RouteData to MapRouteData with mock coordinates
        let waypoints = createMockWaypoints(from: routeData)
        let coordinates = createMockCoordinates(for: waypoints.count)
        
        return MapRouteData(
            waypoints: waypoints,
            totalDistance: "32.0 miles", // Mock data - will be replaced with real calculations
            estimatedTime: "64 min",
            routeCoordinates: coordinates
        )
    }
    
    private static func createMockWaypoints(from routeData: RouteData) -> [RouteStop] {
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
                distance: "\(Float.random(in: 2...8).rounded(1)) mi",
                duration: "\(Int.random(in: 5...15)) min"
            ))
        }
        
        // Add end
        waypoints.append(RouteStop(
            address: routeData.endLocation,
            name: extractBusinessName(routeData.endLocation),
            type: .end,
            distance: "\(Float.random(in: 3...10).rounded(1)) mi",
            duration: "\(Int.random(in: 8...20)) min"
        ))
        
        return waypoints
    }
    
    private static func createMockCoordinates(for waypointCount: Int) -> [CLLocationCoordinate2D] {
        // Create a realistic route path through Houston area
        var coordinates: [CLLocationCoordinate2D] = []
        
        let baseLatitude = 29.7604
        let baseLongitude = -95.3698
        
        for i in 0..<waypointCount {
            let progress = Double(i) / Double(waypointCount - 1)
            
            // Create a curved path
            let lat = baseLatitude + (progress * 0.08) - 0.04 + sin(progress * .pi) * 0.02
            let lng = baseLongitude + (progress * 0.06) - 0.03 + cos(progress * .pi * 2) * 0.015
            
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
            
            // Add intermediate points for smoother route
            if i < waypointCount - 1 {
                for j in 1...3 {
                    let subProgress = Double(j) / 4.0
                    let nextProgress = Double(i + 1) / Double(waypointCount - 1)
                    let interpolatedProgress = progress + (nextProgress - progress) * subProgress
                    
                    let interpolatedLat = baseLatitude + (interpolatedProgress * 0.08) - 0.04 + sin(interpolatedProgress * .pi) * 0.02
                    let interpolatedLng = baseLongitude + (interpolatedProgress * 0.06) - 0.03 + cos(interpolatedProgress * .pi * 2) * 0.015
                    
                    coordinates.append(CLLocationCoordinate2D(latitude: interpolatedLat, longitude: interpolatedLng))
                }
            }
        }
        
        return coordinates
    }
    
    private static func extractBusinessName(_ address: String) -> String {
        if address.contains(",") {
            let name = address.components(separatedBy: ",").first ?? ""
            return name.trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
}

extension Float {
    func rounded(_ digits: Int) -> Float {
        let multiplier = pow(10.0, Float(digits))
        return (self * multiplier).rounded() / multiplier
    }
}
