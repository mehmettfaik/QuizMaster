import Foundation
import FirebaseFirestore

struct CategoryStats: Codable {
    var correctAnswers: Int
    var wrongAnswers: Int
    var point: Int
    
    enum CodingKeys: String, CodingKey {
        case correctAnswers = "correct_answers"
        case wrongAnswers = "wrong_answers"
        case point = "point"
    }
}

struct User: Codable {
    let id: String
    var email: String
    var name: String
    var avatar: String
    var totalPoints: Int
    var quizzesPlayed: Int
    var quizzesWon: Int
    var language: String
    var categoryStats: [String: CategoryStats]
    var isOnline: Bool
    var lastOnline: Date
    var activeGameId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case avatar
        case totalPoints = "total_points"
        case quizzesPlayed = "quizzes_played"
        case quizzesWon = "quizzes_won"
        case language
        case categoryStats = "category_stats"
        case isOnline = "is_online"
        case lastOnline = "last_online"
        case activeGameId = "active_game_id"
    }
    
    static func from(_ document: DocumentSnapshot) -> User? {
        guard let data = document.data() else { return nil }
        
        var categoryStats: [String: CategoryStats] = [:]
        if let stats = data["category_stats"] as? [String: [String: Any]] {
            for (category, statData) in stats {
                categoryStats[category] = CategoryStats(
                    correctAnswers: statData["correct_answers"] as? Int ?? 0,
                    wrongAnswers: statData["wrong_answers"] as? Int ?? 0,
                    point: statData["point"] as? Int ?? 0
                )
            }
        }
        
        let lastOnlineTimestamp = data["last_online"] as? Timestamp
        
        return User(
            id: document.documentID,
            email: data["email"] as? String ?? "",
            name: data["name"] as? String ?? "",
            avatar: data["avatar"] as? String ?? "wizard",
            totalPoints: data["total_points"] as? Int ?? 0,
            quizzesPlayed: data["quizzes_played"] as? Int ?? 0,
            quizzesWon: data["quizzes_won"] as? Int ?? 0,
            language: data["language"] as? String ?? "en",
            categoryStats: categoryStats,
            isOnline: data["is_online"] as? Bool ?? false,
            lastOnline: lastOnlineTimestamp?.dateValue() ?? Date(),
            activeGameId: data["active_game_id"] as? String
        )
    }
} 
