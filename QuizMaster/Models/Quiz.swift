import Foundation

struct Quiz: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: QuizCategory
    let difficulty: QuizDifficulty
    let questions: [Question]
    let timeLimit: Int // in minutes
    let createdAt: Date
    let createdBy: String
    let thumbnail: String?
}

enum QuizCategory: String, Codable, CaseIterable {
    case general = "General Knowledge"
    case science = "Science"
    case history = "History"
    case geography = "Geography"
    case sports = "Sports"
    case entertainment = "Entertainment"
}

enum QuizDifficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
} 