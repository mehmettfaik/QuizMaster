import Foundation
import FirebaseFirestore

struct User: Codable {
    let id: String
    var email: String
    var name: String
    var photoURL: String?
    var totalPoints: Int
    var quizzesPlayed: Int
    var quizzesWon: Int
    var language: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case photoURL
        case totalPoints = "total_points"
        case quizzesPlayed = "quizzes_played"
        case quizzesWon = "quizzes_won"
        case language
    }
    
    static func from(_ document: DocumentSnapshot) -> User? {
        guard let data = document.data() else { return nil }
        return User(
            id: document.documentID,
            email: data["email"] as? String ?? "",
            name: data["name"] as? String ?? "",
            photoURL: data["photoURL"] as? String,
            totalPoints: data["total_points"] as? Int ?? 0,
            quizzesPlayed: data["quizzes_played"] as? Int ?? 0,
            quizzesWon: data["quizzes_won"] as? Int ?? 0,
            language: data["language"] as? String ?? "en"
        )
    }
} 