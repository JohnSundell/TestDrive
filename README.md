# Test Drive 🚘
[![Swift 4.1](https://img.shields.io/badge/swift-4.1-orange.svg?style=flat)](#)
[![Marathon](https://img.shields.io/badge/marathon-compatible-brightgreen.svg?style=flat)](https://github.com/johnsundell/marathon)
[![SPM](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![@johnsundell](https://img.shields.io/badge/contact-@johnsundell-blue.svg?style=flat)](https://twitter.com/johnsundell)

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

🚓  Use a specific version or branch for your test drive (the latest version is used by default):
```
$ testdrive Unbox -v 2.3.0
$ testdrive Unbox -v swift3
$ testdrive Wrap --master
```

## Installation

The easiest way to install Test Drive is using [Marathon](https://github.com/johnsundell/marathon):

```
$ marathon install johnsundell/testdrive
```

You can also install it using the Swift Package Manager:

```
$ git clone https://github.com/JohnSundell/TestDrive.git
$ cd TestDrive
$ swift build -c release
$ cp -f .build/release/TestDrive /usr/local/bin/testdrive
```

## Issues + support

I spend almost all of my available time building tools, content and learning materials for the Swift community — all of which are available to everyone, for free. However, since I’m just one person, I do have to prioritize what I spend my time on — and one thing I’m currently not able to offer is 1:1 support for open source projects. That’s why this repository has Issues disabled. It’s not because I don’t want to help, I really do, I’m just simply not able to.

So before you start using this tool, I recommend that you spend a few minutes familiarizing yourself with its internals (it’s all normal Swift code), so that you’ll be able to self-service on any issues or edge cases you might encounter.

Thanks for understanding, and I hope you’ll enjoy TestDrive!

*— John*
