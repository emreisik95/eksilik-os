// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EksilikApp",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .executable(name: "EksilikCoreHarness", targets: ["EksilikCoreHarness"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tid-kijyun/Kanna.git", from: "5.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "EksilikCoreHarness",
            dependencies: ["Kanna"],
            path: ".",
            sources: [
                "Core/Parsing/AuthParser.swift",
                "Core/Parsing/EntryPageParser.swift",
                "Core/Parsing/HTMLParser.swift",
                "Core/Parsing/PaginationParser.swift",
                "Core/Parsing/ProfileConnectionParser.swift",
                "Core/Parsing/TopicListParser.swift",
                "Core/Parsing/UserProfileParser.swift",
                "Core/Network/EksiEndpoint.swift",
                "Core/Network/TopicRequest.swift",
                "Core/Loading/SkeletonLayout.swift",
                "Core/Links/ExternalLinkPolicy.swift",
                "Core/Presentation/EntryLayoutStyle.swift",
                "Core/Presentation/EntryListChromePolicy.swift",
                "Core/Presentation/HomeNavigationStyle.swift",
                "Core/Presentation/MainTab.swift",
                "Core/Search/SearchPresentation.swift",
                "Core/Images/ImageURLNormalizer.swift",
                "Core/Storage/OfflineTopicStore.swift",
                "Models/Author.swift",
                "Models/Entry.swift",
                "Models/EntryFilter.swift",
                "Models/OfflineTopic.swift",
                "Models/Pagination.swift",
                "Models/ProfileConnection.swift",
                "Models/Topic.swift",
                "Models/UserProfile.swift",
                "CoreTestHarness/main.swift",
            ]
        ),
    ]
)
