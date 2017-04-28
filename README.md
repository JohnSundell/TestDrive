# Test Drive 🚘

With Test Drive, you can quickly try out **any** Swift pod or framework in a playground. Simply run `testdrive` followed by the name of a pod, or the URL to a Git repository, and you will have a playground generated for you in no time!

<p align="center">
  <img src="TestDrive.gif"/>
</p>

**Features**

- [X] Quickly try out a pod/framework without having to modify your project.
- [X] Try out multiple pods/frameworks at once - ideal when comparing similar ones.
- [X] Supports iOS, macOS & tvOS.

## Usage

🚗  Take a pod for a test drive:
```
$ testdrive Unbox
```

🚙  Take a framework from a Git URL for a test drive:
```
$ testdrive git@github.com:johnsundell/files.git
```

🚕  Take multiple pods at once for a test drive:
```
$ testdrive Unbox Wrap
```

🏎  Take a test drive on a specific platform (iOS is the default):
```
$ testdrive Unbox -p tvOS
```

## Installation

The easiest way to install Test Drive is using [Marathon](https://github.com/johnsundell/marathon):

```
$ git clone git@github.com:JohnSundell/TestDrive.git
$ marathon install TestDrive/Sources/TestDrive.swift
```

You can also install it using the Swift Package Manager:

```
$ git clone git@github.com:JohnSundell/TestDrive.git
$ cd TestDrive
$ swift build -c release -Xswiftc -static-stdlib
$ cp -f .build/release/TestDrive /usr/local/bin/testdrive
```

## Help, feedback or suggestions?

- [Open an issue](https://github.com/JohnSundell/TestDrive/issues/new) if you need help, if you found a bug, or if you want to discuss a feature request.
- [Open a PR](https://github.com/JohnSundell/TestDrive/pull/new/master) if you want to make some change to Test Drive.
- Contact [@johnsundell on Twitter](https://twitter.com/johnsundell) for discussions, news & announcements about Test Drive & other projects.
