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
    let encodedPolyline: String? // Add this for real route paths
}

// MARK: - Google Maps UIViewRepresentable
struct GoogleMapsView: UIViewRepresentable {
    let routeData: MapRouteData
    
    func makeUIView(context: Context) -> GMSMapView {
        print("🗺️ Creating Google Maps view...")
        
        // Create the map view with proper initializer
        let camera = GMSCameraPosition.camera(withLatitude: 29.7604, longitude: -95.3698, zoom: 10.0)
        let mapView = GMSMapView(frame: .zero, camera: camera)
        
        // Force the map type to be normal
        mapView.mapType = GMSMapViewType.normal
        
        // Configure map settings for mobile
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = false
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
    
    // MARK: - Polyline Decoding
    
    /**
     * Decode Google's encoded polyline into CLLocationCoordinate2D points
     * This follows the actual roads instead of straight lines
     */
    /**
     * Decode Google's encoded polyline into CLLocationCoordinate2D points
     * This follows the actual roads instead of straight lines
     */
    /**
     * Decode Google's encoded polyline into CLLocationCoordinate2D points
     * This follows the actual roads instead of straight lines
     */
    private func decodePolyline(_ encodedPolyline: String) -> [CLLocationCoordinate2D] {
        guard !encodedPolyline.isEmpty else {
            print("❌ Empty polyline string")
            return []
        }
        
        var coordinates: [CLLocationCoordinate2D] = []
        var lat = 0.0
        var lng = 0.0
        var index = 0
        let chars = Array(encodedPolyline.utf8)
        
        print("📍 Decoding polyline with \(chars.count) characters")
        
        while index < chars.count {
            var shift = 0
            var result = 0
            
            // Decode latitude with bounds checking
            var latByte = 0
            repeat {
                guard index < chars.count else {
                    print("❌ Index out of bounds while decoding latitude at index \(index)")
                    return coordinates
                }
                
                latByte = Int(chars[index]) - 63
                index += 1
                result |= (latByte & 0x1F) << shift
                shift += 5
            } while (latByte & 0x20) != 0 && index < chars.count
            
            let deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lat += Double(deltaLat)
            
            shift = 0
            result = 0
            
            // Decode longitude with bounds checking
            var lngByte = 0
            repeat {
                guard index < chars.count else {
                    print("❌ Index out of bounds while decoding longitude at index \(index)")
                    return coordinates
                }
                
                lngByte = Int(chars[index]) - 63
                index += 1
                result |= (lngByte & 0x1F) << shift
                shift += 5
            } while (lngByte & 0x20) != 0 && index < chars.count
            
            let deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lng += Double(deltaLng)
            
            coordinates.append(CLLocationCoordinate2D(
                latitude: lat / 1e5,
                longitude: lng / 1e5
            ))
        }
        
        print("📍 Successfully decoded \(coordinates.count) polyline points")
        return coordinates
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func setupMarkersAndRoute(on mapView: GMSMapView) {
        // Use real coordinates if available, otherwise fallback
        let coordinates = routeData.routeCoordinates.isEmpty ?
            getCoordinatesFromAddresses() : routeData.routeCoordinates
        
        print("📍 Setting up markers with \(coordinates.count) coordinates")
        
        // Add markers for each waypoint with real coordinates
        for (index, waypoint) in routeData.waypoints.enumerated() {
            guard index < coordinates.count else { continue }
            
            let marker = GMSMarker()
            marker.position = coordinates[index]
            marker.icon = createMarkerIcon(number: index + 1, type: waypoint.type)
            marker.title = waypoint.name.isEmpty ? waypoint.address.components(separatedBy: ",").first : waypoint.name
            marker.snippet = waypoint.address
            marker.map = mapView
            
            print("📍 Added marker \(index + 1) at: \(coordinates[index].latitude), \(coordinates[index].longitude)")
        }
        
        // Draw route polyline - use real route if available, otherwise straight lines
        if let encodedPolyline = routeData.encodedPolyline, !encodedPolyline.isEmpty {
            print("📍 Drawing real route polyline from Google")
            let decodedCoordinates = decodePolyline(encodedPolyline)
            
            if !decodedCoordinates.isEmpty {
                let path = GMSMutablePath()
                decodedCoordinates.forEach { path.add($0) }
                
                let polyline = GMSPolyline(path: path)
                polyline.strokeColor = UIColor.systemBlue
                polyline.strokeWidth = 6.0
                polyline.map = mapView
                print("📍 Drew real route with \(decodedCoordinates.count) points")
            } else {
                print("⚠️ Polyline decoding failed, falling back to straight lines")
                // Fall back to straight lines if decoding fails
                if coordinates.count > 1 {
                    let path = GMSMutablePath()
                    coordinates.forEach { path.add($0) }
                    
                    let polyline = GMSPolyline(path: path)
                    polyline.strokeColor = UIColor.systemRed
                    polyline.strokeWidth = 4.0
                    polyline.map = mapView
                }
            }
        } else if coordinates.count > 1 {
            print("📍 Drawing fallback straight-line route")
            let path = GMSMutablePath()
            coordinates.forEach { path.add($0) }
            
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = UIColor.systemRed
            polyline.strokeWidth = 4.0
            polyline.map = mapView
        }
        
        // Fit camera to show all markers
        // Fit camera to show all markers with proper bounds validation
        if coordinates.count > 1 {
            print("📍 Fitting camera to \(coordinates.count) coordinates")
            
            // Validate coordinates before creating bounds
            let validCoordinates = coordinates.filter { coordinate in
                let isValid = coordinate.latitude != 0.0 &&
                             coordinate.longitude != 0.0 &&
                             coordinate.latitude >= -90.0 &&
                             coordinate.latitude <= 90.0 &&
                             coordinate.longitude >= -180.0 &&
                             coordinate.longitude <= 180.0
                if !isValid {
                    print("⚠️ Invalid coordinate found: \(coordinate.latitude), \(coordinate.longitude)")
                }
                return isValid
            }
            
            if validCoordinates.count > 1 {
                // Log all coordinates for debugging
                print("📍 Valid coordinates:")
                for (index, coord) in validCoordinates.enumerated() {
                    print("   \(index + 1): \(coord.latitude), \(coord.longitude)")
                }
                
                // Calculate bounds manually for better control
                let latitudes = validCoordinates.map { $0.latitude }
                let longitudes = validCoordinates.map { $0.longitude }
                
                let minLat = latitudes.min()!
                let maxLat = latitudes.max()!
                let minLng = longitudes.min()!
                let maxLng = longitudes.max()!
                
                print("📍 Calculated bounds: (\(minLat), \(minLng)) to (\(maxLat), \(maxLng))")
                
                // Calculate center point
                let centerLat = (minLat + maxLat) / 2
                let centerLng = (minLng + maxLng) / 2
                let centerCoordinate = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
                
                print("📍 Center coordinate: \(centerLat), \(centerLng)")
                
                // Calculate span (difference between max and min)
                let latSpan = maxLat - minLat
                let lngSpan = maxLng - minLng
                let maxSpan = max(latSpan, lngSpan)
                
                print("📍 Coordinate span: lat=\(latSpan), lng=\(lngSpan), max=\(maxSpan)")
                
                // Calculate appropriate zoom level based on span
                // Zoom levels: 1=world, 5=continent, 10=city, 15=streets, 20=buildings
                let zoom: Float
                if maxSpan > 10.0 {
                    zoom = 5.0  // Very wide area
                } else if maxSpan > 1.0 {
                    zoom = 8.0  // Large city area
                } else if maxSpan > 0.1 {
                    zoom = 12.0 // City district
                } else if maxSpan > 0.01 {
                    zoom = 15.0 // Neighborhood
                } else {
                    zoom = 17.0 // Street level
                }
                
                print("📍 Calculated zoom level: \(zoom) for span: \(maxSpan)")
                
                // Create camera with calculated center and zoom
                let calculatedCamera = GMSCameraPosition.camera(
                    withTarget: centerCoordinate,
                    zoom: zoom
                )
                
                print("✅ Final camera - Target: \(calculatedCamera.target.latitude), \(calculatedCamera.target.longitude), Zoom: \(calculatedCamera.zoom)")
                
                // Animate to the new position
                mapView.animate(to: calculatedCamera)
                
                // Add a slight delay then fine-tune with bounds if needed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Create Google Maps bounds for fine-tuning
                    let bounds = GMSCoordinateBounds()
                    var boundsWithCoordinates = bounds
                    validCoordinates.forEach { coordinate in
                        boundsWithCoordinates = boundsWithCoordinates.includingCoordinate(coordinate)
                    }
                    
                    // Apply bounds with padding for final adjustment
                    let padding = UIEdgeInsets(top: 100, left: 80, bottom: 150, right: 80)
                    let camera = mapView.camera(for: boundsWithCoordinates, insets: padding)
                    
                    if let finalCamera = camera {
                        // Ensure zoom level is reasonable (between 10-18 for routes)
                        let clampedZoom = max(10.0, min(18.0, finalCamera.zoom))
                        let adjustedCamera = GMSCameraPosition.camera(
                            withTarget: finalCamera.target,
                            zoom: clampedZoom
                        )
                        
                        print("🎯 Fine-tuned camera - Target: \(adjustedCamera.target.latitude), \(adjustedCamera.target.longitude), Zoom: \(adjustedCamera.zoom)")
                        mapView.animate(to: adjustedCamera)
                    }
                }
                
            } else {
                print("❌ No valid coordinates for bounds, using fallback")
                // Fallback for single valid coordinate
                if let firstCoord = validCoordinates.first {
                    let fallbackCamera = GMSCameraPosition.camera(
                        withTarget: firstCoord,
                        zoom: 14.0
                    )
                    mapView.animate(to: fallbackCamera)
                }
            }
        } else if coordinates.count == 1 && coordinates.first!.latitude != 0 && coordinates.first!.longitude != 0 {
            // Single location: center on that point
            print("📍 Single location: centering on coordinate")
            let singleLocationCamera = GMSCameraPosition.camera(
                withTarget: coordinates.first!,
                zoom: 14.0
            )
            mapView.animate(to: singleLocationCamera)
        } else {
            print("❌ No valid coordinates available, using default view")
            // No coordinates: use default Houston view
            let defaultCamera = GMSCameraPosition.camera(
                withLatitude: 29.7604,
                longitude: -95.3698,
                zoom: 12.0
            )
            mapView.animate(to: defaultCamera)
        }
        
        // Add traffic toggle button
        addTrafficButton(to: mapView)
    }

    // Fallback function for when real coordinates aren't available
    private func getCoordinatesFromAddresses() -> [CLLocationCoordinate2D] {
        return routeData.waypoints.map { waypoint in
            // Use the hardcoded logic as fallback
            getCoordinateForLocation(waypoint.address)
        }
    }

    // Helper function to get coordinates for major Texas cities
    private func getCoordinateForLocation(_ address: String) -> CLLocationCoordinate2D {
        let lowerAddress = address.lowercased()
        
        if lowerAddress.contains("houston") {
            return CLLocationCoordinate2D(latitude: 29.7604, longitude: -95.3698)
        } else if lowerAddress.contains("san antonio") {
            return CLLocationCoordinate2D(latitude: 29.4251905, longitude: -98.4945922)
        } else if lowerAddress.contains("dallas") {
            return CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970)
        } else if lowerAddress.contains("austin") {
            return CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431)
        } else if lowerAddress.contains("plomo quesadillas") {
            return CLLocationCoordinate2D(latitude: 32.8116482, longitude: -96.7745424)
        } else {
            // Default to center of Texas for unknown locations
            return CLLocationCoordinate2D(latitude: 31.0, longitude: -97.0)
        }
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
            originalInput: routeData.startLocation,
            type: .start,
            distance: nil,
            duration: nil
        ))

        // Add stops
        for stop in routeData.stops {
            waypoints.append(RouteStop(
                address: stop,
                name: extractBusinessName(stop),
                originalInput: stop,
                type: .stop,
                distance: "\(Int.random(in: 5...15)) min",
                duration: "\(Float.random(in: 2...8).rounded(1)) mi"
            ))
        }

        // Add end
        waypoints.append(RouteStop(
            address: routeData.endLocation,
            name: extractBusinessName(routeData.endLocation),
            originalInput: routeData.endLocation,
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
            routeCoordinates: coordinates,
            encodedPolyline: nil // No real polyline for mock data
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
    
    // MARK: - Polyline Decoding


     /**
      * Decode Google's encoded polyline into CLLocationCoordinate2D points
      * This follows the actual roads instead of straight lines
      */
     private func decodePolyline(_ encodedPolyline: String) -> [CLLocationCoordinate2D] {
         guard !encodedPolyline.isEmpty else {
             print("❌ Empty polyline string")
             return []
         }
         
         var coordinates: [CLLocationCoordinate2D] = []
         var lat = 0.0
         var lng = 0.0
         var index = 0
         let chars = Array(encodedPolyline.utf8)
         
         print("📍 Decoding polyline with \(chars.count) characters")
         
         while index < chars.count {
             // Decode latitude
             var shift = 0
             var result = 0
             
             while true {
                 guard index < chars.count else {
                     print("❌ Index out of bounds while decoding latitude")
                     return coordinates
                 }
                 
                 let currentByte = Int(chars[index]) - 63
                 index += 1
                 result |= (currentByte & 0x1F) << shift
                 shift += 5
                 
                 if (currentByte & 0x20) == 0 {
                     break
                 }
             }
             
             let deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
             lat += Double(deltaLat)
             
             // Decode longitude
             shift = 0
             result = 0
             
             while true {
                 guard index < chars.count else {
                     print("❌ Index out of bounds while decoding longitude")
                     return coordinates
                 }
                 
                 let currentByte = Int(chars[index]) - 63
                 index += 1
                 result |= (currentByte & 0x1F) << shift
                 shift += 5
                 
                 if (currentByte & 0x20) == 0 {
                     break
                 }
             }
             
             let deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
             lng += Double(deltaLng)
             
             coordinates.append(CLLocationCoordinate2D(
                 latitude: lat / 1e5,
                 longitude: lng / 1e5
             ))
         }
         
         print("📍 Successfully decoded \(coordinates.count) polyline points")
         return coordinates
     }
}
