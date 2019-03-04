/**
 *  TestDrive
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Xgen
import Files
import ShellOut
import Releases

// MARK: - Extensions

extension CommandLine {
    static func parseArguments() throws -> Arguments {
        var parsedArguments = Arguments()
        var expectingPlatform = false
        var expectingCheckout = false

        for argument in arguments[1..<arguments.count] {
            if expectingPlatform {
                guard let platform = Playground.Platform(rawValue: argument.lowercased()) else {
                    throw TestDriveError.invalidPlatform(argument)
                }

                parsedArguments.platform = platform
                expectingPlatform = false
                continue
            } else if expectingCheckout {
                parsedArguments.addTagToLastTarget(.checkout(argument))
                expectingCheckout = false
                continue
            }

            switch argument {
            case "--platform", "-p":
                expectingPlatform = true
            case "--version", "-v":
                expectingCheckout = true
            case "--master", "-m":
                parsedArguments.addTagToLastTarget(.master)
            default:
                let target = try Target(kind: targetKind(from: argument), tag: .latestVersion)
                parsedArguments.targets.append(target)
            }
        }

        return parsedArguments
    }

    private static func targetKind(from argument: String) throws -> Target.Kind {
        if argument.hasSuffix(".git") {
            guard let url = URL(string: argument) else {
                throw TestDriveError.invalidURL(argument)
            }

            return .repository(url)
        }

        if argument.contains("github.com/") {
            let components = argument.components(separatedBy: "github.com/")

            guard let url = URL(string: "https://github.com/\(components[1])") else {
                throw TestDriveError.invalidURL(argument)
            }

            return .repository(url)
        }

        return .pod(argument)
    }
}

extension Folder {
    var isValidXcodeProject: Bool {
        guard `extension` == "xcodeproj" else {
            return false
        }

        let lowercasedName = name.lowercased()

        for invalidName in ["demo", "sample", "example"] {
            if lowercasedName.contains(invalidName) {
                return false
            }
        }

        return true
    }
}

// MARK: - Types

enum TestDriveError: Error {
    case invalidURL(String)
    case missingPlatform
    case invalidPlatform(String)
    case missingXcodeProject(URL)
    case invalidPodName(String)
    case invalidPodSourceURL(String)
}

extension TestDriveError: CustomStringConvertible {
    var description: String {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL given: '\(url)'"
        case .missingPlatform:
            return "Missing platform after flag '-p'"
        case .invalidPlatform(let platform):
            return "Invalid platform given: '\(platform)'"
        case .missingXcodeProject(let url):
            return "Xcode project missing at '\(url)'"
        case .invalidPodName(let name):
            return "Cannot find a pod named '\(name)'"
        case .invalidPodSourceURL(let url):
            return "Pod source URL is invalid: '\(url)'"
        }
    }
}

struct Arguments {
    var targets = [Target]()
    var platform = Playground.Platform.iOS
}

extension Arguments {
    mutating func addTagToLastTarget(_ tag: Tag) {
        guard var target = targets.popLast() else {
            return
        }

        target.tag = tag
        targets.append(target)
    }
}

enum Tag {
    case master
    case checkout(String)
    case latestVersion
}

struct Target {
    enum Kind {
        case pod(String)
        case repository(URL)
    }

    var kind: Kind
    var tag: Tag
}

struct Package {
    let name: String
    let folder: Folder
    let projectPath: String
}

class PackageLoader {
    private let folder: Folder

    init() throws {
        folder = try FileSystem().temporaryFolder.createSubfolder(named: "TestDriveTemp-\(UUID().uuidString)")
    }

    deinit {
        cleanup()
    }

    func loadPackages(for targets: [Target]) throws -> [Package] {
        return try targets.compactMap { target in
            switch target.kind {
            case .pod(let name):
                return try loadPackageForPod(named: name, checkoutTag: target.tag)
            case .repository(let url):
                return try loadPackage(from: url, checkoutTag: target.tag)
            }
        }
    }

    func cleanup() {
        try? folder.delete()
    }

    private func loadPackageForPod(named name: String, checkoutTag: Tag) throws -> Package? {
        print("🕵️‍♀️  Finding pod '\(name)'...")

        let name = name.lowercased()
        let searchResult = try shellOut(to: "pod search \(name) --simple").lowercased()
        var foundPod = false

        for line in searchResult.components(separatedBy: .newlines) {
            guard foundPod else {
                foundPod = line.contains("-> \(name) ")
                continue
            }

            guard line.contains("- source:") else {
                continue
            }

            let source = line.replacingOccurrences(of: "- source:", with: "")
                .trimmingCharacters(in: .whitespaces)

            guard let sourceURL = URL(string: source) else {
                throw TestDriveError.invalidPodSourceURL(source)
            }

            return try loadPackage(from: sourceURL, checkoutTag: checkoutTag)
        }

        throw TestDriveError.invalidPodName(name)
    }

    private func loadPackage(from url: URL, checkoutTag: Tag) throws -> Package? {
        var urlString = url.absoluteString

        if !urlString.hasSuffix(".git") {
            urlString.append(".git")
        }

        let name = urlString.components(separatedBy: "/").last!
            .replacingOccurrences(of: ".git", with: "")

        guard !folder.containsSubfolder(named: name) else {
            print("♻️  Reusing clone of \(name)\n")
            return nil
        }

        print("📦  Cloning \(urlString)...")
        try shellOut(to: "git clone \(urlString) \(name) --quiet", at: folder.path)
        let repositoryFolder = try folder.subfolder(named: name)

        let checkoutIdentifier = try resolveCheckoutIdentifier(for: checkoutTag, url: url)
        print("📋  Checking out \(checkoutIdentifier)...")
        try shellOut(to: "git checkout \(checkoutIdentifier) --quiet", at: repositoryFolder.path)
        try shellOut(to: "git submodule update --init --recursive --quiet", at: repositoryFolder.path)

        for subfolder in repositoryFolder.makeSubfolderSequence(recursive: true) {
            if subfolder.isValidXcodeProject {
                let projectPath = subfolder.path.replacingOccurrences(of: repositoryFolder.parent!.path, with: "")
                let packageName = subfolder.nameExcludingExtension
                print("🚗  \(packageName) is ready for test drive\n")
                return Package(name: packageName, folder: repositoryFolder, projectPath: projectPath)
            }
        }

        if repositoryFolder.containsFile(named: "Package.swift") {
            let projectName = "\(name).xcodeproj"
            try shellOut(to: "swift package generate-xcodeproj --output \(projectName)", at: repositoryFolder.path)
            print("🚗  \(name) is ready for test drive\n")
            return Package(name: name, folder: repositoryFolder, projectPath: name + "/" + projectName)
        }

        throw TestDriveError.missingXcodeProject(url)
    }

    private func resolveCheckoutIdentifier(for tag: Tag, url: URL) throws -> String {
        switch tag {
        case .latestVersion:
            print("🚢  Resolving latest version...")

            guard let latestVersion = try Releases.versions(for: url).sorted().last else {
                return "master"
            }

            return latestVersion.string
        case .master:
            return "master"
        case .checkout(let identifier):
            return identifier
        }
    }
}

// MARK: - Functions

func printHelp() {
    print("🚘  Test Drive")
    print("--------------")
    print("Quickly try out any Swift pod or framework in a playground.")
    print("\nUsage:")
    print("- Simply pass a list of pod names or URLs that you want to test drive.")
    print("- You can also specify a platform (iOS, macOS or tvOS) using the '-p' option")
    print("- To use a specific version or branch, use the '-v' argument (or '-m' for master)")
    print("\nExamples:")
    print("- testdrive Unbox Wrap Files")
    print("- testdrive https://github.com/johnsundell/unbox.git Wrap Files")
    print("- testdrive Unbox -p tvOS")
    print("- testdrive Unbox -v 2.3.0")
    print("- testdrive Unbox -v swift3")
}

// MARK: - Script

do {
    let arguments = try CommandLine.parseArguments()

    guard !arguments.targets.isEmpty else {
        printHelp()
        exit(0)
    }

    let packageLoader = try PackageLoader()
    let packages = try packageLoader.loadPackages(for: arguments.targets)
    let packageNames = packages.map { $0.name }

    let workspaceName = "TestDrive-\(packageNames.joined(separator: "-")).xcworkspace"
    let workspaceFolder = try FileSystem().createFolder(at: workspaceName)
    let workspace = Workspace(path: workspaceFolder.path)

    let playground = workspace.addPlayground()
    playground.platform = arguments.platform

    let projectsFolder = try Folder(path: workspaceFolder.path).createSubfolderIfNeeded(withName: "Projects")
    try projectsFolder.empty()

    for package in packages {
        try package.folder.move(to: projectsFolder)
        let projectPath = "\(workspaceName)/Projects/\(package.projectPath)"
        workspace.addProject(at: projectPath)
    }

    print("⚡️  Generating workspace at \(workspace.path)...")
    try workspace.generate()

    try shellOut(to: "open \"\(workspace.path)\"")
    print("\n🚘  Test driving \(packageNames.joined(separator: " + "))")

    packageLoader.cleanup()
} catch {
    print("\n💥  \(error)")
}
