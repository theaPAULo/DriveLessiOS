//
//  ContentView.swift
//  DriveLess
//
//  Clean home screen with Google authentication
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    // Create instances of our managers
    @StateObject private var locationManager = LocationManager()
    @StateObject private var authManager = AuthenticationManager()
    @EnvironmentObject var themeManager: ThemeManager  // ADD THIS LINE
    
    // MARK: - Color Theme (Earthy)
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2) // Dark forest green
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2) // Rich brown
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7) // Soft green
    
    var body: some View {
        NavigationStack {
            Group {
                if authManager.isSignedIn {
                    // User is signed in - show main app
                    MainTabView(locationManager: locationManager, authManager: authManager, themeManager: themeManager)
                } else {
                    // User is not signed in - show sign-in screen
                    signInView
                }
            }
        }
        .onAppear {
            // Silently request location permission
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestLocationPermission()
            }
        }
    }
    
    // MARK: - Sign-In View
    private var signInView: some View {
        VStack(spacing: 0) {
            
            // MARK: - Hero Section
            VStack(spacing: 32) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: 16) {
                    // Logo placeholder (we'll add the actual logo later)
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [primaryGreen, lightGreen]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "map.fill")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Text("DriveLess")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(primaryGreen)
                    
                    Text("Drive Less, Save Time")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Features Preview
                VStack(spacing: 20) {
                    featureRow(
                        icon: "map.circle.fill",
                        title: "Smart Route Planning"
                    )
                    
                    featureRow(
                        icon: "clock.fill",
                        title: "Real-Time Traffic"
                    )
                    
                    featureRow(
                        icon: "location.circle.fill",
                        title: "Save Time & Fuel"
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            
            // MARK: - Authentication Section (Google Only)
            VStack(spacing: 20) {
                
                // Show error message if there is one
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                }
                
                Text("Sign in to start planning routes")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    // Google Sign-In Button (Working!)
                    Button(action: {
                        // Add haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        // Trigger Google Sign-In
                        authManager.signInWithGoogle()
                    }) {
                        HStack(spacing: 12) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "globe")
                                    .font(.system(size: 18, weight: .medium))
                            }
                            
                            Text(authManager.isLoading ? "Signing in..." : "Continue with Google")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [primaryGreen, accentBrown]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .disabled(authManager.isLoading)
                    .opacity(authManager.isLoading ? 0.7 : 1.0)
                    
                    // Coming Soon Message
                    HStack(spacing: 8) {
                        Image(systemName: "applelogo")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("Apple Sign-In coming soon!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    lightGreen.opacity(0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .animation(.easeInOut(duration: 0.3), value: authManager.isLoading)
        .animation(.easeInOut(duration: 0.3), value: authManager.errorMessage)
    }
    
    // MARK: - Feature Row Component
    private func featureRow(icon: String, title: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(primaryGreen)
                .frame(width: 32)
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
