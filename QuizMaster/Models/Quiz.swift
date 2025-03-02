import Foundation

struct Quiz: Codable {
    let id: String
    let title: String
    let description: String
    let questions: [Question]
    let timeLimit: Int? // Time limit in seconds, optional
    let difficulty: QuizDifficulty
    
    enum QuizDifficulty: String, Codable {
        case easy
        case medium
        case hard
    }
}

struct Question: Codable {
    let id: String
    let text: String
    let options: [QuestionOption]
    let correctOptionId: String
    let explanation: String?
    let points: Int
}

struct QuestionOption: Codable {
    let id: String
    let text: String
}

struct QuizResult: Codable {
    let quizId: String
    let score: Int
    let totalPoints: Int
    let completedAt: Date
    let answers: [QuestionAnswer]
}

struct QuestionAnswer: Codable {
    let questionId: String
    let selectedOptionId: String
    let isCorrect: Bool
    let timeSpent: TimeInterval
} 