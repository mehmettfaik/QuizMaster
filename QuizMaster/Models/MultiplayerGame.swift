import Foundation
import FirebaseFirestore

enum GameStatus: String, Codable {
    case pending
    case accepted
    case rejected
    case inProgress
    case completed
    case cancelled
}

struct PlayerScore: Codable {
    var userId: String
    var score: Int
    var correctAnswers: Int
    var wrongAnswers: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case score
        case correctAnswers = "correct_answers"
        case wrongAnswers = "wrong_answers"
    }
}

struct MultiplayerGame: Codable {
    let id: String
    let creatorId: String
    let creatorName: String
    let invitedId: String
    let invitedName: String
    let status: GameStatus
    let currentQuestionIndex: Int
    let playerScores: [String: PlayerScore]
    let questions: [String]?
    let category: String?
    let difficulty: String?
    let createdAt: Date
    let responseTime: Date?
    let startTime: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case creatorId = "creator_id"
        case creatorName = "creator_name"
        case invitedId = "invited_id"
        case invitedName = "invited_name"
        case status
        case currentQuestionIndex = "current_question_index"
        case playerScores = "player_scores"
        case questions
        case category
        case difficulty
        case createdAt = "created_at"
        case responseTime = "response_time"
        case startTime = "start_time"
    }
    
    static func from(_ document: DocumentSnapshot) -> MultiplayerGame? {
        guard let data = document.data(),
              let creatorId = data["creator_id"] as? String,
              let invitedId = data["invited_id"] as? String,
              let statusRaw = data["status"] as? String,
              let status = GameStatus(rawValue: statusRaw),
              let currentQuestionIndex = data["current_question_index"] as? Int,
              let createdAt = (data["created_at"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        let creatorName = data["creator_name"] as? String ?? "Unknown"
        let invitedName = data["invited_name"] as? String ?? "Unknown"
        let questions = data["questions"] as? [String]
        let category = data["category"] as? String
        let difficulty = data["difficulty"] as? String
        let responseTime = (data["response_time"] as? Timestamp)?.dateValue()
        let startTime = (data["start_time"] as? Timestamp)?.dateValue()
        
        var playerScores: [String: PlayerScore] = [:]
        if let scores = data["player_scores"] as? [String: [String: Any]] {
            for (userId, scoreData) in scores {
                if let score = scoreData["score"] as? Int,
                   let correctAnswers = scoreData["correct_answers"] as? Int,
                   let wrongAnswers = scoreData["wrong_answers"] as? Int {
                    playerScores[userId] = PlayerScore(
                        userId: userId,
                        score: score,
                        correctAnswers: correctAnswers,
                        wrongAnswers: wrongAnswers
                    )
                }
            }
        }
        
        return MultiplayerGame(
            id: document.documentID,
            creatorId: creatorId,
            creatorName: creatorName,
            invitedId: invitedId,
            invitedName: invitedName,
            status: status,
            currentQuestionIndex: currentQuestionIndex,
            playerScores: playerScores,
            questions: questions,
            category: category,
            difficulty: difficulty,
            createdAt: createdAt,
            responseTime: responseTime,
            startTime: startTime
        )
    }
} 