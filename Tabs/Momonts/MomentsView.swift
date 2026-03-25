//
//  MomentsView.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/15/25.
//

import SwiftUI
import SwiftData

/// Primary feed of grateful moments with search, creation flow, and streak header.
/// Supports deep linking to present the Add Moment sheet.
struct MomentsView: View {
    /// Bound to deep link state from widgets; when true, presents creation flow.
    @Binding var shouldShowAddMoment: Bool  // ✅ Add binding for widget deep link
    /// Optional data container from environment for persistence and services.
    @Environment(DataContainer.self) private var dataContainer: DataContainer?
    
    // ✅ Add default initializer for preview/normal use
    init(shouldShowAddMoment: Binding<Bool> = .constant(false)) {
        self._shouldShowAddMoment = shouldShowAddMoment
    }
    
    /// Controls presentation of the create-moment sheet.
    @State private var showCreateMoment = false
    /// Controls presentation of the heatmap calendar sheet.
    @State private var showHeatmap = false
    /// Current search text for filtering moments.
    @State private var searchText = ""
    /// Whether the search UI is presented.
    @State private var isSearching = false
    /// Shows the first-launch notification permission prompt.
    @State private var showNotificationPrompt = false
    /// Triggers the celebration overlay after saving a moment.
    @State private var showCelebration = false
    @State private var heartRotation: Angle = .degrees(0)
    @State private var heartRotation3D: Angle = .degrees(0)
    @State private var heartSize: CGFloat = 120
    @State private var showReminders = false
    
    @Query(sort: \Moment.timestamp)
    private var moments: [Moment]

    /// Horizontal offset amplitude used to stagger hexagon rows.
    static let offsetAmount: CGFloat = 70.0
    
    /// Moments filtered by the current search text.
    var filteredMoments: [Moment] {
        if searchText.isEmpty {
            return moments
        } else {
            return moments.filter { moment in
                moment.title.localizedCaseInsensitiveContains(searchText) ||
                moment.note.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    /// Shows search affordance when there are at least 10 moments.
    var shouldShowSearch: Bool {
        moments.count >= 10
    }

    var body: some View {
        NavigationStack {
            mainScrollContent
                .overlay(emptyStateOverlay)
                .toolbar { momentsToolbar }
                .searchable(text: $searchText, isPresented: $isSearching, prompt: "Search moments")
                .autocorrectionDisabled()
                .sheet(isPresented: $showHeatmap) { HeatmapCalendarView() }
                .sheet(isPresented: $showNotificationPrompt) { FirstLaunchNotificationPrompt() }
                .onAppear(perform: handleFirstLaunchPrompt)
                .onChange(of: shouldShowAddMoment) { oldValue, newValue in
                    if newValue {
                        showCreateMoment = true
                        shouldShowAddMoment = false
                    }
                }
                .defaultScrollAnchor(.bottom, for: .initialOffset)
                .defaultScrollAnchor(.bottom, for: .sizeChanges)
                .defaultScrollAnchor(.top, for: .alignment)
                .navigationTitle("Grateful Moments")
                .overlay(celebrationOverlay)
        }
    }
    
    /// Main scrollable content including streak header and hexagon grid.
    private var mainScrollContent: some View {
        ScrollView {
            LazyVStack(spacing: 8, pinnedViews: .sectionHeaders) {
                Section {
                    pathItems
                        .frame(maxWidth: .infinity)
                } header: {
                    streakHeader
                }
            }
        }
    }

    /// Overlay shown for empty results or no content yet.
    @ViewBuilder
    private var emptyStateOverlay: some View {
        if filteredMoments.isEmpty && !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if moments.isEmpty {
            ContentUnavailableView {
                Label("No moments yet!", systemImage: "exclamationmark.circle.fill")
            } description: {
                Text("Post a note or photo to start filling this space with gratitude.")
            }
        }
    }

    /// Toolbar with search, add moment, and reminders/settings.
    @ToolbarContentBuilder
    private var momentsToolbar: some ToolbarContent {
        // Search button (shows when 10+ moments)
        if shouldShowSearch {
            ToolbarItem(placement: .topBarLeading) {
                Button { isSearching.toggle() } label: {
                    Image(systemName: "magnifyingglass")
                }
                .accessibilityLabel("Search moments")
            }
        }

        // Add moment button (always visible)
        ToolbarItem(placement: .topBarTrailing) {
            Button { showCreateMoment = true } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add new moment")
            .accessibilityHint("Opens form to create a new grateful moment")
            .sheet(isPresented: $showCreateMoment) {
                let onSaved = { runCelebration() }
                if let dataContainer {
                    MomentEntryView(onSaved: onSaved)
                        .environment(dataContainer)
                } else {
                    MomentEntryView(onSaved: onSaved)
                }
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showReminders = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Reminders Settings")
            .sheet(isPresented: $showReminders) {
                RemindersSettingsView()
                    .environment(dataContainer)
            }
        }
    }

    /// Full-screen confetti/heart animation overlay for successful saves.
    @ViewBuilder
    private var celebrationOverlay: some View {
        if showCelebration {
            ZStack {
                Color.black.opacity(0.25).ignoresSafeArea()
                
                CelebrationConfettiView()
                    .allowsHitTesting(false)
                
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: heartSize))
                        .foregroundStyle(Color.accentColor)
                        .rotation3DEffect(
                            heartRotation3D,
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.6
                        )
                        .shadow(color: Color.accentColor.opacity(0.5), radius: 10, x: 0, y: 4)
                    Text("Great Job!")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .transition(.opacity.combined(with: .scale))
            .zIndex(999)
            .allowsHitTesting(false)
            .onAppear {
                // Nudge ConfettiView to start immediately when the overlay appears
                DispatchQueue.main.async {
                    showCelebration = true
                }
            }
        }
    }

    /// Delays and presents a notification prompt on first launch.
    private func handleFirstLaunchPrompt() {
        if !UserDefaults.standard.bool(forKey: "hasShownNotificationPrompt") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showNotificationPrompt = true
            }
        }
    }

    /// Generates navigation links for each filtered moment.
    private var pathItems: some View {
        ForEach(Array(filteredMoments.enumerated()), id: \.element.id) { index, moment in
            momentNavigationLink(for: moment, at: index)
        }
    }
    
    /// Configures navigation and transition for a single moment row.
    private func momentNavigationLink(for moment: Moment, at index: Int) -> some View {
        NavigationLink {
            destinationView(for: moment)
        } label: {
            momentHexagonWithOverlay(moment: moment, index: index)
        }
        .accessibilityLabel(accessibilityLabelFor(moment: moment))
        .accessibilityHint(moment.isLocked ? "Double tap to unlock and view this moment" : "Double tap to view details")
        .accessibilityAddTraits(.isButton)
        .scrollTransition { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0)
                .scaleEffect(phase.isIdentity ? 1 : 0.8)
        }
    }
    
    /// Builds an accessibility label that describes a moment succinctly.
    private func accessibilityLabelFor(moment: Moment) -> String {
        var label = "Moment: \(moment.title)"
        if moment.isLocked {
            label += ", locked"
        }
        if moment.image != nil {
            label += ", has photo"
        }
        if !moment.note.isEmpty {
            label += ", has note"
        }
        return label
    }
    
    /// Route to locked or detail view based on moment state.
    @ViewBuilder
    private func destinationView(for moment: Moment) -> some View {
        if moment.isLocked {
            LockedEntryView(moment: moment)
        } else {
            MomentDetailView(moment: moment)
        }
    }
    
    /// Renders a hexagon card with an optional locked overlay and sine-based offset.
    private func momentHexagonWithOverlay(moment: Moment, index: Int) -> some View {
        let isLast = moment == moments.last
        let offset = sin(Double(index) * .pi / 2) * Self.offsetAmount
        
        return Group {
            if isLast {
                MomentHexagonView(moment: moment, layout: .large)
                    .overlay {
                        if moment.isLocked {
                            lockedOverlayContent(isLarge: true)
                        }
                    }
            } else {
                MomentHexagonView(moment: moment)
                    .overlay {
                        if moment.isLocked {
                            lockedOverlayContent(isLarge: false)
                        }
                    }
                    .offset(x: offset)
            }
        }
    }
    
    /// Semi-opaque mask indicating locked content inside the hexagon.
    @ViewBuilder
    private func lockedOverlayContent(isLarge: Bool) -> some View {
        let size = isLarge ? HexagonLayout.large.size : HexagonLayout.standard.size
        
        ZStack {
            Color.lockOverlay
                .opacity(0.95)
            
            VStack(spacing: isLarge ? 8 : 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: isLarge ? 40 : 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Locked")
                    .font(isLarge ? .headline : .caption)
                    .foregroundColor(.white)
            }
        }
        .compositingGroup()
        .mask {
            Image(systemName: "hexagon.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size - 2.0, height: size - 2.0)
        }
    }

    /// Header showing the current streak with a button to open the heatmap.
    @ViewBuilder private var streakHeader: some View {
        let streak = StreakCalculator().calculateStreak(for: moments)
        if streak > 0 {
            HStack {
                Text(verbatim: "\(streak)")
                    .font(.subheadline)
                    .accessibilityLabel("\(streak) day streak")
                
                // Only the flame icon is tappable
                Button {
                    showHeatmap = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.ember)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View streak calendar")
                .accessibilityHint("Shows your activity heatmap")
                
                Spacer()
            }
            .font(.subheadline)
            .padding()
        }
    }
    
    /// Plays sound and animates the heart/confetti celebration, then dismisses it.
    private func runCelebration() {
        SoundManager.shared.playAddMomentSoundIfEnabled()
        withAnimation(.spring(duration: 0.4)) {
            showCelebration = true
        }
        withAnimation(.linear(duration: 2.1)) {
            // Revolving door effect: 3D Y-axis spin, negative for CCW (left-to-right)
            heartRotation3D = .degrees(-360 * 2)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                showCelebration = false
                heartRotation3D = .degrees(0)
            }
        }
    }
}

#Preview {
    MomentsView()
        .sampleDataContainer()
}

#Preview("No moments") {
    MomentsView()
        .modelContainer(for: [Moment.self])
        .environment(DataContainer())
}

// MARK: - Celebration Confetti Particle (ported from BadgeCelebrationView)
struct CelebrationConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var opacity: Double = 1
    var rotation: Double = 0
}
// MARK: - Celebration Confetti View (ported from BadgeCelebrationView)
struct CelebrationConfettiView: View {
    @State private var particles: [CelebrationConfettiParticle] = []
    @State private var isAnimating = false
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: 10, height: 10)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }

    private func createConfetti(in size: CGSize) {
        // Create 50 confetti particles
        for _ in 0..<50 {
            let particle = CelebrationConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                color: colors.randomElement() ?? .blue
            )
            particles.append(particle)
        }
        animateParticles(in: size)
    }

    private func animateParticles(in size: CGSize) {
        for (index, _) in particles.enumerated() {
            let delay = Double(index) * 0.01
            let duration = Double.random(in: 2...3)
            withAnimation(.easeOut(duration: duration).delay(delay)) {
                particles[index].y = size.height + 20
                particles[index].x += CGFloat.random(in: -100...100)
                particles[index].opacity = 0
                particles[index].rotation = Double.random(in: 0...720)
            }
        }
    }
}
