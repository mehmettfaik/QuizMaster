import Foundation

struct Question: Identifiable, Codable {
    let id: String
    let text: String
    let options: [String]
    let correctAnswer: Int
    let explanation: String?
    let points: Int
    let timeLimit: Int? // in seconds, optional per-question time limit
}

struct QuizAttempt: Identifiable, Codable {
    let id: String
    let quizId: String
    let userId: String
    let startedAt: Date
    let completedAt: Date?
    let score: Int
    let answers: [QuestionAnswer]
    let timeSpent: TimeInterval
}

struct QuestionAnswer: Codable {
    let questionId: String
    let selectedAnswer: Int?
    let isCorrect: Bool
    let timeSpent: TimeInterval
} 