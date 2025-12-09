//
//  DiometricAuthManager.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/8/25.
//

import LocalAuthentication
import SwiftUI

class BiometricAuthManager {
    var isUnlocked = false
    var authError: String?
    
    func authenticate(reason: String = "Unlock this moment", completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                        completion(true, nil)
                    } else {
                        self.authError = authenticationError?.localizedDescription ?? "Authentication failed"
                        completion(false, self.authError)
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.authError = error?.localizedDescription ?? "Biometric authentication not available"
                completion(false, self.authError)
            }
        }
    }
}
