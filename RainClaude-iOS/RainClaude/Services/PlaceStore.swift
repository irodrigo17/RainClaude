import Foundation
import Combine

class PlaceStore: ObservableObject {
    @Published private(set) var places: [Place] = []

    private let fileURL: URL

    init() {
        fileURL = URL.documentsDirectory.appending(path: "saved_places.json")
        load()
    }

    init(fileURL: URL) {
        self.fileURL = fileURL
        load()
    }

    func addPlace(_ place: Place) {
        places.append(place)
        save()
    }

    func renamePlace(_ place: Place, to newName: String) {
        guard let index = places.firstIndex(where: { $0.id == place.id }) else { return }
        places[index].name = newName
        save()
    }

    func removePlace(_ place: Place) {
        places.removeAll { $0.id == place.id }
        save()
    }

    func removePlaces(at offsets: IndexSet) {
        places.remove(atOffsets: offsets)
        save()
    }

    func placeNear(latitude: Double, longitude: Double) -> Place? {
        places.first { place in
            abs(place.latitude - latitude) < 0.0005 &&
            abs(place.longitude - longitude) < 0.0005
        }
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(places)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("PlaceStore save error: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            places = try JSONDecoder().decode([Place].self, from: data)
        } catch {
            print("PlaceStore load error: \(error)")
        }
    }
}
