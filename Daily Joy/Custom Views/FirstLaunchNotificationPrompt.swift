//
//  FirstLaunchNotificationPrompt.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/28/25.
//

import SwiftUI

struct FirstLaunchNotificationPrompt: View {
    @Environment(DataContainer.self) private var dataContainer
    @Environment(\.dismiss) private var dismiss
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color("Ember").opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color("Ember"))
            }
            
            // Title & Description
            VStack(spacing: 12) {
                Text("Stay Connected to Joy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Daily Joy learns when you typically reflect and sends gentle, personalized reminders—never pushy, just supportive.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                Button {
                    Task {
                        isRequesting = true
                        await requestNotifications()
                        isRequesting = false
                    }
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Enable Reminders")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Ember"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isRequesting)
                
                Button("Not Now") {
                    markPromptShown()
                    dismiss()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding()
    }
    
    private func requestNotifications() async {
        _ = await dataContainer.notificationManager.requestPermission()
        markPromptShown()
        dismiss()
    }
    
    private func markPromptShown() {
        UserDefaults.standard.set(true, forKey: "hasShownNotificationPrompt")
    }
}

#Preview {
    FirstLaunchNotificationPrompt()
        .sampleDataContainer()
}
