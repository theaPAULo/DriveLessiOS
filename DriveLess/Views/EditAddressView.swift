//
//  EditAddressView.swift
//  DriveLess
//
//  Created by Paul Soni on 6/23/25.
//


//
//  EditAddressView.swift
//  DriveLess
//
//  Edit existing saved addresses
//

import SwiftUI
import GooglePlaces
import CoreLocation

struct EditAddressView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var savedAddressManager: SavedAddressManager
    let addressToEdit: SavedAddress
    
    // Form state
    @State private var selectedAddressType: SavedAddressManager.AddressType = .home
    @State private var customLabel: String = ""
    @State private var selectedAddress: String = ""
    @State private var selectedDisplayName: String = ""
    @State private var selectedFullAddress: String = ""
    
    // UI state
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // LocationManager for current location
    @StateObject private var locationManager = LocationManager()
    
    // MARK: - Color Theme
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Current Info Display
                    currentAddressInfo
                    
                    // MARK: - Address Type Selection (CONSTRAINED)
                    addressTypeSelector
                    
                    // MARK: - Custom Label Input (if custom selected)
                    if selectedAddressType == .custom {
                        customLabelInput
                    }
                    
                    // MARK: - Address Input
                    addressInput
                    
                    // MARK: - Action Buttons
                    VStack(spacing: 12) {
                        saveButton
                        deleteButton
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Edit Location")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            loadExistingData()
        }
    }
    
    // MARK: - Current Address Info
    private var currentAddressInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Address")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Circle()
                    .fill(currentTypeColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: currentTypeIcon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(currentTypeColor)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(addressToEdit.label ?? "Unknown")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Text(addressToEdit.fullAddress ?? "No address")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Address Type Selector (CONSTRAINED)
    private var addressTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location Type")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(availableAddressTypes, id: \.self) { type in
                    AddressTypeButton(
                        type: type,
                        isSelected: selectedAddressType == type,
                        isDisabled: isTypeDisabled(type),
                        action: {
                            if !isTypeDisabled(type) {
                                selectedAddressType = type
                                if type != .custom {
                                    customLabel = ""
                                }
                            }
                        }
                    )
                }
            }
            
            // Show constraint message if applicable
            if hasConstraintMessage {
                Text(constraintMessage)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Custom Label Input
    private var customLabelInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Label")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("e.g., Mom's House, Favorite Restaurant", text: $customLabel)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Address Input
    private var addressInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Address")
                .font(.headline)
                .foregroundColor(.primary)
            
            InlineAutocompleteTextField(
                text: $selectedDisplayName,
                placeholder: "Search for an address or place",
                icon: "location.circle.fill",
                iconColor: primaryGreen,
                currentLocation: locationManager.location,
                onPlaceSelected: { place in
                    handlePlaceSelected(place)
                }
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveChanges) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                
                Text("Save Changes")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [primaryGreen, primaryGreen.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(!canSave)
        .opacity(canSave ? 1.0 : 0.6)
    }
    
    // MARK: - Delete Button
    private var deleteButton: some View {
        Button(action: deleteAddress) {
            HStack(spacing: 12) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                
                Text("Delete Location")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Computed Properties
    
    private var availableAddressTypes: [SavedAddressManager.AddressType] {
        var types: [SavedAddressManager.AddressType] = []
        
        // Add Home if editing current home or no home exists
        if addressToEdit.addressType == "home" || savedAddressManager.getHomeAddress() == nil {
            types.append(.home)
        }
        
        // Add Work if editing current work or no work exists
        if addressToEdit.addressType == "work" || savedAddressManager.getWorkAddress() == nil {
            types.append(.work)
        }
        
        // Always allow Custom
        types.append(.custom)
        
        return types
    }
    
    private func isTypeDisabled(_ type: SavedAddressManager.AddressType) -> Bool {
        return !availableAddressTypes.contains(type)
    }
    
    private var hasConstraintMessage: Bool {
        return !availableAddressTypes.contains(.home) || !availableAddressTypes.contains(.work)
    }
    
    private var constraintMessage: String {
        if !availableAddressTypes.contains(.home) && !availableAddressTypes.contains(.work) {
            return "Home and Work locations already exist"
        } else if !availableAddressTypes.contains(.home) {
            return "Home location already exists"
        } else if !availableAddressTypes.contains(.work) {
            return "Work location already exists"
        }
        return ""
    }
    
    private var currentTypeColor: Color {
        guard let type = addressToEdit.addressType else { return primaryGreen }
        switch type {
        case "home": return .green
        case "work": return .blue
        default: return primaryGreen
        }
    }
    
    private var currentTypeIcon: String {
        guard let type = addressToEdit.addressType else { return "mappin.circle.fill" }
        switch type {
        case "home": return "house.fill"
        case "work": return "building.2.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    private var canSave: Bool {
        let hasValidLabel = selectedAddressType != .custom || !customLabel.isEmpty
        let hasValidAddress = !selectedFullAddress.isEmpty
        
        return hasValidLabel && hasValidAddress
    }
    
    // MARK: - Action Methods
    
    private func loadExistingData() {
        // Load current address data
        selectedFullAddress = addressToEdit.fullAddress ?? ""
        selectedDisplayName = addressToEdit.displayName ?? ""
        
        if let addressType = addressToEdit.addressType,
           let type = SavedAddressManager.AddressType(rawValue: addressType) {
            selectedAddressType = type
        }
        
        if selectedAddressType == .custom {
            customLabel = addressToEdit.label ?? ""
        }
    }
    
    private func handlePlaceSelected(_ place: GMSPlace) {
        let businessName = place.name ?? ""
        let fullAddress = place.formattedAddress ?? ""
        
        selectedFullAddress = fullAddress
        selectedDisplayName = businessName.isEmpty ? fullAddress : businessName
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func saveChanges() {
        let label = selectedAddressType == .custom ? customLabel : selectedAddressType.displayName
        
        // Update the existing address
        savedAddressManager.updateAddress(
            addressToEdit,
            newLabel: label,
            newFullAddress: selectedFullAddress,
            newDisplayName: selectedDisplayName
        )
        
        // Update address type if changed
        addressToEdit.addressType = selectedAddressType.rawValue
        savedAddressManager.coreDataManager.save()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
    
    private func deleteAddress() {
        savedAddressManager.deleteAddress(addressToEdit)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
}

#Preview {
    EditAddressView(
        savedAddressManager: SavedAddressManager(),
        addressToEdit: SavedAddress()
    )
}