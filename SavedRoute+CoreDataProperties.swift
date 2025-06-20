//
//  SavedRoute+CoreDataProperties.swift
//  DriveLess
//
//  Created by Paul Soni on 6/20/25.
//
//

import Foundation
import CoreData


extension SavedRoute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedRoute> {
        return NSFetchRequest<SavedRoute>(entityName: "SavedRoute")
    }

    @NSManaged public var considerTraffic: Bool
    @NSManaged public var createdDate: Date?
    @NSManaged public var endLocation: String?
    @NSManaged public var estimatedTime: String?
    @NSManaged public var id: UUID?
    @NSManaged public var routeName: String?
    @NSManaged public var startLocation: String?
    @NSManaged public var stops: String?
    @NSManaged public var totalDistance: String?
    @NSManaged public var waypointOrder: String?
    @NSManaged public var stopDisplayNames: String?
    @NSManaged public var endLocationDisplayName: String?
    @NSManaged public var startLocationDisplayName: String?

}

extension SavedRoute : Identifiable {

}
