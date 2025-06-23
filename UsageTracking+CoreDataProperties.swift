//
//  UsageTracking+CoreDataProperties.swift
//  DriveLess
//
//  Created by Claude on 6/23/25.
//
//

import Foundation
import CoreData

extension UsageTracking {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UsageTracking> {
        return NSFetchRequest<UsageTracking>(entityName: "UsageTracking")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var routeCalculations: Int32
    @NSManaged public var userID: String?

}

extension UsageTracking : Identifiable {

}
