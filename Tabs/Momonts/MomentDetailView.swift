//
//  MomentDetailView.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/15/25.
//

import SwiftUI
import SwiftData

struct MomentDetailView: View {
    // Set 'badgeAwardedThisEdit = true' from your badge award logic when a badge is earned during edit/save.
    var moment: Moment
    @State private var showConfirmation = false
    @State private var showEditor = false
    @State private var showCelebration = false
    @State private var heartRotation: Angle = .degrees(0)
    @State private var badgeAwardedThisEdit = false
    @State private var showShareSheet = false


    @Environment(\.dismiss) private var dismiss
    @Environment(DataContainer.self) private var dataContainer


    var body: some View {
        ZStack {
            ScrollView {
                contentStack
            }
            if showCelebration {
                celebrationOverlay
                    .transition(.opacity.combined(with: .scale))
                    .ignoresSafeArea()
            }
        }
        .navigationTitle(moment.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showEditor = true
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share moment")
            }
            ToolbarItem(placement: .destructiveAction) {
                Button {
                    showConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .confirmationDialog("Delete Moment", isPresented: $showConfirmation) {
                    Button("Delete Moment", role: .destructive) {
                        dataContainer.context.delete(moment)
                        try? dataContainer.context.save()
                        dataContainer.updateWidgetSnapshot()
                        dismiss()
                    }
                } message: {
                    Text("The moment will be permanently deleted.")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            MomentEntryView(existingMoment: moment) {
                // Reset state
                badgeAwardedThisEdit = false
                heartRotation = .degrees(0)

                // 1) Show celebration overlay immediately (heart + confetti base)
                withAnimation(.spring(duration: 0.4)) {
                    showCelebration = true
                }

                // 2) Spin the heart for ~2.2 seconds
                withAnimation(.linear(duration: 2.2)) {
                    heartRotation = .degrees(720 * 3) // 3 full spins
                }

                // 3) Dismiss the editor sheet right away
                showEditor = false

                // 4) Decide whether to continue confetti into badge award or end it after heart spin
                // NOTE: Set `badgeAwardedThisEdit = true` from your badge-award logic before this fires if a badge was earned.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.25) {
                    if badgeAwardedThisEdit {
                        // Keep confetti visible and let the badge award UI take over presentation.
                        // Optionally, we can soften the heart emphasis now.
                        withAnimation(.easeOut(duration: 0.3)) {
                            heartRotation = .degrees(0)
                        }
                    } else {
                        // No badge: end the celebration (hide confetti and overlay)
                        withAnimation(.easeOut(duration: 0.4)) {
                            showCelebration = false
                            heartRotation = .degrees(0)
                        }
                    }
                }
            }
            .environment(dataContainer)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }


    private var shareItems: [Any] {
        var items: [Any] = [shareText]
        if let image = moment.image {
            items.append(image)
        }
        return items
    }

    private var shareText: String {
        var parts: [String] = [moment.title]
        if !moment.note.isEmpty {
            parts.append(moment.note)
        }
        parts.append(Self.shareDateFormatter.string(from: moment.timestamp))
        return parts.joined(separator: "\n")
    }

    private static let shareDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private var contentStack: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(moment.timestamp, style: .date)
                    .font(.subheadline)
                Spacer()
                // Badges feature not implemented yet
            }
            if !moment.note.isEmpty {
                Text(moment.note)
                    .textSelection(.enabled)
            }
            if let image = moment.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.25)
            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(Color.accentColor)
                    .rotationEffect(heartRotation)
                    .shadow(color: Color.accentColor.opacity(0.5), radius: 10, x: 0, y: 4)
                Text("Great Job!")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .overlay(alignment: .bottomLeading) {
            ConfettiView(isActive: showCelebration, origin: .bottomLeading)
                .allowsHitTesting(false)
                .padding(12)
        }
        .overlay(alignment: .bottomTrailing) {
            ConfettiView(isActive: showCelebration, origin: .bottomTrailing)
                .allowsHitTesting(false)
                .padding(12)
        }
    }

    private struct ConfettiPiece: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var color: Color
        var angle: Angle
        var speed: CGFloat
        var rotationSpeed: Angle
    }

    struct ConfettiView: View {
        var isActive: Bool
        enum Origin { case bottomLeading, bottomTrailing }
        var origin: Origin = .bottomLeading

        @State private var pieces: [ConfettiPiece] = []
        @State private var timerActive = false

        let colors: [Color] = [
            .accentColor,
            .red, .orange, .yellow, .green, .mint, .teal, .blue, .indigo, .purple, .pink
        ]

        var body: some View {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    for i in pieces.indices {
                        let piece = pieces[i]
                        var transform = CGAffineTransform.identity
                        transform = transform.translatedBy(x: piece.x, y: piece.y)
                        transform = transform.rotated(by: CGFloat(piece.angle.radians))
                        context.concatenate(transform)
                        let rect = CGRect(x: -piece.size/2, y: -piece.size/2, width: piece.size, height: piece.size)
                        context.fill(Path(roundedRect: rect, cornerRadius: piece.size/5), with: .color(piece.color))
                    }
                }
                .onChange(of: isActive) { _, newValue in
                    if newValue {
                        start(size: nil)
                    } else {
                        pieces.removeAll()
                        timerActive = false
                    }
                }
                .onAppear {
                    if isActive { start(size: nil) }
                }
                .onDisappear {
                    timerActive = false
                }
            }
            .frame(width: 1, height: 1) // minimal hit area; drawing happens in overlays
            .allowsHitTesting(false)
        }

        private func start(size: CGSize?) {
            guard !timerActive else { return }
            timerActive = true
            pieces = generatePieces(count: 40)
            withAnimation(.easeOut(duration: 1.8)) {
                animateFall()
            }
        }

        private func generatePieces(count: Int) -> [ConfettiPiece] {
            (0..<count).map { _ in
                let size: CGFloat = .random(in: 6...12)
                let color = colors.randomElement() ?? .accentColor
                let angle: Angle = .degrees(.random(in: -20...20))
                let speed: CGFloat = .random(in: 120...260)
                let rotationSpeed: Angle = .degrees(.random(in: -360...360))
                return ConfettiPiece(
                    x: origin == .bottomLeading ? .random(in: 0...40) : .random(in: -40...0),
                    y: .random(in: -10...10),
                    size: size,
                    color: color,
                    angle: angle,
                    speed: speed,
                    rotationSpeed: rotationSpeed
                )
            }
        }

        private func animateFall() {
            // Update positions over time using implicit animation hooks
            for i in pieces.indices {
                pieces[i].y -= pieces[i].speed
                pieces[i].x += origin == .bottomLeading ? CGFloat.random(in: 80...160) : CGFloat.random(in: -160...(-80))
                pieces[i].angle += pieces[i].rotationSpeed
            }
        }
    }
}


#Preview {
    NavigationStack {
        MomentDetailView(moment: .imageSample)
            .sampleDataContainer()
    }
}


#Preview("Long note") {
    NavigationStack {
        MomentDetailView(moment: Moment.longTextSample)
            .sampleDataContainer()
    }
}

