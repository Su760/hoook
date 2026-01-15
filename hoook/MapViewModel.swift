//
//  MapViewModel.swift
//  hook
//
//  ViewModel for managing map state, annotations, and region updates
//

import Foundation
import MapKit
import CoreLocation
import Combine
import SwiftUI

@MainActor
class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var region: MKCoordinateRegion
    @Published var venues: [Venue] = []
    @Published var games: [MapGame] = []
    @Published var isLoading = false
    @Published var selectedVenue: Venue?
    @Published var selectedGame: MapGame?
    @Published var selectedSport: Sport? = nil
    @Published var selectedTimeFilter: MapTimeFilter = .today
    @Published var selectedDistance: MapDistancePreset = .ten
    
    // MARK: - Private Properties
    
    var hasInitializedRegion = false
    private var isUserInteracting = false
    
    // MARK: - Computed Properties
    
    var annotations: [MapAnnotationType] {
        var items: [MapAnnotationType] = []
        items.append(contentsOf: venues.map { MapAnnotationType.venue($0) })
        items.append(contentsOf: games.map { MapAnnotationType.game($0) })
        return items
    }
    
    // MARK: - Initialization
    
    init() {
        // Default to UT Austin area
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
    }
    
    // MARK: - Region Management
    
    func initializeRegionToUserLocation(_ location: CLLocation) {
        guard !hasInitializedRegion else { return }
        hasInitializedRegion = true
        
        let distance = Double(selectedDistance.rawValue)
        let span = MKCoordinateSpan(
            latitudeDelta: max(distance / 69.0, 0.05), // Minimum zoom level
            longitudeDelta: max(distance / 69.0, 0.05)
        )
        
        withAnimation(.easeOut(duration: 0.5)) {
            region = MKCoordinateRegion(center: location.coordinate, span: span)
        }
        print("📍 Initialized region: lat=\(location.coordinate.latitude), lng=\(location.coordinate.longitude), span=\(span.latitudeDelta)")
    }
    
    func updateRegionToUserLocation(_ location: CLLocation) {
        guard !hasInitializedRegion else { return }
        initializeRegionToUserLocation(location)
    }
    
    func centerOnCoordinate(_ coordinate: CLLocationCoordinate2D, zoomLevel: Double = 0.01) {
        isUserInteracting = true
        withAnimation(.easeOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: zoomLevel, longitudeDelta: zoomLevel)
            )
        }
        print("📍 Centered on: lat=\(coordinate.latitude), lng=\(coordinate.longitude), zoom=\(zoomLevel)")
    }
    
    func centerOnVenue(_ venue: Venue) {
        selectedVenue = venue
        selectedGame = nil
        centerOnCoordinate(venue.coordinate, zoomLevel: 0.015)
    }
    
    func centerOnGame(_ game: MapGame) {
        selectedGame = game
        selectedVenue = nil
        centerOnCoordinate(game.coordinate, zoomLevel: 0.015)
    }
    
    func updateDistance(_ newDistance: MapDistancePreset) {
        guard newDistance != selectedDistance else { return }
        selectedDistance = newDistance
        
        // Only update region if we haven't initialized yet or user hasn't interacted
        if !hasInitializedRegion || !isUserInteracting {
            let distance = Double(newDistance.rawValue)
            let span = MKCoordinateSpan(
                latitudeDelta: max(distance / 69.0, 0.05),
                longitudeDelta: max(distance / 69.0, 0.05)
            )
            withAnimation(.easeOut(duration: 0.3)) {
                region = MKCoordinateRegion(center: region.center, span: span)
            }
        }
    }
    
    // MARK: - Data Management
    
    func setVenues(_ newVenues: [Venue]) {
        venues = newVenues
        print("📍 Loaded \(newVenues.count) venues")
    }
    
    func setGames(_ newGames: [MapGame]) {
        games = newGames
        print("📍 Loaded \(newGames.count) games")
    }
    
    func clearSelection() {
        selectedVenue = nil
        selectedGame = nil
    }
}
