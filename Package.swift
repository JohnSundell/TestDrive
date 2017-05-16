/**
 *  TestDrive
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import PackageDescription

// Copy the script into `main.swift` to build a command line tool
let scriptURL = URL(fileURLWithPath: "Sources/TestDrive.swift")
let scriptData = try Data(contentsOf: scriptURL)

let mainURL = URL(fileURLWithPath: "Sources/main.swift")
try scriptData.write(to: mainURL)

let package = Package(
    name: "TestDrive",
    dependencies: [
        .Package(url: "https://github.com/JohnSundell/Xgen.git", majorVersion: 1),
        .Package(url: "https://github.com/JohnSundell/Files.git", majorVersion: 1),
        .Package(url: "https://github.com/JohnSundell/ShellOut.git", majorVersion: 1),
        .Package(url: "https://github.com/JohnSundell/Releases.git", majorVersion: 1)
    ],
    exclude: ["Sources/TestDrive.swift"]
)
