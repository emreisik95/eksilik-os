import Foundation

enum EksiEndpoint {
    // Topic lists
    case popular
    case today(page: Int)
    case todayInHistory(year: Int? = nil)
    case events
    case following
    case latest
    // sorunsal removed - no longer exists on eksisozluk
    case debe
    case kenar
    case caylaklar
    case cop

    // Entry viewing
    case topic(slug: String, page: Int?)
    case entry(id: String)
    case topicPopular(slug: String, page: Int?)
    case topicSearch(slug: String, keywords: String)
    case topicByAuthor(slug: String, author: String)
    case topicByDay(slug: String, date: String)
    case topicNice(slug: String)
    case topicDailyNice(slug: String)
    case topicBuddy(slug: String)
    case topicEksiSeyler(slug: String)

    // Entry actions
    case createEntry
    case editEntry(id: String)
    case deleteEntry
    case favoriteEntry
    case unfavoriteEntry
    case voteEntry
    case removeVote
    case favoriteUsers(entryId: String)

    // Search
    case autocomplete(query: String)

    // Channels
    case channels
    case channelFollow(slug: String)
    case channelUnfollow(slug: String)

    // User
    case profile(username: String)
    case profileEntries(username: String, filter: String, page: Int = 1)
    case blockUser

    // Messages
    case messages(page: Int?)
    case messageThread(id: String)
    case sendMessage

    // Auth
    case login
    case logout

    // Comment voting
    case commentVote

    var path: String {
        switch self {
        case .popular: return "/basliklar/gundem"
        case .today(let page): return "/basliklar/bugun/\(page)"
        case .todayInHistory(let year):
            if let year { return "/basliklar/tarihte-bugun?year=\(year)" }
            return "/basliklar/tarihte-bugun"
        case .events: return "/basliklar/olay"
        case .following: return "/basliklar/takip"
        case .latest: return "/basliklar/son"
        case .debe: return "/debe"
        case .kenar: return "/basliklar/kenar"
        case .caylaklar: return "/basliklar/caylaklar/bugun"
        case .cop: return "/cop"
        case .topic(let slug, let page):
            if let page { return "/\(slug)?p=\(page)" }
            return "/\(slug)"
        case .entry(let id): return "/entry/\(id)"
        case .topicPopular(let slug, let page):
            if let page { return "/\(slug)?a=popular&p=\(page)" }
            return "/\(slug)?a=popular"
        case .topicSearch(let slug, let keywords): return "/\(slug)?a=find&keywords=\(keywords)"
        case .topicByAuthor(let slug, let author): return "/\(slug)?a=search&author=\(author)"
        case .topicByDay(let slug, let date): return "/\(slug)?day=\(date)"
        case .topicNice(let slug): return "/\(slug)?a=nice"
        case .topicDailyNice(let slug): return "/\(slug)?a=dailynice"
        case .topicBuddy(let slug): return "/\(slug)?a=buddy"
        case .topicEksiSeyler(let slug): return "/\(slug)?a=eksiseyler"
        case .createEntry: return "/entry/ekle"
        case .editEntry(let id): return "/entry/duzelt/\(id)"
        case .deleteEntry: return "/entry/sil"
        case .favoriteEntry: return "/entry/favla"
        case .unfavoriteEntry: return "/entry/favlama"
        case .voteEntry: return "/entry/vote"
        case .removeVote: return "/entry/removevote"
        case .favoriteUsers: return "/entry/favorileyenler"
        case .autocomplete: return "/autocomplete/query"
        case .channels: return "/kanallar/m"
        case .channelFollow(let slug): return "/kanal/takip-et"
        case .channelUnfollow(let slug): return "/kanal/takip-birak"
        case .profile(let username): return "/biri/\(username)"
        case .profileEntries(let username, let filter, let page):
            let ts = Int(Date().timeIntervalSince1970 * 1000)
            return "/\(filter)?nick=\(username)&p=\(page)&_=\(ts)"
        case .blockUser: return "/userrelation/addrelation"
        case .messages(let page):
            if let page { return "/mesaj?p=\(page)" }
            return "/mesaj"
        case .messageThread(let id): return "/mesaj/\(id)"
        case .sendMessage: return "/mesaj/yolla"
        case .login: return "/giris"
        case .logout: return "/terk"
        case .commentVote: return "/yorum/vote"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .createEntry, .deleteEntry, .favoriteEntry, .unfavoriteEntry,
             .voteEntry, .removeVote, .blockUser, .sendMessage, .commentVote,
             .channelFollow, .channelUnfollow:
            return .post
        default:
            return .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .autocomplete(let query):
            return [URLQueryItem(name: "q", value: query)]
        case .favoriteUsers(let entryId):
            return [URLQueryItem(name: "entryId", value: entryId)]
        default:
            return nil
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}
