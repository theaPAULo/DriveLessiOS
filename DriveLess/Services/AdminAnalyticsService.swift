//
//  AdminAnalyticsService.swift
//  DriveLess
//
//  Created by Paul Soni on 6/23/25.
//


//
//  AdminAnalyticsService.swift
//  DriveLess
//
//  Analytics service for admin dashboard - provides real data from Core Data
//

import Foundation
import CoreData
import FirebaseAuth

class AdminAnalyticsService: ObservableObject {
    static let shared = AdminAnalyticsService()
    private let coreDataManager = CoreDataManager.shared
    
    private init() {}
    
    // MARK: - Main Dashboard Data Function
    
    /// Gets comprehensive dashboard data from Core Data and other sources
    /// - Returns: AdminDashboardData with real analytics
    func getDashboardData() -> AdminDashboardData {
        print("📊 AdminAnalyticsService: Fetching dashboard data...")
        
        var data = AdminDashboardData()
        
        // Get usage statistics
        data.routesToday = getRoutesToday()
        data.routesThisWeek = getRoutesThisWeek()
        data.routesThisMonth = getRoutesThisMonth()
        
        // Get user statistics
        data.totalUsers = getTotalUsers()
        data.newUsersThisWeek = getNewUsersThisWeek()
        data.activeUsersToday = getActiveUsersToday()
        
        // Calculate performance metrics
        data.errorsToday = getErrorsToday()
        data.successRate = getSuccessRate()
        data.averageRoutesPerUser = getAverageRoutesPerUser()
        
        print("📊 Dashboard data compiled: \(data.routesToday) routes today, \(data.totalUsers) total users")
        
        return data
    }
    
    // MARK: - Usage Analytics
    
    /// Gets total route calculations for today
    private func getRoutesToday() -> Int {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UsageTracking> = UsageTracking.fetchRequest()
        
        // Get today's date range
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", today as NSDate, tomorrow as NSDate)
        
        do {
            let results = try context.fetch(request)
            let totalRoutes = results.reduce(0) { $0 + Int($1.routeCalculations) }
            print("📊 Routes today: \(totalRoutes)")
            return totalRoutes
        } catch {
            print("❌ Error fetching today's routes: \(error)")
            return 0
        }
    }
    
    /// Gets total route calculations for this week
    private func getRoutesThisWeek() -> Int {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UsageTracking> = UsageTracking.fetchRequest()
        
        // Get this week's date range
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", weekStart as NSDate, weekEnd as NSDate)
        
        do {
            let results = try context.fetch(request)
            let totalRoutes = results.reduce(0) { $0 + Int($1.routeCalculations) }
            print("📊 Routes this week: \(totalRoutes)")
            return totalRoutes
        } catch {
            print("❌ Error fetching this week's routes: \(error)")
            return 0
        }
    }
    
    /// Gets total route calculations for this month
    private func getRoutesThisMonth() -> Int {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UsageTracking> = UsageTracking.fetchRequest()
        
        // Get this month's date range
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", monthStart as NSDate, monthEnd as NSDate)
        
        do {
            let results = try context.fetch(request)
            let totalRoutes = results.reduce(0) { $0 + Int($1.routeCalculations) }
            print("📊 Routes this month: \(totalRoutes)")
            return totalRoutes
        } catch {
            print("❌ Error fetching this month's routes: \(error)")
            return 0
        }
    }
    
    /// Gets total number of unique users who have used the app
    private func getTotalUsers() -> Int {
        // Use the manual method which is more reliable
        return getTotalUsersManual()
    }

    /// Manual method for counting unique users (more reliable than dictionary result type)
    private func getTotalUsersManual() -> Int {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UsageTracking> = UsageTracking.fetchRequest()
        
        do {
            let results = try context.fetch(request)
            let uniqueUserIDs = Set(results.compactMap { $0.userID })
            print("📊 Total unique users: \(uniqueUserIDs.count)")
            return uniqueUserIDs.count
        } catch {
            print("❌ Error in user count: \(error)")
            return 0
        }
    }
    
    /// Gets number of new users this week (users who first appeared this week)
    private func getNewUsersThisWeek() -> Int {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UsageTracking> = UsageTracking.fetchRequest()
        
        // Get this week's date range
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", weekStart as NSDate, weekEnd as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let thisWeekResults = try context.fetch(request)
            let thisWeekUsers = Set(thisWeekResults.compactMap { $0.userID })
            
            // Get all users before this week
            let beforeWeekRequest: NSFetchRequest<UsageTracking> = UsageTracking.fetchRequest()
            beforeWeekRequest.predicate = NSPredicate(format: "date < %@", weekStart as NSDate)
            
            let beforeWeekResults = try context.fetch(beforeWeekRequest)
            let beforeWeekUsers = Set(beforeWeekResults.compactMap { $0.userID })
            
            // New users = users this week who weren't there before
            let newUsers = thisWeekUsers.subtracting(beforeWeekUsers)
            print("📊 New users this week: \(newUsers.count)")
            return newUsers.count
            
        } catch {
            print("❌ Error fetching new users this week: \(error)")
            return 0
        }
    }
    
    /// Gets number of users who used the app today
    private func getActiveUsersToday() -> Int {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UsageTracking> = UsageTracking.fetchRequest()
        
        // Get today's date range
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", today as NSDate, tomorrow as NSDate)
        
        do {
            let results = try context.fetch(request)
            let uniqueActiveUsers = Set(results.compactMap { $0.userID })
            print("📊 Active users today: \(uniqueActiveUsers.count)")
            return uniqueActiveUsers.count
        } catch {
            print("❌ Error fetching active users today: \(error)")
            return 0
        }
    }
    
    // MARK: - Performance Analytics
    
    /// Gets number of errors today (placeholder - we'll enhance this)
    private func getErrorsToday() -> Int {
        // For now, return a mock value
        // TODO: Implement error tracking in future updates
        let mockErrors = Int.random(in: 0...3)
        print("📊 Errors today (mock): \(mockErrors)")
        return mockErrors
    }
    
    /// Calculates success rate (placeholder - we'll enhance this)
    private func getSuccessRate() -> Double {
        let routesToday = getRoutesToday()
        let errorsToday = getErrorsToday()
        
        guard routesToday > 0 else { return 100.0 }
        
        let successfulRoutes = routesToday - errorsToday
        let successRate = (Double(successfulRoutes) / Double(routesToday)) * 100.0
        
        print("📊 Success rate: \(successRate)%")
        return max(0.0, successRate)
    }
    
    /// Calculates average routes per user
    private func getAverageRoutesPerUser() -> Double {
        let totalUsers = getTotalUsers()
        let totalRoutes = getAllTimeRoutes()
        
        guard totalUsers > 0 else { return 0.0 }
        
        let average = Double(totalRoutes) / Double(totalUsers)
        print("📊 Average routes per user: \(average)")
        return average
    }
    
    /// Gets total routes ever calculated
    private func getAllTimeRoutes() -> Int {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UsageTracking> = UsageTracking.fetchRequest()
        
        do {
            let results = try context.fetch(request)
            let totalRoutes = results.reduce(0) { $0 + Int($1.routeCalculations) }
            print("📊 All-time routes: \(totalRoutes)")
            return totalRoutes
        } catch {
            print("❌ Error fetching all-time routes: \(error)")
            return 0
        }
    }
    
    // MARK: - Additional Analytics Methods
    
    /// Gets usage data for the last 7 days (for future charts)
    func getWeeklyUsageData() -> [DailyUsage] {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UsageTracking> = UsageTracking.fetchRequest()
        
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: now)!
        
        request.predicate = NSPredicate(format: "date >= %@", weekAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let results = try context.fetch(request)
            
            // Group by day
            var dailyData: [Date: Int] = [:]
            
            for result in results {
                if let date = result.date {
                    let dayStart = calendar.startOfDay(for: date)
                    dailyData[dayStart, default: 0] += Int(result.routeCalculations)
                }
            }
            
            // Convert to array format
            var weeklyUsage: [DailyUsage] = []
            for i in 0...6 {
                let day = calendar.date(byAdding: .day, value: i, to: weekAgo)!
                let dayStart = calendar.startOfDay(for: day)
                let routes = dailyData[dayStart] ?? 0
                
                weeklyUsage.append(DailyUsage(
                    date: dayStart,
                    routeCount: routes,
                    dayName: calendar.shortWeekdaySymbols[calendar.component(.weekday, from: dayStart) - 1]
                ))
            }
            
            print("📊 Weekly usage data compiled: \(weeklyUsage.count) days")
            return weeklyUsage
            
        } catch {
            print("❌ Error fetching weekly usage data: \(error)")
            return []
        }
    }
    
    /// Gets top user statistics
    func getTopUserStats() -> [UserStats] {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<UsageTracking> = UsageTracking.fetchRequest()
        
        do {
            let results = try context.fetch(request)
            
            // Group by user ID and sum their route calculations
            var userTotals: [String: Int] = [:]
            
            for result in results {
                if let userID = result.userID {
                    userTotals[userID, default: 0] += Int(result.routeCalculations)
                }
            }
            
            // Convert to sorted array
            let topUsers = userTotals
                .sorted { $0.value > $1.value }
                .prefix(10)
                .map { UserStats(userID: $0.key, totalRoutes: $0.value) }
            
            print("📊 Top user stats compiled: \(topUsers.count) users")
            return topUsers
            
        } catch {
            print("❌ Error fetching top user stats: \(error)")
            return []
        }
    }
}

// MARK: - Supporting Data Models

struct DailyUsage {
    let date: Date
    let routeCount: Int
    let dayName: String
}

struct UserStats {
    let userID: String
    let totalRoutes: Int
    
    // Computed property to get a friendly user identifier
    var displayName: String {
        // Show first 8 characters of userID for privacy
        return String(userID.prefix(8)) + "..."
    }
}
