import XCTest
@testable import EksilikApp

final class SeylerParserTests: XCTestCase {
    func testParsesLiveHeroContentAndMashupCardsInSourceOrder() {
        let html = """
        <a href="https://eksiseyler.com/ilk-hikaye" class="hero-item row-item full">
          <img class="hero-img" src="/public/images/layout/empty.png"
               style="background-image: url('https://seyler.ekstat.com/img/max/800/hero.jpg')"
               alt="İlk Hikaye">
          <span class="hero-headline">İlk Hikaye</span>
        </a>
        <div class="content-box white-bg mashup-prev-2">
          <div class="content-img"><a href="https://eksiseyler.com/ikinci-hikaye">
            <img src="/empty.png" data-src="https://seyler.ekstat.com/img/230/second.jpg" alt="İkinci Hikaye">
          </a></div>
          <div class="content-meta"><span class="meta-category">BİLİM</span><span class="meta-stats">1,2b</span></div>
          <div class="content-title"><a href="https://eksiseyler.com/ikinci-hikaye">İkinci Hikaye</a></div>
        </div>
        <div class="mashup-box">
          <div class="mashup-meta"><div class="meta-category">KÜLTÜR</div><div class="meta-stats">418</div></div>
          <div class="mashup-title"><a href="/ucuncu-hikaye">Üçüncü Hikaye</a></div>
          <div class="mashup-img"><a href="/ucuncu-hikaye"><img src="//seyler.ekstat.com/img/230/third.jpg"></a></div>
        </div>
        """

        let stories = SeylerParser.parse(html: html)

        XCTAssertEqual(stories.map(\.title), ["İlk Hikaye", "İkinci Hikaye", "Üçüncü Hikaye"])
        XCTAssertEqual(stories.map(\.category), [nil, "BİLİM", "KÜLTÜR"])
        XCTAssertEqual(stories.map(\.readCount), [nil, "1,2b", "418"])
        XCTAssertEqual(stories.map(\.isFeatured), [true, false, false])
        XCTAssertEqual(stories[0].imageURL?.absoluteString, "https://seyler.ekstat.com/img/max/800/hero.jpg")
        XCTAssertEqual(stories[1].imageURL?.absoluteString, "https://seyler.ekstat.com/img/230/second.jpg")
        XCTAssertEqual(stories[2].imageURL?.absoluteString, "https://seyler.ekstat.com/img/230/third.jpg")
    }

    func testDeduplicatesStoriesAndRejectsNavigationOrExternalLinks() {
        let html = """
        <div class="content-box">
          <div class="content-title"><a href="/aynisi">Aynı Hikaye</a></div>
        </div>
        <div class="mashup-box">
          <div class="mashup-title"><a href="https://eksiseyler.com/aynisi">Tekrar</a></div>
        </div>
        <div class="content-box">
          <div class="content-title"><a href="/kategori/bilim">Kategori</a></div>
        </div>
        <div class="content-box">
          <div class="content-title"><a href="https://example.com/disarisi">Dışarı</a></div>
        </div>
        """

        let stories = SeylerParser.parse(html: html)

        XCTAssertEqual(stories.count, 1)
        XCTAssertEqual(stories.first?.url.absoluteString, "https://eksiseyler.com/aynisi")
        XCTAssertEqual(stories.first?.title, "Aynı Hikaye")
    }

    func testVisibleCategoriesUseCurrentSitePaths() {
        XCTAssertEqual(
            SeylerCategory.allCases.map(\.title),
            ["yeni", "kültür", "bilim", "eğlence", "yaşam", "spor", "haber"]
        )
        XCTAssertEqual(SeylerCategory.latest.path, "/")
        XCTAssertEqual(SeylerCategory.science.path, "/kategori/bilim")
        XCTAssertEqual(SeylerCategory.entertainment.path, "/kategori/eglence")
    }

    func testParsesNativeArticleMetadataAndOrderedContentBlocks() {
        let html = """
        <div class="content-detail" id="content-body-area">
          <div class="content-heading">
            <div class="content-meta">
              <div class="meta-category"><a>EKONOMİ</a><span class="meta-date">13 Ağustos 2026</span></div>
              <div class="meta-stats"><b>1,8b</b> OKUNMA <b>13</b> PAYLAŞIM</div>
            </div>
            <h1 class="content-title">Panda Neden Bugün Yok?</h1>
            <div class="content-spot">Panda'nın kısa hikayesi.</div>
            <div class="cover-img"><img src="/placeholder.jpg" data-src="https://seyler.ekstat.com/cover.jpg"></div>
          </div>
          <div class="mashup-components">
            <div class="content-block"><div class="content-body">
              <p>ilk &amp; ikinci paragraf</p>
              <h3>bir ara başlık</h3>
              <figure><img src="https://seyler.ekstat.com/inside.jpg" alt="arşiv görseli"></figure>
              <blockquote>önemli bir alıntı</blockquote>
            </div></div>
            <div class="content-seperator"><a class="content-author">hibravez</a></div>
            <div class="content-block"><div class="content-body">
              <div class="medium-insert-embeds"><a href="/baska-yazi">önerilen içerik</a></div>
            </div></div>
          </div>
        </div>
        """

        let article = SeylerArticleParser.parse(
            html: html,
            sourceURL: URL(string: "https://eksiseyler.com/panda")!
        )

        XCTAssertEqual(article?.title, "Panda Neden Bugün Yok?")
        XCTAssertEqual(article?.summary, "Panda'nın kısa hikayesi.")
        XCTAssertEqual(article?.category, "EKONOMİ")
        XCTAssertEqual(article?.date, "13 Ağustos 2026")
        XCTAssertEqual(article?.readCount, "1,8b")
        XCTAssertEqual(article?.shareCount, "13")
        XCTAssertEqual(article?.authors, ["hibravez"])
        XCTAssertEqual(article?.heroImageURL?.absoluteString, "https://seyler.ekstat.com/cover.jpg")
        XCTAssertEqual(
            article?.blocks,
            [
                .paragraph("ilk & ikinci paragraf"),
                .heading("bir ara başlık"),
                .image(
                    url: URL(string: "https://seyler.ekstat.com/inside.jpg")!,
                    caption: "arşiv görseli"
                ),
                .quote("önemli bir alıntı"),
            ]
        )
    }

    func testNativeArticleParserRejectsDocumentsWithoutArticleContent() {
        XCTAssertNil(
            SeylerArticleParser.parse(
                html: "<nav>menü</nav>",
                sourceURL: URL(string: "https://eksiseyler.com/menu")!
            )
        )
    }
}
