import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var model = AppModel(seed: false)
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GamesHomeView()
                .environmentObject(model)
                .tabItem {
                    Label("Games", systemImage: "house.fill")
                }
                .tag(0)
            
            HostGameView()
                .environmentObject(model)
                .tabItem {
                    Label("Host", systemImage: "plus.circle.fill")
                }
                .tag(2)

            ProfileView()
                .environmentObject(model)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(3)
        }
        .tint(.tabActiveIndicator)
    }
}

struct GamesHomeView: View {
    @EnvironmentObject var model: AppModel
    @State private var sportFilter: Sport? = nil
    @State private var skillFilter: SkillBand? = nil
    @State private var onCampusOnly = false
    @State private var timeFilter: TimeWindow = .today
    @State private var showFilters = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with logo
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Games Near You")
                                .font(.montserratBold(size: 34))
                                .foregroundColor(.navigationText)
                            
                            Text("Find your next pickup game")
                                .font(.montserrat(size: 15))
                                .foregroundColor(.navigationText.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Anchor logo aligned to the right
                        Image("1")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .background(Color.navigationBackground)
                
                // Time Filter Pills
                TimeFilterPillsView(selectedTime: $timeFilter, onFiltersTap: {
                    showFilters = true
                })
                    .padding(.vertical, 12)
                    .background(Color.navigationBackground)
                
                // Game List
                if model.filteredGames(sport: sportFilter, skill: skillFilter, onCampusOnly: onCampusOnly, timeWindow: timeFilter).isEmpty {
                    EmptyStateView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.screenBackground)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(model.filteredGames(sport: sportFilter, skill: skillFilter, onCampusOnly: onCampusOnly, timeWindow: timeFilter)) { game in
                                NavigationLink {
                                    GameDetailView(game: game)
                                } label: {
                                    GameCard(game: game, currentUser: model.currentUser, joinAction: {
                                        model.join(gameID: game.id)
                                    }, leaveAction: {
                                        model.leave(gameID: game.id)
                                    })
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .background(Color.screenBackground)
                }
            }
            .background(Color.screenBackground)
            .navigationBarHidden(true)
            .sheet(isPresented: $showFilters) {
                FiltersSheetView(sport: $sportFilter, skill: $skillFilter, onCampusOnly: $onCampusOnly)
            }
        }
    }
}

struct TimeFilterPillsView: View {
    @Binding var selectedTime: TimeWindow
    var onFiltersTap: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([TimeWindow.today, .tomorrow, .week, .weekend]) { window in
                        Button {
                            selectedTime = window
                        } label: {
                            Text(window.label)
                                .font(.montserratMedium(size: 14))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedTime == window ? Color.tabActiveIndicator : Color.navigationText.opacity(0.2))
                                .foregroundColor(selectedTime == window ? .navigationText : .navigationText.opacity(0.8))
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if let onFiltersTap = onFiltersTap {
                Button {
                    onFiltersTap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Filters")
                    }
                    .font(.montserratMedium(size: 14))
                    .foregroundColor(.navigationText)
                }
                .padding(.trailing)
            }
        }
    }
}

struct FiltersSheetView: View {
    @Binding var sport: Sport?
    @Binding var skill: SkillBand?
    @Binding var onCampusOnly: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Sport") {
                    Picker("Sport", selection: Binding(
                        get: { sport ?? .all },
                        set: { newValue in sport = newValue == .all ? nil : newValue }
                    )) {
                        ForEach(Sport.allCases, id: \.self) { option in
                            Text(option == .all ? "All" : option.rawValue.capitalized).tag(option)
                        }
                    }
                }
                
                Section("Skill Level") {
                    Picker("Skill", selection: Binding(
                        get: { skill ?? .all },
                        set: { newValue in skill = newValue == .all ? nil : newValue }
                    )) {
                        ForEach(SkillBand.allCases, id: \.self) { option in
                            Text(option == .all ? "All" : option.display).tag(option)
                        }
                    }
                }
                
                Section {
                    Toggle("On Campus Only", isOn: $onCampusOnly)
                }
            }
            .navigationTitle("Filters")
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
}

struct GameCard: View {
    let game: Game
    let currentUser: User
    let joinAction: () -> Void
    let leaveAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Sport Icon
            ZStack {
                Circle()
                    .fill(sportColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: sportIcon)
                    .font(.title2)
                    .foregroundColor(sportColor)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Sport Name and Skill Badge
                HStack {
                    Text(game.sport.rawValue.capitalized)
                        .font(.montserratBold(size: 18))
                        .foregroundColor(.brandPrimary)
                    Spacer()
                    Text(game.skillBand.display)
                        .font(.montserratSemiBold(size: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.brandLightBlue.opacity(0.3))
                        .foregroundColor(.brandPrimary)
                        .cornerRadius(12)
                }
                
                // Game Details
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Text(formatDate(game.date))
                            .font(.montserrat(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Text(game.location)
                            .font(.montserrat(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "person.3")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Text("\(game.roster.count)/\(game.playerCap) players")
                            .font(.montserrat(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // Action Row
                HStack {
                    Text("View details")
                        .font(.montserratMedium(size: 14))
                        .foregroundColor(.buttonGhostText)
                    
                    Spacer()
                    
                    if game.isUserJoined(currentUser) || game.isUserWaitlisted(currentUser) {
                        Button {
                            leaveAction()
                        } label: {
                            Text("Leave")
                                .font(.montserratSemiBold(size: 14))
                                .foregroundColor(.buttonSecondaryText)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.buttonSecondaryBackground)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .highPriorityGesture(TapGesture().onEnded {
                            leaveAction()
                        })
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var sportColor: Color {
        return .brandMediumBlue
    }
    
    private var sportIcon: String {
        switch game.sport {
        case .basketball: return "basketball.fill"
        case .soccer: return "soccerball"
        case .tennis: return "figure.tennis"
        case .pickleball: return "figure.pickleball"
        case .volleyball: return "figure.volleyball"
        default: return "sportscourt"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: date))"
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Tomorrow at \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct GameDetailView: View {
    @EnvironmentObject var model: AppModel
    let game: Game

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GameCard(game: game, currentUser: model.currentUser, joinAction: {
                    model.join(gameID: game.id)
                }, leaveAction: {
                    model.leave(gameID: game.id)
                })
                .padding(.horizontal, -16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Roster")
                        .font(.montserratBold(size: 18))
                        .foregroundColor(.brandPrimary)
                    if game.roster.isEmpty {
                        Text("No one has joined yet.")
                            .font(.montserrat(size: 14))
                            .foregroundColor(.textSecondary)
                    } else {
                        ForEach(game.roster) { player in
                            HStack {
                                Circle().fill(Color.brandLightBlue.opacity(0.3)).frame(width: 36, height: 36)
                                    .overlay(Text(player.initials).font(.montserratBold(size: 12)).foregroundColor(.brandPrimary))
                                VStack(alignment: .leading) {
                                    Text(player.displayName)
                                        .font(.montserratMedium(size: 15))
                                        .foregroundColor(.textPrimary)
                                    Text(player.skillBand.display)
                                        .font(.montserrat(size: 12))
                                        .foregroundColor(.textSecondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Waitlist")
                        .font(.montserratBold(size: 18))
                        .foregroundColor(.brandPrimary)
                    if game.waitlist.isEmpty {
                        Text("No one is waiting.")
                            .font(.montserrat(size: 14))
                            .foregroundColor(.textSecondary)
                    } else {
                        ForEach(game.waitlist) { player in
                            Text(player.displayName)
                                .font(.montserrat(size: 15))
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.montserratBold(size: 18))
                        .foregroundColor(.brandPrimary)
                    Label {
                        Text("Hosted by \(game.host.displayName)")
                            .foregroundColor(.textPrimary)
                    } icon: {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.brandMediumBlue)
                    }
                    Label {
                        Text(game.skillBand.display + " level")
                            .foregroundColor(.textPrimary)
                    } icon: {
                        Image(systemName: "figure.run")
                            .foregroundColor(.brandMediumBlue)
                    }
                    if game.onCampus {
                        Label {
                            Text("On campus")
                                .foregroundColor(.textPrimary)
                        } icon: {
                            Image(systemName: "building.2")
                                .foregroundColor(.brandMediumBlue)
                        }
                    }
                    if !game.description.isEmpty {
                        Text(game.description)
                            .font(.montserrat(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
            }
            .padding()
        }
        .background(Color.screenBackground)
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HostGameView: View {
    @EnvironmentObject var model: AppModel
    @State private var title = ""
    @State private var sport: Sport = .basketball
    @State private var date = Date().addingTimeInterval(3600 * 4)
    @State private var location = "Gregory Gym"
    @State private var skillBand: SkillBand = .casual
    @State private var cap: Int = 10
    @State private var onCampus = true
    @State private var recurrenceWeeks = 0
    @State private var description = ""
    @State private var showConfirmation = false
    @State private var showCustomLocation = false
    @State private var customLocationName = ""
    @State private var customLocationAddress = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header matching Games tab style
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Host a Game")
                                .font(.montserratBold(size: 34))
                                .foregroundColor(.navigationText)
                            
                            Text("Create your next pickup game")
                                .font(.montserrat(size: 15))
                                .foregroundColor(.navigationText.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Anchor logo aligned to the right
                        Image("1")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .background(Color.navigationBackground)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Basics Section
                        // Basics Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Basics")
                                .font(.montserratBold(size: 18))
                                .foregroundColor(.brandPrimary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                TextField("Title", text: $title, prompt: Text("e.g., Basketball pickup").foregroundColor(.textSecondary))
                                    .foregroundColor(.textPrimary)
                                    .padding()
                                    .background(Color.cardBackground)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                                    .cornerRadius(12)
                                
                                // Sport Picker
                                Menu {
                                    Picker("Sport", selection: $sport) {
                                        ForEach(Sport.playable) { sport in
                                            Text(sport.rawValue.capitalized).tag(sport)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text("Sport")
                                            .foregroundColor(.textSecondary)
                                        Spacer()
                                        Text(sport.rawValue.capitalized)
                                            .foregroundColor(.textPrimary)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding()
                                    .background(Color.cardBackground)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                                    .cornerRadius(12)
                                }
                                
                                // Date Picker
                                DatePicker(
                                    "Date & Time",
                                    selection: $date,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .foregroundColor(.textPrimary)
                                .padding()
                                .background(Color.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                                .cornerRadius(12)
                                
                                // Location Picker
                                Menu {
                                    Button("Gregory Gymnasium") { location = "Gregory Gymnasium" }
                                    Button("Belmont Hall") { location = "Belmont Hall" }
                                    Button("Recreational Sports Center (RSC)") { location = "Recreational Sports Center (RSC)" }
                                    Button("Whittaker Fields") { location = "Whittaker Fields" }
                                    Button("East Campus Courts") { location = "East Campus Courts" }
                                    Button("Other") {
                                        location = ""
                                        showCustomLocation = true
                                    }
                                } label: {
                                    HStack {
                                        Text("Location")
                                            .foregroundColor(.textSecondary)
                                        Spacer()
                                        Text(location.isEmpty ? "Select location" : location)
                                            .foregroundColor(.textPrimary)
                                            .lineLimit(1)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding()
                                    .background(Color.cardBackground)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)
                        
                        // Details Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.montserratBold(size: 18))
                                .foregroundColor(.brandPrimary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                // Skill Band Picker
                                Menu {
                                    Picker("Skill Band", selection: $skillBand) {
                                        ForEach(SkillBand.allCases.filter { $0 != .all }) { band in
                                            Text(band.display).tag(band)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text("Skill Band")
                                            .foregroundColor(.textSecondary)
                                        Spacer()
                                        Text(skillBand.display)
                                            .foregroundColor(.textPrimary)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding()
                                    .background(Color.cardBackground)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                                    .cornerRadius(12)
                                }
                                
                                HStack {
                                    Text("Player Cap")
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                    HStack(spacing: 16) {
                                        Button {
                                            if cap > 4 { cap -= 1 }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.brandMediumBlue)
                                        }
                                        Text("\(cap)")
                                            .font(.montserratBold(size: 18))
                                            .foregroundColor(.textPrimary)
                                            .frame(width: 40)
                                        Button {
                                            if cap < 40 { cap += 1 }
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.brandMediumBlue)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                                .cornerRadius(12)
                                
                                HStack {
                                    Text("Repeat weekly")
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                    HStack(spacing: 16) {
                                        Button {
                                            if recurrenceWeeks > 0 { recurrenceWeeks -= 1 }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.brandMediumBlue)
                                        }
                                        Text("\(recurrenceWeeks)x")
                                            .font(.montserratBold(size: 18))
                                            .foregroundColor(.textPrimary)
                                            .frame(width: 40)
                                        Button {
                                            if recurrenceWeeks < 3 { recurrenceWeeks += 1 }
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.brandMediumBlue)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                                .cornerRadius(12)
                                
                                TextField("Notes (court change, etc.)", text: $description, prompt: Text("Optional notes...").foregroundColor(.textSecondary), axis: .vertical)
                                    .foregroundColor(.textPrimary)
                                    .lineLimit(2...4)
                                    .padding()
                                    .background(Color.cardBackground)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Post Button
                        Button {
                            let created = model.createGame(
                                title: title.isEmpty ? "\(sport.rawValue.capitalized) pickup" : title,
                                sport: sport,
                                date: date,
                                location: location,
                                skillBand: skillBand,
                                cap: cap,
                                onCampus: onCampus,
                                recurrence: recurrenceWeeks,
                                description: description
                            )
                            showConfirmation = created
                            resetForm()
                        } label: {
                            Text("Post Game")
                                .font(.montserratBold(size: 16))
                                .foregroundColor(.buttonPrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.buttonPrimaryBackground)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
                .background(Color.screenBackground)
            }
            .background(Color.screenBackground)
            .navigationBarHidden(true)
            .alert("Game posted", isPresented: $showConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your game is live and visible in the feed.")
            }
            .sheet(isPresented: $showCustomLocation) {
                NavigationStack {
                    Form {
                        Section("Custom Location") {
                            TextField("Location Name", text: $customLocationName)
                            TextField("Address", text: $customLocationAddress)
                        }
                    }
                    .navigationTitle("Add Location")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showCustomLocation = false
                                customLocationName = ""
                                customLocationAddress = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                if !customLocationName.isEmpty {
                                    location = customLocationName
                                }
                                showCustomLocation = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func resetForm() {
        title = ""
        date = Date().addingTimeInterval(3600 * 4)
        location = ""
        cap = 10
        recurrenceWeeks = 0
        description = ""
        customLocationName = ""
        customLocationAddress = ""
    }
}

struct ProfileView: View {
    @EnvironmentObject var model: AppModel
    @StateObject private var authViewModel = AuthViewModel()
    @State private var bioText: String = ""
    @State private var availability: Availability = .weeknights
    @State private var selectedSports: Set<Sport> = []
    @State private var skill: SkillBand = .casual
    @State private var showSettings = false

    var body: some View {
        Group {
            if authViewModel.user != nil {
                // User is signed in - show profile
                authenticatedProfileView
            } else {
                // User is not signed in - show sign in
                SignInView()
                    .environmentObject(authViewModel)
            }
        }
    }
    
    // MARK: - Authenticated Profile View
    
    private var authenticatedProfileView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Image("1")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                        Spacer()
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.title3)
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Profile Content
                    VStack(spacing: 24) {
                        // Avatar and Name
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.brandLightBlue.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                
                                // Show Firebase user info if available
                                if let displayName = authViewModel.user?.displayName {
                                    Text(getInitials(from: displayName))
                                        .font(.montserratBold(size: 36))
                                        .foregroundColor(.brandPrimary)
                                } else {
                                    Text(model.currentUser.initials)
                                        .font(.montserratBold(size: 36))
                                        .foregroundColor(.brandPrimary)
                                }
                            }
                            
                            Text(authViewModel.user?.displayName ?? model.currentUser.displayName)
                                .font(.montserratBold(size: 28))
                                .foregroundColor(.textPrimary)
                            
                            if let email = authViewModel.user?.email {
                                Text(email)
                                    .font(.montserrat(size: 14))
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Text(model.currentUser.skillBand.display)
                                .font(.montserratMedium(size: 15))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.brandLightBlue.opacity(0.3))
                                .foregroundColor(.brandPrimary)
                                .cornerRadius(16)
                        }
                        .padding(.top, 20)
                        
                        // Stats Cards
                        HStack(spacing: 16) {
                            StatCard(
                                icon: "calendar",
                                value: "\(model.currentUser.gamesPlayed)",
                                label: "Games Played",
                                color: .brandMediumBlue
                            )
                            
                            StatCard(
                                icon: "trophy.fill",
                                value: "\(model.currentUser.gamesHosted)",
                                label: "Games Hosted",
                                color: .brandMediumBlue
                            )
                        }
                        .padding(.horizontal)
                        
                        // Sports Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sports")
                                .font(.montserratBold(size: 18))
                                .foregroundColor(.brandPrimary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(model.currentUser.sports) { sport in
                                        SportTag(sport: sport)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Availability Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Availability")
                                .font(.montserratBold(size: 18))
                                .foregroundColor(.brandPrimary)
                                .padding(.horizontal)
                            
                            HStack {
                                Text(model.currentUser.availability.label)
                                    .font(.montserratMedium(size: 15))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.brandLightBlue.opacity(0.3))
                                    .foregroundColor(.brandPrimary)
                                    .cornerRadius(16)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        // Sign Out Button
                        Button {
                            authViewModel.signOut()
                        } label: {
                            Text("Sign Out")
                                .font(.montserratSemiBold(size: 16))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                    .padding(.bottom, 32)
                }
            }
            .background(Color.screenBackground)
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                ProfileSettingsView(
                    bioText: $bioText,
                    availability: $availability,
                    selectedSports: $selectedSports,
                    skill: $skill
                )
                .environmentObject(model)
            }
            .onAppear {
                bioText = model.currentUser.bio
                selectedSports = Set(model.currentUser.sports)
                availability = model.currentUser.availability
                skill = model.currentUser.skillBand
            }
        }
    }
    
    // Helper function to get initials from display name
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined().uppercased()
    }
}


struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.brandMediumBlue)
            Text(value)
                .font(.montserratBold(size: 32))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.montserrat(size: 12))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
    }
}

struct SportTag: View {
    let sport: Sport
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: sportIcon)
                .font(.caption)
            Text(sport.rawValue.capitalized)
                .font(.montserratMedium(size: 14))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.brandLightBlue.opacity(0.2))
        .foregroundColor(.brandPrimary)
        .cornerRadius(16)
    }
    
    private var sportIcon: String {
        switch sport {
        case .basketball: return "basketball.fill"
        case .soccer: return "soccerball"
        case .tennis: return "figure.tennis"
        case .pickleball: return "figure.pickleball"
        case .volleyball: return "figure.volleyball"
        default: return "sportscourt"
        }
    }
}

struct ProfileSettingsView: View {
    @EnvironmentObject var model: AppModel
    @Binding var bioText: String
    @Binding var availability: Availability
    @Binding var selectedSports: Set<Sport>
    @Binding var skill: SkillBand
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("You") {
                    Text(model.currentUser.displayName)
                    Picker("Skill Band", selection: $skill) {
                        ForEach(SkillBand.allCases.filter { $0 != .all }) { band in
                            Text(band.display).tag(band)
                        }
                    }
                    TextField("Short bio", text: $bioText, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Preferences") {
                    Picker("Availability", selection: $availability) {
                        ForEach(Availability.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    ForEach(Sport.playable) { sport in
                        Toggle(sport.rawValue.capitalized, isOn: Binding(
                            get: { selectedSports.contains(sport) },
                            set: { isOn in
                                if isOn { selectedSports.insert(sport) } else { selectedSports.remove(sport) }
                            })
                        )
                    }
                }
                
                Section {
                    Button("Save Profile") {
                        model.updateProfile(skill: skill, bio: bioText, sports: selectedSports, availability: availability)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Profile")
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
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 42))
                .foregroundColor(.textSecondary)
            Text("No games match those filters.")
                .font(.montserratBold(size: 18))
                .foregroundColor(.textPrimary)
            Text("Try expanding radius or clearing filters to see anchor games.")
                .font(.montserrat(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .frame(maxHeight: .infinity)
        .padding(.bottom, 100)
    }
}

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    ContentView()
}
