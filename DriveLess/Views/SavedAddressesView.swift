//
//  SavedAddressesView.swift
//  DriveLess
//
//  Manage saved addresses (Home, Work, Custom locations) - IMPROVED UX
//

import SwiftUI

struct SavedAddressesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var savedAddressManager: SavedAddressManager
    
    @State private var showingAddAddressSheet = false
    @State private var editingAddress: SavedAddress? = nil

    // MARK: - Color Theme (Earthy - matching app theme)
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2)
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // MARK: - Header Info
                if !savedAddressManager.savedAddresses.isEmpty {
                    headerInfoView
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                }
                
                // MARK: - Address List
                if savedAddressManager.savedAddresses.isEmpty {
                    emptyStateView
                } else {
                    addressListView
                }
                
                // MARK: - Add Location Button (when addresses exist)
                if !savedAddressManager.savedAddresses.isEmpty {
                    addLocationButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Saved Locations")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(primaryGreen)
            }
        }
        .sheet(isPresented: $showingAddAddressSheet) {
            AddAddressView(savedAddressManager: savedAddressManager)
        }
        .sheet(item: $editingAddress) { address in
            EditAddressView(
                savedAddressManager: savedAddressManager,
                addressToEdit: address
            )
        }
    }
    
    // MARK: - Header Info
    private var headerInfoView: some View {
        HStack(spacing: 20) {
            VStack {
                Text("\(savedAddressManager.savedAddresses.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryGreen)
                Text("Saved")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 30)
            
            VStack {
                Text("\(homeAndWorkCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(homeAndWorkCount > 0 ? primaryGreen : .secondary)
                Text("Home & Work")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 30)
            
            VStack {
                Text("\(savedAddressManager.getCustomAddresses().count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryGreen)
                Text("Custom")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.bottom, 10)
    }
    
    // MARK: - Address List
    private var addressListView: some View {
        List {
            ForEach(savedAddressManager.savedAddresses, id: \.id) { address in
                SavedAddressRow(
                    address: address,
                    savedAddressManager: savedAddressManager,
                    onTap: {
                        // FIXED: Open edit view instead of add view
                        editingAddress = address
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: deleteAddresses)
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "house.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Saved Locations")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Add your home, work, and favorite places for quick access")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showingAddAddressSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Location")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(primaryGreen)
                .cornerRadius(25)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Add Location Button (NEW)
    private var addLocationButton: some View {
        Button {
            showingAddAddressSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Add New Location")
                    .font(.system(size: 16, weight: .semibold))
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
            .shadow(color: primaryGreen.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteAddresses(offsets: IndexSet) {
        for index in offsets {
            savedAddressManager.deleteAddress(savedAddressManager.savedAddresses[index])
        }
    }
    
    // MARK: - Computed Properties
    
    private var homeAndWorkCount: Int {
        var count = 0
        if savedAddressManager.getHomeAddress() != nil { count += 1 }
        if savedAddressManager.getWorkAddress() != nil { count += 1 }
        return count
    }
}

// MARK: - Saved Address Row Component (UNCHANGED)
struct SavedAddressRow: View {
    let address: SavedAddress
    let savedAddressManager: SavedAddressManager
    let onTap: () -> Void
    
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                
                // Address Type Icon
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(iconColor)
                    )
                
                // Address Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(address.label ?? "Unknown Location")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(savedAddressManager.formatAddressForDisplay(address))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if let addressType = address.addressType {
                        Text(SavedAddressManager.AddressType(rawValue: addressType)?.displayName ?? "Custom")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(iconColor.opacity(0.2))
                            .foregroundColor(iconColor)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // EDIT INDICATOR
                Image(systemName: "pencil.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var iconName: String {
        guard let addressType = address.addressType,
              let type = SavedAddressManager.AddressType(rawValue: addressType) else {
            return "mappin.circle.fill"
        }
        return type.icon
    }
    
    private var iconColor: Color {
        guard let addressType = address.addressType else { return primaryGreen }
        
        switch addressType {
        case "home": return .green
        case "work": return .blue
        default: return primaryGreen
        }
    }
}

#Preview("SavedAddressesView") {
    SavedAddressesView(savedAddressManager: SavedAddressManager())
}
