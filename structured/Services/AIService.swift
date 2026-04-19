import Foundation
#if DEBUG
import BugReporterSDK
#endif

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String      // "user" | "assistant" | "system"
    let content: String
    let createdAt: Date

    init(role: String, content: String) {
        self.role = role
        self.content = content
        self.createdAt = Date()
    }
}

// MARK: - AI Service

enum AIError: LocalizedError {
    case serverError(Int)
    case invalidResponse
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .serverError(let code): return "Server error (\(code)). Try again."
        case .invalidResponse:       return "Unexpected response format."
        case .networkError(let e):   return e.localizedDescription
        }
    }
}

struct AIService {
    private static let baseURL  = "https://azure-openai-proxy.ball-breaker.workers.dev"
    private static let devToken = "a83c17f2b50e4e4f93e9c26f52a9d0bb"

    /// Session with BugReporter network logging injected in debug builds only.
    /// Release builds use the default URLSession so user conversations are never logged.
    private static let session: URLSession = {
        #if DEBUG
        return URLSession(configuration: BugReporter.trackedSessionConfiguration())
        #else
        return URLSession.shared
        #endif
    }()

    /// Send a conversation and return the assistant's reply text.
    static func chat(messages: [[String: String]]) async throws -> String {
        let url = URL(string: "\(baseURL)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(devToken, forHTTPHeaderField: "x-worker")

        let body: [String: Any] = ["messages": messages, "temperature": 0.7]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw AIError.serverError(http.statusCode)
        }

        guard
            let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices   = json["choices"] as? [[String: Any]],
            let message   = choices.first?["message"] as? [String: Any],
            let content   = message["content"] as? String
        else {
            throw AIError.invalidResponse
        }

        return content
    }
}
