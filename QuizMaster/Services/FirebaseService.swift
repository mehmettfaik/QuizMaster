import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GoogleSignIn

class FirebaseService {
    static let shared = FirebaseService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Authentication
    func signUp(email: String, password: String, name: String, completion: @escaping (Result<User, Error>) -> Void) {
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
                "total_points": 0,
                "quizzes_played": 0,
                "quizzes_won": 0,
                "language": "en"
            ]
            
            self?.db.collection("users").document(userId).setData(userData) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let user = User(id: userId, email: email, name: name, photoURL: nil, totalPoints: 0, quizzesPlayed: 0, quizzesWon: 0, language: "en")
                completion(.success(user))
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userId = result?.user.uid else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
                return
            }
            
            self?.getUser(userId: userId, completion: completion)
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func signInWithGoogle(presenting: UIViewController, completion: @escaping (Result<User, Error>) -> Void) {
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
                
                // Check if user exists
                self?.db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    if let snapshot = snapshot, snapshot.exists == true {
                        // User exists, get data
                        self?.getUser(userId: userId, completion: completion)
                    } else {
                        // New user, create profile
                        let userData: [String: Any] = [
                            "email": authentication.profile?.email ?? "",
                            "name": authentication.profile?.name ?? "",
                            "total_points": 0,
                            "quizzes_played": 0,
                            "quizzes_won": 0,
                            "language": "en"
                        ]
                        
                        self?.db.collection("users").document(userId).setData(userData) { error in
                            if let error = error {
                                completion(.failure(error))
                                return
                            }
                            
                            let user = User(
                                id: userId,
                                email: authentication.profile?.email ?? "",
                                name: authentication.profile?.name ?? "",
                                photoURL: authentication.profile?.imageURL(withDimension: 200),
                                totalPoints: 0,
                                quizzesPlayed: 0,
                                quizzesWon: 0,
                                language: "en"
                            )
                            completion(.success(user))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - User Operations
    func getUser(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists == true, let user = User.from(snapshot) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            
            completion(.success(user))
        }
    }
    
    // MARK: - Quiz Operations
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
    
    func updateUserScore(userId: String, points: Int, won: Bool) {
        let userRef = db.collection("users").document(userId)
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let userDocument: DocumentSnapshot
            do {
                try userDocument = transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let oldPoints = userDocument.data()?["total_points"] as? Int,
                  let oldPlayed = userDocument.data()?["quizzes_played"] as? Int,
                  let oldWon = userDocument.data()?["quizzes_won"] as? Int else {
                return nil
            }
            
            transaction.updateData([
                "total_points": oldPoints + points,
                "quizzes_played": oldPlayed + 1,
                "quizzes_won": oldWon + (won ? 1 : 0)
            ], forDocument: userRef)
            
            return nil
        }) { _, error in
            if let error = error {
                print("Error updating user score: \(error)")
            }
        }
    }
    
    // MARK: - Leaderboard
    func getLeaderboard(completion: @escaping (Result<[User], Error>) -> Void) {
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
                
                let users = documents.compactMap { User.from($0) }
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