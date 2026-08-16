import Foundation

/// Making cards for a deck, from its name.
protocol CardGenerator {
    func generate(count: Int, forDeckNamed name: String) async throws -> [Card]
}

enum GeneratorError: Error, Equatable {
    case notConfigured
    case unauthorized
    case rateLimited
    case server(status: Int)
    case badResponse(String)
    case implausibleResponse(String)
}

/// Talks to a chat-completions endpoint and parses cards out of the reply.
struct RemoteCardGenerator: CardGenerator {
    let key: APIKey
    let endpoint: URL
    let session: URLSession

    init(key: APIKey,
         endpoint: URL = URL(string: "https://api.openai.com/v1/chat/completions")!,
         session: URLSession = .shared) {
        self.key = key
        self.endpoint = endpoint
        self.session = session
    }

    /// Limits on what a reply may contain.
    ///
    /// The endpoint is not part of this app and is not trusted, whoever runs
    /// it. A reply is data arriving from somewhere else; the fact that we asked
    /// for it politely does not make it safe. See Chapter 22.
    static let maximumCards = 100
    static let maximumFieldLength = 500

    func generate(count: Int, forDeckNamed name: String) async throws -> [Card] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        // The key goes in a header. Never a query parameter: URLs end up in
        // server logs, proxy logs, and analytics, and nobody redacts them.
        request.setValue("Bearer \(key.rawValue)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            Prompt(deck: name, count: count))

        let (data, response) = try await session.data(for: request)

        switch (response as? HTTPURLResponse)?.statusCode ?? 0 {
        case 200..<300: break
        case 401, 403:  throw GeneratorError.unauthorized
        case 429:       throw GeneratorError.rateLimited
        case let status: throw GeneratorError.server(status: status)
        }

        do {
            let cards = try JSONDecoder().decode(Reply.self, from: data).cards
            guard cards.count <= Self.maximumCards else {
                throw GeneratorError.implausibleResponse(
                    "\(cards.count) cards for a request of \(count)")
            }
            guard cards.allSatisfy({
                $0.front.count <= Self.maximumFieldLength
                    && $0.back.count <= Self.maximumFieldLength
            }) else {
                throw GeneratorError.implausibleResponse("a card field is too long")
            }
            return cards
        } catch let error as GeneratorError {
            throw error
        } catch {
            // Deliberately does not include the response body. A failed request
            // often echoes the request back, headers included.
            throw GeneratorError.badResponse(
                "The reply did not contain cards (\(data.count) bytes).")
        }
    }

    struct Prompt: Encodable {
        let deck: String
        let count: Int
    }

    struct Reply: Decodable {
        let cards: [Card]
    }
}
