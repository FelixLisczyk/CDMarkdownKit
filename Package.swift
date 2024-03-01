// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "CDMarkdownKit",
    products: [
        .library(
            name: "CDMarkdownKit",
            targets: ["CDMarkdownKit"]
        ),
    ],
    targets: [
        .target(
            name: "CDMarkdownKit",
            path: "Source"
        ),
    ]
)
