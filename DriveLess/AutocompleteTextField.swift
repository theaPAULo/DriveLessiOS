//
//  AutocompleteTextField.swift
//  DriveLess
//
//  Enhanced inline Google Places autocomplete with better mobile UX
//

import SwiftUI
import GooglePlaces
import CoreLocation

// MARK: - Prediction Model
struct PlacePrediction: Identifiable {
    let id = UUID()
    let placeID: String
    let primaryText: String
    let secondaryText: String
    let fullText: String
}

// MARK: - Enhanced Inline Autocomplete Text Field
struct InlineAutocompleteTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let iconColor: Color
    let currentLocation: CLLocation?
    let onPlaceSelected: (GMSPlace) -> Void
    
    @State private var predictions: [PlacePrediction] = []
    @State private var isSearching = false
    @State private var showingSuggestions = false
    @State private var isTextFieldFocused = false
    @StateObject private var placesClient = PlacesClient()
    @FocusState private var textFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Text Field with better mobile design
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .font(.system(size: 18, weight: .medium))
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16, weight: .regular))
                    .focused($textFieldFocused)
                    .onChange(of: text) { _, newValue in
                        searchPlaces(query: newValue)
                    }
                    .onChange(of: textFieldFocused) { _, focused in
                        isTextFieldFocused = focused
                        if focused && !text.isEmpty {
                            showingSuggestions = true
                        } else if !focused {
                            // Delay hiding suggestions to allow for selection
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showingSuggestions = false
                            }
                        }
                    }
                
                // Loading indicator or clear button
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if !text.isEmpty {
                    Button(action: clearText) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isTextFieldFocused ? iconColor : Color.clear, lineWidth: 2)
                    )
            )
            
            // Enhanced Suggestions Dropdown
            if showingSuggestions && !predictions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(predictions) { prediction in
                        Button(action: {
                            selectPrediction(prediction)
                        }) {
                            HStack(spacing: 12) {
                                // Location icon for each suggestion
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(prediction.primaryText)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    if !prediction.secondaryText.isEmpty {
                                        Text(prediction.secondaryText)
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle()) // Makes entire area tappable
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(Color(.systemBackground))
                        
                        if prediction.id != predictions.last?.id {
                            Divider()
                                .padding(.leading, 48) // Align with text
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .padding(.top, 8)
                .zIndex(1) // Ensure suggestions appear above other content
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func searchPlaces(query: String) {
        guard !query.isEmpty else {
            predictions = []
            showingSuggestions = false
            return
        }
        
        guard query.count >= 2 else { return } // Wait for at least 2 characters
        
        isSearching = true
        if isTextFieldFocused {
            showingSuggestions = true
        }
        
        placesClient.searchPlaces(
            query: query,
            location: currentLocation
        ) { results in
            DispatchQueue.main.async {
                self.predictions = results
                self.isSearching = false
            }
        }
    }
    
    private func selectPrediction(_ prediction: PlacePrediction) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        text = prediction.fullText
        showingSuggestions = false
        textFieldFocused = false // Dismiss keyboard
        
        // Fetch place details
        placesClient.getPlaceDetails(placeID: prediction.placeID) { place in
            if let place = place {
                DispatchQueue.main.async {
                    self.onPlaceSelected(place)
                }
            }
        }
    }
    
    private func clearText() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        text = ""
        predictions = []
        showingSuggestions = false
    }
}

// MARK: - Enhanced Places Client
class PlacesClient: ObservableObject {
    private let client = GMSPlacesClient.shared()
    
    func searchPlaces(query: String, location: CLLocation?, completion: @escaping ([PlacePrediction]) -> Void) {
        
        // Create the autocomplete session token
        let token = GMSAutocompleteSessionToken.init()
        
        // Create filter with enhanced settings for better results
        let filter = GMSAutocompleteFilter()
        filter.countries = ["US"] // Limit to US
        filter.types = [] // Allow all types for flexibility
        
        if let location = location {
            print("🗺️ Searching near: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            // Create location bias for better local results
            let northEast = CLLocationCoordinate2D(
                latitude: location.coordinate.latitude + 0.1,
                longitude: location.coordinate.longitude + 0.1
            )
            let southWest = CLLocationCoordinate2D(
                latitude: location.coordinate.latitude - 0.1,
                longitude: location.coordinate.longitude - 0.1
            )
            
            filter.locationBias = GMSPlaceRectangularLocationOption(northEast, southWest)
        }
        
        // Enhanced autocomplete request
        client.findAutocompletePredictions(
            fromQuery: query,
            filter: filter,
            sessionToken: token
        ) { (results, error) in
            if let error = error {
                print("❌ Autocomplete error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let results = results else {
                print("❌ No results returned")
                completion([])
                return
            }
            
            print("🔍 Found \(results.count) predictions for '\(query)'")
            
            let predictions = results.prefix(5).map { result in // Limit to 5 results for mobile
                PlacePrediction(
                    placeID: result.placeID,
                    primaryText: result.attributedPrimaryText.string,
                    secondaryText: result.attributedSecondaryText?.string ?? "",
                    fullText: result.attributedFullText.string
                )
            }
            
            completion(Array(predictions))
        }
    }
    
    func getPlaceDetails(placeID: String, completion: @escaping (GMSPlace?) -> Void) {
        // Use the correct field names for iOS SDK
        let placeProperties = [
            "place_id",
            "name",
            "formatted_address",
            "geometry/location",  // This is the correct path for coordinates
            "types"
        ]
        
        // Create the request with the correct field format
        let request = GMSFetchPlaceRequest(placeID: placeID, placeProperties: placeProperties, sessionToken: nil)
        
        // Use the updated API method
        client.fetchPlace(with: request) { (place, error) in
            if let error = error {
                print("❌ Place details error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let place = place {
                print("✅ Got place details: \(place.formattedAddress ?? "Unknown address")")
                print("📍 Place name: \(place.name ?? "Unknown name")")
                
                // Check if coordinates are valid
                let lat = place.coordinate.latitude
                let lng = place.coordinate.longitude
                if lat != -180.0 && lng != -180.0 && lat != 0.0 && lng != 0.0 {
                    print("📍 Valid coordinates: \(lat), \(lng)")
                } else {
                    print("❌ Invalid coordinates received: \(lat), \(lng)")
                }
                
                completion(place)
            } else {
                print("❌ No place returned from API")
                completion(nil)
            }
        }
    }
}
