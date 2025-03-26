import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GoogleSignIn

class FirebaseService {
    static let shared = FirebaseService()
    private let auth = Auth.auth()
    fileprivate let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Authentication
    func signUp(email: String, password: String, name: String, completion: @escaping (Result<QuizMaster.User, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userId = result?.user.uid else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
                return
            }
            
            let userData: [String: Any] = [
                "email": email,
                "name": name,
                "avatar": "wizard",
                "total_points": 0,
                "quizzes_played": 0,
                "quizzes_won": 0,
                "language": "tr",
                "category_stats": [:] as [String: Any],
                "isOnline": true,
                "lastSeen": Timestamp(date: Date())
            ]
            
            // UserDefaults'a kullanıcı bilgilerini kaydet
            UserDefaults.standard.set(userId, forKey: "userId")
            UserDefaults.standard.set(name, forKey: "userName")
            UserDefaults.standard.set("wizard", forKey: "userAvatar")
            UserDefaults.standard.synchronize()
            
            self?.db.collection("users").document(userId).setData(userData) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let user = QuizMaster.User(
                    id: userId,
                    email: email,
                    name: name,
                    avatar: "wizard",
                    totalPoints: 0,
                    quizzesPlayed: 0,
                    quizzesWon: 0,
                    language: "tr",
                    categoryStats: [:]
                )
                completion(.success(user))
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<QuizMaster.User, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userId = result?.user.uid else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
                return
            }
            
            self?.db.collection("users").document(userId).updateData([
                "isOnline": true,
                "lastSeen": Timestamp(date: Date())
            ])
            
            self?.db.collection("users").document(userId).getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let userData = snapshot?.data() {
                    UserDefaults.standard.set(userId, forKey: "userId")
                    UserDefaults.standard.set(userData["name"] as? String ?? "", forKey: "userName")
                    UserDefaults.standard.set(userData["avatar"] as? String ?? "wizard", forKey: "userAvatar")
                    UserDefaults.standard.synchronize()
                }
                
                self?.getUser(userId: userId, completion: completion)
            }
        }
    }
    
    func signOut() throws {
        if let userId = Auth.auth().currentUser?.uid {
            self.db.collection("users").document(userId).updateData([
                "isOnline": false,
                "lastSeen": Timestamp(date: Date())
            ])
        }
        try auth.signOut()
    }
    
    func signInWithGoogle(presenting: UIViewController, completion: @escaping (Result<QuizMaster.User, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let authentication = result?.user,
                  let idToken = authentication.idToken?.tokenString else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google authentication failed"])
                completion(.failure(error))
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: authentication.accessToken.tokenString)
            
            self?.auth.signIn(with: credential) { [weak self] result, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let userId = result?.user.uid else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
                    return
                }
                
                self?.db.collection("users").document(userId).getDocument { [weak self] document, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    if let document = document, document.exists {
                        let userData = document.data() ?? [:]
                        UserDefaults.standard.set(userId, forKey: "userId")
                        UserDefaults.standard.set(userData["name"] as? String ?? authentication.profile?.name ?? "", forKey: "userName")
                        UserDefaults.standard.set(userData["avatar"] as? String ?? "wizard", forKey: "userAvatar")
                        UserDefaults.standard.synchronize()
                        
                        self?.db.collection("users").document(userId).updateData([
                            "isOnline": true,
                            "lastSeen": Timestamp(date: Date())
                        ])
                        self?.getUser(userId: userId, completion: completion)
                    } else {
                        let name = authentication.profile?.name ?? ""
                        let userData: [String: Any] = [
                            "email": authentication.profile?.email ?? "",
                            "name": name,
                            "avatar": "wizard",
                            "total_points": 0,
                            "quizzes_played": 0,
                            "quizzes_won": 0,
                            "language": "tr",
                            "category_stats": [:] as [String: Any],
                            "isOnline": true,
                            "lastSeen": Timestamp(date: Date())
                        ]
                        
                        UserDefaults.standard.set(userId, forKey: "userId")
                        UserDefaults.standard.set(name, forKey: "userName")
                        UserDefaults.standard.set("wizard", forKey: "userAvatar")
                        UserDefaults.standard.synchronize()
                        
                        self?.db.collection("users").document(userId).setData(userData) { error in
                            if let error = error {
                                completion(.failure(error))
                                return
                            }
                            
                            let user = QuizMaster.User(
                                id: userId,
                                email: authentication.profile?.email ?? "",
                                name: name,
                                avatar: "wizard",
                                totalPoints: 0,
                                quizzesPlayed: 0,
                                quizzesWon: 0,
                                language: "tr",
                                categoryStats: [:]
                            )
                            completion(.success(user))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - User Operations
    func getUser(userId: String, completion: @escaping (Result<QuizMaster.User, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists == true, let user = QuizMaster.User.from(snapshot) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            
            completion(.success(user))
        }
    }
    
    // MARK: - Leaderboard
    func getLeaderboard(completion: @escaping (Result<[QuizMaster.User], Error>) -> Void) {
        db.collection("users")
            .order(by: "total_points", descending: true)
            .limit(to: 100)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let users = documents.compactMap { QuizMaster.User.from($0) }
                completion(.success(users))
            }
    }
    
    // MARK: - Profile Image
    func uploadProfileImage(userId: String, imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let storageRef = storage.reference().child("profile_images/\(userId).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                self.db.collection("users").document(userId).updateData([
                    "photoURL": downloadURL.absoluteString
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    completion(.success(downloadURL.absoluteString))
                }
            }
        }
    }
}

// MARK: - Quiz Operations
extension FirebaseService {
    func getQuizzes(category: QuizCategory, difficulty: QuizDifficulty, completion: @escaping (Result<[Quiz], Error>) -> Void) {
        db.collection("quizzes")
            .whereField("category", isEqualTo: category.rawValue)
            .whereField("difficulty", isEqualTo: difficulty.rawValue)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let quizzes = documents.compactMap { Quiz.from($0) }
                completion(.success(quizzes))
            }
    }
    
    func getQuizCategories(completion: @escaping (Result<[String], Error>) -> Void) {
        db.collection("quizzes")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                // Benzersiz kategorileri al
                let categories = Array(Set(documents.compactMap { document in
                    document.data()["category"] as? String
                })).sorted()
                
                completion(.success(categories))
            }
    }
    
    func updateUserScore(userId: String, category: String, correctAnswers: Int, wrongAnswers: Int, points: Int) {
        let userRef = db.collection("users").document(userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let userDocument: DocumentSnapshot
            do {
                try userDocument = transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let oldPlayed = userDocument.data()?["quizzes_played"] as? Int else {
                return nil
            }
            
            var categoryStats = userDocument.data()?["category_stats"] as? [String: [String: Any]] ?? [:]
            let currentStats = categoryStats[category] as? [String: Any] ?? [
                "correct_answers": 0,
                "wrong_answers": 0,
                "point": 0
            ]
            
            let updatedStats: [String: Any] = [
                "correct_answers": (currentStats["correct_answers"] as? Int ?? 0) + correctAnswers,
                "wrong_answers": (currentStats["wrong_answers"] as? Int ?? 0) + wrongAnswers,
                "point": (currentStats["point"] as? Int ?? 0) + points
            ]
            
            categoryStats[category] = updatedStats
            
            // Calculate total points from all categories
            var totalPoints = 0
            for (_, stats) in categoryStats {
                if let categoryPoints = stats["point"] as? Int {
                    totalPoints += categoryPoints
                }
            }
            
            transaction.updateData([
                "quizzes_played": oldPlayed + 1,
                "category_stats": categoryStats,
                "total_points": totalPoints
            ], forDocument: userRef)
            
            return nil
        }) { _, error in
            if let error = error {
                print("Error updating user score: \(error)")
            }
        }
    }
} 
