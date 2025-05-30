// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Clustering",
  platforms: [.iOS(.v13)],
  products: [
    .library(name: "Clustering", targets: ["Clustering"])
  ],
  targets: [
    .target(name: "Clustering")
  ]
)
