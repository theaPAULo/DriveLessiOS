//
//  FirestoreAnalyticsService.swift
//  DriveLess
//
//  Created by Paul Soni on 6/28/25.
//


//
//  FirestoreAnalyticsService.swift
//  DriveLess
//
//  Handles centralized user analytics in Firestore for admin dashboard
//  CREATE THIS FILE: Right-click Services folder → New File → Swift File → Name: FirestoreAnalyticsService.swift
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirestoreAnalyticsService: ObservableObject {
    static let shared = FirestoreAnalyticsService()
    private let db = Firestore.firestore()
    
    // Published properties for real-time dashboard updates
    @Published var totalUsers: Int = 0
    @Published var activeUsersToday: Int = 0
    @Published var routesToday: Int = 0
    @Published var isConnected: Bool = false
    
    private init() {
        print("🔥 FirestoreAnalyticsService initialized")
        startRealtimeListeners()
    }
    
    // MARK: - User Tracking
    
    /// Records user sign-in and creates/updates user profile
    func trackUserSignIn(signInMethod: String) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ Cannot track sign-in - no authenticated user")
            return
        }
        
        let userID = currentUser.uid
        let now = Date()
        
        // Update user profile
        let userProfile: [String: Any] = [
            "email": currentUser.email ?? "",
            "displayName": currentUser.displayName ?? "",
            "signInMethod": signInMethod,
            "lastActive": now,
            "updatedAt": now
        ]
        
        // Set merge: true to update existing fields or create if doesn't exist
        db.collection("users").document(userID).setData(userProfile, merge: true) { error in
            if let error = error {
                print("❌ Error updating user profile: \(error)")
            } else {
                print("✅ User profile updated for \(userID)")
            }
        }
        
        // Record sign-in session
        let sessionData: [String: Any] = [
            "signInTime": now,
            "signInMethod": signInMethod,
            "deviceInfo": getDeviceInfo(),
            "appVersion": getAppVersion()
        ]
        
        db.collection("users").document(userID).collection("sessions").addDocument(data: sessionData) { error in
            if let error = error {
                print("❌ Error recording session: \(error)")
            } else {
                print("✅ Sign-in session recorded")
            }
        }
        
        // Update daily analytics
        updateDailyAnalytics(increment: "totalSessions")
        
        // Track sign-in event
        trackEvent(type: "user_sign_in", details: signInMethod, success: true)
    }
    
    /// Records user sign-out
    func trackUserSignOut() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        // Update last active time
        let userRef = db.collection("users").document(currentUser.uid)
        userRef.updateData([
            "lastActive": Date()
        ]) { error in
            if let error = error {
                print("❌ Error updating last active: \(error)")
            } else {
                print("✅ Updated last active on sign-out")
            }
        }
        
        // Track sign-out event
        trackEvent(type: "user_sign_out", details: nil, success: true)
    }
    
    // MARK: - Event Tracking
    
    /// Tracks any app event for analytics
    func trackEvent(type: String, details: String? = nil, success: Bool = true, errorMessage: String? = nil) {
        guard let currentUser = Auth.auth().currentUser else {
            print("⚠️ Cannot track event - no authenticated user")
            return
        }
        
        let eventData: [String: Any] = [
            "type": type,
            "timestamp": Date(),
            "details": details ?? "",
            "success": success,
            "errorMessage": errorMessage ?? "",
            "appVersion": getAppVersion()
        ]
        
        // Add to user's events subcollection
        db.collection("users").document(currentUser.uid).collection("events").addDocument(data: eventData) { error in
            if let error = error {
                print("❌ Error tracking event: \(error)")
            } else {
                print("📊 Event tracked: \(type)")
            }
        }
        
        // Update daily analytics for errors
        if !success {
            updateDailyAnalytics(increment: "errors")
        }
    }
    
    /// Records route calculation
    func trackRouteCalculation(stops: [String], totalDistance: String, totalTime: String, success: Bool) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let routeData: [String: Any] = [
            "userID": currentUser.uid,
            "createdAt": Date(),
            "stops": stops,
            "totalDistance": totalDistance,
            "totalTime": totalTime,
            "success": success
        ]
        
        // Add to global routes collection
        db.collection("routes").addDocument(data: routeData) { error in
            if let error = error {
                print("❌ Error recording route: \(error)")
            } else {
                print("✅ Route calculation recorded")
                
                // Update daily analytics
                if success {
                    self.updateDailyAnalytics(increment: "totalRoutes")
                }
            }
        }
        
        // Track as event
        trackEvent(
            type: "route_calculated", 
            details: "\(stops.count) stops", 
            success: success,
            errorMessage: success ? nil : "Route calculation failed"
        )
    }
    
    // MARK: - Analytics Aggregation
    
    /// Updates daily analytics counters
    private func updateDailyAnalytics(increment field: String, by amount: Int = 1) {
        let today = getTodayDateString()
        let dailyRef = db.collection("analytics").document("daily").collection("days").document(today)
        
        dailyRef.updateData([
            field: FieldValue.increment(Int64(amount)),
            "lastUpdated": Date()
        ]) { error in
            if let error = error {
                // Document might not exist, create it
                dailyRef.setData([
                    field: amount,
                    "date": today,
                    "lastUpdated": Date()
                ], merge: true)
            }
        }
    }
    
    // MARK: - Real-time Dashboard Data
    
    /// Sets up real-time listeners for dashboard
    private func startRealtimeListeners() {
        // Listen to today's analytics
        let today = getTodayDateString()
        let todayRef = db.collection("analytics").document("daily").collection("days").document(today)
        
        todayRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error listening to today's analytics: \(error)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("📊 No analytics data for today yet")
                return
            }
            
            DispatchQueue.main.async {
                self?.routesToday = data["totalRoutes"] as? Int ?? 0
                self?.isConnected = true
                print("📊 Real-time update: \(self?.routesToday ?? 0) routes today")
            }
        }
        
        // Listen to total user count
        db.collection("users").addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error listening to users: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                self?.totalUsers = snapshot?.documents.count ?? 0
                print("📊 Real-time update: \(self?.totalUsers ?? 0) total users")
            }
        }
        
        // Listen to active users today
        let startOfDay = Calendar.current.startOfDay(for: Date())
        db.collection("users")
            .whereField("lastActive", isGreaterThan: startOfDay)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error listening to active users: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.activeUsersToday = snapshot?.documents.count ?? 0
                    print("📊 Real-time update: \(self?.activeUsersToday ?? 0) active users today")
                }
            }
    }
    
    // MARK: - Dashboard Data API
    
    /// Gets comprehensive dashboard data from Firestore
    func getDashboardData() async -> AdminDashboardData {
        var dashboardData = AdminDashboardData()
        
        do {
            // Get today's analytics
            let today = getTodayDateString()
            let todayDoc = try await db.collection("analytics").document("daily").collection("days").document(today).getDocument()
            
            if let todayData = todayDoc.data() {
                dashboardData.routesToday = todayData["totalRoutes"] as? Int ?? 0
                dashboardData.errorsToday = todayData["errors"] as? Int ?? 0
            }
            
            // Get this week's routes
            dashboardData.routesThisWeek = try await getRoutesThisWeek()
            
            // Get this month's routes  
            dashboardData.routesThisMonth = try await getRoutesThisMonth()
            
            // Get user statistics
            let usersSnapshot = try await db.collection("users").getDocuments()
            dashboardData.totalUsers = usersSnapshot.documents.count
            
            // Get active users today
            let startOfDay = Calendar.current.startOfDay(for: Date())
            let activeUsersSnapshot = try await db.collection("users")
                .whereField("lastActive", isGreaterThan: startOfDay)
                .getDocuments()
            dashboardData.activeUsersToday = activeUsersSnapshot.documents.count
            
            // Get new users this week
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let newUsersSnapshot = try await db.collection("users")
                .whereField("createdAt", isGreaterThan: weekAgo)
                .getDocuments()
            dashboardData.newUsersThisWeek = newUsersSnapshot.documents.count
            
            // Calculate success rate
            let totalRoutes = dashboardData.routesToday
            let errors = dashboardData.errorsToday
            dashboardData.successRate = totalRoutes > 0 ? Double(totalRoutes - errors) / Double(totalRoutes) * 100.0 : 100.0
            
            // Calculate average routes per user
            dashboardData.averageRoutesPerUser = dashboardData.totalUsers > 0 ? 
                Double(try await getTotalAllTimeRoutes()) / Double(dashboardData.totalUsers) : 0.0
            
            print("📊 Firestore dashboard data loaded: \(dashboardData.totalUsers) users, \(dashboardData.routesToday) routes today")
            
        } catch {
            print("❌ Error loading dashboard data: \(error)")
        }
        
        return dashboardData
    }
    
    // MARK: - Helper Methods
    
    private func getRoutesThisWeek() async throws -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let snapshot = try await db.collection("routes")
            .whereField("createdAt", isGreaterThan: weekAgo)
            .getDocuments()
        return snapshot.documents.count
    }
    
    private func getRoutesThisMonth() async throws -> Int {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let snapshot = try await db.collection("routes")
            .whereField("createdAt", isGreaterThan: monthAgo)
            .getDocuments()
        return snapshot.documents.count
    }
    
    private func getTotalAllTimeRoutes() async throws -> Int {
        let snapshot = try await db.collection("routes").getDocuments()
        return snapshot.documents.count
    }
    
    private func getTodayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.model) - iOS \(device.systemVersion)"
    }
}