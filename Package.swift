// swift-tools-version: 6.0
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
import PackageDescription

let package = Package(
    name: "CharacterEfficiencyIsland",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "IslandCore", targets: ["IslandCore"]),
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        .executable(name: "CharacterEfficiencyIsland", targets: ["CharacterEfficiencyIsland"])
    ],
    targets: [
        .target(name: "IslandCore"),
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        .executableTarget(
            name: "CharacterEfficiencyIsland",
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            resources: [.process("Assets")]
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        )
    ]
)
