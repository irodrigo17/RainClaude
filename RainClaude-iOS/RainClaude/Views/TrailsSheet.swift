import SwiftUI
import MapKit

struct TrailsSheet: View {
    @EnvironmentObject private var placeStore: PlaceStore
    @Environment(\.dismiss) private var dismiss

    let region: MKCoordinateRegion

    @State private var trails: [Trail] = []
    @State private var isLoading = true
    @State private var selectedTrail: Trail?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Searching for trails…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if trails.isEmpty {
                    ContentUnavailableView(
                        "No Trails Found",
                        systemImage: "bicycle",
                        description: Text("No mountain biking trails found in this area.")
                    )
                } else {
                    List(trails) { trail in
                        trailRow(trail)
                    }
                }
            }
            .navigationTitle("Mountain Biking Trails")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(item: $selectedTrail) { trail in
            LocationRainfallSheet(coordinate: trail.coordinate)
                .environmentObject(placeStore)
        }
        .task {
            await searchTrails()
        }
    }

    private func trailRow(_ trail: Trail) -> some View {
        Button {
            selectedTrail = trail
        } label: {
            HStack {
                Text(trail.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    toggleSaved(trail)
                } label: {
                    Image(systemName: isSaved(trail) ? "star.fill" : "star")
                        .foregroundStyle(isSaved(trail) ? .orange : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(.primary)
    }

    private func isSaved(_ trail: Trail) -> Bool {
        placeStore.placeNear(latitude: trail.coordinate.latitude, longitude: trail.coordinate.longitude) != nil
    }

    private func toggleSaved(_ trail: Trail) {
        let coord = trail.coordinate
        if let existing = placeStore.placeNear(latitude: coord.latitude, longitude: coord.longitude) {
            placeStore.removePlace(existing)
        } else {
            placeStore.addPlace(
                Place(name: trail.name, latitude: coord.latitude, longitude: coord.longitude)
            )
        }
    }

    // MARK: - Overpass Search

    private func searchTrails() async {
        let center = region.center
        let span = region.span
        let south = center.latitude - span.latitudeDelta / 2
        let north = center.latitude + span.latitudeDelta / 2
        let west = center.longitude - span.longitudeDelta / 2
        let east = center.longitude + span.longitudeDelta / 2
        let bbox = "\(south),\(west),\(north),\(east)"

        let query = """
        [out:json][timeout:25];
        (
          relation["route"="mtb"](\(bbox));
          way["mtb:scale"](\(bbox));
          way["sport"="mountain_biking"](\(bbox));
          node["sport"="mountain_biking"](\(bbox));
        );
        out center;
        """

        var components = URLComponents(string: "https://overpass-api.de/api/interpreter")!
        components.queryItems = [URLQueryItem(name: "data", value: query)]
        guard let url = components.url else {
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OverpassResponse.self, from: data)
            trails = buildTrails(from: response.elements)
        } catch {
            trails = []
        }
        isLoading = false
    }

    private func buildTrails(from elements: [OverpassElement]) -> [Trail] {
        var groups: [String: (count: Int, lat: Double, lon: Double)] = [:]

        for element in elements {
            guard let name = element.tags?["name"], !name.isEmpty else { continue }

            let lat: Double
            let lon: Double
            if let center = element.center {
                lat = center.lat
                lon = center.lon
            } else if let eLat = element.lat, let eLon = element.lon {
                lat = eLat
                lon = eLon
            } else {
                continue
            }

            if let existing = groups[name] {
                groups[name] = (existing.count + 1, existing.lat, existing.lon)
            } else {
                groups[name] = (1, lat, lon)
            }
        }

        return groups
            .map { name, info in
                Trail(
                    name: name,
                    coordinate: CLLocationCoordinate2D(latitude: info.lat, longitude: info.lon),
                    segmentCount: info.count
                )
            }
            .sorted { $0.segmentCount > $1.segmentCount }
            .prefix(10)
            .map { $0 }
    }
}

// MARK: - Trail

struct Trail: Identifiable {
    let name: String
    let coordinate: CLLocationCoordinate2D
    let segmentCount: Int

    var id: String { "\(name)_\(coordinate.latitude)_\(coordinate.longitude)" }
}

// MARK: - Overpass API Models

private struct OverpassResponse: Codable {
    let elements: [OverpassElement]
}

private struct OverpassElement: Codable {
    let type: String
    let id: Int
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?
}

private struct OverpassCenter: Codable {
    let lat: Double
    let lon: Double
}
