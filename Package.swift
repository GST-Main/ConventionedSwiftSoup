// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "PrettySwiftSoup",
    products: [
        .library(name: "PrettySwiftSoup", targets: ["PrettySwiftSoup"])
    ],
    targets: [
        .target(name: "PrettySwiftSoup",
                path: "Sources",
                exclude: [],
                resources: [.copy("PrivacyInfo.xcprivacy")]),
        .testTarget(name: "PrettySwiftSoupTests", dependencies: ["PrettySwiftSoup"])
    ]
)


