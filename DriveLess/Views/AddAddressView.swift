//
//  AddAddressView.swift
//  DriveLess
//
//  Interface for adding new saved addresses (Home, Work, Custom) - UPDATED WITH CONSTRAINTS
//

import SwiftUI
import GooglePlaces
import CoreLocation

struct AddAddressView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var savedAddressManager: SavedAddressManager
    
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
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Address Type Selection
                    addressTypeSelector
                    
                    // MARK: - Custom Label Input (if custom selected)
                    if selectedAddressType == .custom {
                        customLabelInput
                    }
                    
                    // MARK: - Address Input
                    addressInput
                    
                    // MARK: - Current Location Button
                    currentLocationButton
                    
                    // MARK: - Save Button
                    saveButton
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear {
            // Request location permission for current location feature
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestLocationPermission()
            }
            
            // Set default type to first available option
            if let firstAvailable = availableAddressTypes.first {
                selectedAddressType = firstAvailable
            }
        }
    }
    
    // MARK: - Address Type Selector (WITH CONSTRAINTS)
    private var addressTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location Type")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(SavedAddressManager.AddressType.allCases, id: \.self) { type in
                    AddressTypeButton(
                        type: type,
                        isSelected: selectedAddressType == type,
                        isDisabled: isTypeDisabled(type),
                        action: {
                            if !isTypeDisabled(type) {
                                selectedAddressType = type
                                // Clear custom label when switching away from custom
                                if type != .custom {
                                    customLabel = ""
                                }
                            }
                        }
                    )
                }
            }
            
            // Show constraint message if applicable
            if !constraintMessage.isEmpty {
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
    
    // MARK: - Current Location Button
    private var currentLocationButton: some View {
        Button(action: useCurrentLocation) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .medium))
                
                Text("Use Current Location")
                    .font(.system(size: 16, weight: .medium))
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .foregroundColor(primaryGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(primaryGreen, lineWidth: 1)
            )
        }
        .disabled(isLoading || locationManager.location == nil)
        .opacity(locationManager.location == nil ? 0.5 : 1.0)
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveAddress) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                
                Text("Save Location")
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
    
    // MARK: - Computed Properties (WITH CONSTRAINTS)
    
    /// Available address types based on existing saved addresses
    private var availableAddressTypes: [SavedAddressManager.AddressType] {
        var types: [SavedAddressManager.AddressType] = []
        
        // Only add Home if no home address exists
        if savedAddressManager.getHomeAddress() == nil {
            types.append(.home)
        }
        
        // Only add Work if no work address exists
        if savedAddressManager.getWorkAddress() == nil {
            types.append(.work)
        }
        
        // Always allow Custom
        types.append(.custom)
        
        return types
    }
    
    /// Check if a specific address type is disabled
    private func isTypeDisabled(_ type: SavedAddressManager.AddressType) -> Bool {
        return !availableAddressTypes.contains(type)
    }
    
    /// Message explaining constraints to user
    private var constraintMessage: String {
        if savedAddressManager.getHomeAddress() != nil && savedAddressManager.getWorkAddress() != nil {
            return "Home and Work locations already exist. New locations will be saved as Custom."
        } else if savedAddressManager.getHomeAddress() != nil {
            return "Home location already exists"
        } else if savedAddressManager.getWorkAddress() != nil {
            return "Work location already exists"
        }
        return ""
    }
    
    private var canSave: Bool {
        let hasValidLabel = selectedAddressType != .custom || !customLabel.isEmpty
        let hasValidAddress = !selectedFullAddress.isEmpty
        
        return hasValidLabel && hasValidAddress
    }
    
    // MARK: - Action Methods
    
    private func handlePlaceSelected(_ place: GMSPlace) {
        selectedDisplayName = place.name ?? ""
        selectedFullAddress = place.formattedAddress ?? ""
        
        print("📍 Selected place: '\(selectedDisplayName)' at '\(selectedFullAddress)'")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func useCurrentLocation() {
        guard let location = locationManager.location else {
            errorMessage = "Current location not available"
            return
        }
        
        isLoading = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Use reverse geocoding to get address
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Failed to get address: \(error.localizedDescription)"
                    return
                }
                
                if let placemark = placemarks?.first {
                    // Format the address
                    var addressComponents: [String] = []
                    
                    if let streetNumber = placemark.subThoroughfare {
                        addressComponents.append(streetNumber)
                    }
                    if let streetName = placemark.thoroughfare {
                        addressComponents.append(streetName)
                    }
                    if let city = placemark.locality {
                        addressComponents.append(city)
                    }
                    if let state = placemark.administrativeArea {
                        addressComponents.append(state)
                    }
                    if let zip = placemark.postalCode {
                        addressComponents.append(zip)
                    }
                    
                    let fullAddress = addressComponents.joined(separator: ", ")
                    
                    selectedDisplayName = "Current Location"
                    selectedFullAddress = fullAddress
                    
                    print("📍 Got current location: \(fullAddress)")
                }
            }
        }
    }
    
    private func saveAddress() {
        let label = selectedAddressType == .custom ? customLabel : selectedAddressType.displayName
        
        savedAddressManager.saveAddress(
            label: label,
            fullAddress: selectedFullAddress,
            displayName: selectedDisplayName,
            addressType: selectedAddressType
        )
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("✅ Saved \(selectedAddressType.displayName): \(label)")
        
        dismiss()
    }
}

// MARK: - Address Type Button Component (UPDATED WITH DISABLED STATE)
struct AddressTypeButton: View {
    let type: SavedAddressManager.AddressType
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(buttonTextColor)
                
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(buttonTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(buttonBorderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
    
    // MARK: - Button Styling Based on State
    
    private var buttonTextColor: Color {
        if isDisabled {
            return .gray
        } else if isSelected {
            return .white
        } else {
            return primaryGreen
        }
    }
    
    private var buttonBackgroundColor: Color {
        if isDisabled {
            return Color(.systemGray5)
        } else if isSelected {
            return primaryGreen
        } else {
            return Color.clear
        }
    }
    
    private var buttonBorderColor: Color {
        if isDisabled {
            return .gray.opacity(0.3)
        } else {
            return primaryGreen
        }
    }
}

#Preview {
    AddAddressView(savedAddressManager: SavedAddressManager())
}
