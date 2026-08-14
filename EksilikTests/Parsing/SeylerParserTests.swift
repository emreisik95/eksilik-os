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
}
