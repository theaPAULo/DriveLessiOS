//
//  FirestoreProductionTest.swift
//  DriveLess
//
//  Created by Paul Soni on 6/28/25.
//


//
//  FirestoreProductionTest.swift
//  DriveLess
//
//  Test Firestore production setup with security rules
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirestoreProductionTest {
    private let db = Firestore.firestore()
    
    func testProductionSetup() {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ No authenticated user for Firestore test")
            return
        }
        
        print("🔥 Testing Firestore Production Setup...")
        print("🔐 User ID: \(currentUser.uid)")
        
        // Test 1: Write to user's own document (should succeed)
        testUserDataWrite(userID: currentUser.uid)
        
        // Test 2: Write to analytics (should succeed)
        testAnalyticsWrite()
        
        // Test 3: Read analytics as admin (should succeed if you're admin)
        testAdminAnalyticsRead()
        
        // Test 4: Create a route (should succeed)
        testRouteCreation(userID: currentUser.uid)
    }
    
    private func testUserDataWrite(userID: String) {
        let userData: [String: Any] = [
            "email": Auth.auth().currentUser?.email ?? "",
            "lastActive": Date(),
            "testConnection": true
        ]
        
        db.collection("users").document(userID).setData(userData, merge: true) { error in
            if let error = error {
                print("❌ User data write failed: \(error)")
            } else {
                print("✅ User data write successful!")
            }
        }
    }
    
    private func testAnalyticsWrite() {
        let analyticsData: [String: Any] = [
            "testEvent": true,
            "timestamp": Date(),
            "userCount": 1
        ]
        
        db.collection("analytics").document("test").setData(analyticsData, merge: true) { error in
            if let error = error {
                print("❌ Analytics write failed: \(error)")
            } else {
                print("✅ Analytics write successful!")
            }
        }
    }
    
    private func testAdminAnalyticsRead() {
        db.collection("analytics").document("test").getDocument { document, error in
            if let error = error {
                print("❌ Admin analytics read failed: \(error)")
                print("   (This is expected if you're not configured as admin)")
            } else if let document = document, document.exists {
                print("✅ Admin analytics read successful!")
                print("🔐 You have admin access")
            } else {
                print("⚠️ Analytics document doesn't exist yet")
            }
        }
    }
    
    private func testRouteCreation(userID: String) {
        let routeData: [String: Any] = [
            "userID": userID,
            "stops": ["Home", "Store", "Work"],
            "createdAt": Date(),
            "totalDistance": "15.2 miles",
            "success": true
        ]
        
        db.collection("routes").addDocument(data: routeData) { error in
            if let error = error {
                print("❌ Route creation failed: \(error)")
            } else {
                print("✅ Route creation successful!")
            }
        }
    }
    
    // Test admin functionality
    func testAdminDashboard() {
        print("🔐 Testing admin dashboard access...")
        
        // Try to read all users (admin only)
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Admin user list failed: \(error)")
                print("   Check that your UID is in the admin list")
            } else {
                print("✅ Admin user list successful! Found \(snapshot?.documents.count ?? 0) users")
            }
        }
        
        // Try to read all routes (admin only)
        db.collection("routes").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Admin route list failed: \(error)")
            } else {
                print("✅ Admin route list successful! Found \(snapshot?.documents.count ?? 0) routes")
            }
        }
    }
}