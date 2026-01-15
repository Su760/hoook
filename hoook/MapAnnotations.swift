//
//  MapAnnotations.swift
//  hook
//
//  MapKit annotation views for venues and games
//

import SwiftUI
import MapKit

// MARK: - Annotation Items

enum MapAnnotationType: Identifiable {
    case venue(Venue)
    case game(MapGame)
    
    var id: UUID {
        switch self {
        case .venue(let venue):
            return venue.id
        case .game(let game):
            return game.id
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .venue(let venue):
            return venue.coordinate
        case .game(let game):
            return game.coordinate
        }
    }
}

// MARK: - Annotation View

struct MapAnnotationView: View {
    let annotation: MapAnnotationType
    @State private var isSelected = false
    
    var body: some View {
        switch annotation {
        case .venue:
            VenuePinView(isSelected: $isSelected)
        case .game:
            GamePinView(isSelected: $isSelected)
        }
    }
}

// MARK: - Pin Buttons with Bindings

struct VenuePinButton: View {
    let venue: Venue
    @Binding var isSelected: Bool
    
    var body: some View {
        Button {
            isSelected = true
        } label: {
            VenuePinView(isSelected: $isSelected)
        }
    }
}

struct GamePinButton: View {
    let game: MapGame
    @Binding var isSelected: Bool
    
    var body: some View {
        Button {
            isSelected = true
        } label: {
            GamePinView(isSelected: $isSelected)
        }
    }
}

// MARK: - Venue Pin

struct VenuePinView: View {
    @Binding var isSelected: Bool
    
    var body: some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: 30))
            .foregroundColor(.brandBlack)
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Game Pin

struct GamePinView: View {
    @Binding var isSelected: Bool
    
    var body: some View {
        Image(systemName: "sportscourt.fill")
            .font(.system(size: 28))
            .foregroundColor(.brandPrimary)
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Callout Views

struct VenueCalloutView: View {
    let venue: Venue
    let onViewGames: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(venue.name)
                .font(.montserratBold(size: 16))
                .foregroundColor(.textPrimary)
            
            Text(venue.address)
                .font(.montserrat(size: 13))
                .foregroundColor(.textSecondary)
            
            Button {
                onViewGames()
            } label: {
                Text("View games")
                    .font(.montserratSemiBold(size: 14))
                    .foregroundColor(.buttonPrimaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.buttonPrimaryBackground)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct GameCalloutView: View {
    let game: MapGame
    let onSeeDetails: () -> Void
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(game.startTime) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: game.startTime))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: game.startTime)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(game.title)
                .font(.montserratBold(size: 16))
                .foregroundColor(.textPrimary)
            
            VStack(alignment: .leading, spacing: 4) {
                Label {
                    Text(formattedTime)
                        .font(.montserrat(size: 13))
                        .foregroundColor(.textSecondary)
                } icon: {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Label {
                    Text("Host: \(game.hostName)")
                        .font(.montserrat(size: 13))
                        .foregroundColor(.textSecondary)
                } icon: {
                    Image(systemName: "person.circle")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                if let venueName = game.venueName {
                    Label {
                        Text(venueName)
                            .font(.montserrat(size: 13))
                            .foregroundColor(.textSecondary)
                    } icon: {
                        Image(systemName: "mappin")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            
            Button {
                onSeeDetails()
            } label: {
                Text("See details")
                    .font(.montserratSemiBold(size: 14))
                    .foregroundColor(.buttonPrimaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.buttonPrimaryBackground)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(width: 220)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
