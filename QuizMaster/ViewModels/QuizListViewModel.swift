import Foundation
import Combine

class QuizListViewModel: ObservableObject {
    @Published var quizzes: [Quiz] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    @Published var selectedCategory: QuizCategory?
    @Published var selectedDifficulty: QuizDifficulty?
    @Published var searchText = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadQuizzes() {
        isLoading = true
        // TODO: Implement API call to fetch quizzes
        // For now, using mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.quizzes = self.mockQuizzes()
            self.isLoading = false
        }
    }
    
    func filteredQuizzes() -> [Quiz] {
        var filtered = quizzes
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let difficulty = selectedDifficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    private func mockQuizzes() -> [Quiz] {
        // TODO: Replace with actual data
        return []
    }
} 