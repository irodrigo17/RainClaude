import SwiftUI
import CoreLocation

struct LocationRainfallSheet: View {
    @EnvironmentObject private var placeStore: PlaceStore
    @Environment(\.dismiss) private var dismiss

    let coordinate: CLLocationCoordinate2D

    @State private var placeName = "Loading..."
    @State private var rainfallSummary: RainfallSummary?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var nearbyPlace: Place? {
        placeStore.placeNear(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading rainfall data...")
                            .padding(.top, 40)
                    } else if let errorMessage {
                        ContentUnavailableView(
                            "Error",
                            systemImage: "exclamationmark.triangle",
                            description: Text(errorMessage)
                        )
                    } else if let summary = rainfallSummary {
                        RainfallCardView(summary: summary)
                    }

                    Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(placeName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        toggleSaved()
                    } label: {
                        Image(systemName: nearbyPlace != nil ? "star.fill" : "star")
                    }
                    .disabled(placeName == "Loading...")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            await loadData()
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        // Reverse geocode
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let pm = placemarks.first {
                let parts = [pm.locality, pm.administrativeArea, pm.country].compactMap { $0 }
                placeName = parts.isEmpty ? formatCoordinate() : parts.joined(separator: ", ")
            } else {
                placeName = formatCoordinate()
            }
        } catch {
            placeName = formatCoordinate()
        }

        // Fetch rainfall
        do {
            rainfallSummary = try await WeatherService.fetchRainfall(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func formatCoordinate() -> String {
        String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }

    private func toggleSaved() {
        if let existing = nearbyPlace {
            placeStore.removePlace(existing)
        } else {
            placeStore.addPlace(
                Place(name: placeName, latitude: coordinate.latitude, longitude: coordinate.longitude)
            )
        }
    }
}
