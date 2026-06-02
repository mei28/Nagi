# Nagi (凪)

English | [日本語](./README.ja.md)

> A flow-time work-session tracker that respects your natural working rhythm. macOS only.

Nagi is a native SwiftUI rewrite of Fathom (a Tauri + React prototype).

- Philosophy: **Simple, Lovable, Complete (SLC)**
- Core idea: **flow time** — work naturally, then take a break worth N% of the time you worked (20% by default)
- All data stays on-device; zero network traffic

## Features

| Area | What it does |
|------|--------------|
| Timer | Time Timer–style circular timer. Working hue-shifts each lap (blue → indigo → purple); breaks drain from dark to light green (hourglass style) |
| Break suggestion | On stop, computed as `work duration × break ratio`. Start / Skip only — no memo prompt in the way |
| Notifications | `UNUserNotificationCenter` notification + sound when a break ends (each toggleable) |
| History | Date-sectioned list with add / edit / delete and `endTime > startTime` validation |
| Calendar | Monthly heatmap (5 blue levels) + month navigation + jump to Today. Edit a day's sessions in the side panel |
| Menu bar | Always-on mode: timer controls + last-10-weeks GitHub-style heatmap + inline note editing for the 5 most recent sessions. Liquid Glass tone |
| Data | Export / Import as Fathom-compatible JSON (Replace / Merge), plus a two-step confirm delete-all |
| Language | ja / en (follows the system, or switch manually in Settings) |

## Requirements

- macOS 14 Sonoma or later (Apple Silicon / Intel)
- Development: Xcode 16+ / Swift 5.9+ (uses `PBXFileSystemSynchronizedRootGroup`)

## Install (release build)

### Homebrew (recommended)

```sh
brew install --cask mei28/nagi/nagi
```

The app is unsigned, so Gatekeeper may block it on first launch. If so, install without the quarantine attribute:

```sh
brew install --cask --no-quarantine mei28/nagi/nagi
```

### Manual (zip)

1. Download `Nagi-<version>.zip` from [Releases](https://github.com/mei28/Nagi/releases)
2. Unzip and drag `Nagi.app` into `/Applications`
3. On first launch Gatekeeper blocks it — **right-click → Open** to approve
4. Allow the notification prompt (used for the break-end alert)

## Build (from source)

### Prerequisites

```sh
# required tools
brew install just xcode-build-server xcbeautify

# after installing Xcode.app from the App Store, point the command-line tools at it
sudo xcode-select -s /Applications/Xcode.app
```

### Common commands

```sh
just doctor   # environment check (xcodebuild / sourcekit-lsp / xcbeautify)
just lsp      # generate buildServer.json (for nvim + sourcekit-lsp)
just build    # Debug build
just run      # build and launch (open)
just run-fg   # run in foreground (stdout visible)
just run-ja   # launch in Japanese locale
just run-en   # launch in English locale
just test     # unit tests (NagiTests only)
just release  # Release build + dist/Nagi-<version>.zip
just install  # copy into /Applications
just clean    # remove intermediates
just where    # print the build product path
just version 1.2.3  # bump MARKETING_VERSION across the project
```

## Usage

### Basic flow

1. **Start** to begin working — the timer starts running
2. **Stop** to end — the suggested break time appears
3. **Start break** to take it, or **Skip** to go straight back to work
4. During a break the timer "shrinks" clockwise (hourglass). At zero you get a notification + sound

### Writing notes

- Stop on the main screen does not prompt for a note
- Tap a session row in the History tab (or the Calendar tab's side panel) → edit sheet
- The menu bar's History section supports inline editing too

### Settings tab

- **Rotation**: time for one full lap (1 / 15 / 30 / 60 min)
- **Break ratio**: break length as a fraction of work time (1–100%, default 20%)
- **Notification / Sound**: toggle each independently
- **Language**: System / 日本語 / English (restart required)
- **Data**: Export / Import / delete-all (Fathom-compatible JSON)

### Menu bar mode

Click the **N icon** in the menu bar:

- **Timer**: current state + a large clock + a state-aware primary button
- **Calendar**: last-10-weeks GitHub-style heatmap
- **History**: 5 most recent, inline note editing, 🗑 to delete immediately
- **Open Nagi…**: bring the main window to the front
- **Quit Nagi**: quit the app

## License

[MIT License](./LICENSE)

## About the name

"Nagi" (凪) is the Japanese word for the calm when wind and tide fall still — the quiet *interval* between focus and rest.
