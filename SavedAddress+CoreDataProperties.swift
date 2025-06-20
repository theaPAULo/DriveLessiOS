//
//  SavedAddress+CoreDataProperties.swift
//  DriveLess
//
//  Created by Paul Soni on 6/20/25.
//
//

import Foundation
import CoreData


extension SavedAddress {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedAddress> {
        return NSFetchRequest<SavedAddress>(entityName: "SavedAddress")
    }

    @NSManaged public var addressType: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var displayName: String?
    @NSManaged public var fullAddress: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isDefault: Bool
    @NSManaged public var label: String?

}

extension SavedAddress : Identifiable {

}
