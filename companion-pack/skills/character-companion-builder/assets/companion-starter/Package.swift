// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GenericCompanion",
    platforms: [.macOS(.v13)],
    products: [
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        .executable(name: "GenericCompanion", targets: ["Companion"])
    ],
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    targets: [
        .executableTarget(
            name: "Companion",
            resources: [
                .copy("Assets/EfficiencyIsland"),
                .copy("Assets/Tracker")
            ]
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        )
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    ]
)
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
