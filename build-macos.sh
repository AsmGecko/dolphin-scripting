#!/usr/bin/env bash
# Builds Felk's Dolphin with Python scripting (github.com/Felk/dolphin) for macOS, with DolphinTool: Felk only publishes
# it for Windows. Nothing of Dolphin is changed, only how it's built.
# Needs: brew install cmake ninja pkg-config qt libusb. Takes half an hour.
# Usage: build-macos.sh <tag of Felk/dolphin> <out folder>
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: build-macos.sh <tag of Felk/dolphin> <out folder>" >&2
  exit 1
fi
tag="$1"
out="$(mkdir -p "$2" && cd "$2" && pwd)"
src="$out/src"

if [ ! -d "$src" ]; then
  git -c advice.detachedHead=false clone -q --depth 1 -b "$tag" https://github.com/Felk/dolphin.git "$src"
  # Not the Qt, FFmpeg and Python it brings along for Windows
  for windows_only in Qt FFmpeg-bin python; do
    git -C "$src" config "submodule.Externals/$windows_only.update" none
  done
  git -C "$src" submodule update -q --init --recursive
fi
# Qt 6.10 and later keep their private headers apart, the fmt of Dolphin doesn't build as consteval with the clang of
# Xcode 26, its libusb crashes on start, and MoltenVK wants macOS 12 or later: Metal does without Vulkan
qt="$(brew --prefix qtbase)/lib"
flags=-DFMT_CONSTEVAL=
for module in QtCore QtGui QtWidgets; do
  headers=("$qt/$module.framework/Headers/"[0-9]*)
  flags+=" -isystem ${headers[0]} -isystem ${headers[0]}/$module"
done
cmake -S "$src" -B "$src/build" -G Ninja -Wno-dev -Wno-deprecated -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$(brew --prefix qt)" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_CXX_FLAGS="$flags" \
  -DUSE_SYSTEM_LIBS=OFF -DUSE_SYSTEM_LIBUSB=ON -DENABLE_VULKAN=OFF -DENABLE_AUTOUPDATE=OFF -DENABLE_TESTS=OFF \
  -DSKIP_POSTPROCESS_BUNDLE=ON > /dev/null
ninja -C "$src/build" dolphin-emu dolphin-tool > /dev/null
rm -rf "$out/DolphinQt.app" "$out/dolphin-tool"
cp -R "$src/build/Binaries/DolphinQt.app" "$src/build/Binaries/dolphin-tool" "$out/"
echo "$tag" > "$out/version"
echo "ok: $out (Dolphin $tag)"
