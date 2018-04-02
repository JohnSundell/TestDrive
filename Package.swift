// swift-tools-version:4.1

/**
 *  TestDrive
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import PackageDescription

let package = Package(
    name: "TestDrive",
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Xgen.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/Files.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/Releases.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "TestDrive",
            dependencies: ["Xgen", "Files", "ShellOut", "Releases"],
            path: "Sources",
            exclude: ["Marathonfile"]
        )
    ]
)
