import Foundation

enum Route: Hashable {
    case topicList(link: String, title: String)
    case entryList(link: String, title: String)
    case entryById(id: String)
    case profile(username: String)
    case messageThread(link: String, title: String)
    case composeEntry(topicLink: String)
    case composeMessage(to: String, subject: String)
    case favoriteUsers(entryId: String)
    case settings
    case themePicker
    case blockedTopics
    case login
    case webPage(url: String, title: String)
}
