import Foundation
import FirebaseFirestore

class QuizListViewModel {
    private let db = Firestore.firestore()
    private(set) var quizzes: [QuizListItem] = []
    var onQuizzesUpdated: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    func fetchQuizzes(category: String? = nil, searchText: String = "") {
        let quizzesRef = db.collection("aaaa")
        
        let query = category != nil ? quizzesRef.whereField("category", isEqualTo: category!) : quizzesRef
        
        query.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                self?.onError?(error)
                print("Error fetching quizzes: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                self?.quizzes = []
                self?.onQuizzesUpdated?()
                return
            }
            
            let filteredQuizzes = documents
                .compactMap { QuizListItem.from($0) }
                .filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }
            
            self?.quizzes = filteredQuizzes
            self?.onQuizzesUpdated?()
        }
    }
    
    func clearQuizzes() {
        quizzes = []
        onQuizzesUpdated?()
    }
} 