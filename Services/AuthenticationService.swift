import Foundation
import LocalAuthentication
import Combine

class AuthenticationService: ObservableObject {
  let objectWillChange = ObservableObjectPublisher()

    @Published var isUnlocked = false
    @Published var isBiometricAvailable = false
    @Published var isAuthenticating = false
    
    init() {
        checkBiometryAvailability()
    }
    
    func checkBiometryAvailability() {
        let context = LAContext()
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            isBiometricAvailable = true
        } else {
            isBiometricAvailable = false
        }
    }
    
    func authenticate() {
        guard !isAuthenticating else { return }

        let context = LAContext()
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            let reason = "일기를 보호하기 위해 인증이 필요합니다."
            isAuthenticating = true
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    self.isAuthenticating = false
                    if success {
                        self.isUnlocked = true
                    } else {
                        // 인증 실패 처리 (필요하면)
                        self.isUnlocked = false
                    }
                }
            }
        } else {
            isUnlocked = true
        }
    }
}
