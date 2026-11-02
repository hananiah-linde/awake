# Awake

A tiny macOS menu bar app that keeps your Mac awake.

Awake lives in the menu bar as a coffee cup:

- **Click** the cup to keep your Mac awake indefinitely. Click it again to turn Awake off.
- **Right-click** (or two-finger tap) for **Keep Awake For** 15 minutes up to 8 hours, **Launch at Login**, and **Quit**. Timed sessions turn themselves off when time is up.

| Icon | Meaning |
| --- | --- |
| Greyed-out cup | Off: your Mac sleeps normally |
| Cup | On until you turn it off |
| Cup with a clock | On until the chosen time is up |

While Awake is on, both the display and the system stay awake.

Awake uses an IOKit power assertion, the same mechanism as `caffeinate`. Quitting the app releases it immediately.

Requires macOS 13 Ventura or later.

## Install

Homebrew:

```sh
brew tap hananiah-linde/tap
brew trust --cask hananiah-linde/tap/awake
brew install --cask hananiah-linde/tap/awake
```

Homebrew only loads casks from third-party taps you've trusted, which is what `brew trust` does.

Or download `Awake-<version>.zip` from [Releases](https://github.com/hananiah-linde/awake/releases), unzip, and move `Awake.app` to `/Applications`.

## Build from source

Requires Xcode 16 or later (Swift 6).

```sh
git clone https://github.com/hananiah-linde/awake.git
cd awake
make build        # -> dist/Awake.app
make run          # build, quit any running copy, and launch
```

`scripts/build-app.sh` accepts these environment variables:

| Variable        | Default                          | Purpose                                 |
| --------------- | -------------------------------- | --------------------------------------- |
| `UNIVERSAL`     | `0`                              | `1` builds for both arm64 and x86_64     |
| `BUILD`         | `1`                              | `CFBundleVersion`                        |
| `BUNDLE_ID`     | `io.github.hananiah-linde.awake` | `CFBundleIdentifier`                     |
| `SIGN_IDENTITY` | `-` (ad-hoc)                     | `codesign` identity                      |

The version comes from the `VERSION` file.

Launch at Login works best when the app lives in `/Applications`:

```sh
cp -R dist/Awake.app /Applications/
```

## Verify it's working

Turn Awake on, then:

```sh
pmset -g assertions | grep -i awake
```

You should see a `PreventUserIdleDisplaySleep` assertion named "Awake is keeping this Mac awake". Turn it off and the line disappears.

## Releasing

Releases are built on this Mac with the shared script in [hananiah-linde/homebrew-tap](https://github.com/hananiah-linde/homebrew-tap), cloned next to this repo:

1. Bump `VERSION`, commit, and push.
2. `make release`

That tags `v<VERSION>`, builds a universal app, signs it with Developer ID, notarizes and staples it, publishes `Awake-<version>.zip` to a GitHub Release, and updates the cask. See the tap's README for the one-time keychain setup. A manual CI fallback is under Actions → Release.

## License

[MIT](LICENSE)
