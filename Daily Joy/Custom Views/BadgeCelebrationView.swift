//
//  BadgeCelebrationView.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/7/25.
//

import SwiftUI

// MARK: - Confetti Particle
struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var opacity: Double = 1
    var rotation: Double = 0
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
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
            let particle = ConfettiParticle(
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

// MARK: - Badge Celebration View
struct BadgeCelebrationView: View {
    let badge: Badge
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var confettiOpacity: Double = 1
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissCelebration()
                }
            
            // Confetti
            ConfettiView()
                .opacity(confettiOpacity)
            
            // Badge card
            VStack(spacing: 20) {
                // Badge icon
                Image(badge.details.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .shadow(color: badge.details.color.opacity(0.5), radius: 20)
                
                // Title
                Text("Badge Unlocked!")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                
                // Badge name
                Text(badge.details.title)
                    .font(.title2.bold())
                    .foregroundStyle(badge.details.color)
                
                // Message
                Text(badge.details.congratulatoryMessage)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Dismiss button
                Button(action: dismissCelebration) {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(badge.details.color)
                        .clipShape(Capsule())
                }
                .padding(.top, 10)
            }
            .padding(30)
            .frame(maxWidth: 400)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(badge.details.color.opacity(0.5), lineWidth: 2)
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            triggerHaptics()
            animateIn()
        }
    }
    
    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.8
            opacity = 0
            confettiOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    private func triggerHaptics() {
        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Additional impact haptics for celebration feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
}

// MARK: - View Extension for Easy Integration
extension View {
    func badgeCelebration(badge: Badge?, isPresented: Binding<Bool>) -> some View {
        self.overlay {
            if let badge = badge, isPresented.wrappedValue {
                BadgeCelebrationView(badge: badge, isPresented: isPresented)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var showCelebration = true
        
        var body: some View {
            Color.gray
                .badgeCelebration(badge: .sample, isPresented: $showCelebration)
        }
    }
    
    return PreviewWrapper()
}
