//
//  ErrorTrackingService.swift
//  DriveLess
//
//  Created by Paul Soni on 6/28/25.
//

//
//  ErrorTrackingService.swift
//  DriveLess
//
//  Centralized error tracking for real admin dashboard analytics
//  CREATE THIS FILE: Right-click Services folder → New File → Swift File → Name: ErrorTrackingService.swift
//

import Foundation
import FirebaseAuth
import UIKit

// MARK: - Error Types
enum DriveLessError: String, CaseIterable {
    case routeCalculationFailed = "route_calculation_failed"
    case googleAPIError = "google_api_error"
    case networkError = "network_error"
    case authenticationError = "authentication_error"
    case locationError = "location_error"
    case coreDataError = "core_data_error"
    case firestoreError = "firestore_error"
    case userInputError = "user_input_error"
    case unknownError = "unknown_error"
}

// MARK: - Error Tracking Service
class ErrorTrackingService: ObservableObject {
    static let shared = ErrorTrackingService()
    
    private init() {
        print("🚨 ErrorTrackingService initialized")
    }
    
    // MARK: - Main Error Tracking Method
    
    /// Records an error with full context for admin dashboard
    /// - Parameters:
    ///   - errorType: The type of error that occurred
    ///   - message: Human-readable error description
    ///   - details: Additional context (API response, user action, etc.)
    ///   - location: Where in the app the error occurred (optional)
    func trackError(
        type: DriveLessError,
        message: String,
        details: String? = nil,
        location: String? = nil
    ) {
        let timestamp = Date()
        let userID = Auth.auth().currentUser?.uid ?? "anonymous"
        
        // Create comprehensive error context
        let errorContext = createErrorContext(
            type: type,
            message: message,
            details: details,
            location: location,
            timestamp: timestamp
        )
        
        // Log error for debugging
        print("🚨 ERROR TRACKED: [\(type.rawValue)] \(message)")
        if let details = details {
            print("   Details: \(details)")
        }
        if let location = location {
            print("   Location: \(location)")
        }
        
        // Track in both local Core Data and Firestore for dashboard
        trackErrorLocally(errorContext: errorContext, userID: userID)
        trackErrorInFirestore(errorContext: errorContext, userID: userID)
        
        // Track as event in existing analytics systems
        RealTimeTrackingService.shared.trackEvent(
            type: type.rawValue,
            details: details,
            success: false,
            errorMessage: message
        )
        
        FirestoreAnalyticsService.shared.trackEvent(
            type: type.rawValue,
            details: details,
            success: false,
            errorMessage: message
        )
    }
    
    // MARK: - Convenience Methods for Common Errors
    
    /// Track route calculation failures
    func trackRouteError(_ error: Error, context: String) {
        trackError(
            type: .routeCalculationFailed,
            message: error.localizedDescription,
            details: context,
            location: "RouteCalculator"
        )
    }
    
    /// Track Google API failures
    func trackGoogleAPIError(_ error: Error, endpoint: String) {
        trackError(
            type: .googleAPIError,
            message: error.localizedDescription,
            details: "Endpoint: \(endpoint)",
            location: "Google Maps SDK"
        )
    }
    
    /// Track network connectivity issues
    func trackNetworkError(_ error: Error, operation: String) {
        trackError(
            type: .networkError,
            message: error.localizedDescription,
            details: "Operation: \(operation)",
            location: "Network Layer"
        )
    }
    
    /// Track authentication problems
    func trackAuthError(_ error: Error, provider: String) {
        trackError(
            type: .authenticationError,
            message: error.localizedDescription,
            details: "Provider: \(provider)",
            location: "AuthenticationManager"
        )
    }
    
    /// Track location service failures
    func trackLocationError(_ error: Error) {
        trackError(
            type: .locationError,
            message: error.localizedDescription,
            details: "Location services unavailable",
            location: "LocationManager"
        )
    }
    
    /// Track Core Data failures
    func trackCoreDataError(_ error: Error, operation: String) {
        trackError(
            type: .coreDataError,
            message: error.localizedDescription,
            details: "Operation: \(operation)",
            location: "CoreDataManager"
        )
    }
    
    /// Track Firestore failures
    func trackFirestoreError(_ error: Error, operation: String) {
        trackError(
            type: .firestoreError,
            message: error.localizedDescription,
            details: "Operation: \(operation)",
            location: "FirestoreAnalyticsService"
        )
    }
    
    // MARK: - Private Helper Methods
    
    /// Creates comprehensive error context dictionary
    private func createErrorContext(
        type: DriveLessError,
        message: String,
        details: String?,
        location: String?,
        timestamp: Date
    ) -> [String: Any] {
        
        var context: [String: Any] = [
            "errorType": type.rawValue,
            "message": message,
            "timestamp": timestamp,
            "appVersion": getAppVersion(),
            "deviceInfo": getDeviceInfo(),
            "memoryUsage": getMemoryUsage(),
            "networkStatus": getNetworkStatus()
        ]
        
        // Add optional fields if available
        if let details = details {
            context["details"] = details
        }
        
        if let location = location {
            context["location"] = location
        }
        
        return context
    }
    
    /// Saves error to local Core Data using existing AppEvent entity
    private func trackErrorLocally(errorContext: [String: Any], userID: String) {
        RealTimeTrackingService.shared.trackEvent(
            type: errorContext["errorType"] as? String ?? "unknown_error",
            details: errorContext["details"] as? String,
            success: false,
            errorMessage: errorContext["message"] as? String
        )
    }
    
    /// Saves error to Firestore for admin dashboard analytics
    private func trackErrorInFirestore(errorContext: [String: Any], userID: String) {
        FirestoreAnalyticsService.shared.trackEvent(
            type: errorContext["errorType"] as? String ?? "unknown_error",
            details: errorContext["details"] as? String,
            success: false,
            errorMessage: errorContext["message"] as? String
        )
    }
    
    // MARK: - System Information Methods
    
    /// Gets current app version
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    /// Gets device information
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.model) - iOS \(device.systemVersion)"
    }
    
    /// Gets approximate memory usage
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            return usedMB
        } else {
            return 0.0
        }
    }
    
    /// Gets basic network connectivity status
    private func getNetworkStatus() -> String {
        // Simple reachability check
        // For production apps, you might want to use a more sophisticated network monitoring library
        return "Unknown" // TODO: Implement proper network status checking if needed
    }
}

// MARK: - Global Error Handler Extension
extension ErrorTrackingService {
    
    /// Sets up global error handling for uncaught exceptions
    /// Call this from your AppDelegate or App init
    func setupGlobalErrorHandling() {
        NSSetUncaughtExceptionHandler { exception in
            ErrorTrackingService.shared.trackError(
                type: .unknownError,
                message: "Uncaught exception: \(exception.name.rawValue)",
                details: exception.reason,
                location: "Global Exception Handler"
            )
        }
        
        print("✅ Global error handling configured")
    }
}