import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import Firebase

class QuizViewModel {
    // MARK: - Published Properties
    @Published private(set) var currentQuestion: Question?
    @Published private(set) var isFinished = false
    @Published private(set) var score = 0
    @Published private(set) var error: Error?
    @Published private(set) var isLoading = false
    @Published private(set) var currentQuestionIndex = 0
    @Published private(set) var totalQuestions = 0
    @Published private(set) var progress: Float = 0.0
    
    // MARK: - Private Properties
    private let firebaseService = FirebaseService.shared
    private var quiz: Quiz?
    private var questions: [Question] = []
    private var cancellables = Set<AnyCancellable>()
    private var currentCategory: QuizCategory = .vehicle
    private var currentDifficulty: QuizDifficulty = .easy
    
    // MARK: - Quiz Loading
    func loadQuiz(category: String, difficulty: QuizDifficulty) {
        isLoading = true
        error = nil
        
        currentCategory = QuizCategory(rawValue: category) ?? .science
        currentDifficulty = difficulty
        
        // Format category name for Firestore path - camelCase
        let formattedCategory = category.components(separatedBy: " ")
            .enumerated()
            .map { index, word in
                if index == 0 {
                    return word.lowercased()
                }
                return word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
            .joined()
        
        let db = Firestore.firestore()
        let questionsRef = db
            .collection("aaaa")
            .document(formattedCategory)
            .collection("questions")
            .whereField("difficulty", isEqualTo: difficulty.rawValue.lowercased())
        
        print("📝 Loading questions for:")
        print("   Category: \(category)")
        print("   Formatted Category (camelCase): \(formattedCategory)")
        print("   Difficulty: \(difficulty.rawValue)")
        print("   Full Path: aaaa/\(formattedCategory)/questions")
        
        questionsRef.getDocuments { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ Error loading quiz: \(error.localizedDescription)")
                    self.error = error
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("❌ No quiz found for category: \(category) and difficulty: \(difficulty)")
                    self.error = NSError(
                        domain: "QuizError",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Bu kategori ve zorluk seviyesinde soru bulunamadı."]
                    )
                    return
                }
                
                print("✅ Found \(documents.count) questions")
                self.processQuizDocuments(documents)
            }
        }
    }
    
    // MARK: - Quiz Processing
    private func processQuizDocuments(_ documents: [QueryDocumentSnapshot]) {
        questions.removeAll()
        
        for document in documents {
            if let question = createQuestion(from: document) {
                questions.append(question)
            }
        }
        
        guard !questions.isEmpty else {
            print("❌ No valid questions found")
            error = NSError(
                domain: "QuizError",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Geçerli soru bulunamadı."]
            )
            return
        }
        
        // Soruları karıştır
        questions.shuffle()
        
        // Quiz modelini oluştur
        quiz = Quiz(
            id: UUID().uuidString,
            category: currentCategory,
            difficulty: currentDifficulty,
            questions: questions,
            timePerQuestion: 30,
            pointsPerQuestion: 10
        )
        
        // İlk soruyu ayarla
        totalQuestions = questions.count
        currentQuestionIndex = 0
        currentQuestion = questions.first
        progress = 0.0
        score = 0
        isFinished = false
        
        print("✅ Successfully loaded \(questions.count) questions")
    }
    
    private func createQuestion(from document: QueryDocumentSnapshot) -> Question? {
        let data = document.data()
        
        guard let text = data["question"] as? String,
              let options = data["options"] as? [String],
              let correctAnswer = data["correct_answer"] as? String else {
            print("❌ Invalid question data:", data)
            return nil
        }
        
        let questionImage = data["question_image"] as? String
        let optionImages = data["option_images"] as? [String]
        
        print("📝 Loaded Question:")
        print("   Question:", text)
        print("   Options:", options)
        print("   Correct Answer:", correctAnswer)
        print("   Question Image:", questionImage ?? "None")
        print("   Option Images:", optionImages ?? "None")
        
        // Detaylı şık resmi kontrolü
        if let images = optionImages {
            print("🖼 Option Images Check:")
            for (index, imageName) in images.enumerated() {
                let image = UIImage(named: imageName)
                print("   Şık \(index + 1) - \(imageName): \(image != nil ? "✅ Loaded" : "❌ Not found in Assets")")
            }
        }
        
        print("   Document ID:", document.documentID)
        print("------------------------")
        
        return Question(
            text: text,
            options: options,
            correctAnswer: correctAnswer,
            questionImage: questionImage,
            optionImages: optionImages
        )
    }
    
    // MARK: - Quiz Navigation
    func nextQuestion() {
        guard currentQuestionIndex < questions.count - 1 else {
            isFinished = true
            updateUserScore()
            return
        }
        
        currentQuestionIndex += 1
        currentQuestion = questions[currentQuestionIndex]
        progress = Float(currentQuestionIndex) / Float(totalQuestions)
    }
    
    // MARK: - Answer Handling
    func answerQuestion(_ answer: String?) {
        guard let quiz = quiz,
              let currentQuestion = currentQuestion else { return }
        
        let isCorrect = answer == currentQuestion.correctAnswer
        
        if isCorrect {
            score += quiz.pointsPerQuestion
            print("✅ Correct answer! Current score: \(score)")
        } else {
            print("❌ Wrong answer. Correct answer was: \(currentQuestion.correctAnswer)")
        }
    }
    
    // MARK: - Score Management
    private func updateUserScore() {
        guard let userId = Auth.auth().currentUser?.uid,
              let quiz = quiz else {
            print("❌ No user logged in or quiz not available")
            return
        }
        
        // Calculate correct and wrong answers
        var correctAnswers = 0
        var wrongAnswers = 0
        let pointsPerQuestion = quiz.pointsPerQuestion
        
        for (index, question) in questions.enumerated() {
            if score >= (index + 1) * pointsPerQuestion {
                correctAnswers += 1
            } else {
                wrongAnswers += 1
            }
        }
        
        firebaseService.updateUserScore(
            userId: userId,
            category: currentCategory.rawValue,
            correctAnswers: correctAnswers,
            wrongAnswers: wrongAnswers,
            points: score
        )
        print("✅ Score updated - Category: \(currentCategory.rawValue), Points: \(score), Correct: \(correctAnswers), Wrong: \(wrongAnswers)")
    }
    
    // MARK: - Quiz State
    func resetQuiz() {
        currentQuestionIndex = 0
        score = 0
        isFinished = false
        progress = 0.0
        currentQuestion = questions.first
        questions.shuffle()
    }
    
    var currentProgress: Float {
        guard totalQuestions > 0 else { return 0 }
        return Float(currentQuestionIndex) / Float(totalQuestions)
    }
    
    var isLastQuestion: Bool {
        return currentQuestionIndex == totalQuestions - 1
    }
}
