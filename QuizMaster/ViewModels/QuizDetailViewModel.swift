import Foundation
import Combine

class QuizDetailViewModel: ObservableObject {
    let quiz: Quiz
    @Published var isLoading = false
    @Published var error: Error?
    @Published var userStats: QuizUserStats?
    
    init(quiz: Quiz) {
        self.quiz = quiz
    }
    
    func loadQuizStats() {
        isLoading = true
        // TODO: Implement API call to fetch user stats for this quiz
        // For now, using mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.userStats = QuizUserStats(
                attempts: 3,
                bestScore: 85,
                averageScore: 75,
                totalTimePlayed: 45 // minutes
            )
            self.isLoading = false
        }
    }
}

struct QuizUserStats {
    let attempts: Int
    let bestScore: Int
    let averageScore: Int
    let totalTimePlayed: Int // in minutes
} 