//
//  RealTimeTrackingService.swift
//  DriveLess
//
//  Created by Paul Soni on 6/27/25.
//


//
//  RealTimeTrackingService.swift
//  DriveLess
//
//  Real-time analytics and user behavior tracking service
//

import Foundation
import CoreData
import FirebaseAuth
import UIKit

class RealTimeTrackingService: ObservableObject {
    static let shared = RealTimeTrackingService()
    private let coreDataManager = CoreDataManager.shared
    
    // Track current session
    @Published var currentSession: UserSession?
    
    private init() {
        print("🔄 RealTimeTrackingService initialized")
    }
    
    // MARK: - User Session Tracking
    
    /// Starts a new user session when user signs in
    func startUserSession(signInMethod: String) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ Cannot start session - no authenticated user")
            return
        }
        
        let context = coreDataManager.viewContext
        let session = UserSession(context: context)
        
        session.id = UUID()
        session.userID = currentUser.uid
        session.signInTime = Date()
        session.signInMethod = signInMethod
        session.appVersion = getAppVersion()
        session.deviceInfo = getDeviceInfo()
        
        // Save the session
        coreDataManager.save()
        
        // Update published property
        DispatchQueue.main.async {
            self.currentSession = session
        }
        
        print("✅ Started user session for \(currentUser.uid) via \(signInMethod)")
        
        // Also ensure user metrics exist
        ensureUserMetricsExist(userID: currentUser.uid)
        
        // Track this as an app event
        trackEvent(type: "user_sign_in", details: signInMethod, success: true)
    }
    
    /// Ends the current user session when user signs out
    func endUserSession() {
        guard let session = currentSession else {
            print("⚠️ No active session to end")
            return
        }
        
        let now = Date()
        session.signOutTime = now
        
        if let signInTime = session.signInTime {
            session.sessionDuration = Int32(now.timeIntervalSince(signInTime))
        }
        
        coreDataManager.save()
        
        print("✅ Ended user session - Duration: \(session.sessionDuration) seconds")
        
        // Track sign out event
        trackEvent(type: "user_sign_out", details: nil, success: true)
        
        // Clear current session
        DispatchQueue.main.async {
            self.currentSession = nil
        }
    }
    
    // MARK: - Event Tracking
    
    /// Tracks any app event for analytics
    func trackEvent(type: String, details: String? = nil, success: Bool = true, errorMessage: String? = nil) {
        guard let currentUser = Auth.auth().currentUser else {
            print("⚠️ Cannot track event - no authenticated user")
            return
        }
        
        let context = coreDataManager.viewContext
        let event = AppEvent(context: context)
        
        event.id = UUID()
        event.userID = currentUser.uid
        event.eventType = type
        event.timeStamp = Date()
        event.details = details
        event.success = success
        event.errorMessage = errorMessage
        
        coreDataManager.save()
        
        print("📊 Tracked event: \(type) for user \(currentUser.uid)")
        
        // Update user's last active date
        updateUserLastActive(userID: currentUser.uid)
    }
    
    // MARK: - User Metrics Management
    
    /// Ensures UserMetrics record exists for a user
    private func ensureUserMetricsExist(userID: String) {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UserMetrics> = UserMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)
        
        do {
            let existing = try context.fetch(request)
            if existing.isEmpty {
                // Create new user metrics
                let metrics = UserMetrics(context: context)
                metrics.id = UUID()
                metrics.userID = userID
                metrics.totalRoutes = 0
                metrics.totalAddresses = 0
                metrics.favoriteRoutes = 0
                metrics.lastActiveDate = Date()
                metrics.accountCreatedDate = Date()
                
                coreDataManager.save()
                print("✅ Created user metrics for \(userID)")
            }
        } catch {
            print("❌ Error checking user metrics: \(error)")
        }
    }
    
    /// Updates user's last active timestamp
    private func updateUserLastActive(userID: String) {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UserMetrics> = UserMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)
        
        do {
            let results = try context.fetch(request)
            if let userMetrics = results.first {
                userMetrics.lastActiveDate = Date()
                coreDataManager.save()
            }
        } catch {
            print("❌ Error updating last active: \(error)")
        }
    }
    
    /// Increments user's route count
    func incrementUserRouteCount() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UserMetrics> = UserMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", currentUser.uid)
        
        do {
            let results = try context.fetch(request)
            if let userMetrics = results.first {
                userMetrics.totalRoutes += 1
                coreDataManager.save()
                print("📈 Incremented route count for user")
            }
        } catch {
            print("❌ Error incrementing route count: \(error)")
        }
    }
    
    /// Increments user's address count
    func incrementUserAddressCount() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UserMetrics> = UserMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", currentUser.uid)
        
        do {
            let results = try context.fetch(request)
            if let userMetrics = results.first {
                userMetrics.totalAddresses += 1
                coreDataManager.save()
                print("📈 Incremented address count for user")
            }
        } catch {
            print("❌ Error incrementing address count: \(error)")
        }
    }
    
    // MARK: - System Metrics
    
    /// Records system performance metrics
    func recordSystemMetrics(apiResponseTime: Double, memoryUsage: Double) {
        let context = coreDataManager.viewContext
        let metrics = SystemMetrics(context: context)
        
        metrics.id = UUID()
        metrics.date = Date()
        metrics.apiResponseTime = apiResponseTime
        metrics.memoryUsage = memoryUsage
        metrics.crashCount = 0 // Will implement crash tracking later
        metrics.activeUsers = Int32(getCurrentActiveUserCount())
        
        coreDataManager.save()
        print("📊 Recorded system metrics")
    }
    
    // MARK: - Helper Methods
    
    /// Gets current app version
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    /// Gets device information
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.model) - iOS \(device.systemVersion)"
    }
    
    /// Gets count of currently active users (simplified)
    private func getCurrentActiveUserCount() -> Int {
        // Count users active in last 5 minutes
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UserMetrics> = UserMetrics.fetchRequest()
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        request.predicate = NSPredicate(format: "lastActiveDate >= %@", fiveMinutesAgo as NSDate)
        
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    // MARK: - Data Cleanup
    
    /// Cleans up old tracking data (call periodically)
    func cleanupOldData() {
        let context = coreDataManager.viewContext
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        
        // Clean up old app events (keep last 30 days)
        let eventRequest: NSFetchRequest<NSFetchRequestResult> = AppEvent.fetchRequest()
        eventRequest.predicate = NSPredicate(format: "timestamp < %@", thirtyDaysAgo as NSDate)
        
        do {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: eventRequest)
            try context.execute(deleteRequest)
            coreDataManager.save()
            print("🧹 Cleaned up old event data")
        } catch {
            print("❌ Error cleaning up old data: \(error)")
        }
    }
}
