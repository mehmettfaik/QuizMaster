import Foundation
import Combine

class QuizReviewViewModel: ObservableObject {
    let quiz: Quiz
    let answers: [QuestionAnswer]
    
    @Published var currentQuestionIndex = 0
    @Published var showExplanation = false
    
    init(quiz: Quiz, answers: [QuestionAnswer]) {
        self.quiz = quiz
        self.answers = answers
    }
    
    var currentQuestion: Question {
        quiz.questions[currentQuestionIndex]
    }
    
    var currentAnswer: QuestionAnswer {
        answers[currentQuestionIndex]
    }
    
    var progress: Float {
        Float(currentQuestionIndex + 1) / Float(quiz.questions.count)
    }
    
    var isLastQuestion: Bool {
        currentQuestionIndex == quiz.questions.count - 1
    }
    
    func moveToNextQuestion() {
        guard !isLastQuestion else { return }
        withAnimation {
            currentQuestionIndex += 1
            showExplanation = false
        }
    }
    
    func moveToPreviousQuestion() {
        guard currentQuestionIndex > 0 else { return }
        withAnimation {
            currentQuestionIndex -= 1
            showExplanation = false
        }
    }
    
    func toggleExplanation() {
        withAnimation {
            showExplanation.toggle()
        }
    }
    
    func questionTimeString(for index: Int) -> String {
        let timeSpent = answers[index].timeSpent
        let minutes = Int(timeSpent) / 60
        let seconds = Int(timeSpent) % 60
        return "\(minutes)m \(seconds)s"
    }
} 