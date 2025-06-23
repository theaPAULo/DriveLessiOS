//
//  AdminAuthView.swift
//  DriveLess
//
//  Admin authentication and dashboard access
//

import SwiftUI
import FirebaseAuth

struct AdminAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var adminPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showingAdminDashboard: Bool = false
    
    // Updated admin password
    private let validAdminPassword = "DriveMehn628!"
    
    // Color theme matching app
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // MARK: - Admin Header
                VStack(spacing: 16) {
                    // Admin icon
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [primaryGreen, accentBrown]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Text("Admin Access")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Enter admin credentials to access dashboard")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // MARK: - Password Input
                VStack(spacing: 20) {
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Admin Password")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("Enter admin password", text: $adminPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onSubmit {
                                if !adminPassword.isEmpty {
                                    authenticateAdmin()
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                    
                    // Login button
                    Button(action: authenticateAdmin) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "lock.shield")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text(isLoading ? "Authenticating..." : "Access Admin Panel")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [primaryGreen, accentBrown]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: primaryGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(adminPassword.isEmpty || isLoading)
                    .opacity(adminPassword.isEmpty || isLoading ? 0.6 : 1.0)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // MARK: - Security Note
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Secure admin access only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Admin status will be permanent for this Firebase account")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Admin Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .fullScreenCover(isPresented: $showingAdminDashboard) {
                AdminDashboardView()
            }
        }
    }
    
    // MARK: - Authentication Logic
    private func authenticateAdmin() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isLoading = true
        errorMessage = nil
        
        // Simulate authentication delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if adminPassword == validAdminPassword {
                // Successful authentication - Make this user a permanent admin
                print("🔐 Admin authentication successful")
                
                // Get current Firebase user ID
                if let currentUser = Auth.auth().currentUser {
                    let userID = currentUser.uid
                    print("🔐 Setting admin status for user: \(userID)")
                    
                    // Store admin user ID persistently (this makes them admin forever)
                    var adminUsers = UserDefaults.standard.stringArray(forKey: "driveless_admin_users") ?? []
                    if !adminUsers.contains(userID) {
                        adminUsers.append(userID)
                        UserDefaults.standard.set(adminUsers, forKey: "driveless_admin_users")
                        print("✅ User \(userID) added to admin list")
                    }
                    
                    // Also set the general admin mode flag for immediate effect
                    UserDefaults.standard.set(true, forKey: "driveless_admin_mode")
                    UserDefaults.standard.set(Date(), forKey: "driveless_admin_login_time")
                    
                } else {
                    print("⚠️ No Firebase user found, using fallback admin mode")
                    // Fallback for non-authenticated users (shouldn't happen in production)
                    UserDefaults.standard.set(true, forKey: "driveless_admin_mode")
                }
                
                // Show success feedback
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                
                // Navigate to admin dashboard
                isLoading = false

                // Small delay to ensure UI is ready, then show dashboard
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showingAdminDashboard = true
                }

                // Don't auto-dismiss - let user close dashboard manually
                // dismiss() // REMOVED - this was causing the conflict
                
            } else {
                // Failed authentication
                print("❌ Admin authentication failed")
                
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
                
                errorMessage = "Invalid admin password. Please try again."
                adminPassword = "" // Clear password field
                isLoading = false
            }
        }
    }
}

#Preview {
    AdminAuthView()
}
