import XCTest
@testable import EksilikApp

final class MessageFormParserTests: XCTestCase {
    private let threadPage = """
    <form id="message-search-form" action="/mesaj/ara" method="get"><input name="q" /></form>
    <form id="message-delete-form" action="/mesaj/sil" method="post">
      <input type="hidden" name="__RequestVerificationToken" value="delete-token" />
      <input type="hidden" name="ThreadIds" value="2541826" />
    </form>
    <form id="message-send-form-2541826" action="/mesaj/yolla" method="post">
      <input type="hidden" name="__RequestVerificationToken" value=" reply-token " />
      <input type="hidden" name="ThreadId" value="2541826" />
      <input type="hidden" name="IsReply" value="True" />
      <input type="hidden" name="Empty" value="" />
      <input type="text" name="To" value="altere ses" />
      <textarea name="Message"></textarea>
    </form>
    """

    func testReplyFormCarriesTokenAndServerThreadID() throws {
        let form = try XCTUnwrap(MessageFormParser.sendForm(html: threadPage, isReply: true))

        XCTAssertEqual(form.token, "reply-token")
        XCTAssertEqual(form.threadID, "2541826")
        XCTAssertEqual(form.hiddenFields["IsReply"], "True")
        XCTAssertNil(form.hiddenFields["Empty"])
        XCTAssertNil(form.hiddenFields["To"], "visible inputs are composed by the app")
    }

    func testReplyFormKeepsWhatABrowserWouldSubmit() throws {
        let form = try XCTUnwrap(MessageFormParser.sendForm(html: threadPage, isReply: true))

        XCTAssertEqual(form.visibleFields, ["To": "altere ses"])
        XCTAssertEqual(form.messageFieldName, "Message")
        XCTAssertEqual(form.recipientFieldName, "To")
        XCTAssertEqual(form.submittedFields["IsReply"], "True")
        XCTAssertEqual(form.submittedFields["To"], "altere ses")
    }

    func testControlsAreCollectedLikeABrowserSubmit() throws {
        let html = """
        <form id="message-compose" action="/mesaj/gonder" method="post">
          <input type="hidden" name="__RequestVerificationToken" value="t" />
          <input name="recipientNick" value="" />
          <input type="checkbox" name="Notify" value="true" checked />
          <input type="checkbox" name="Archive" value="true" />
          <input type="radio" name="Kind" value="a" />
          <input type="radio" name="Kind" value="b" checked="checked" />
          <input type="submit" name="Send" value="gönder" />
          <select name="Folder"><option value="in">gelen</option><option value="out" selected>giden</option></select>
          <textarea name="Content"></textarea>
        </form>
        """

        let form = try XCTUnwrap(MessageFormParser.forms(html: html).first)

        XCTAssertEqual(form.visibleFields, ["Notify": "true", "Kind": "b", "Folder": "out"])
        XCTAssertEqual(form.recipientFieldName, "recipientNick")
        XCTAssertEqual(form.messageFieldName, "Content")
    }

    func testComposerFormIsUsedWhenNoSendMarkerIsRendered() throws {
        let html = """
        <form id="message-delete" action="/mesaj/sil" method="post">
          <input type="hidden" name="__RequestVerificationToken" value="delete" />
        </form>
        <form id="message-compose" action="/mesaj/gonder" method="post">
          <input type="hidden" name="__RequestVerificationToken" value="compose" />
          <textarea name="Content"></textarea>
        </form>
        """

        XCTAssertEqual(MessageFormParser.sendForm(html: html, isReply: false)?.token, "compose")
        XCTAssertEqual(MessageFormParser.sendForm(html: html, isReply: true)?.token, "compose")
    }

    func testDeleteAndSearchFormsNeverBecomeSendForms() {
        XCTAssertNil(MessageFormParser.sendForm(html: threadPage, isReply: false))
        let deleteOnly = """
        <form action="/mesaj/sil" method="post">
          <input type="hidden" name="__RequestVerificationToken" value="delete-token" />
        </form>
        """
        XCTAssertNil(MessageFormParser.sendForm(html: deleteOnly, isReply: false))
        XCTAssertNil(MessageFormParser.sendForm(html: deleteOnly, isReply: true))
    }

    func testNewMessageFormIsFoundByIdOrAjaxAction() throws {
        let byID = """
        <form id="message-send-form" method="post">
          <input type="hidden" name="__RequestVerificationToken" value="new-token" />
        </form>
        """
        let byAction = """
        <form action="/mesaj/sendajax" method="post">
          <input type="hidden" name="__RequestVerificationToken" value="ajax-token" />
        </form>
        """

        XCTAssertEqual(MessageFormParser.sendForm(html: byID, isReply: false)?.token, "new-token")
        XCTAssertEqual(MessageFormParser.sendForm(html: byAction, isReply: false)?.token, "ajax-token")
        XCTAssertNil(MessageFormParser.sendForm(html: byID, isReply: true))
    }

    func testFormsWithoutTokenAreIgnored() {
        let html = #"<form id="message-send-form"><input type="hidden" name="ThreadId" value="9" /></form>"#
        XCTAssertNil(MessageFormParser.sendForm(html: html, isReply: true))
        XCTAssertEqual(MessageFormParser.forms(html: html).count, 1)
    }

    func testNonMessageFormsAreSkipped() {
        let html = """
        <form id="entry-form" action="/entry/ekle">
          <input type="hidden" name="__RequestVerificationToken" value="entry-token" />
        </form>
        """
        XCTAssertTrue(MessageFormParser.forms(html: html).isEmpty)
    }
}
