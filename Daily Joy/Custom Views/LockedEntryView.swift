//
//  LockedEntryView.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/8/25.
//

import SwiftUI
import SwiftData
import LocalAuthentication

/// Presents a locked moment with biometric authentication to reveal its contents.
struct LockedEntryView: View {
    let moment: Moment
    @State private var showUnlockedContent = false
    @State private var authError: String?
    
    /// Returns true if the device can evaluate owner authentication (Face ID/Touch ID/passcode).
    private var canAuthenticate: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
    
    var body: some View {
        // Shows locked UI until biometric auth succeeds, then reveals `MomentDetailView`.
        ZStack {
            if showUnlockedContent {
                MomentDetailView(moment: moment)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("This moment is locked")
                        .font(.headline)
                    
                    Text("Unlock to view")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if canAuthenticate {
                        Button(action: {
                            // Authenticate the user before revealing the locked content
                            let authManager = BiometricAuthManager()
                            authManager.authenticate(reason: "Unlock this moment") { success, error in
                                if success {
                                    withAnimation {
                                        showUnlockedContent = true
                                    }
                                } else {
                                    authError = error
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "faceid")
                                Text("Unlock")
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    if let error = authError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                .padding()
            }
        }
    }
}

