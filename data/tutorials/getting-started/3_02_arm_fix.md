---
id: arm64-fix
title: Fix Homebrew Errors on Apple M1
description: |
  This page will walk you through the workaround for ARM64 processors on newer Macs.
category: "Resources"
---

<!--
DOCUMENTATION REFERENCES:
- OCaml on macOS: https://ocaml.org/install#macOS
- opam installation guide: https://opam.ocaml.org/doc/Install.html
- Homebrew documentation: https://docs.brew.sh/

MACOS ARM64 SPECIFIC:
- Apple M1/M2/M3 processors use ARM64 architecture
- Homebrew changed install location on ARM64
- Old location: /usr/local/bin/brew (Intel/Rosetta)
- New location: /opt/homebrew/bin/brew (ARM64 native)

HOMEBREW LOCATIONS:
- Intel Macs: /usr/local/bin/brew
- ARM64 Macs: /opt/homebrew/bin/brew
- Universal binaries may exist in both locations

ROSETTA 2:
- Compatibility layer for Intel apps on ARM64 Macs
- Can interfere with native ARM64 installations
- Should be disabled for native development when possible
- Apple Support article: https://support.apple.com/en-us/HT211861

COMMAND LINE TOOLS (CLT):
- Required for compilation on macOS
- Can be installed without full Xcode
- Download from Apple Developer: https://developer.apple.com/download/
- Location: /Library/Developer/CommandLineTools

TROUBLESHOOTING STEPS:
1. Check Homebrew location with: where brew
2. Verify CLT installation
3. Disable Rosetta if needed
4. Uninstall/reinstall Homebrew
5. Verify with: brew doctor

RELATED TUTORIALS:
- Install OCaml: /docs/installing-ocaml
- Install on macOS: /docs/install#macOS
- opam switches: /docs/opam-switch-introduction

EXTERNAL RESOURCES:
- Homebrew ARM64 discussion: https://github.com/Homebrew/brew/issues/9177
- Homebrew homepage: https://brew.sh/
- Homebrew installation: https://docs.brew.sh/Installation
- Apple Developer downloads: https://developer.apple.com/download/all/
- Rosetta 2 info: https://support.apple.com/en-us/HT211861
-->

Since [Homebrew has changed](https://github.com/Homebrew/brew/issues/9177) the way it installs, sometimes the executable files cannot be found on macOS ARM64 M1. This might cause errors as you work through these tutorials. We want Homebrew to install ARM64 by default, so there are a few changes we need to make in order to do this.

Before we get started, let's check where Homebrew is installed. We can do this by running this in the CLI:

```shell
where brew
```

If the response is `/usr/local/bin/brew`, we'll need to make the changes. It needs to be `/opt/homebrew/bin/brew`.

### Install CLT

First, ensure the Command Line Tools (CLT) are installed by running

```shell
$ ls /Library/Developer/CommandLineTools
Library SDKs usr
```

If they're not installed, let's install them now. You don't have to install all of XCode; you can install just the CLT by [downloading them directly from Apple's Developer](https://developer.apple.com/download/all/). Look for a non-beta version for stability, like "Command Line Tools for XCode 14.3.1"

### Disable Rosetta

Next, it's necessary to disable Rosetta if you have it installed. This [Apple Support article](https://support.apple.com/en-us/HT211861) tells you how to check. If it's installed, please follow the steps below.

1. Uninstall Homebrew by running the following:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```

2. Reinstall Homebrew:

```Shell
brew install /Users/tarides/Library/Caches/Homebrew/downloads/9e6d2a225119ad88cde6474d39696e66e4f87dc4a4d101243b91986843df691e--libev--4.33.arm64_monterey.bottle.tar.gz
```

3. Check to see if Homebrew is in the correct location now. It should return what's shown below:

```shell
$ which brew
/opt/homebrew/bin/brew
```

4. Close Terminal

It's essential to close your current Terminal window and open a new one for it to work properly. Then run the following command. If you get the output shown, you're ready to brew!

```shell
$ brew doctor
Your system is ready to brew.
```

### Return to Install Tutorial

Now that's all sorted, you can return to the [Install OCaml tutorial](/docs/installing-ocaml) to install and initialise opam.

You're all set to keep learning OCaml!
