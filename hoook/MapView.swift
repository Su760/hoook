//
//  MapView.swift
//  hook
//
//  Map-based discovery view showing venues and games
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = MapViewModel()
    @EnvironmentObject var model: AppModel
    
    @State private var showPermissionAlert = false
    @State private var showListView = false
    @State private var manualLocationSearch = ""
    @State private var showLocationSearch = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main Map View
                mapContent
                    .ignoresSafeArea(edges: .top)
                
                // Filters Overlay
                VStack {
                    filtersOverlay
                        .padding(.top, 8)
                    Spacer()
                }
                
                // Permission/Empty State Overlays
                if locationManager.permissionState == .denied || locationManager.permissionState == .restricted {
                    permissionDeniedOverlay
                } else if !viewModel.isLoading && viewModel.venues.isEmpty && viewModel.games.isEmpty && locationManager.permissionState != .notDetermined {
                    emptyStateOverlay
                }
                
                // Loading Indicator
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.cardBackground.opacity(0.9))
                        .cornerRadius(12)
                }
            }
            .navigationBarHidden(true)
            .alert("Location Access", isPresented: $showPermissionAlert) {
                Button("Allow") {
                    locationManager.requestPermission()
                }
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("Hook uses your location to show nearby games and venues. Location is used only for discovery — player locations are never shown.")
            }
            .onAppear {
                checkAndRequestLocation()
            }
            .onChange(of: locationManager.currentLocation) { newLocation in
                guard let location = newLocation else { return }
                let wasInitialized = viewModel.hasInitializedRegion
                viewModel.updateRegionToUserLocation(location)
                // Only fetch data on first location update
                if !wasInitialized {
                    fetchMapData()
                }
            }
            .onChange(of: viewModel.selectedSport) { _ in
                fetchMapData()
            }
            .onChange(of: viewModel.selectedTimeFilter) { _ in
                fetchMapData()
            }
            .onChange(of: viewModel.selectedDistance) { newDistance in
                viewModel.updateDistance(newDistance)
                fetchMapData()
            }
            .sheet(isPresented: $showListView) {
                MapListView(
                    venues: viewModel.venues,
                    games: viewModel.games,
                    onVenueSelected: { venue in
                        viewModel.centerOnVenue(venue)
                        showListView = false
                    },
                    onGameSelected: { game in
                        viewModel.centerOnGame(game)
                        showListView = false
                    }
                )
            }
            .sheet(item: $viewModel.selectedVenue) { venue in
                VenueGamesSheet(venue: venue, games: viewModel.games.filter { $0.venueId == venue.id }, appModel: model)
            }
            .sheet(item: $viewModel.selectedGame) { game in
                MapGameDetailView(game: game, appModel: model)
            }
        }
    }
    
    // MARK: - Map Content
    
    @ViewBuilder
    private var mapContent: some View {
        Map(coordinateRegion: $viewModel.region,
            showsUserLocation: locationManager.permissionState == .authorizedWhenInUse || locationManager.permissionState == .authorizedAlways,
            userTrackingMode: .none,
            annotationItems: viewModel.annotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                Group {
                    switch annotation {
                    case .venue(let venue):
                        VenuePinButton(
                            venue: venue,
                            isSelected: Binding(
                                get: { viewModel.selectedVenue?.id == venue.id },
                                set: { isSelected in
                                    if isSelected {
                                        viewModel.centerOnVenue(venue)
                                    } else {
                                        viewModel.selectedVenue = nil
                                    }
                                }
                            )
                        )
                    case .game(let game):
                        GamePinButton(
                            game: game,
                            isSelected: Binding(
                                get: { viewModel.selectedGame?.id == game.id },
                                set: { isSelected in
                                    if isSelected {
                                        viewModel.centerOnGame(game)
                                    } else {
                                        viewModel.selectedGame = nil
                                    }
                                }
                            )
                        )
                    }
                }
            }
        }
    }
    
    
    // MARK: - Filters Overlay
    
    private var filtersOverlay: some View {
        VStack(spacing: 12) {
            // Sport Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterPill(
                        title: "All",
                        isSelected: viewModel.selectedSport == nil,
                        action: { viewModel.selectedSport = nil }
                    )
                    ForEach(Sport.playable) { sport in
                        FilterPill(
                            title: sport.rawValue.capitalized,
                            isSelected: viewModel.selectedSport == sport,
                            action: { viewModel.selectedSport = sport }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Time & Distance Filters + List Toggle
            HStack(spacing: 12) {
                // Time Filter
                Menu {
                    ForEach(MapTimeFilter.allCases) { filter in
                        Button {
                            viewModel.selectedTimeFilter = filter
                        } label: {
                            HStack {
                                Text(filter.label)
                                if viewModel.selectedTimeFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "clock")
                        Text(viewModel.selectedTimeFilter.label)
                    }
                    .font(.montserratMedium(size: 14))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                // Distance Filter
                Menu {
                    ForEach(MapDistancePreset.allCases) { preset in
                        Button {
                            viewModel.selectedDistance = preset
                        } label: {
                            HStack {
                                Text(preset.label)
                                if viewModel.selectedDistance == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "location.circle")
                        Text(viewModel.selectedDistance.label)
                    }
                    .font(.montserratMedium(size: 14))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                Spacer()
                
                // List Toggle
                Button {
                    showListView = true
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 18))
                        .foregroundColor(.textPrimary)
                        .padding(10)
                        .background(Color.cardBackground)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.screenBackground.opacity(0.95))
    }
    
    // MARK: - Permission Denied Overlay
    
    private var permissionDeniedOverlay: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 48))
                .foregroundColor(.textSecondary)
            
            Text("Location Access Needed")
                .font(.montserratBold(size: 20))
                .foregroundColor(.textPrimary)
            
            Text("Hook uses your location to show nearby games and venues. Location is used only for discovery — player locations are never shown.")
                .font(.montserrat(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button {
                    locationManager.openSettings()
                } label: {
                    Text("Open Settings")
                        .font(.montserratSemiBold(size: 16))
                        .foregroundColor(.buttonPrimaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.buttonPrimaryBackground)
                        .cornerRadius(12)
                }
                
                Button {
                    showLocationSearch = true
                } label: {
                    Text("Search Location")
                        .font(.montserratSemiBold(size: 16))
                        .foregroundColor(.buttonGhostText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cardBorder, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 24)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.screenBackground)
        .sheet(isPresented: $showLocationSearch) {
            ManualLocationSearchView(
                searchText: $manualLocationSearch,
                onLocationSelected: { coordinate in
                    viewModel.centerOnCoordinate(coordinate, zoomLevel: 0.1)
                    fetchMapData(at: coordinate)
                    showLocationSearch = false
                }
            )
        }
    }
    
    // MARK: - Empty State Overlay
    
    private var emptyStateOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 48))
                .foregroundColor(.textSecondary)
            
            Text("No games or venues found")
                .font(.montserratBold(size: 20))
                .foregroundColor(.textPrimary)
            
            Text("Try expanding your search radius or creating a new game.")
                .font(.montserrat(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if viewModel.selectedDistance != .fifty {
                Button {
                    withAnimation {
                        viewModel.selectedDistance = MapDistancePreset(rawValue: viewModel.selectedDistance.rawValue * 2) ?? .fifty
                    }
                } label: {
                    Text("Expand Radius")
                        .font(.montserratSemiBold(size: 16))
                        .foregroundColor(.buttonPrimaryText)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.buttonPrimaryBackground)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.screenBackground.opacity(0.9))
    }
    
    // MARK: - Helpers
    
    private func checkAndRequestLocation() {
        switch locationManager.permissionState {
        case .notDetermined:
            showPermissionAlert = true
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            // If we already have a location, initialize region immediately
            if let location = locationManager.currentLocation {
                viewModel.initializeRegionToUserLocation(location)
                fetchMapData()
            }
        default:
            break
        }
    }
    
    private func fetchMapData() {
        guard let location = locationManager.currentLocation else { return }
        fetchMapData(at: location.coordinate)
    }
    
    private func fetchMapData(at coordinate: CLLocationCoordinate2D) {
        viewModel.isLoading = true
        
        Task {
            do {
                async let venuesTask = MapService.shared.fetchVenues(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    radiusMiles: viewModel.selectedDistance.rawValue,
                    sport: viewModel.selectedSport
                )
                
                async let gamesTask = MapService.shared.fetchGames(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    radiusMiles: viewModel.selectedDistance.rawValue,
                    sport: viewModel.selectedSport,
                    timeWindow: viewModel.selectedTimeFilter
                )
                
                let (fetchedVenues, fetchedGames) = try await (venuesTask, gamesTask)
                
                await MainActor.run {
                    viewModel.setVenues(fetchedVenues)
                    viewModel.setGames(fetchedGames)
                    
                    // Auto-expand if fewer than 5 items found
                    if fetchedVenues.count + fetchedGames.count < 5 && viewModel.selectedDistance != .fifty {
                        viewModel.selectedDistance = MapDistancePreset(rawValue: viewModel.selectedDistance.rawValue * 2) ?? .fifty
                    }
                    
                    viewModel.isLoading = false
                    print("📍 Map data loaded: \(fetchedVenues.count) venues, \(fetchedGames.count) games")
                }
            } catch {
                await MainActor.run {
                    viewModel.isLoading = false
                    print("❌ Error fetching map data: \(error)")
                }
            }
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.montserratMedium(size: 14))
                .foregroundColor(isSelected ? .buttonPrimaryText : .textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.buttonPrimaryBackground : Color.cardBackground)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Supporting Views

struct MapListView: View {
    let venues: [Venue]
    let games: [MapGame]
    let onVenueSelected: (Venue) -> Void
    let onGameSelected: (MapGame) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if !venues.isEmpty {
                    Section("Venues") {
                        ForEach(venues) { venue in
                            Button {
                                onVenueSelected(venue)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.brandBlack)
                                    VStack(alignment: .leading) {
                                        Text(venue.name)
                                            .font(.montserratSemiBold(size: 16))
                                            .foregroundColor(.textPrimary)
                                        Text(venue.address)
                                            .font(.montserrat(size: 13))
                                            .foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                
                if !games.isEmpty {
                    Section("Games") {
                        ForEach(games) { game in
                            Button {
                                onGameSelected(game)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "sportscourt.fill")
                                        .foregroundColor(.brandPrimary)
                                    VStack(alignment: .leading) {
                                        Text(game.title)
                                            .font(.montserratSemiBold(size: 16))
                                            .foregroundColor(.textPrimary)
                                        Text(formatGameTime(game.startTime))
                                            .font(.montserrat(size: 13))
                                            .foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Map Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatGameTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct VenueGamesSheet: View {
    let venue: Venue
    let games: [MapGame]
    let appModel: AppModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(venue.name)
                        .font(.montserratBold(size: 24))
                        .foregroundColor(.textPrimary)
                    Text(venue.address)
                        .font(.montserrat(size: 15))
                        .foregroundColor(.textSecondary)
                }
                .padding()
                
                if games.isEmpty {
                    Text("No upcoming games at this venue.")
                        .font(.montserrat(size: 15))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    List {
                        ForEach(games) { game in
                            NavigationLink {
                                MapGameDetailView(game: game, appModel: appModel)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(game.title)
                                        .font(.montserratSemiBold(size: 16))
                                        .foregroundColor(.textPrimary)
                                    Text(formatGameTime(game.startTime))
                                        .font(.montserrat(size: 13))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Venue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatGameTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct MapGameDetailView: View {
    let game: MapGame
    let appModel: AppModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        // Map to existing Game model if possible, or show simplified view
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(game.title)
                    .font(.montserratBold(size: 28))
                    .foregroundColor(.textPrimary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text(formatGameTime(game.startTime))
                            .foregroundColor(.textPrimary)
                    } icon: {
                        Image(systemName: "clock")
                            .foregroundColor(.brandMediumBlue)
                    }
                    
                    if let venueName = game.venueName {
                        Label {
                            Text(venueName)
                                .foregroundColor(.textPrimary)
                        } icon: {
                            Image(systemName: "mappin")
                                .foregroundColor(.brandMediumBlue)
                        }
                    }
                    
                    Label {
                        Text("Host: \(game.hostName)")
                            .foregroundColor(.textPrimary)
                    } icon: {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.brandMediumBlue)
                    }
                    
                    Label {
                        Text("\(game.playerCount)/\(game.playerCap) players")
                            .foregroundColor(.textPrimary)
                    } icon: {
                        Image(systemName: "person.3")
                            .foregroundColor(.brandMediumBlue)
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
            }
            .padding()
        }
        .background(Color.screenBackground)
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func formatGameTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct ManualLocationSearchView: View {
    @Binding var searchText: String
    let onLocationSelected: (CLLocationCoordinate2D) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var searchResults: [MKMapItem] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search city or zip code", text: $searchText)
                    .font(.montserrat(size: 16))
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    .padding()
                    .onSubmit {
                        performSearch()
                    }
                
                List(searchResults, id: \.self) { item in
                    Button {
                        if let coordinate = item.placemark.location?.coordinate {
                            onLocationSelected(coordinate)
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Unknown")
                                .font(.montserratSemiBold(size: 16))
                                .foregroundColor(.textPrimary)
                            Text(item.placemark.title ?? "")
                                .font(.montserrat(size: 13))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                searchResults = response.mapItems
            }
        }
    }
}
