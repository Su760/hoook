//
//  MapService.swift
//  hook
//
//  Network layer for fetching venues and games with caching
//

import Foundation
import CoreLocation

class MapService {
    static let shared = MapService()
    
    // Cache duration: 60 seconds
    private let cacheDuration: TimeInterval = 60.0
    private var venuesCache: [Venue] = []
    private var gamesCache: [MapGame] = []
    private var cacheTimestamp: Date?
    
    private init() {}
    
    // MARK: - Fetch Venues
    
    func fetchVenues(
        latitude: Double,
        longitude: Double,
        radiusMiles: Int,
        sport: Sport? = nil
    ) async throws -> [Venue] {
        // Check cache
        if let cached = getCachedVenues(
            latitude: latitude,
            longitude: longitude,
            radiusMiles: radiusMiles,
            sport: sport
        ) {
            return cached
        }
        
        // TODO: Replace with actual API endpoint
        // let url = URL(string: "https://api.hook.app/venues?lat=\(latitude)&lng=\(longitude)&radius_miles=\(radiusMiles)&sport=\(sport?.rawValue ?? "")")!
        
        // For now, return mock data
        let venues = generateMockVenues(
            centerLat: latitude,
            centerLng: longitude,
            radiusMiles: radiusMiles,
            sport: sport
        )
        
        // Update cache
        venuesCache = venues
        cacheTimestamp = Date()
        
        return venues
    }
    
    // MARK: - Fetch Games
    
    func fetchGames(
        latitude: Double,
        longitude: Double,
        radiusMiles: Int,
        sport: Sport? = nil,
        timeWindow: MapTimeFilter = .today
    ) async throws -> [MapGame] {
        // Check cache
        if let cached = getCachedGames(
            latitude: latitude,
            longitude: longitude,
            radiusMiles: radiusMiles,
            sport: sport,
            timeWindow: timeWindow
        ) {
            return cached
        }
        
        // TODO: Replace with actual API endpoint
        // let url = URL(string: "https://api.hook.app/games?lat=\(latitude)&lng=\(longitude)&radius_miles=\(radiusMiles)&sport=\(sport?.rawValue ?? "")&time_window=\(timeWindow.rawValue)")!
        
        // For now, return mock data
        let games = generateMockGames(
            centerLat: latitude,
            centerLng: longitude,
            radiusMiles: radiusMiles,
            sport: sport,
            timeWindow: timeWindow
        )
        
        // Update cache
        gamesCache = games
        cacheTimestamp = Date()
        
        return games
    }
    
    // MARK: - Cache Helpers
    
    private func getCachedVenues(
        latitude: Double,
        longitude: Double,
        radiusMiles: Int,
        sport: Sport?
    ) -> [Venue]? {
        guard let timestamp = cacheTimestamp,
              Date().timeIntervalSince(timestamp) < cacheDuration else {
            return nil
        }
        return venuesCache
    }
    
    private func getCachedGames(
        latitude: Double,
        longitude: Double,
        radiusMiles: Int,
        sport: Sport?,
        timeWindow: MapTimeFilter
    ) -> [MapGame]? {
        guard let timestamp = cacheTimestamp,
              Date().timeIntervalSince(timestamp) < cacheDuration else {
            return nil
        }
        return gamesCache
    }
    
    // MARK: - Mock Data Generators
    
    private func generateMockVenues(
        centerLat: Double,
        centerLng: Double,
        radiusMiles: Int,
        sport: Sport?
    ) -> [Venue] {
        // Generate mock venues around the center point
        var venues: [Venue] = []
        
        // Convert miles to approximate degrees (rough approximation: 1 degree ≈ 69 miles)
        let radiusDegrees = Double(radiusMiles) / 69.0
        
        let venueNames = [
            "Gregory Gymnasium",
            "Whitaker Fields",
            "Recreational Sports Center",
            "Belmont Hall Courts",
            "East Campus Courts",
            "Intramural Fields",
            "Recreation Center",
            "West Campus Gym",
            "North Field Complex",
            "South Athletic Facility"
        ]
        
        let addresses = [
            "2101 Speedway, Austin, TX 78712",
            "2101 Speedway, Austin, TX 78712",
            "2001 San Jacinto Blvd, Austin, TX 78712",
            "2100 San Antonio St, Austin, TX 78705",
            "2101 Speedway, Austin, TX 78712",
            "2101 Speedway, Austin, TX 78712",
            "2101 Speedway, Austin, TX 78712",
            "2400 Nueces St, Austin, TX 78705",
            "2400 Nueces St, Austin, TX 78705",
            "2101 Speedway, Austin, TX 78712"
        ]
        
        for (index, name) in venueNames.enumerated() {
            // Generate random offset within radius
            let angle = Double(index) * 2.0 * .pi / Double(venueNames.count)
            let distance = Double.random(in: 0.1...radiusDegrees)
            let latOffset = distance * cos(angle)
            let lngOffset = distance * sin(angle)
            
            venues.append(Venue(
                name: name,
                address: addresses[index % addresses.count],
                latitude: centerLat + latOffset,
                longitude: centerLng + lngOffset,
                sportTypes: ["basketball", "soccer", "volleyball"]
            ))
        }
        
        return venues
    }
    
    private func generateMockGames(
        centerLat: Double,
        centerLng: Double,
        radiusMiles: Int,
        sport: Sport?,
        timeWindow: MapTimeFilter
    ) -> [MapGame] {
        var games: [MapGame] = []
        let now = Date()
        
        // Generate games at different times based on time window
        let timeOffsets: [TimeInterval]
        switch timeWindow {
        case .now:
            timeOffsets = [0, 1800, 3600] // now, +30min, +1hr
        case .today:
            timeOffsets = [3600, 7200, 14400, 21600] // +1hr to +6hr
        case .next24h:
            timeOffsets = [3600, 7200, 14400, 21600, 43200, 64800]
        case .thisWeek:
            timeOffsets = [86400, 172800, 259200, 345600, 432000]
        }
        
        let radiusDegrees = Double(radiusMiles) / 69.0
        let sports: [Sport] = sport != nil ? [sport!] : [.basketball, .soccer, .tennis, .pickleball, .volleyball]
        
        for (index, offset) in timeOffsets.enumerated() {
            let gameSport = sports[index % sports.count]
            let angle = Double(index) * 2.0 * .pi / Double(timeOffsets.count)
            let distance = Double.random(in: 0.1...radiusDegrees)
            let latOffset = distance * cos(angle)
            let lngOffset = distance * sin(angle)
            
            games.append(MapGame(
                title: "\(gameSport.rawValue.capitalized) pickup",
                sport: gameSport.rawValue,
                venueName: "Venue \(index + 1)",
                startTime: now.addingTimeInterval(offset),
                hostId: UUID(),
                hostName: "Player \(index + 1)",
                latitude: centerLat + latOffset,
                longitude: centerLng + lngOffset,
                skillBand: ["casual", "intermediate", "competitive"][index % 3],
                playerCount: Int.random(in: 2...8),
                playerCap: 10
            ))
        }
        
        return games
    }
}
