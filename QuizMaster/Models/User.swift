import Foundation

struct User: Identifiable, Codable {
    let id: String
    var username: String
    var email: String
    var profileImage: String?
    var totalPoints: Int
    var quizzesCompleted: Int
    var achievements: [Achievement]
    var createdQuizzes: [String] // Quiz IDs
    var attemptedQuizzes: [String] // Quiz IDs
}

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let unlockedAt: Date
} 