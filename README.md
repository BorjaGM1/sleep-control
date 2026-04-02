# Sleep Control

Tiny macOS menu bar app for keeping your Mac awake.

It gives you two toggles:

- `No Sleep`: runs `pmset -a disablesleep 1`
- `StayAwake`: runs `caffeinate -dimsu`

This app is intentionally small and local-first. It is unsigned for public distribution, not notarized, and not intended for the Mac App Store.

## What It Does

- Adds a menu bar icon with live status
- Toggles `No Sleep` with an admin prompt
- Toggles `StayAwake` without opening Terminal
- Shows current power source
- Lets you turn both features off with one click

## Why This Exists

On a MacBook, closing the lid normally triggers `Clamshell Sleep`. That is fine for normal laptop use, but annoying when you want a long-running local task to keep going.

Sleep Control wraps the two most useful local controls in one menu bar app:

- `pmset disablesleep` for the aggressive system-wide switch
- `caffeinate` for the standard keep-awake assertion

## Safety

`No Sleep` uses the hidden `pmset disablesleep` switch. That can keep a Mac awake even with the lid closed.

Use it carefully:

- Do not put the Mac in a bag while it is closed and awake.
- Expect higher battery drain and more heat.
- Turn it off when you are done.
- Treat this as a practical power-user tool, not a safe default.

## Download

If the repo has a GitHub Release, download the latest `Sleep Control-macos-unsigned.zip`, unzip it, and move `Sleep Control.app` wherever you want.

Because the app is unsigned for public distribution:

- macOS may warn on first launch
- if needed, right-click the app and choose `Open`

## Build

Requirements:

- macOS
- Apple Command Line Tools
- `swiftc`
- `xcrun`

Quick check:

```bash
swiftc --version
xcrun --show-sdk-path
```

Build the app:

```bash
./build.zsh
```

Output:

```text
build/Sleep Control.app
```

Install locally:

```bash
./install.zsh
```

Install and launch:

```bash
./install.zsh --launch
```

## Packaging

Create a shareable zip:

```bash
./package.zsh
```

Outputs:

```text
dist/Sleep Control-macos-unsigned.zip
dist/Sleep Control-macos-unsigned.zip.sha256
```

## Releases

This repo includes GitHub Actions for:

- macOS build verification on pushes and pull requests
- artifact uploads for packaged builds
- automatic GitHub Releases when you push a tag like `v1.0.0`

To publish a release:

```bash
git tag -a v1.0.0 -m "Sleep Control v1.0.0"
git push origin v1.0.0
```

## Project Files

- `main.swift`: AppKit status bar app
- `Info.plist`: app bundle metadata
- `build.zsh`: builds `Sleep Control.app`
- `install.zsh`: installs into `~/Applications`
- `package.zsh`: creates the release zip

## License

MIT
