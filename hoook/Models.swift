import Foundation
import SwiftUI
import Combine

enum Sport: String, CaseIterable, Identifiable {
    case all
    case basketball
    case soccer
    case tennis
    case pickleball
    case volleyball
    case other

    var id: String { rawValue }

    static var playable: [Sport] {
        allCases.filter { $0 != .all }
    }
}

enum SkillBand: String, CaseIterable, Identifiable {
    case all
    case casual
    case intermediate
    case competitive

    var id: String { rawValue }

    var display: String {
        switch self {
        case .casual: return "Casual"
        case .intermediate: return "Intermediate"
        case .competitive: return "Competitive"
        case .all: return "All"
        }
    }
}

enum Availability: String, CaseIterable, Identifiable {
    case weeknights
    case weekends
    case mornings
    case anytime

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weeknights: return "Weeknights"
        case .weekends: return "Weekends"
        case .mornings: return "Mornings"
        case .anytime: return "Anytime"
        }
    }
}

enum TimeWindow: String, CaseIterable, Identifiable {
    case today
    case tomorrow
    case week
    case weekend
    case all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .week: return "This Week"
        case .weekend: return "Weekend"
        case .all: return "All"
        }
    }
}

struct User: Identifiable, Hashable {
    let id: UUID
    var firstName: String
    var lastInitial: String
    var skillBand: SkillBand
    var availability: Availability
    var sports: [Sport]
    var bio: String
    var gamesPlayed: Int = 0
    var gamesHosted: Int = 0

    var displayName: String {
        "\(firstName) \(lastInitial)."
    }

    var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        return first + lastInitial
    }
}

struct Game: Identifiable, Hashable {
    let id: UUID
    var title: String
    var sport: Sport
    var date: Date
    var location: String
    var skillBand: SkillBand
    var playerCap: Int
    var onCampus: Bool
    var host: User
    var roster: [User]
    var waitlist: [User]
    var description: String

    var spotsLeft: Int {
        max(playerCap - roster.count, 0)
    }

    var isFull: Bool {
        roster.count >= playerCap
    }

    func isUserJoined(_ user: User) -> Bool {
        roster.contains(user)
    }

    func isUserWaitlisted(_ user: User) -> Bool {
        waitlist.contains(user)
    }

    func actionLabel(for user: User) -> String {
        if isUserJoined(user) { return "Leave" }
        if isUserWaitlisted(user) { return "Leave waitlist" }
        return isFull ? "Join waitlist" : "Join"
    }
}

final class AppModel: ObservableObject {
    @Published var currentUser: User
    @Published private(set) var games: [Game]

    init(seed: Bool = false) {
        var user = User(
            id: UUID(),
            firstName: "Alex",
            lastInitial: "S",
            skillBand: .intermediate,
            availability: .weeknights,
            sports: [.basketball, .soccer, .pickleball],
            bio: "UT Austin student who loves pickup hoops and casual soccer."
        )
        if seed {
            let seededGames = AppModel.seedGames(host: user)
            user.gamesHosted = seededGames.count
            games = seededGames
        } else {
            games = []
        }
        currentUser = user
    }

    func filteredGames(sport: Sport?, skill: SkillBand?, onCampusOnly: Bool, timeWindow: TimeWindow) -> [Game] {
        games.filter { game in
            let matchesSport = sport == nil || sport == .all || game.sport == sport
            let matchesSkill = skill == nil || skill == .all || game.skillBand == skill
            let matchesCampus = !onCampusOnly || game.onCampus
            let matchesTime: Bool
            switch timeWindow {
            case .today:
                matchesTime = Calendar.current.isDateInToday(game.date)
            case .tomorrow:
                matchesTime = Calendar.current.isDateInTomorrow(game.date)
            case .week:
                matchesTime = Calendar.current.isDate(game.date, equalTo: Date(), toGranularity: .weekOfYear)
            case .weekend:
                let weekday = Calendar.current.component(.weekday, from: game.date)
                matchesTime = weekday == 1 || weekday == 7 // Saturday or Sunday
            case .all:
                matchesTime = true
            }
            return matchesSport && matchesSkill && matchesCampus && matchesTime
        }
        .sorted { $0.date < $1.date }
    }

    func join(gameID: UUID) {
        guard let idx = games.firstIndex(where: { $0.id == gameID }) else { return }
        var game = games[idx]
        if game.isUserJoined(currentUser) || game.isUserWaitlisted(currentUser) { return }

        if game.roster.count < game.playerCap {
            game.roster.append(currentUser)
        } else {
            game.waitlist.append(currentUser)
        }
        games[idx] = game
    }

    func leave(gameID: UUID) {
        guard let idx = games.firstIndex(where: { $0.id == gameID }) else { return }
        var game = games[idx]
        game.roster.removeAll { $0 == currentUser }
        game.waitlist.removeAll { $0 == currentUser }

        if game.roster.count < game.playerCap, let next = game.waitlist.first {
            game.waitlist.removeFirst()
            game.roster.append(next)
        }
        games[idx] = game
    }

    @discardableResult
    func createGame(title: String, sport: Sport, date: Date, location: String, skillBand: SkillBand, cap: Int, onCampus: Bool, recurrence: Int, description: String) -> Bool {
        var newGames: [Game] = []
        for offset in 0...recurrence {
            let nextDate = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: date) ?? date
            let game = Game(
                id: UUID(),
                title: title,
                sport: sport,
                date: nextDate,
                location: location,
                skillBand: skillBand,
                playerCap: cap,
                onCampus: onCampus,
                host: currentUser,
                roster: [currentUser], // Changed from [] to [currentUser]
                waitlist: [],
                description: description
            )
            newGames.append(game)
        }
        games.append(contentsOf: newGames)
        currentUser.gamesHosted += newGames.count
        return true
    }

    func updateProfile(skill: SkillBand, bio: String, sports: Set<Sport>, availability: Availability) {
        currentUser.skillBand = skill
        currentUser.bio = bio
        currentUser.sports = Array(sports)
        currentUser.availability = availability
    }

    private static func seedGames(host: User) -> [Game] {
        let now = Date()
        let jordan = User(
            id: UUID(),
            firstName: "Jordan",
            lastInitial: "P",
            skillBand: .casual,
            availability: .weekends,
            sports: [.basketball, .soccer],
            bio: "Shows up early, brings an extra ball."
        )
        let dev = User(
            id: UUID(),
            firstName: "Dev",
            lastInitial: "K",
            skillBand: .competitive,
            availability: .anytime,
            sports: [.pickleball, .tennis],
            bio: "Club player testing competitive runs."
        )

        // Create a game for today at 6pm
        let calendar = Calendar.current
        var today6pm = calendar.startOfDay(for: now)
        today6pm = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today6pm) ?? now
        if today6pm < now {
            today6pm = calendar.date(byAdding: .day, value: 1, to: today6pm) ?? now
        }
        
        let games: [Game] = [
            Game(
                id: UUID(),
                title: "Evening Basketball",
                sport: .basketball,
                date: today6pm,
                location: "Whitaker Fields",
                skillBand: .casual,
                playerCap: 10,
                onCampus: true,
                host: host,
                roster: [host],
                waitlist: [],
                description: "Casual pickup game. All skill levels welcome."
            ),
            Game(
                id: UUID(),
                title: "Pickleball – West Campus Courts",
                sport: .pickleball,
                date: now.addingTimeInterval(60 * 60 * 4),
                location: "Intramural Courts",
                skillBand: .intermediate,
                playerCap: 8,
                onCampus: true,
                host: host,
                roster: [jordan, dev],
                waitlist: [],
                description: "Casual run, paddles available. Show up 10 min early."
            ),
            Game(
                id: UUID(),
                title: "Friday Night Hoops",
                sport: .basketball,
                date: now.addingTimeInterval(60 * 60 * 24),
                location: "Gregory Gym Court 3",
                skillBand: .casual,
                playerCap: 10,
                onCampus: true,
                host: host,
                roster: [host, jordan],
                waitlist: [],
                description: "Anchor game to keep the list warm. All levels welcome."
            ),
            Game(
                id: UUID(),
                title: "Weekend Soccer Scrimmage",
                sport: .soccer,
                date: now.addingTimeInterval(60 * 60 * 54),
                location: "Whitaker Fields",
                skillBand: .competitive,
                playerCap: 14,
                onCampus: false,
                host: host,
                roster: [dev],
                waitlist: [jordan],
                description: "Full-field if we hit 14. Bring a light and dark shirt."
            ),
            Game(
                id: UUID(),
                title: "Volleyball Practice",
                sport: .volleyball,
                date: today6pm.addingTimeInterval(60 * 60 * 2),
                location: "Intramural Courts",
                skillBand: .intermediate,
                playerCap: 12,
                onCampus: true,
                host: host,
                roster: [host],
                waitlist: [],
                description: "Intermediate level volleyball game."
            )
        ]
        return games
    }
}
