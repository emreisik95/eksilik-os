import XCTest
@testable import EksilikApp

final class ProfileConnectionsTests: XCTestCase {
    func testProfileParserCapturesFollowerAndFollowingLinksFromCountAnchors() {
        let html = """
        <h1 id="user-profile-title" data-nick="sherlockun besinci sezonu"></h1>
        <ul id="user-entry-stats">
          <li><a href="/takipci/sherlockun-besinci-sezonu"><span id="user-follower-count">35</span> takipçi</a></li>
          <li><a href="/takip/sherlockun-besinci-sezonu"><span id="user-following-count">8</span> takip</a></li>
        </ul>
        """

        let profile = UserProfileParser.parse(html: html)

        XCTAssertEqual(profile.followerLink, "/takipci/sherlockun-besinci-sezonu")
        XCTAssertEqual(profile.followingLink, "/takip/sherlockun-besinci-sezonu")
    }

    func testConnectionParserReadsRealFollowListMarkupAndDeduplicatesPeople() {
        let html = """
        <ul id="follow-list">
          <li data-reverse-follow="true">
            <div class="follows-picture"><a href="/biri/altere-ses"><img src="//img.ekstat.com/profiles/altere.jpg" alt="altere ses"></a></div>
            <a id="follows-nick" href="/biri/altere-ses">altere ses</a>
            <a id="reverse-follow-text">seni takip ediyor</a>
            <a id="buddy-link" class="relation-link buddy-list-link remove-relation">takip ediliyor</a>
          </li>
          <li>
            <img src="//ekstat.com/img/default-profile-picture-dark.svg" alt="ottoviii">
            <a id="follows-nick" href="/biri/ottoviii">ottoviii</a>
            <a id="buddy-link" class="relation-link buddy-list-link">takip et</a>
          </li>
          <li><a id="follows-nick" href="/biri/altere-ses">altere ses</a></li>
        </ul>
        """

        let people = ProfileConnectionParser.parse(html: html)

        XCTAssertEqual(people.map(\.username), ["altere ses", "ottoviii"])
        XCTAssertEqual(people.first?.profileLink, "/biri/altere-ses")
        XCTAssertEqual(people.first?.avatarURL, "https://img.ekstat.com/profiles/altere.jpg")
        XCTAssertEqual(people.first?.followsYou, true)
        XCTAssertEqual(people.first?.isFollowing, true)
        XCTAssertEqual(people.last?.followsYou, false)
        XCTAssertEqual(people.last?.isFollowing, false)
        XCTAssertNil(people.last?.avatarURL)
    }

    func testConnectionParserIgnoresNavigationAndMalformedLinks() {
        let html = """
        <nav><a href="/biri/navigation-user">navigation user</a></nav>
        <ul id="follow-list">
          <li><a id="follows-nick" href="/entry/123">not a profile</a></li>
          <li><a id="follows-nick" href="javascript:alert(1)">unsafe</a></li>
        </ul>
        """

        XCTAssertTrue(ProfileConnectionParser.parse(html: html).isEmpty)
    }

    func testProfileConnectionEndpointKeepsServerPathOnCurrentHost() {
        XCTAssertEqual(
            EksiEndpoint.profileConnections(path: "/takipci/sherlockun-besinci-sezonu").path,
            "/takipci/sherlockun-besinci-sezonu"
        )
        XCTAssertEqual(
            EksiEndpoint.profileConnections(path: "takip/sherlockun-besinci-sezonu").path,
            "/takip/sherlockun-besinci-sezonu"
        )
    }
}
