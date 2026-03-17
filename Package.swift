// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirebaseAdmin",
    platforms: [
        .macOS(.v15), .iOS(.v18)
    ],
    products: [
        .library(
            name: "FirebaseApp",
            targets: ["FirebaseApp"]),
        .library(
            name: "AppCheck",
            targets: ["AppCheck"]),
        .library(
            name: "Firestore",
            targets: ["Firestore"]),
        .library(
            name: "FirebaseAuth",
            targets: ["FirebaseAuth"]),
        .library(
            name: "FirebaseMessaging", 
            targets: ["FirebaseMessaging"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.21.2"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.68.0"),
        .package(url: "https://github.com/1amageek/FirebaseAPI.git", from: "1.0.1"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.0.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.7"),
        .package(url: "https://github.com/apple/swift-configuration", .upToNextMinor(from: "0.1.0"))
    ],
    targets: [
        .target(
            name: "FirebaseApp",
            dependencies: [
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "Configuration", package: "swift-configuration"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency=targeted", .when(platforms: [.macOS, .iOS]))
            ]
        ),
        .target(
            name: "AppCheck",
            dependencies: [
                "FirebaseApp",
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "JWTKit", package: "jwt-kit")
            ],
            swiftSettings: swiftSettings),
        .target(
            name: "Firestore",
            dependencies: [
                "FirebaseApp",
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "FirestoreAPI", package: "FirebaseAPI"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "JWTKit", package: "jwt-kit"),
            ],swiftSettings: swiftSettings),
        .target(
            name: "FirebaseAuth",
            dependencies: [
                "FirebaseApp",
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "AnyCodable", package: "AnyCodable"),
            ],swiftSettings: swiftSettings),
        .target(
            name: "FirebaseMessaging",
            dependencies: [
                "FirebaseApp",
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "JWTKit", package: "jwt-kit"),
            ],swiftSettings: swiftSettings),
        .testTarget(
            name: "FirebaseAppTests",
            dependencies: ["FirebaseApp"]
        ),
        .testTarget(
            name: "AppCheckTests",
            dependencies: [
                "AppCheck",
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .testTarget(
            name: "FirestoreTests",
            dependencies: ["Firestore"]
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableExperimentalFeature("StrictConcurrency"),
] }
