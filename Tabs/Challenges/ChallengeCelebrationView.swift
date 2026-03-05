//
//  ChallengeCelebrationView.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/9/25.
//

import SwiftUI

struct ChallengeCelebrationView: View {
    let challenge: String
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @AppStorage(InteractionSoundSettingsKey.appStorageKey) private var playInteractionSounds: Bool = true
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Fireworks animation (only if motion is not reduced)
                if !reduceMotion {
                    ZStack {
                        ForEach(0..<8) { i in
                            FireworkParticle(index: i)
                        }
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(scale)
                    }
                    .frame(height: 150)
                } else {
                    // Static celebration for reduced motion
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 150)
                }
                
                VStack(spacing: 12) {
                    Text("Challenge Complete! 🎉")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    
                    Text(challenge)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button {
                    withAnimation {
                        isPresented = false
                    }
                } label: {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(40)
            .scaleEffect(scale)
            .opacity(opacity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Challenge completed: \(challenge)")
        }
        .onAppear {
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Play celebration sound (respects Reduce Motion and in-app toggle)
            SoundFeedback.shared.playAddMomentSound(
                reduceMotion: reduceMotion,
                enabled: playInteractionSounds
            )
            
            // Animations (respect reduced motion)
            if reduceMotion {
                scale = 1.0
                opacity = 1.0
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

struct FireworkParticle: View {
    let index: Int
    @State private var isAnimating = false
    
    private var particleColor: Color {
        let colors: [Color] = [.yellow, .orange, .red, .purple, .blue]
        return colors[index % colors.count]
    }
    
    var body: some View {
        Circle()
            .fill(particleColor)
            .frame(width: 8, height: 8)
            .offset(
                x: isAnimating ? cos(Double(index) * .pi / 4) * 80 : 0,
                y: isAnimating ? sin(Double(index) * .pi / 4) * 80 : 0
            )
            .opacity(isAnimating ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 1.0)
                    .delay(Double(index) * 0.05)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - View Extension
extension View {
    func challengeCelebration(challenge: String?, isPresented: Binding<Bool>) -> some View {
        self.overlay {
            if isPresented.wrappedValue, let challenge = challenge {
                ChallengeCelebrationView(challenge: challenge, isPresented: isPresented)
                    .transition(.opacity)
            }
        }
    }
}
