import Foundation
import FirebaseFirestore

struct QuizListItem: Identifiable {
    let id: String
    let title: String
    let category: String
    let quizCount: Int
    
    static func from(_ document: QueryDocumentSnapshot) -> QuizListItem? {
        let data = document.data()
        return QuizListItem(
            id: document.documentID,
            title: data["title"] as? String ?? "Untitled Quiz",
            category: data["category"] as? String ?? "General",
            quizCount: data["quizCount"] as? Int ?? 0
        )
    }
} 