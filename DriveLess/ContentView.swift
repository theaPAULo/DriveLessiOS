//
//  ContentView.swift
//  DriveLess
//
//  Clean home screen with sign-in only options
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    // Create an instance of our LocationManager
    @StateObject private var locationManager = LocationManager()
    
    // MARK: - Color Theme (Earthy)
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2) // Dark forest green
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2) // Rich brown
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7) // Soft green
    
    var body: some View {
        NavigationView {
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
                    
                    // Features Preview (minimized - no sub-text)
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
                
                // MARK: - Sign-In Section (Only Options)
                VStack(spacing: 20) {
                    
                    Text("Sign in to start planning routes")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 16) {
                        // Apple Sign-In (Primary)
                        NavigationLink(destination: RouteInputView(locationManager: locationManager)) {
                            HStack(spacing: 12) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 18, weight: .medium))
                                
                                Text("Continue with Apple")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.black)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            // Add haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        })
                        
                        // Google Sign-In
                        NavigationLink(destination: RouteInputView(locationManager: locationManager)) {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.system(size: 18, weight: .medium))
                                
                                Text("Continue with Google")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            // Add haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        })
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
            .navigationBarHidden(true) // This hides the navigation bar completely
        }
        .onAppear {
            // Silently request location permission
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestLocationPermission()
            }
        }
    }
    
    // MARK: - Feature Row Component (Simplified)
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
