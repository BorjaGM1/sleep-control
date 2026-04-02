# Sleep Control

Sleep Control is a tiny macOS menu bar app for the annoying case where a MacBook goes to sleep in the middle of a long local task.

It exposes two keep-awake controls in one place:

- `No Sleep`: runs `pmset -a disablesleep 1`
- `StayAwake`: runs `caffeinate -dimsu`

It is intentionally small, local-first, and built with plain AppKit. No background service, no settings screen, no extra cruft.

## Features

- Adds a menu bar icon with live status
- Toggles `No Sleep` with an admin prompt
- Toggles `StayAwake` without opening Terminal
- Shows current power source
- Lets you turn both features off with one click

## Why This Exists

On a MacBook, closing the lid normally triggers `Clamshell Sleep`. That is fine for normal laptop use, but not when you want a local job to keep running. Sleep Control wraps the two most useful built-in controls behind a single menu bar toggle set.

## Safety

`No Sleep` uses the hidden `pmset disablesleep` switch. That can keep a Mac awake even with the lid closed.

- Do not put the Mac in a bag while it is closed and awake.
- Expect higher battery drain and more heat.
- Turn it off when you are done.
- Treat this as a practical power-user tool, not a safe default.

## Install

### Download a release

Download the latest `Sleep Control-macos-unsigned.zip` from Releases, unzip it, and move `Sleep Control.app` wherever you want.

The app is unsigned for public distribution, so macOS may warn on first launch. If that happens, right-click the app and choose `Open`.

### Build from source

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

The repo includes GitHub Actions for:

- macOS build verification on pushes and pull requests
- artifact uploads for packaged builds
- automatic GitHub Releases when you push a tag like `v1.0.0`

To publish a release:

```bash
git tag -a v1.0.0 -m "Sleep Control v1.0.0"
git push origin v1.0.0
```

## License

MIT
