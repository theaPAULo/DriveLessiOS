//
//  RouteData.swift
//  DriveLess
//
//  Created by Paul Soni on 6/19/25.
//


//
//  RouteData.swift
//  DriveLess
//
//  Data models for route planning and results
//

import SwiftUI

// MARK: - Route Data Models
struct RouteData {
    let startLocation: String
    let endLocation: String
    let stops: [String]
    let isRoundTrip: Bool
    let considerTraffic: Bool
    
    // Results (to be calculated)
    var totalDistance: String = "0 miles"
    var estimatedTime: String = "0 min"
    var optimizedStops: [RouteStop] = []
}

struct RouteStop {
    let address: String          // Full street address from Google
    let name: String            // Business name (user input or extracted)
    let originalInput: String   // What the user originally typed
    let type: StopType
    let distance: String?
    let duration: String?
    
    // Computed property to get the best display name
    var displayName: String {
        // If we have a business name that's different from address, use it
        if !name.isEmpty && name != address {
            return name
        }
        // Otherwise, try to extract business name from address
        if address.contains(",") {
            let firstPart = address.components(separatedBy: ",").first ?? ""
            // Check if it looks like a business name (doesn't start with numbers)
            if !firstPart.isEmpty && !(firstPart.trimmingCharacters(in: .whitespaces).first?.isNumber ?? false) {
                return firstPart.trimmingCharacters(in: .whitespaces)
            }
        }
        // Fallback to original input if available
        return !originalInput.isEmpty ? originalInput : address
    }
    
    // Computed property to get the best address for subtitle
    var displayAddress: String {
        // Always return the full formatted address
        return address
    }
}

enum StopType {
    case start, stop, end
    
    var color: Color {
        switch self {
        case .start: return .green
        case .stop: return .blue
        case .end: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .start: return "location.circle.fill"
        case .stop: return "mappin.circle.fill"
        case .end: return "flag.checkered"
        }
    }
    
    var label: String {
        switch self {
        case .start: return "START"
        case .stop: return "STOP"
        case .end: return "END"
        }
    }
}
