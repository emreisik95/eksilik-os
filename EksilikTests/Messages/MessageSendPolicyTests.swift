import XCTest
@testable import EksilikApp

final class MessageSendPolicyTests: XCTestCase {
    func testRepliesLoadTheirConversationBeforeSending() {
        let pages = MessageSendPolicy.formPages(recipient: "altere ses", threadID: " 2541826 ")
        XCTAssertEqual(pages.map(\.path), ["/mesaj/2541826"])
    }

    func testNewMessagesLoadInboxThenRecipientProfile() {
        let pages = MessageSendPolicy.formPages(recipient: " altere ses ", threadID: nil)
        XCTAssertEqual(pages.map(\.path), ["/mesaj", "/biri/altere%20ses"])
        XCTAssertEqual(MessageSendPolicy.formPages(recipient: " ", threadID: "  ").map(\.path), ["/mesaj"])
    }

    func testFreshFormTokenBeatsPageAndCachedTokens() {
        let form = MessageForm(
            id: "message-send-form",
            action: nil,
            hiddenFields: ["__RequestVerificationToken": "form"]
        )
        XCTAssertEqual(MessageSendPolicy.token(form: form, pageToken: "page", cachedToken: "cached"), "form")
        XCTAssertEqual(MessageSendPolicy.token(form: nil, pageToken: " page ", cachedToken: "cached"), "page")
        XCTAssertEqual(MessageSendPolicy.token(form: nil, pageToken: " ", cachedToken: "cached"), "cached")
        XCTAssertNil(MessageSendPolicy.token(form: nil, pageToken: nil, cachedToken: "\n"))
    }

    func testRequestBodyMirrorsBrowserSubmitWithServerThreadID() {
        let form = MessageForm(
            id: "message-send-form-1",
            action: "/mesaj/yolla",
            hiddenFields: [
                "__RequestVerificationToken": "token",
                "threadId": "2541826",
                "Extra": "server",
                "Message": "stale",
            ]
        )
        let payload = ["To": "altere ses", "Message": "merhaba", "ThreadId": "altere-ses", "IsReply": "True"]

        let body = MessageSendPolicy.requestBody(payload: payload, form: form)

        XCTAssertEqual(body, [
            "To": "altere ses",
            "Message": "merhaba",
            "ThreadId": "2541826",
            "IsReply": "True",
            "Extra": "server",
        ])
    }

    func testBodyWithoutComposedThreadKeepsRenderedFields() {
        let form = MessageForm(id: "message-send-form", action: nil, hiddenFields: ["ThreadId": "1"])
        let body = MessageSendPolicy.requestBody(payload: ["To": "a", "Message": "b"], form: form)
        XCTAssertEqual(body, ["To": "a", "Message": "b", "ThreadId": "1"])
        XCTAssertEqual(MessageSendPolicy.requestBody(payload: ["To": "a"], form: nil), ["To": "a"])
    }

    func testOutcomeTreatsExplicitFailureAsRejection() {
        let rejected = Data(#"{"Success":false,"Message":"bu yazara mesaj gönderemezsiniz"}"#.utf8)
        XCTAssertEqual(
            MessageSendPolicy.outcome(responseBody: rejected),
            .rejected(reason: "bu yazara mesaj gönderemezsiniz")
        )
        XCTAssertEqual(
            MessageSendPolicy.outcome(responseBody: Data(#"{"success":false}"#.utf8)),
            .rejected(reason: nil)
        )
        XCTAssertEqual(MessageSendPolicy.outcome(responseBody: Data(#"{"Success":true}"#.utf8)), .delivered)
        XCTAssertEqual(MessageSendPolicy.outcome(responseBody: Data()), .delivered)
        XCTAssertEqual(MessageSendPolicy.outcome(responseBody: Data("<div>tamam</div>".utf8)), .delivered)
    }

    func testOutcomeDetectsLoginPageResponses() {
        let login = Data(#"<ul><li><a id="top-login-link" href="/giris">giriş</a></li></ul>"#.utf8)
        XCTAssertEqual(MessageSendPolicy.outcome(responseBody: login), .signedOut)
    }

    func testPagesWithoutTokenKeepTheLastSessionToken() {
        XCTAssertEqual(MessageSendPolicy.retainedToken(current: "old", incoming: nil), "old")
        XCTAssertEqual(MessageSendPolicy.retainedToken(current: "old", incoming: "  "), "old")
        XCTAssertEqual(MessageSendPolicy.retainedToken(current: "old", incoming: "new"), "new")
        XCTAssertNil(MessageSendPolicy.retainedToken(current: nil, incoming: nil))
    }
}
