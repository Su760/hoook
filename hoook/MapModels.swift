//
//  MapModels.swift
//  hook
//
//  Venue and Game models for map-based discovery
//

import Foundation
import CoreLocation

// MARK: - Venue Model

struct Venue: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let sportTypes: [String] // e.g., ["basketball", "soccer"]
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(id: UUID = UUID(), name: String, address: String, latitude: Double, longitude: Double, sportTypes: [String] = []) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.sportTypes = sportTypes
    }
}

// MARK: - Map Game Model (simplified for map display)

struct MapGame: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let sport: String
    let venueId: UUID?
    let venueName: String?
    let startTime: Date
    let hostId: UUID
    let hostName: String
    let latitude: Double
    let longitude: Double
    let skillBand: String
    let playerCount: Int
    let playerCap: Int
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(id: UUID = UUID(), 
         title: String, 
         sport: String, 
         venueId: UUID? = nil,
         venueName: String? = nil,
         startTime: Date,
         hostId: UUID,
         hostName: String,
         latitude: Double,
         longitude: Double,
         skillBand: String,
         playerCount: Int,
         playerCap: Int) {
        self.id = id
        self.title = title
        self.sport = sport
        self.venueId = venueId
        self.venueName = venueName
        self.startTime = startTime
        self.hostId = hostId
        self.hostName = hostName
        self.latitude = latitude
        self.longitude = longitude
        self.skillBand = skillBand
        self.playerCount = playerCount
        self.playerCap = playerCap
    }
}

// MARK: - API Response Models

struct VenuesResponse: Codable {
    let venues: [Venue]
}

struct GamesResponse: Codable {
    let games: [MapGame]
}

// MARK: - Map Filter Models

enum MapTimeFilter: String, CaseIterable, Identifiable {
    case now = "now"
    case today = "today"
    case next24h = "next24h"
    case thisWeek = "thisWeek"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .now: return "Now"
        case .today: return "Today"
        case .next24h: return "Next 24h"
        case .thisWeek: return "This Week"
        }
    }
}

enum MapDistancePreset: Int, CaseIterable, Identifiable {
    case ten = 10
    case twenty = 20
    case fifty = 50
    
    var id: Int { rawValue }
    
    var label: String {
        "\(rawValue) mi"
    }
}
