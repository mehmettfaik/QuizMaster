import Foundation
import Combine

class QuizListViewModel {
    // MARK: - Properties
    @Published private(set) var quizzes: [Quiz] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    // MARK: - Public Methods
    func fetchQuizzes() {
        isLoading = true
        error = nil
        
        networkService.fetch(Endpoint.getQuizzes)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] (quizzes: [Quiz]) in
                self?.quizzes = quizzes
            }
            .store(in: &cancellables)
    }
    
    func selectQuiz(_ quiz: Quiz) {
        // TODO: Handle quiz selection and navigation
        print("Selected quiz: \(quiz.title)")
    }
    
    func filterQuizzes(by difficulty: Quiz.QuizDifficulty?) {
        // TODO: Implement quiz filtering
    }
} 