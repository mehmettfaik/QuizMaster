import Foundation
import Combine

class QuizSessionViewModel: ObservableObject {
    let quiz: Quiz
    
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswer: Int?
    @Published var timeRemaining: Int
    @Published var answers: [QuestionAnswer] = []
    @Published var isCompleted = false
    @Published var showExplanation = false
    
    private var timer: Timer?
    private var questionTimer: Timer?
    private var startTime: Date?
    
    init(quiz: Quiz) {
        self.quiz = quiz
        self.timeRemaining = quiz.timeLimit * 60 // Convert minutes to seconds
    }
    
    var currentQuestion: Question {
        quiz.questions[currentQuestionIndex]
    }
    
    var progress: Float {
        Float(currentQuestionIndex + 1) / Float(quiz.questions.count)
    }
    
    var isLastQuestion: Bool {
        currentQuestionIndex == quiz.questions.count - 1
    }
    
    func startQuiz() {
        startTime = Date()
        startTimer()
    }
    
    func selectAnswer(_ index: Int) {
        selectedAnswer = index
    }
    
    func nextQuestion() {
        guard let selectedAnswer = selectedAnswer else { return }
        
        // Record answer
        let timeSpent = Date().timeIntervalSince(startTime ?? Date())
        let answer = QuestionAnswer(
            questionId: currentQuestion.id,
            selectedAnswer: selectedAnswer,
            isCorrect: selectedAnswer == currentQuestion.correctAnswer,
            timeSpent: timeSpent
        )
        answers.append(answer)
        
        // Move to next question or complete quiz
        if isLastQuestion {
            completeQuiz()
        } else {
            currentQuestionIndex += 1
            self.selectedAnswer = nil
            startTime = Date()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.completeQuiz()
            }
        }
    }
    
    private func completeQuiz() {
        timer?.invalidate()
        timer = nil
        isCompleted = true
        
        // Calculate final score and create quiz attempt
        let totalPoints = answers.reduce(0) { $0 + ($1.isCorrect ? quiz.questions[$0].points : 0) }
        let maxPoints = quiz.questions.reduce(0) { $0 + $1.points }
        let score = Int((Float(totalPoints) / Float(maxPoints)) * 100)
        
        let attempt = QuizAttempt(
            id: UUID().uuidString,
            quizId: quiz.id,
            userId: "current_user_id", // TODO: Get from auth service
            startedAt: startTime ?? Date(),
            completedAt: Date(),
            score: score,
            answers: answers,
            timeSpent: TimeInterval(quiz.timeLimit * 60 - timeRemaining)
        )
        
        // TODO: Save attempt to backend
        print("Quiz completed with score: \(score)%")
    }
    
    func toggleExplanation() {
        showExplanation.toggle()
    }
} 