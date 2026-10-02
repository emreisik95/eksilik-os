import XCTest
@testable import EksilikApp

/// Message pages as the server renders them, reduced to what the send flow reads.
enum MessagePageFixture {
    static let loggedInNav = #"<li class="buddy mobile-only"><a href="/biri/ben" title="ben">ben</a></li>"#

    static func thread(_ messages: [(text: String, direction: String)]) -> String {
        let articles = messages
            .map { #"<article class="\#($0.direction)"><p>\#($0.text)</p></article>"# }
            .joined()
        return #"<section id="message-thread">"# + articles + "</section>"
    }

    static let replyFormWithThread = """
    <form id="message-send-form" action="/mesaj/yolla" method="post">
      <input type="hidden" name="__RequestVerificationToken" value="t" />
      <input type="hidden" name="ThreadId" value="2541826" />
      <textarea name="Message"></textarea>
    </form>
    """

    static let newMessageForm = """
    <form id="message-send-form" action="/mesaj/sendajax" method="post">
      <input type="hidden" name="__RequestVerificationToken" value="t" />
      <input type="text" name="To" />
      <textarea name="Message"></textarea>
    </form>
    """
}

final class MessageTransportSpy: MessageTransport {
    struct Post {
        let path: String
        let body: [String: String]
        let token: String?
        let isAjax: Bool
    }

    private let pages: [String: String]
    /// Pages that change between reads, served in order; the last one repeats
    /// unless `exhaustedSequencesFail` is set.
    private var sequences: [String: [String]]
    private let exhaustedSequencesFail: Bool
    private let response: String
    /// Status codes the server answers a post to these paths with.
    private let failures: [String: Int]
    private(set) var fetched: [String] = []
    private(set) var posts: [Post] = []

    init(
        pages: [String: String],
        sequences: [String: [String]] = [:],
        response: String = #"{"Success":true}"#,
        failures: [String: Int] = [:],
        exhaustedSequencesFail: Bool = false
    ) {
        self.pages = pages
        self.sequences = sequences
        self.exhaustedSequencesFail = exhaustedSequencesFail
        self.response = response
        self.failures = failures
    }

    func fetchHTML(for endpoint: EksiEndpoint) async throws -> String {
        fetched.append(endpoint.path)
        if let sequence = sequences[endpoint.path] {
            guard let html = sequence.first else { throw NetworkError.cloudflareBlocked }
            if sequence.count > 1 || exhaustedSequencesFail {
                sequences[endpoint.path] = Array(sequence.dropFirst())
            }
            return html
        }
        guard let html = pages[endpoint.path] else { throw NetworkError.cloudflareBlocked }
        return html
    }

    func post(
        endpoint: EksiEndpoint,
        body: [String: String],
        csrfToken: String?
    ) async throws -> (Data, HTTPURLResponse) {
        posts.append(Post(path: endpoint.path, body: body, token: csrfToken, isAjax: !endpoint.omitsAjaxHeader))
        if let status = failures[endpoint.path] {
            throw NetworkError.requestFailed(statusCode: status)
        }
        let url = try XCTUnwrap(URL(string: "https://eksisozluk.com" + endpoint.path))
        let http = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        return (Data(response.utf8), http)
    }
}
