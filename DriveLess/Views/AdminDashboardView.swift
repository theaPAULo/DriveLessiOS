//
//  AdminDashboardView.swift
//  DriveLess
//
//  Created by Paul Soni on 6/23/25.
//


//
//  AdminDashboardView.swift
//  DriveLess
//
//  Admin analytics dashboard with app metrics
//

import SwiftUI
import Firebase
import FirebaseAuth

struct AdminDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var usageTracker = UsageTrackingManager()
    @State private var isLoading = true
    @State private var dashboardData = AdminDashboardData()
    
    // Color theme matching app
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Header
                    adminHeaderView
                    
                    if isLoading {
                        // MARK: - Loading State
                        loadingView
                    } else {
                        // MARK: - Dashboard Content
                        VStack(spacing: 20) {
                            
                            // Quick Stats Overview
                            quickStatsView
                            
                            // Usage Analytics
                            usageAnalyticsView
                            
                            // User Analytics
                            userAnalyticsView
                            
                            // System Performance
                            systemPerformanceView
                            
                            // Admin Actions
                            adminActionsView
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryGreen)
                }
            }
        }
        .onAppear {
            loadDashboardData()
        }
    }
    
    // MARK: - Admin Header
    private var adminHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")  // <-- FIXED SYMBOL NAME
                    .font(.title2)
                    .foregroundColor(primaryGreen)
                
                VStack(alignment: .leading) {
                    Text("Admin Dashboard")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("DriveLess Analytics & Controls")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Admin badge
                Text("ADMIN")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(primaryGreen)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(primaryGreen)
            
            Text("Loading analytics...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Quick Stats Overview
    private var quickStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(primaryGreen)
                Text("Quick Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                
                StatCard(
                    icon: "person.3.fill",
                    title: "Total Users",
                    value: "\(dashboardData.totalUsers)",
                    subtitle: "Registered",
                    color: .blue
                )
                
                StatCard(
                    icon: "map.fill",
                    title: "Routes Today",
                    value: "\(dashboardData.routesToday)",
                    subtitle: "Calculated",
                    color: primaryGreen
                )
                
                StatCard(
                    icon: "calendar.circle.fill",
                    title: "This Week",
                    value: "\(dashboardData.routesThisWeek)",
                    subtitle: "Routes",
                    color: .orange
                )
                
                StatCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Errors",
                    value: "\(dashboardData.errorsToday)",
                    subtitle: "Today",
                    color: .red
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Usage Analytics
    private var usageAnalyticsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(primaryGreen)
                Text("Usage Analytics")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Daily Route Calculations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(dashboardData.routesToday)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(primaryGreen)
                }
                
                HStack {
                    Text("Weekly Total")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(dashboardData.routesThisWeek)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Monthly Total")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(dashboardData.routesThisMonth)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Divider()
                
                HStack {
                    Text("Average per User")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(String(format: "%.1f", dashboardData.averageRoutesPerUser))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - User Analytics
    private var userAnalyticsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(primaryGreen)
                Text("User Analytics")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Total Registered Users")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(dashboardData.totalUsers)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(primaryGreen)
                }
                
                HStack {
                    Text("New Users This Week")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(dashboardData.newUsersThisWeek)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Active Users Today")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(dashboardData.activeUsersToday)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - System Performance
    private var systemPerformanceView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gauge.high")
                    .foregroundColor(primaryGreen)
                Text("System Performance")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Errors Today")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(dashboardData.errorsToday)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(dashboardData.errorsToday > 0 ? .red : primaryGreen)
                }
                
                HStack {
                    Text("Success Rate")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(dashboardData.successRate, specifier: "%.1f")%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(dashboardData.successRate > 95.0 ? primaryGreen : .orange)
                }
                
                HStack {
                    Text("App Version")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("1.0")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Admin Actions
    private var adminActionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gear.circle.fill")
                    .foregroundColor(primaryGreen)
                Text("Admin Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                
                Button(action: refreshData) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Data")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(primaryGreen)
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                Button(action: exportAnalytics) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Analytics")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(primaryGreen)
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                Button(action: viewDetailedLogs) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("View Detailed Logs")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(primaryGreen)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Data Loading and Actions
    
    private func loadDashboardData() {
        print("📊 Loading admin dashboard data...")
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Load real data from Core Data and other sources
            dashboardData = AdminAnalyticsService.shared.getDashboardData()
            
            withAnimation(.easeInOut(duration: 0.5)) {
                isLoading = false
            }
            
            print("✅ Dashboard data loaded")
        }
    }
    
    private func refreshData() {
        print("🔄 Refreshing admin dashboard data...")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isLoading = true
        loadDashboardData()
    }
    
    private func exportAnalytics() {
        print("📤 Exporting analytics data...")
        // TODO: Implement analytics export functionality
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func viewDetailedLogs() {
        print("📋 Viewing detailed logs...")
        // TODO: Implement detailed logs view
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Dashboard Data Model
struct AdminDashboardData {
    var totalUsers: Int = 0
    var routesToday: Int = 0
    var routesThisWeek: Int = 0
    var routesThisMonth: Int = 0
    var newUsersThisWeek: Int = 0
    var activeUsersToday: Int = 0
    var errorsToday: Int = 0
    var successRate: Double = 0.0
    var averageRoutesPerUser: Double = 0.0
}

// MARK: - Stat Card Component
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    AdminDashboardView()
}
