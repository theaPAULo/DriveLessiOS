//
//  SavedAddressManager.swift
//  DriveLess
//
//  Created by Paul Soni on 6/20/25.
//


//
//  SavedAddressManager.swift
//  DriveLess
//
//  Manages saving and loading user's favorite addresses (Home, Work, Custom)
//

import Foundation
import CoreData

class SavedAddressManager: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    
    // Published property to notify UI of changes
    @Published var savedAddresses: [SavedAddress] = []
    
    // MARK: - Address Types
    enum AddressType: String, CaseIterable {
        case home = "home"
        case work = "work"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .home: return "Home"
            case .work: return "Work"
            case .custom: return "Custom"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .work: return "building.2.fill"
            case .custom: return "mappin.circle.fill"
            }
        }
    }
    
    init() {
        loadSavedAddresses()
    }
    
    // MARK: - Save Address
    
    /// Saves a new address to the user's saved addresses
    /// - Parameters:
    ///   - label: User-friendly label (e.g., "Home", "Mom's House")
    ///   - fullAddress: Complete address from Google Places
    ///   - displayName: Business/place name if available
    ///   - addressType: Type of address (home, work, custom)
    func saveAddress(
        label: String,
        fullAddress: String,
        displayName: String = "",
        addressType: AddressType
    ) {
        let context = coreDataManager.viewContext
        
        // Check if this address type already exists (for Home/Work)
        if addressType != .custom {
            // Remove existing Home/Work address
            if let existingAddress = savedAddresses.first(where: { $0.addressType == addressType.rawValue }) {
                deleteAddress(existingAddress)
            }
        }
        
        // Create new SavedAddress entity
        let savedAddress = SavedAddress(context: context)
        
        // Set properties
        savedAddress.id = UUID()
        savedAddress.label = label
        savedAddress.fullAddress = fullAddress
        savedAddress.displayName = displayName
        savedAddress.addressType = addressType.rawValue
        savedAddress.createdDate = Date()
        savedAddress.isDefault = (addressType == .home) // Home is default
        
        // Save to Core Data
        coreDataManager.save()
        
        // Reload addresses to update UI
        loadSavedAddresses()
        
        print("✅ Saved address: \(label) (\(addressType.displayName))")
    }
    
    // MARK: - Load Addresses
    
    /// Loads all saved addresses from Core Data
    func loadSavedAddresses() {
        let context = coreDataManager.viewContext
        let request: NSFetchRequest<SavedAddress> = SavedAddress.fetchRequest()
        
        // Sort by type (Home, Work, then Custom) and creation date
        request.sortDescriptors = [
            NSSortDescriptor(key: "addressType", ascending: true),
            NSSortDescriptor(keyPath: \SavedAddress.createdDate, ascending: false)
        ]
        
        do {
            savedAddresses = try context.fetch(request)
            print("📍 Loaded \(savedAddresses.count) saved addresses")
        } catch {
            print("❌ Failed to load saved addresses: \(error)")
            savedAddresses = []
        }
    }
    
    // MARK: - Delete Address
    
    /// Deletes a saved address
    /// - Parameter address: The SavedAddress to delete
    func deleteAddress(_ address: SavedAddress) {
        let context = coreDataManager.viewContext
        context.delete(address)
        coreDataManager.save()
        
        // Reload addresses to update UI
        loadSavedAddresses()
        
        print("🗑️ Deleted address: \(address.label ?? "Unknown")")
    }
    
    // MARK: - Update Address
    
    /// Updates an existing saved address
    /// - Parameters:
    ///   - address: The SavedAddress to update
    ///   - newLabel: New label for the address
    ///   - newFullAddress: New full address
    ///   - newDisplayName: New display name
    func updateAddress(
        _ address: SavedAddress,
        newLabel: String,
        newFullAddress: String,
        newDisplayName: String = ""
    ) {
        address.label = newLabel
        address.fullAddress = newFullAddress
        address.displayName = newDisplayName
        
        coreDataManager.save()
        loadSavedAddresses()
        
        print("✏️ Updated address: \(newLabel)")
    }
    
    // MARK: - Convenience Methods
    
    /// Gets the user's home address if saved
    /// - Returns: SavedAddress for home, or nil if not set
    func getHomeAddress() -> SavedAddress? {
        return savedAddresses.first { $0.addressType == AddressType.home.rawValue }
    }
    
    /// Gets the user's work address if saved
    /// - Returns: SavedAddress for work, or nil if not set
    func getWorkAddress() -> SavedAddress? {
        return savedAddresses.first { $0.addressType == AddressType.work.rawValue }
    }
    
    /// Gets all custom addresses
    /// - Returns: Array of custom SavedAddress objects
    func getCustomAddresses() -> [SavedAddress] {
        return savedAddresses.filter { $0.addressType == AddressType.custom.rawValue }
    }
    
    /// Converts a SavedAddress to a user-friendly display string
    /// - Parameter address: The SavedAddress to format
    /// - Returns: Formatted string for display
    func formatAddressForDisplay(_ address: SavedAddress) -> String {
        if let displayName = address.displayName, !displayName.isEmpty {
            return displayName
        }
        
        // Extract business name from full address
        if let fullAddress = address.fullAddress, fullAddress.contains(",") {
            let firstPart = fullAddress.components(separatedBy: ",").first ?? ""
            let trimmed = firstPart.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        
        return address.label ?? "Unknown Address"
    }
}
