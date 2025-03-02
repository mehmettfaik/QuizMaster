import Foundation
import Combine

class MainViewModel {
    // MARK: - Properties
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Add bindings here when needed
    }
    
    // MARK: - Public Methods
    func startQuiz() {
        // TODO: Implement quiz start logic
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            // TODO: Navigate to quiz screen
        }
    }
} 