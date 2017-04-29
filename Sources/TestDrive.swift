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

        for argument in arguments[1..<arguments.count] {
            if expectingPlatform {
                guard let platform = Playground.Platform(rawValue: argument.lowercased()) else {
                    throw TestDriveError.invalidPlatform(argument)
                }

                parsedArguments.platform = platform
                continue
            }

            if argument == "-p" {
                expectingPlatform = true
                continue
            }

            try parsedArguments.targets.append(target(from: argument))
        }

        return parsedArguments
    }

    private static func target(from argument: String) throws -> Target {
        if argument.hasSuffix(".git") {
            guard let url = URL(string: argument) else {
                throw TestDriveError.invalidURL(argument)
            }

            return .repository(url)
        }

        if argument.contains("github.com/") {
            let components = argument.components(separatedBy: "github.com/")

            guard let url = URL(string: "git@github.com:\(components[1])") else {
                throw TestDriveError.invalidURL(argument)
            }

            return .repository(url)
        }

        return .pod(argument)
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

enum Target {
    case pod(String)
    case repository(URL)
}

struct Package {
    let name: String
    let folder: Folder
    let path: String
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
        return try targets.map { target in
            switch target {
            case .pod(let name):
                return try loadPackageForPod(named: name)
            case .repository(let url):
                return try loadPackage(from: url)
            }
        }
    }

    func cleanup() {
        try? folder.delete()
    }

    private func loadPackageForPod(named name: String) throws -> Package {
        print("🕵️‍♀️  Finding pod '\(name)'...")

        let name = name.lowercased()
        let searchResult = try shellOut(to: "pod search \(name)").lowercased()
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

            return try loadPackage(from: sourceURL)
        }

        throw TestDriveError.invalidPodName(name)
    }

    private func loadPackage(from url: URL) throws -> Package {
        var urlString = url.absoluteString

        if !urlString.hasSuffix(".git") {
            urlString.append(".git")
        }

        let name = urlString.components(separatedBy: "/").last!
                            .replacingOccurrences(of: ".git", with: "")

        print("📦  Cloning \(urlString)...")
        try shellOut(to: "git clone \(urlString) \(name) --quiet", at: folder.path)
        let repositoryFolder = try folder.subfolder(named: name)

        print("🚢  Resolving latest version...")

        if let latestRelease = try Releases.versions(for: url).sorted().last {
            print("📋  Checking out version \(latestRelease)...")
            try shellOut(to: "git checkout \(latestRelease) --quiet", at: repositoryFolder.path)
        }
        
        for subfolder in repositoryFolder.makeSubfolderSequence(recursive: true) {
            if subfolder.extension == "xcodeproj" && !subfolder.name.lowercased().contains("demo") {
                let path = subfolder.path.replacingOccurrences(of: repositoryFolder.parent!.path, with: "")
                let packageName = subfolder.nameExcludingExtension
                print("🚗  \(packageName) is ready for test drive\n")
                return Package(name: packageName, folder: repositoryFolder, path: path)
            }
        }

        throw TestDriveError.missingXcodeProject(url)
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
    print("\nExamples:")
    print("- testdrive Unbox Wrap Files")
    print("- testdrive https://github.com/johnsundell/unbox.git Wrap Files")
    print("- testdrive Unbox -p tvOS")
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
    let packageNames = packages.map({ $0.name })

    let workspaceName = "TestDrive-\(packageNames.joined(separator: "-")).xcworkspace"
    let workspaceFolder = try FileSystem().createFolder(at: workspaceName)
    let workspace = Workspace(path: workspaceFolder.path)

    let playground = workspace.addPlayground()
    playground.platform = arguments.platform

    let projectsFolder = try Folder(path: workspaceFolder.path).createSubfolderIfNeeded(withName: "Projects")
    try projectsFolder.empty()

    for package in packages {
        try package.folder.move(to: projectsFolder)
        let projectPath = "\(workspaceName)/Projects/\(package.path)"
        workspace.addProject(at: projectPath)
    }

    print("⚡️  Generating workspace at \(workspace.path)...")
    try workspace.generate()

    try shellOut(to: "open \(workspace.path)")
    print("\n🚘  Test driving \(packageNames.joined(separator: " + "))")

    packageLoader.cleanup()
} catch {
    print("\n💥  \(error)")
}
