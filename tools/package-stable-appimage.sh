#!/bin/sh
# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later
set -eu

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir="$root_dir/build/gcc"
output_dir="$root_dir/artifacts"
output_name="Eden-v0.2.1-gyro-fix-x86_64.AppImage"
helper_revision=c28bb80743106fdf08cb10fb27d19d9932eb0865
helper_sha256=4ce6946b8d6c9d0f472d41ad533e920132de66ec58d1e3445ea4f1d27376eec7

if [ "$(uname -m)" != x86_64 ]; then
    echo "This personal packaging script targets the x86_64 Steam Deck." >&2
    exit 1
fi
if [ ! -x "$build_dir/bin/eden" ]; then
    echo "Build Eden inside eden-dev first: cmake --build build/gcc --parallel 4" >&2
    exit 1
fi
if ! sed -n '/^YUZU_USE_EXTERNAL_SDL2:BOOL=ON$/p' "$build_dir/CMakeCache.txt" | grep -q .; then
    echo "Configure with YUZU_USE_EXTERNAL_SDL2=ON to include patched SDL2." >&2
    exit 1
fi
if ! sed -n '/^YUZU_SYSTEM_PROFILE:STRING=generic$/p' "$build_dir/CMakeCache.txt" | grep -q .; then
    echo "Configure with YUZU_SYSTEM_PROFILE=generic to select the patched SDL2 source." >&2
    exit 1
fi
for tool in curl sha256sum patchelf strings tar ldd; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Missing packaging tool inside eden-dev: $tool" >&2
        exit 1
    fi
done
if [ -e "$output_dir/$output_name" ]; then
    echo "Move the previous AppImage aside before packaging again: $output_dir/$output_name" >&2
    exit 1
fi
mkdir -p "$output_dir" "$root_dir/build/appimage"
work_dir=$(mktemp -d "$root_dir/build/appimage/package.XXXXXX")
helper="$work_dir/quick-sharun"
curl --fail --location --retry 3     "https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/$helper_revision/useful-tools/quick-sharun.sh"     --output "$helper"
printf '%s  %s\n' "$helper_sha256" "$helper" | sha256sum --check -
chmod +x "$helper"
sed 's/^Name=Eden$/Name=Eden 0.2.1 Gyro Fix/'     "$root_dir/dist/dev.eden_emu.eden.desktop" > "$work_dir/dev.eden_emu.eden.desktop"

export APPDIR="$work_dir/AppDir"
export OUTPATH="$output_dir"
export OUTNAME="$output_name"
export ICON="$root_dir/dist/dev.eden_emu.eden.svg"
export DESKTOP="$work_dir/dev.eden_emu.eden.desktop"
export MAIN_BIN=eden
export VERSION=0.2.1-gyro-fix
export OPTIMIZE_LAUNCH=1
export DEPLOY_QT=1
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1
export ADD_HOOKS=wayland-is-broken.hook
export STRACE_MODE=0
unset UPINFO GITHUB_REPOSITORY

cd "$work_dir"
"$helper" "$build_dir/bin/eden"
"$helper" --make-appimage
test -x "$output_dir/$output_name"
printf '\nPersonal AppImage: %s\n' "$output_dir/$output_name"
