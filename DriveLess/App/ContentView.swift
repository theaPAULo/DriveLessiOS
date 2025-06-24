//
//  ContentView.swift
//  DriveLess
//
//  Clean home screen with Google AND Apple authentication
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    // Create instances of our managers
    @StateObject private var locationManager = LocationManager()
    @StateObject private var authManager = AuthenticationManager()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticManager: HapticManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    // MARK: - Color Theme (Earthy)
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2) // Dark forest green
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2) // Rich brown
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7) // Soft green
    
    var body: some View {
        NavigationStack {
            Group {
                if authManager.isSignedIn {
                    // User is signed in - show main app
                    MainTabView(locationManager: locationManager, authManager: authManager, themeManager: themeManager, hapticManager: hapticManager, settingsManager: settingsManager)
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
            
            // MARK: - Authentication Section (UPDATED with both Google and Apple)
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
                    // Apple Sign-In Button (NEW - Primary option)
                    Button(action: {
                        // Add haptic feedback
                        hapticManager.buttonTap()
                        
                        // Trigger Apple Sign-In
                        authManager.signInWithApple()
                    }) {
                        HStack(spacing: 12) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 18, weight: .medium))
                            }
                            
                            Text(authManager.isLoading ? "Signing in..." : "Continue with Apple")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black) // Apple's standard black background
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .disabled(authManager.isLoading)
                    .opacity(authManager.isLoading ? 0.7 : 1.0)
                    
                    // Divider with "OR"
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                        
                        Text("OR")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                    .padding(.vertical, 8)
                    
                    // Google Sign-In Button (UPDATED - Secondary option)
                    Button(action: {
                        // Add haptic feedback
                        hapticManager.buttonTap()
                        
                        // Trigger Google Sign-In
                        authManager.signInWithGoogle()
                    }) {
                        HStack(spacing: 12) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: primaryGreen))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "globe")
                                    .font(.system(size: 18, weight: .medium))
                            }
                            
                            Text(authManager.isLoading ? "Signing in..." : "Continue with Google")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(primaryGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(primaryGreen, lineWidth: 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                )
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .disabled(authManager.isLoading)
                    .opacity(authManager.isLoading ? 0.7 : 1.0)
                    
                    // Privacy Notice (NEW - Required for Apple Sign-In)
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("Your data is secure and private")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Sign in to sync your routes across devices and access advanced features")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
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
