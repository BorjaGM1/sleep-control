# Sleep Control

Tiny macOS menu bar app for two things:

- `No Sleep`: toggles `pmset -a disablesleep`
- `StayAwake`: runs `caffeinate -dimsu`

This is a small AppKit utility meant to be practical, not polished. It is distributed outside the Mac App Store and is not notarized.

## What It Does

- Shows a menu bar icon with current state
- Lets you toggle `No Sleep` with an admin prompt
- Lets you toggle `StayAwake` without opening Terminal
- Shows current power source
- Lets you turn both features off with one click

## Safety

`No Sleep` uses the hidden `pmset disablesleep` switch. That can keep a Mac awake even when the lid is closed.

Use it carefully:

- do not put the Mac in a bag while it is closed and awake
- expect higher battery drain and heat
- turn it off when you are done

## Requirements

- macOS with Apple Command Line Tools installed
- `swiftc`
- `xcrun`

You can check quickly with:

```bash
swiftc --version
xcrun --show-sdk-path
```

## Build

```bash
./build.zsh
```

That creates:

```text
build/Sleep Control.app
```

## Install

```bash
./install.zsh
```

That copies the app to:

```text
~/Applications/Sleep Control.app
```

To install and launch immediately:

```bash
./install.zsh --launch
```

## Package For Sharing

```bash
./package.zsh
```

That creates:

```text
dist/Sleep Control-macos-unsigned.zip
dist/Sleep Control-macos-unsigned.zip.sha256
```

That zip is the easiest thing to upload to a GitHub Release.

## Share It

Simplest path:

1. Push this folder to GitHub.
2. Run `./package.zsh`.
3. Upload the zip from `dist/` to a GitHub Release.

Notes for people downloading it:

- the app is unsigned/ad-hoc signed, not notarized
- macOS may warn on first launch
- if needed, right-click the app and choose `Open`

## Files

- `main.swift`: app source
- `Info.plist`: bundle metadata
- `build.zsh`: build into `./build`
- `install.zsh`: copy into `~/Applications`
- `package.zsh`: create release zip

## License

MIT
