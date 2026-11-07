# dolphin-scripting

Builds of [Felk's Dolphin with Python scripting](https://github.com/Felk/dolphin) for macOS, with DolphinTool. Felk
publishes it for Windows only, so this builds it for the Mac. Nothing of Dolphin is changed: `build-macos.sh` clones a
tag of Felk's repository and builds it as it is.

```bash
brew install cmake ninja pkg-config qt libusb
./build-macos.sh scripting-preview4 out      # half an hour; out/DolphinQt.app and out/dolphin-tool
```

A tag `<Felk's tag>-mac<n>` (for example `scripting-preview4-mac1`) makes GitHub build it on Apple silicon and Intel and
put the zips on the release, each with `dolphin-<tag>-source.tar.gz`: the source exactly as it was built (Felk's
commit, every submodule, and `sources.txt` with their commits and the versions of the Homebrew packages).

Dolphin is GPL-2.0-or-later, and so is this repository (`LICENSE`).
