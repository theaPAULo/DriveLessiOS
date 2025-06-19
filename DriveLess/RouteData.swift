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
    let address: String
    let name: String
    let type: StopType
    let distance: String?
    let duration: String?
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