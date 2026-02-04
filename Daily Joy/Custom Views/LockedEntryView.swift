//
//  LockedEntryView.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/8/25.
//

import SwiftUI
import SwiftData
import LocalAuthentication

struct LockedEntryView: View {
    let moment: Moment
    @State private var showUnlockedContent = false
    @State private var authError: String?
    
    private var canAuthenticate: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
    
    var body: some View {
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
