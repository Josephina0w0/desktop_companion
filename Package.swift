// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CharacterEfficiencyIsland",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "IslandCore", targets: ["IslandCore"]),
        .executable(name: "CharacterEfficiencyIsland", targets: ["CharacterEfficiencyIsland"])
    ],
    targets: [
        .target(name: "IslandCore"),
        .executableTarget(
            name: "CharacterEfficiencyIsland",
            resources: [.process("Assets")]
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        )
    ]
)
