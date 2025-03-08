// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "QuizMaster",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "QuizMaster",
            targets: ["QuizMaster"]),
    ],
    dependencies: [
        .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.0.0"))
    ],
    targets: [
        .target(
            name: "QuizMaster",
            dependencies: [
                .product(name: "FirebaseAuth", package: "Firebase"),
                .product(name: "FirebaseFirestore", package: "Firebase"),
                .product(name: "FirebaseStorage", package: "Firebase"),
                .product(name: "FirebaseMessaging", package: "Firebase")
            ])
    ]
) 