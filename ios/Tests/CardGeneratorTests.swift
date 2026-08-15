import Testing
import Foundation
@testable import Flashcards

/// Answers HTTP without a network.
///
/// A URLProtocol stub rather than a mock URLSession: the request goes through
/// the real URLSession machinery, so the tests check what is actually sent -
/// headers, body, URL - and not what a fake remembered being told. Same
/// argument as Chapter 9's file tests.
final class StubProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var body = Data()
    nonisolated(unsafe) static var lastRequest: URLRequest?

    static func reset(status: Int = 200, body: String = "") {
        self.status = status
        self.body = Data(body.utf8)
        self.lastRequest = nil
    }

    static var session: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        // httpBody is stripped by the loading system; the stream survives.
        var recorded = request
        if let stream = request.httpBodyStream {
            stream.open()
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: buffer.count)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
            stream.close()
            recorded.httpBody = data
        }
        StubProtocol.lastRequest = recorded

        let response = HTTPURLResponse(
            url: request.url!, statusCode: StubProtocol.status,
            httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: StubProtocol.body)
        client?.urlProtocolDidFinishLoading(self)
    }
}

@Suite("CardGenerator", .serialized)
struct CardGeneratorTests {

    private func generator() throws -> RemoteCardGenerator {
        RemoteCardGenerator(
            key: try #require(APIKey("sk-test-SECRETVALUE")),
            endpoint: URL(string: "https://example.invalid/v1/chat")!,
            session: StubProtocol.session)
    }

    @Test("Cards come back parsed")
    func parsesCards() async throws {
        StubProtocol.reset(body: """
        {"cards": [{"front": "to run", "back": "correr"}]}
        """)
        let cards = try await generator().generate(count: 1, forDeckNamed: "Spanish")
        #expect(cards.count == 1)
        #expect(cards.first?.back == "correr")
    }

    @Test("The key is sent as a header, never in the URL")
    func keyGoesInTheHeader() async throws {
        StubProtocol.reset(body: #"{"cards": []}"#)
        _ = try await generator().generate(count: 1, forDeckNamed: "Spanish")

        let request = try #require(StubProtocol.lastRequest)
        #expect(request.value(forHTTPHeaderField: "Authorization")
                == "Bearer sk-test-SECRETVALUE")
        #expect(!(request.url?.absoluteString.contains("SECRETVALUE") ?? true))
    }

    @Test("HTTP failures become specific errors", arguments: [
        (401, GeneratorError.unauthorized),
        (403, GeneratorError.unauthorized),
        (429, GeneratorError.rateLimited),
        (500, GeneratorError.server(status: 500)),
    ])
    func mapsStatusCodes(status: Int, expected: GeneratorError) async throws {
        StubProtocol.reset(status: status, body: "")
        await #expect(throws: expected) {
            try await generator().generate(count: 1, forDeckNamed: "Spanish")
        }
    }

    /// The one that matters. A 401 body commonly echoes the request back,
    /// Authorization header included, and the obvious error message pastes it
    /// straight into a log.
    @Test("No error ever contains the key")
    func errorsNeverLeakTheKey() async throws {
        let bodies = [
            #"{"error": "invalid api key: sk-test-SECRETVALUE"}"#,
            #"{"request": {"headers": {"Authorization": "Bearer sk-test-SECRETVALUE"}}}"#,
            "sk-test-SECRETVALUE",
        ]
        for status in [200, 401, 500] {
            for body in bodies {
                StubProtocol.reset(status: status, body: body)
                do {
                    _ = try await generator().generate(count: 1, forDeckNamed: "Spanish")
                } catch {
                    let text = "\(error) \(String(describing: error))"
                    #expect(!text.contains("SECRETVALUE"),
                            "an error description leaked the key: \(text)")
                }
            }
        }
    }

    @Test("An APIKey does not print itself")
    func keyRedactsItself() throws {
        let key = try #require(APIKey("sk-test-SECRETVALUE"))
        #expect("\(key)" == "APIKey(redacted)")
        #expect(String(describing: key) == "APIKey(redacted)")
        #expect(String(reflecting: key) == "APIKey(redacted)")
        #expect(!"The key is \(key)".contains("SECRETVALUE"))
    }

    @Test("Blank keys are refused", arguments: ["", " ", "\n", nil])
    func refusesBlankKeys(value: String?) {
        #expect(APIKey(value) == nil)
    }
}
