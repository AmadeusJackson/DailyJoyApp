//
//  MomentDetailView.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/15/25.
//

import SwiftUI
import SwiftData


struct MomentDetailView: View {
    var moment: Moment
    @State private var showConfirmation = false
    @State private var showEditor = false
    @State private var showCelebration = false
    @State private var heartRotation: Angle = .degrees(0)


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
                        dismiss()
                    }
                } message: {
                    Text("The moment will be permanently deleted.")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            MomentEntryView(existingMoment: moment) {
                // Trigger celebration
                withAnimation(.spring(duration: 0.6)) {
                    showCelebration = true
                    heartRotation = .degrees(0)
                }
                // Spin the heart continuously for a moment
                withAnimation(.linear(duration: 1.0).repeatCount(2, autoreverses: false)) {
                    heartRotation = .degrees(720)
                }
                // Dismiss the editor sheet
                showEditor = false
                // Hide celebration after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showCelebration = false
                        heartRotation = .degrees(0)
                    }
                }
            }
            .environment(dataContainer)
        }
    }


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
                    .font(.system(size: 72))
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

    private struct ConfettiView: View {
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
                        var piece = pieces[i]
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

