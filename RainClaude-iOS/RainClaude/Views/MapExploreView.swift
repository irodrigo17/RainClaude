import SwiftUI
import MapKit

struct MapExploreView: View {
    @EnvironmentObject private var placeStore: PlaceStore

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedCoordinate = CLLocationCoordinate2D()
    @State private var hasSelection = false
    @State private var showingSheet = false
    @State private var mapSelection: UUID?
    @State private var selectedPlaceID: UUID?

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var searchTask: Task<Void, Never>?

    // Rainfall overlay
    @StateObject private var gridService = RainfallGridService()
    @State private var overlayVisible = true
    @State private var overlayTimeframe: RainfallTimeframe = .threeDays
    @State private var overlayOpacity: Double = 0.3
    @State private var cameraChangeCount = 0

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $cameraPosition, selection: $mapSelection) {
                    UserAnnotation()

                    if hasSelection {
                        Marker("Selected", coordinate: selectedCoordinate)
                            .tint(.blue)
                    }

                    ForEach(placeStore.places) { place in
                        Marker(place.name, coordinate: place.coordinate)
                            .tint(.orange)
                            .tag(place.id)
                    }
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .onTapGesture { screenPosition in
                    guard let coordinate = proxy.convert(screenPosition, from: .local) else { return }
                    selectedCoordinate = coordinate
                    selectedPlaceID = nil
                    hasSelection = true
                    showingSheet = true
                }
                .onChange(of: mapSelection) { _, newValue in
                    guard let placeID = newValue,
                          let place = placeStore.places.first(where: { $0.id == placeID }) else { return }
                    selectedCoordinate = place.coordinate
                    selectedPlaceID = placeID
                    hasSelection = false
                    showingSheet = true
                    mapSelection = nil
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    cameraChangeCount += 1
                    if overlayVisible {
                        gridService.updateRegion(context.region)
                    }
                }
                .overlay {
                    rainfallImageOverlay(proxy: proxy)
                }
                .overlay(alignment: .bottomTrailing) {
                    VStack(alignment: .trailing, spacing: 10) {
                        RainfallOverlayControls(
                            isVisible: $overlayVisible,
                            timeframe: $overlayTimeframe,
                            opacity: $overlayOpacity,
                            isLoading: gridService.isLoading
                        )

                        Button {
                            cameraPosition = .userLocation(fallback: .automatic)
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16))
                                .frame(width: 44, height: 44)
                        }
                        .tint(.primary)
                        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(12)
                }
                .onChange(of: overlayVisible) { _, visible in
                    if visible {
                        gridService.refetch()
                    }
                }
            }
            .sheet(isPresented: $showingSheet) {
                LocationRainfallSheet(coordinate: selectedCoordinate, placeID: selectedPlaceID)
                    .environmentObject(placeStore)
            }
            .searchable(text: $searchText, prompt: "Search places")
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                guard !newValue.isEmpty else {
                    searchResults = []
                    return
                }
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    guard !Task.isCancelled else { return }
                    await runSearch(query: newValue)
                }
            }
            .searchSuggestions {
                ForEach(searchResults, id: \.self) { item in
                    Button {
                        selectSearchResult(item)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Unknown")
                            if let subtitle = item.placemark.title, subtitle != item.name {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Rainfall Image Overlay

    @ViewBuilder
    private func rainfallImageOverlay(proxy: MapProxy) -> some View {
        // Reference published properties to trigger re-renders
        let _ = gridService.gridVersion
        let _ = cameraChangeCount

        if overlayVisible,
           let bounds = gridService.gridBounds,
           let image = gridService.rainfallImage(for: overlayTimeframe),
           let tl = proxy.convert(bounds.topLeft, to: .local),
           let br = proxy.convert(bounds.bottomRight, to: .local) {
            let width = br.x - tl.x
            let height = br.y - tl.y
            if width > 0, height > 0 {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: width, height: height)
                    .position(x: (tl.x + br.x) / 2, y: (tl.y + br.y) / 2)
                    .opacity(overlayOpacity)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Search

    private func performSearch() {
        Task { await runSearch(query: searchText) }
    }

    private func runSearch(query: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            searchResults = response.mapItems
        } catch {
            searchResults = []
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        cameraPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        ))
        selectedCoordinate = coordinate
        selectedPlaceID = nil
        hasSelection = true
        searchResults = []
        showingSheet = true
    }
}
