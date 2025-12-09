//
//  MomentsView.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/15/25.
//

import SwiftUI
import SwiftData

struct MomentsView: View {
    @State private var showCreateMoment = false
    @State private var showHeatmap = false
    @Query(sort: \Moment.timestamp)
    private var moments: [Moment]

    static let offsetAmount: CGFloat = 70.0

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
                if moments.isEmpty {
                    ContentUnavailableView {
                        Label("No moments yet!", systemImage: "exclamationmark.circle.fill")
                    } description: {
                        Text("Post a note or photo to start filling this space with gratitude.")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateMoment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $showCreateMoment) {
                        MomentEntryView()
                    }
                }
            }
            .sheet(isPresented: $showHeatmap) {
                HeatmapCalendarView()
            }
            .defaultScrollAnchor(.bottom, for: .initialOffset)
            .defaultScrollAnchor(.bottom, for: .sizeChanges)
            .defaultScrollAnchor(.top, for: .alignment)
            .navigationTitle("Grateful Moments")
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var pathItems: some View {
        ForEach(Array(moments.enumerated()), id: \.element.id) { index, moment in
            momentNavigationLink(for: moment, at: index)
        }
    }
    
    private func momentNavigationLink(for moment: Moment, at index: Int) -> some View {
        NavigationLink {
            destinationView(for: moment)
        } label: {
            momentHexagonWithOverlay(moment: moment, index: index)
        }
        .scrollTransition { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0)
                .scaleEffect(phase.isIdentity ? 1 : 0.8)
        }
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
            Color(hex: "0000FF")
                .opacity(0.85)
            
            VStack(spacing: isLarge ? 8 : 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: isLarge ? 40 : 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Locked")
                    .font(isLarge ? .headline : .caption)
                    .foregroundColor(.white)
            }
        }
        .mask {
            Image(systemName: "hexagon.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size - 2.0, height: size - 2.0)
                .fontWeight(.ultraLight)
        }
    }

    @ViewBuilder private var streakHeader: some View {
        let streak = StreakCalculator().calculateStreak(for: moments)
        if streak > 0 {
            HStack {
                Text(verbatim: "\(streak)")
                    .font(.subheadline)
                
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

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
