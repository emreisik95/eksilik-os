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
                "Core/Parsing/TopicListParser.swift",
                "Core/Parsing/UserProfileParser.swift",
                "Models/Author.swift",
                "Models/Entry.swift",
                "Models/Pagination.swift",
                "Models/Topic.swift",
                "Models/UserProfile.swift",
                "CoreTestHarness/main.swift",
            ]
        ),
    ]
)
