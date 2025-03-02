import Foundation
import Combine

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
}

protocol NetworkServiceProtocol {
    func fetch<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error>
}

enum Endpoint {
    case getQuizzes
    case getQuiz(id: String)
    case submitQuizResult(QuizResult)
    
    var path: String {
        switch self {
        case .getQuizzes:
            return "/quizzes"
        case .getQuiz(let id):
            return "/quizzes/\(id)"
        case .submitQuizResult:
            return "/quiz-results"
        }
    }
    
    var method: String {
        switch self {
        case .getQuizzes, .getQuiz:
            return "GET"
        case .submitQuizResult:
            return "POST"
        }
    }
}

class NetworkService: NetworkServiceProtocol {
    private let baseURL = "https://api.quizmaster.com" // Replace with your actual API base URL
    
    func fetch<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error> {
        guard let url = URL(string: baseURL + endpoint.path) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        
        if case .submitQuizResult(let result) = endpoint {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(result)
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError("Server error")
                }
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let decodingError = error as? DecodingError {
                    return NetworkError.decodingError
                }
                return error
            }
            .eraseToAnyPublisher()
    }
} 