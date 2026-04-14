import Foundation

struct WatchAIService {
    private static let baseURL  = "https://azure-openai-proxy.ball-breaker.workers.dev"
    private static let devToken = "a83c17f2b50e4e4f93e9c26f52a9d0bb"

    static func chat(messages: [[String: String]]) async throws -> String {
        let url = URL(string: "\(baseURL)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(devToken, forHTTPHeaderField: "x-worker")

        let body: [String: Any] = ["messages": messages, "temperature": 0.7]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }

        guard
            let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw URLError(.cannotParseResponse)
        }

        return content
    }
}
