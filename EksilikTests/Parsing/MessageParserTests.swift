import XCTest
@testable import EksilikApp

final class MessageParserTests: XCTestCase {
    func testThreadListParsesRowsWithoutCrossRowArrayAlignment() {
        let html = """
        <ul id="threads">
          <li class="unread">
            <article>
              <a href="/mesaj/42">
                <h2>altere ses <small>3</small></h2>
                <p>son mesajın kısa önizlemesi</p>
              </a>
              <footer><time>13.08.2026 10:15</time></footer>
            </article>
          </li>
          <li>
            <article>
              <a href="/mesaj/84">
                <h2>sherlockun besinci sezonu</h2>
                <p>ikinci konuşma</p>
              </a>
              <footer><time>12.08.2026 20:00</time></footer>
            </article>
          </li>
        </ul>
        """

        let threads = MessageParser.parseThreadList(html: html)

        XCTAssertEqual(threads.count, 2)
        XCTAssertEqual(threads[0].id, "42")
        XCTAssertEqual(threads[0].link, "42")
        XCTAssertEqual(threads[0].username, "altere ses")
        XCTAssertEqual(threads[0].messageCount, "3")
        XCTAssertEqual(threads[0].preview, "son mesajın kısa önizlemesi")
        XCTAssertEqual(threads[0].date, "13.08.2026 10:15")
        XCTAssertTrue(threads[0].isUnread)
        XCTAssertFalse(threads[1].isUnread)
    }

    func testThreadListSupportsClassBasedCurrentMarkup() {
        let html = """
        <div class="message-thread-list">
          <div class="thread unread" data-thread-id="105">
            <a href="/mesaj/105">
              <span class="username">kullanıcı</span>
              <span class="message-count">2</span>
              <p class="preview">merhaba</p>
              <time>şimdi</time>
            </a>
          </div>
        </div>
        """

        let thread = MessageParser.parseThreadList(html: html).first

        XCTAssertEqual(thread?.id, "105")
        XCTAssertEqual(thread?.username, "kullanıcı")
        XCTAssertEqual(thread?.messageCount, "2")
        XCTAssertTrue(thread?.isUnread == true)
    }

    func testThreadIdentifierNormalizationRejectsInvalidAndExternalLinks() {
        XCTAssertEqual(MessageParser.threadIdentifier(from: "/mesaj/42"), "42")
        XCTAssertEqual(
            MessageParser.threadIdentifier(from: "https://eksisozluk.com/mesaj/sherlockun-besinci-sezonu?p=2"),
            "sherlockun-besinci-sezonu"
        )
        XCTAssertNil(MessageParser.threadIdentifier(from: "/mesaj/"))
        XCTAssertNil(MessageParser.threadIdentifier(from: "https://example.com/mesaj/42"))
        XCTAssertNil(MessageParser.threadIdentifier(from: "//example.com/mesaj/42"))
    }

    func testConversationParserUsesStableServerIDsAndContent() {
        let html = """
        <ul id="message-thread">
          <li>
            <article data-message-id="501">
              <h3><a href="/biri/altere-ses">altere ses</a></h3>
              <p>ilk <strong>mesaj</strong></p>
              <footer><time>10:15</time></footer>
            </article>
          </li>
          <li>
            <article data-id="502">
              <h3>sherlockun besinci sezonu</h3>
              <div class="message-content">yanıt</div>
              <time>10:16</time>
            </article>
          </li>
        </ul>
        """

        let messages = MessageContentParser.parse(html: html)

        XCTAssertEqual(messages.map(\.id), ["501", "502"])
        XCTAssertEqual(messages.map(\.sender), ["altere ses", "sherlockun besinci sezonu"])
        XCTAssertTrue(messages[0].contentHTML.contains("<strong>mesaj</strong>"))
        XCTAssertEqual(messages[0].contentText, "ilk mesaj")
        XCTAssertEqual(messages[1].contentHTML, "yanıt")
        XCTAssertEqual(messages[1].contentText, "yanıt")
        XCTAssertEqual(messages.map(\.date), ["10:15", "10:16"])
    }

    func testCurrentConversationMarkupDerivesDirectionSenderAndReplyIDs() {
        let html = """
        <div id="message-thread">
          <article class="incoming">
            <p>gelen <strong>mesaj</strong></p>
            <footer>
              <time>10:15</time>
              <a class="message-report-link" data-id="1995151134">mesajı bildir</a>
            </footer>
          </article>
          <article class="outgoing">
            <p>sherlockun besinci sezonu -&gt; ayatasagun: yanıt</p>
            <footer><time>10:16</time></footer>
          </article>
        </div>
        """

        let messages = MessageContentParser.parse(
            html: html,
            currentUsername: "sherlockun besinci sezonu",
            participant: "ayatasagun"
        )

        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages.map(\.direction), [.incoming, .outgoing])
        XCTAssertEqual(messages.map(\.sender), ["ayatasagun", "sherlockun besinci sezonu"])
        XCTAssertEqual(messages[0].id, "1995151134")
        XCTAssertEqual(messages[1].id, "message-1")
        XCTAssertEqual(
            messages[1].contentText,
            "sherlockun besinci sezonu -> ayatasagun: yanıt"
        )
    }

    func testConversationPlainTextIsDecodedBeforeSwiftUIRendering() {
        let html = """
        <div id="message-thread">
          <article class="incoming">
            <p>ilk &amp; ikinci<br>yeni satır &lt;3</p>
          </article>
        </div>
        """

        let message = MessageContentParser.parse(html: html).first

        XCTAssertEqual(message?.contentText, "ilk & ikinci\nyeni satır <3")
    }
}
