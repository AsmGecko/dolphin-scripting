#!/usr/bin/env bash
# Builds Felk's Dolphin with Python scripting (github.com/Felk/dolphin) for Windows with the patches in patches/, which
# Felk's own Windows build doesn't have. Runs in Git Bash.
# Needs: Visual Studio with "Desktop development with C++" (MSVC and a Windows SDK). Takes half an hour.
# Usage: build-windows.sh <tag of Felk/dolphin> <out folder>
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: build-windows.sh <tag of Felk/dolphin> <out folder>" >&2
  exit 1
fi
tag="$1"
revision=1       # of these patches and this script: the n of a release tag <tag>-win<n>
here="$(cd "$(dirname "$0")" && pwd)"
out="$(mkdir -p "$2" && cd "$2" && pwd)"
src="$out/src"

vswhere="/c/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
msbuild="$("$vswhere" -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
  -find 'MSBuild\**\Bin\MSBuild.exe' 2> /dev/null | head -n 1 | tr -d '\r')"
if [ -z "$msbuild" ]; then
  echo "no MSBuild with the C++ tools: add \"Desktop development with C++\" in the Visual Studio Installer" >&2
  exit 1
fi

if [ ! -d "$src" ]; then
  git -c advice.detachedHead=false clone -q --depth 1 -b "$tag" https://github.com/Felk/dolphin.git "$src"
  git -C "$src" submodule update -q --init --recursive --depth 1
  for patch in "$here"/patches/*.patch; do
    git -C "$src" apply "$patch"
  done
fi
# Felk's tag asks for Visual Studio 2022's v143; without it, the newest toolset installed
toolsets="$(ls -d "$(dirname "$msbuild")/../../Microsoft/VC/"*/Platforms/x64/PlatformToolsets/v* | xargs -n 1 basename)"
toolset=
if ! grep -qx v143 <<< "$toolsets"; then
  toolset="$(sort -V <<< "$toolsets" | tail -n 1)"
  # whose STL no longer has stdext's array iterators, which Qt 6.5 uses; Qt 6.6 dropped them the same way
  sed -i '/define QT_MAKE_\(UN\)\{0,1\}CHECKED_ARRAY_ITERATOR(x.*stdext::/d' \
    "$src"/Externals/Qt/Qt6.*/x64/include/QtCore/qcompilerdetection.h
fi
"$msbuild" "$(cygpath -w "$src/Source/dolphin-emu.sln")" -m -nologo -v:minimal -p:Configuration=Release \
  -p:Platform=x64 ${toolset:+-p:PlatformToolset=$toolset} -t:Dolphin -t:DolphinTool
for built in "$src/Binary/x64/"*; do
  rm -rf "$out/$(basename "$built")"
done
cp -R "$src/Binary/x64/." "$out/"
touch "$out/portable.txt"
echo "$tag-win$revision" > "$out/version"
echo "ok: $out (Dolphin $tag-win$revision)"
