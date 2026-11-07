// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Ember",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Ember", targets: ["Ember"])],
    targets: [
        .executableTarget(name: "Ember", resources: [.copy("Flame.metal")]),
        .testTarget(name: "EmberTests", dependencies: ["Ember"])
    ]
)
