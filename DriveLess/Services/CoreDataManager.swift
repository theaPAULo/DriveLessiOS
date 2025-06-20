//
//  CoreDataManager.swift
//  DriveLess
//
//  Created by Paul Soni on 6/20/25.
//


//
//  CoreDataManager.swift
//  DriveLess
//
//  Core Data stack and persistence management
//

import Foundation
import CoreData
import SwiftUI

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DriveLessModel")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error.localizedDescription)")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        
        // Enable automatic merging of changes from parent contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    // Main context for UI operations
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data saved successfully")
            } catch {
                print("❌ Core Data save failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Background Context for Heavy Operations
    func backgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
}