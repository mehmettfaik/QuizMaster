import Foundation
import Combine
import UIKit

class AuthViewModel {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func signUp(email: String, password: String, name: String) {
        isLoading = true
        error = nil
        
        firebaseService.signUp(email: email, password: password, name: name) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success(let user):
                self?.currentUser = user
            case .failure(let error):
                self?.error = error
            }
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        error = nil
        
        firebaseService.signIn(email: email, password: password) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success(let user):
                self?.currentUser = user
            case .failure(let error):
                self?.error = error
            }
        }
    }
    
    func signInWithGoogle(presenting: UIViewController) {
        isLoading = true
        error = nil
        
        firebaseService.signInWithGoogle(presenting: presenting) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success(let user):
                self?.currentUser = user
            case .failure(let error):
                self?.error = error
            }
        }
    }
    
    func signOut() {
        do {
            try firebaseService.signOut()
            currentUser = nil
        } catch {
            self.error = error
        }
    }
    
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func validatePassword(_ password: String) -> Bool {
        return password.count >= 6
    }
} 