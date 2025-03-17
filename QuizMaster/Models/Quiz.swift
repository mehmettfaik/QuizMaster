import Foundation
import FirebaseFirestore

enum QuizCategory: String, Codable, CaseIterable {
    case vehicle = "Vehicle"
    case science = "Science"
    case sports = "Sports"
    case history = "History"
    case art = "Art"
    case celebrity = "Celebrity"
    case videoGames = "Video Games"
    case generalCulture = "General Culture"
    case animals = "Animals"
    case computerScience = "Computer Science"
    case mathematics = "Mathematics"
    case mythology = "Mythology"
    
    var iconName: String {
        switch self {
        case .vehicle: return "car.fill"
        case .science: return "atom"
        case .sports: return "sportscourt.fill"
        case .history: return "book.fill"
        case .art: return "paintpalette.fill"
        case .celebrity: return "star.fill"
        case .videoGames: return "gamecontroller.fill"
        case .generalCulture: return "globe"
        case .animals: return "pawprint.fill"
        case .computerScience: return "desktopcomputer"
        case .mathematics: return "function"
        case .mythology: return "building.columns.fill"
        }
    }
}

enum QuizDifficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

struct Quiz: Codable {
    let id: String
    let category: QuizCategory
    let difficulty: QuizDifficulty
    let questions: [Question]
    let timePerQuestion: Int
    let pointsPerQuestion: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case difficulty
        case questions
        case timePerQuestion = "time_per_question"
        case pointsPerQuestion = "points_per_question"
    }
    
    static func from(_ document: DocumentSnapshot) -> Quiz? {
        guard let data = document.data() else { return nil }
        return Quiz(
            id: document.documentID,
            category: QuizCategory(rawValue: data["category"] as? String ?? "") ?? .science,
            difficulty: QuizDifficulty(rawValue: data["difficulty"] as? String ?? "") ?? .medium,
            questions: (data["questions"] as? [[String: Any]])?.compactMap { Question.from($0) } ?? [],
            timePerQuestion: data["time_per_question"] as? Int ?? 10,
            pointsPerQuestion: data["points_per_question"] as? Int ?? 10
        )
    }
}

struct Question: Codable {
    let text: String
    let options: [String]
    let correctAnswer: String
    let questionImage: String?
    let optionImages: [String]?
    
    enum CodingKeys: String, CodingKey {
        case text = "question"
        case options
        case correctAnswer = "correct_answer"
        case questionImage = "question_image"
        case optionImages = "option_images"
    }
    
    static func from(_ data: [String: Any]) -> Question? {
        guard let text = data["question"] as? String,
              let options = data["options"] as? [String],
              let correctAnswer = data["correct_answer"] as? String else {
            return nil
        }
        
        return Question(
            text: text,
            options: options,
            correctAnswer: correctAnswer,
            questionImage: data["question_image"] as? String,
            optionImages: data["option_images"] as? [String]
        )
    }
} 
