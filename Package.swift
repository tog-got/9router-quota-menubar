// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuotaMenuBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "QuotaMenuBar",
            targets: ["QuotaMenuBar"]
        ),
        .executable(
            name: "QuotaTrackerCoreTestRunner",
            targets: ["QuotaTrackerCoreTestRunner"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "QuotaTrackerCore",
            dependencies: [],
            path: "Sources/QuotaTrackerCore"
        ),
        .executableTarget(
            name: "QuotaMenuBar",
            dependencies: ["QuotaTrackerCore"],
            path: "Sources/QuotaMenuBar"
        ),
        .executableTarget(
            name: "QuotaTrackerCoreTestRunner",
            dependencies: ["QuotaTrackerCore"],
            path: "Sources/QuotaTrackerCoreTestRunner"
        )
    ]
)
