//
//  AutocompleteTextField.swift
//  DriveLess
//
//  Inline Google Places autocomplete text field
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

// MARK: - Inline Autocomplete Text Field
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
    @StateObject private var placesClient = PlacesClient()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Text Field
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: text) { _, newValue in
                        searchPlaces(query: newValue)
                    }
                    .onTapGesture {
                        if !text.isEmpty {
                            showingSuggestions = true
                        }
                    }
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Suggestions Dropdown
            if showingSuggestions && !predictions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(predictions) { prediction in
                        Button(action: {
                            selectPrediction(prediction)
                        }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(prediction.primaryText)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Text(prediction.secondaryText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(Color(.systemBackground))
                        
                        if prediction.id != predictions.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.top, 4)
            }
        }
        .onTapGesture {
            // Dismiss suggestions when tapping outside
            showingSuggestions = false
        }
    }
    
    private func searchPlaces(query: String) {
        guard !query.isEmpty else {
            predictions = []
            showingSuggestions = false
            return
        }
        
        guard query.count >= 2 else { return } // Wait for at least 2 characters
        
        isSearching = true
        showingSuggestions = true
        
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
        text = prediction.fullText
        showingSuggestions = false
        
        // Fetch place details
        placesClient.getPlaceDetails(placeID: prediction.placeID) { place in
            if let place = place {
                DispatchQueue.main.async {
                    self.onPlaceSelected(place)
                }
            }
        }
    }
}

// MARK: - Places Client (Simplified)
class PlacesClient: ObservableObject {
    private let client = GMSPlacesClient.shared()
    
    func searchPlaces(query: String, location: CLLocation?, completion: @escaping ([PlacePrediction]) -> Void) {
        
        // Create the autocomplete session token
        let token = GMSAutocompleteSessionToken.init()
        
        // Create filter with basic settings
        let filter = GMSAutocompleteFilter()
        filter.countries = ["US"] // Limit to US
        
        if let location = location {
            print("🗺️ Searching near: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            // Note: We'll add location bias later once we get basic functionality working
        }
        
        // Use the basic autocomplete API that should work
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
            
            let predictions = results.map { result in
                PlacePrediction(
                    placeID: result.placeID,
                    primaryText: result.attributedPrimaryText.string,
                    secondaryText: result.attributedSecondaryText?.string ?? "",
                    fullText: result.attributedFullText.string
                )
            }
            
            completion(predictions)
        }
    }
    
    func getPlaceDetails(placeID: String, completion: @escaping (GMSPlace?) -> Void) {
        // Use the simplest approach that works
        let fields: GMSPlaceField = [.placeID, .name, .formattedAddress, .coordinate]
        
        client.fetchPlace(
            fromPlaceID: placeID,
            placeFields: fields,
            sessionToken: nil
        ) { (place, error) in
            if let error = error {
                print("❌ Place details error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            print("✅ Got place details: \(place?.formattedAddress ?? "Unknown")")
            completion(place)
        }
    }
}
