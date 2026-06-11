// swift-tools-version: 6.0
// Keepers — on-device AI photo culling. Root SPM package: all domain logic
// lives here and tests on macOS via `swift test`; the iOS app shell
// (project.yml/XcodeGen) composes these products.
import PackageDescription

let package = Package(
    name: "KeepersKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "KeepersCore", targets: ["KeepersCore"]),
        .library(name: "IngestKit", targets: ["IngestKit"]),
        .library(name: "ScoringKit", targets: ["ScoringKit"]),
        .library(name: "RankerKit", targets: ["RankerKit"]),
        .library(name: "ExportKit", targets: ["ExportKit"]),
        .library(name: "PersistenceKit", targets: ["PersistenceKit"]),
        .library(name: "TaggingKit", targets: ["TaggingKit"]),
        .library(name: "KeepersUI", targets: ["KeepersUI"])
    ],
    targets: [
        // KeepersCore depends on nothing (DESIGN.md dependency rule).
        .target(name: "KeepersCore"),

        // Kits depend on KeepersCore only.
        .target(name: "IngestKit", dependencies: ["KeepersCore"]),
        .target(name: "ScoringKit", dependencies: ["KeepersCore"]),
        .target(name: "RankerKit", dependencies: ["KeepersCore"]),
        .target(name: "ExportKit", dependencies: ["KeepersCore"]),
        .target(name: "PersistenceKit", dependencies: ["KeepersCore"]),
        .target(name: "TaggingKit", dependencies: ["KeepersCore"]),

        // UI composes kits (never the other way around).
        .target(
            name: "KeepersUI",
            dependencies: [
                "KeepersCore",
                "IngestKit",
                "ScoringKit",
                "RankerKit",
                "ExportKit",
                "PersistenceKit"
            ]
        ),

        .testTarget(name: "KeepersCoreTests", dependencies: ["KeepersCore"]),
        .testTarget(name: "IngestKitTests", dependencies: ["IngestKit"]),
        .testTarget(name: "ScoringKitTests", dependencies: ["ScoringKit"]),
        .testTarget(name: "RankerKitTests", dependencies: ["RankerKit"]),
        .testTarget(
            name: "ExportKitTests",
            dependencies: ["ExportKit"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(name: "PersistenceKitTests", dependencies: ["PersistenceKit"]),
        .testTarget(name: "TaggingKitTests", dependencies: ["TaggingKit"]),
        .testTarget(name: "KeepersUITests", dependencies: ["KeepersUI"]),
        .testTarget(name: "InvariantTests", dependencies: ["KeepersCore"])
    ]
)
