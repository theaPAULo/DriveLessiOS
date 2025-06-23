//
//  UsageTrackingManager.swift
//  DriveLess
//
//  Created by Paul Soni on 6/23/25.
//


//
//  UsageTrackingManager.swift
//  DriveLess
//
//  Manages daily usage limits and tracking for route calculations
//

import Foundation
import CoreData
import FirebaseAuth

class UsageTrackingManager: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    
    // Published properties that SwiftUI views can observe
    @Published var todayUsage: Int = 0
    @Published var hasExceededLimit: Bool = false
    
    // MARK: - Constants
    static let DAILY_LIMIT = 25 // Free routes per day
    static let ADMIN_USER_ID = "admin_bypass" // Special admin identifier
    
    init() {
        loadTodayUsage()
    }
    
    // MARK: - Public Methods
    
    /// Checks if the current user can perform another route calculation
    /// - Returns: True if user is under limit or is admin, false otherwise
    func canPerformRouteCalculation() -> Bool {
        // Admin users bypass limits
        if isAdminUser() {
            print("🔐 Admin user - bypassing usage limits")
            return true
        }
        
        // Check if under daily limit
        let underLimit = todayUsage < Self.DAILY_LIMIT
        print("📊 Usage check: \(todayUsage)/\(Self.DAILY_LIMIT) - Can perform: \(underLimit)")
        return underLimit
    }
    
    /// Increments the usage counter for today
    /// Only increments for non-admin users
    func incrementUsage() {
        // Don't increment for admin users
        if isAdminUser() {
            print("🔐 Admin user - not incrementing usage")
            return
        }
        
        let context = coreDataManager.viewContext
        let today = startOfToday()
        let currentUserID = getCurrentUserID()
        
        // Find or create today's usage record
        let usageRecord = findOrCreateTodayUsage(context: context, date: today, userID: currentUserID)
        
        // Increment the counter
        usageRecord.routeCalculations += 1
        
        // Save changes
        coreDataManager.save()
        
        // Update published properties
        todayUsage = Int(usageRecord.routeCalculations)
        hasExceededLimit = todayUsage >= Self.DAILY_LIMIT
        
        print("📈 Usage incremented to: \(todayUsage)/\(Self.DAILY_LIMIT)")
    }
    
    /// Gets the remaining routes for today
    /// - Returns: Number of routes remaining (always 999+ for admin)
    func getRemainingRoutes() -> Int {
        if isAdminUser() {
            return 999 // Show unlimited for admin
        }
        
        return max(0, Self.DAILY_LIMIT - todayUsage)
    }
    
    /// Gets usage percentage (0.0 to 1.0)
    /// - Returns: Usage as percentage of daily limit
    func getUsagePercentage() -> Double {
        if isAdminUser() {
            return 0.0 // Always show 0% for admin
        }
        
        return min(1.0, Double(todayUsage) / Double(Self.DAILY_LIMIT))
    }
    
    // MARK: - Private Methods
    
    /// Loads today's usage from Core Data
    public func loadTodayUsage() {
        let context = coreDataManager.viewContext
        let today = startOfToday()
        let currentUserID = getCurrentUserID()
        
        // Create fetch request for today's usage
        let request: NSFetchRequest<UsageTracking> = UsageTracking.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@ AND userID == %@", today as NSDate, currentUserID)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let todayRecord = results.first {
                todayUsage = Int(todayRecord.routeCalculations)
                hasExceededLimit = todayUsage >= Self.DAILY_LIMIT
                print("📊 Loaded today's usage: \(todayUsage)/\(Self.DAILY_LIMIT)")
            } else {
                // No record for today, start fresh
                todayUsage = 0
                hasExceededLimit = false
                print("📊 No usage record for today, starting fresh")
            }
        } catch {
            print("❌ Failed to load today's usage: \(error)")
            todayUsage = 0
            hasExceededLimit = false
        }
    }
    
    /// Finds existing usage record for today or creates a new one
    private func findOrCreateTodayUsage(context: NSManagedObjectContext, date: Date, userID: String) -> UsageTracking {
        // Try to find existing record
        let request: NSFetchRequest<UsageTracking> = UsageTracking.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@ AND userID == %@", date as NSDate, userID)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let existingRecord = results.first {
                return existingRecord
            }
        } catch {
            print("❌ Error fetching usage record: \(error)")
        }
        
        // Create new record if none exists
        let newRecord = UsageTracking(context: context)
        newRecord.id = UUID()
        newRecord.date = date
        newRecord.userID = userID
        newRecord.routeCalculations = 0
        
        print("📊 Created new usage record for \(userID) on \(date)")
        return newRecord
    }
    
    /// Gets the start of today (midnight) for consistent date comparison
    private func startOfToday() -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
    }
    
    /// Gets current user ID for tracking (Firebase Auth ID or guest)
    private func getCurrentUserID() -> String {
        if let user = Auth.auth().currentUser {
            return user.uid
        }
        return "guest_user" // Fallback for non-authenticated users
    }
    
    /// Checks if current user is a permanent admin
    private func isAdminUser() -> Bool {
        // Check if admin mode is already set
        if UserDefaults.standard.bool(forKey: "driveless_admin_mode") {
            return true
        }
        
        // Check if current Firebase user is in the admin list
        if let currentUser = Auth.auth().currentUser {
            let userID = currentUser.uid
            
            // List of admin Firebase UIDs - keep this in sync with ProfileView
            let adminUIDs = [
                "X4bKhg8XgfUAvAOgK97eMweHCz33", // Your current UID
                // Add other admin UIDs here as needed
            ]
            
            if adminUIDs.contains(userID) {
                print("🔐 User \(userID) is a permanent admin")
                // Set admin mode flag for this session
                UserDefaults.standard.set(true, forKey: "driveless_admin_mode")
                return true
            }
        }
        
        return false
    }
}
