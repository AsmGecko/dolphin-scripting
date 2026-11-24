# dolphin-scripting

Builds of [Felk's Dolphin with Python scripting](https://github.com/Felk/dolphin) for macOS and Windows, with
DolphinTool. Felk publishes it for Windows only and without these patches, so `build-macos.sh` and `build-windows.sh`
clone a tag of Felk's repository and build it with the patches in `patches/`:

- `sd-card.patch`: an SD card for the memory card slots and SP1 (`SlotB = 14` in Dolphin.ini), as an SD Gecko or an
  SD2SP2 has it: SDHC in SPI mode, read and written, in `Load/GCSD.img` in the user folder. It waits as a slow card
  does: idle before a read block, busy after a written one that ends in the middle of a byte. `DOLPHIN_SD_SDSC=1` in
  the environment makes it an SDSC card, addressed by byte. For testing a game's own SD driver.
- `change-disc.patch`: `dolphin.emulation.change_disc(path)` in the scripts, which does what File > Change Disc
  does: the disc out, and the one at path in a second later. For testing a loader that waits for the disc.
- `mmu-page-cross.patch`: a read across two pages is translated like a write already is, with the MMU on, and stops at
  the first page fault. Felk's tag read the bytes untranslated, so Super Mario Strikers' virtual memory crashed in a
  match.

```bash
brew install cmake ninja pkg-config qt libusb
./build-macos.sh scripting-preview4 out      # half an hour; out/DolphinQt.app and out/dolphin-tool
```

On Windows, in Git Bash, with Visual Studio's "Desktop development with C++" (MSVC and a Windows SDK):

```bash
./build-windows.sh scripting-preview4 out    # a few minutes on many cores; out/Dolphin.exe and out/DolphinTool.exe
```

Felk's tag asks for Visual Studio 2022's v143 toolset. Without it the script takes the newest one installed and drops
the two `stdext` array iterators from the Qt 6.5 headers it brings along, which newer MSVC no longer has (Qt 6.6 did
the same).

A tag `<Felk's tag>-mac<n>` (for example `scripting-preview4-mac2`, `<n>` as `revision` in `build-macos.sh`) makes GitHub build it on Apple silicon and Intel and
put the zips on the release, each with `dolphin-<tag>-source.tar.gz`: the source exactly as it was built (Felk's
commit, every submodule, and `sources.txt` with their commits and the versions of the Homebrew packages).

Dolphin is GPL-2.0-or-later, and so is this repository (`LICENSE`).
