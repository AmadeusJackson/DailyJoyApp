//
//  MomentsView.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/15/25.
//

import SwiftUI
import SwiftData

struct MomentsView: View {
    @Binding var shouldShowAddMoment: Bool  // ✅ Add binding for widget deep link
    
    // ✅ Add default initializer for preview/normal use
    init(shouldShowAddMoment: Binding<Bool> = .constant(false)) {
        self._shouldShowAddMoment = shouldShowAddMoment
    }
    
    @State private var showCreateMoment = false
    @State private var showHeatmap = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var showNotificationPrompt = false
    @Query(sort: \Moment.timestamp)
    private var moments: [Moment]

    static let offsetAmount: CGFloat = 70.0
    
    // Filtered moments based on search
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
    
    // Show search only when there are 10+ moments
    var shouldShowSearch: Bool {
        moments.count >= 10
    }

    var body: some View {
        NavigationStack {
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
            .overlay {
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
            .toolbar {
                // Search button (shows when 10+ moments)
                if shouldShowSearch {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isSearching.toggle()
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .accessibilityLabel("Search moments")
                    }
                }
                
                // Add moment button (always visible)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateMoment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add new moment")
                    .accessibilityHint("Opens form to create a new grateful moment")
                    .sheet(isPresented: $showCreateMoment) {
                        MomentEntryView()
                    }
                }
            }
            .searchable(text: $searchText, isPresented: $isSearching, prompt: "Search moments")
            .autocorrectionDisabled()
            .sheet(isPresented: $showHeatmap) {
                HeatmapCalendarView()
            }
            .sheet(isPresented: $showNotificationPrompt) {
                FirstLaunchNotificationPrompt()
            }
            .onAppear {
                // Check if we should show notification prompt (first launch)
                if !UserDefaults.standard.bool(forKey: "hasShownNotificationPrompt") {
                    // Delay so user sees the app first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showNotificationPrompt = true
                    }
                }
            }
            // ✅ Handle widget deep link
            .onChange(of: shouldShowAddMoment) { oldValue, newValue in
                if newValue {
                    showCreateMoment = true
                    shouldShowAddMoment = false  // Reset the binding
                }
            }
            .defaultScrollAnchor(.bottom, for: .initialOffset)
            .defaultScrollAnchor(.bottom, for: .sizeChanges)
            .defaultScrollAnchor(.top, for: .alignment)
            .navigationTitle("Grateful Moments")
        }
    }

    private var pathItems: some View {
        ForEach(Array(filteredMoments.enumerated()), id: \.element.id) { index, moment in
            momentNavigationLink(for: moment, at: index)
        }
    }
    
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
    
    @ViewBuilder
    private func destinationView(for moment: Moment) -> some View {
        if moment.isLocked {
            LockedEntryView(moment: moment)
        } else {
            MomentDetailView(moment: moment)
        }
    }
    
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
