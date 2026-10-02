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
        XCTAssertEqual(MessageSendPolicy.outcome(responseBody: Data(#"{"isSuccess":true}"#.utf8)), .delivered)
    }

    func testOutcomeWithoutExplicitAnswerNeedsConfirmation() {
        XCTAssertEqual(MessageSendPolicy.outcome(responseBody: Data()), .unconfirmed)
        XCTAssertEqual(MessageSendPolicy.outcome(responseBody: Data("<div>tamam</div>".utf8)), .unconfirmed)
        XCTAssertEqual(MessageSendPolicy.outcome(responseBody: Data(#"{"Id":5}"#.utf8)), .unconfirmed)
        let valid = Data(#"<div class="validation-summary-valid"><ul><li style="display:none"></li></ul></div>"#.utf8)
        XCTAssertEqual(MessageSendPolicy.outcome(responseBody: valid), .unconfirmed)
    }

    func testOutcomeSurfacesRenderedValidationErrors() {
        let page = Data("""
        <form action="/mesaj/yolla">
          <div class="validation-summary-errors"><ul><li>  mesaj   çok kısa </li></ul></div>
        </form>
        """.utf8)
        XCTAssertEqual(MessageSendPolicy.outcome(responseBody: page), .rejected(reason: "mesaj çok kısa"))
        let field = Data(#"<span class="field-validation-error">alıcı bulunamadı</span>"#.utf8)
        XCTAssertEqual(MessageSendPolicy.outcome(responseBody: field), .rejected(reason: "alıcı bulunamadı"))
    }

    func testSubmitEndpointFollowsSameSiteFormAction() {
        func form(_ action: String?) -> MessageForm {
            MessageForm(id: "message-send-form", action: action, hiddenFields: [:])
        }
        XCTAssertEqual(MessageSendPolicy.submitEndpoint(form: nil, isReply: true).path, "/mesaj/yolla")
        XCTAssertEqual(MessageSendPolicy.submitEndpoint(form: nil, isReply: false).path, "/mesaj/sendajax")
        XCTAssertEqual(MessageSendPolicy.submitEndpoint(form: form("/Mesaj/Yolla"), isReply: false).path, "/mesaj/yolla")
        XCTAssertEqual(
            MessageSendPolicy.submitEndpoint(form: form("https://eksisozluk.com/mesaj/gonder?ref=1"), isReply: true).path,
            "/mesaj/gonder?ref=1"
        )
        XCTAssertEqual(MessageSendPolicy.submitEndpoint(form: form("/mesaj/gonder"), isReply: true).method, .post)
        for foreign in ["https://example.com/mesaj/yolla", "/entry/ekle", "/mesaj/", "javascript:alert(1)", "", nil] {
            XCTAssertEqual(
                MessageSendPolicy.submitEndpoint(form: form(foreign), isReply: true).path,
                "/mesaj/yolla",
                "action \(String(describing: foreign))"
            )
        }
    }

    func testRequestBodyUsesTheFormsOwnFieldNames() {
        let form = MessageForm(
            id: nil,
            action: "/mesaj/gonder",
            hiddenFields: ["__RequestVerificationToken": "token", "ThreadId": "77"],
            visibleFields: ["to": "altere ses", "Notify": "true"],
            messageFieldName: "Content",
            recipientFieldName: "to"
        )
        let payload = ["To": "altere-ses", "Message": "merhaba", "ThreadId": "altere-ses", "IsReply": "True"]

        XCTAssertEqual(MessageSendPolicy.requestBody(payload: payload, form: form), [
            "to": "altere ses",
            "Content": "merhaba",
            "ThreadId": "77",
            "IsReply": "True",
            "Notify": "true",
        ])
    }

    func testRequestBodyNeverSendsALinkSlugAsConversationID() {
        let form = MessageForm(
            id: "message-send-form",
            action: "/mesaj/yolla",
            hiddenFields: ["__RequestVerificationToken": "token", "IsReply": "True"],
            messageFieldName: "Message"
        )
        let slug = ["To": "altere ses", "Message": "selam", "ThreadId": "altere-ses", "IsReply": "True"]
        XCTAssertEqual(MessageSendPolicy.requestBody(payload: slug, form: form), ["To": "altere ses", "Message": "selam"])

        var numeric = slug
        numeric["ThreadId"] = "2541826"
        XCTAssertEqual(MessageSendPolicy.requestBody(payload: numeric, form: form), [
            "To": "altere ses",
            "Message": "selam",
            "ThreadId": "2541826",
            "IsReply": "True",
        ])
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
