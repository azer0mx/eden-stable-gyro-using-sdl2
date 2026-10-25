# Local v0.2.1 SDL2 motion fix

This checkout starts at stable v0.2.1 (58c1e20ee5). It adapts the SDL3
report-mode correction to SDL 2.32.10. The stable port has not been built or
hardware-tested yet; prior successful tests were on the SDL3 development build.

The patch restores motion-capable reports when simple reports arrive while SDL2
sensor reporting is enabled. The first command is immediate; later commands are
limited to one every five seconds, with no lifetime cap. It uses unsigned 32-bit
elapsed-time arithmetic for SDL2 tick wraparound and the driver's existing device
lock release pattern. It does not reconnect the controller or change bindings.

The patch is registered for `sdl2_generic`, so select the generic SDL source
profile even when running on Steam Deck. The `sdl2_steamdeck` dependency is a
different pinned SDL revision and is not patched here. This source profile is
independent of CPU optimization and of SteamOS Desktop/Game Mode.

Inside eden-dev, use a fresh build directory in this checkout:

```sh
cd ~/Developer/eden-stable-gyro
cmake -S . -B build/gcc -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DYUZU_USE_EXTERNAL_SDL2=ON \
  -DYUZU_USE_BUNDLED_SDL2=OFF \
  -DYUZU_SYSTEM_PROFILE=generic
cmake --build build/gcc --parallel 4
```

This does not reproduce the release's exact Clang 22.1.6/PGO toolchain. CMake uses
the compiler available in eden-dev. Do not reuse the development checkout's CMake
cache, object files, or SDL3 libraries. The source, cache, and build outputs are
separate; no configuration or build has been run by the agent.

The Qt executable is `build/gcc/bin/eden`. Test first with development XDG paths,
not the normal installed stable profile. Keep the known-working SDL3 executable
and its launcher as a fallback. Validate Desktop startup, Game Mode startup without
reselection, gameplay gyro, and several fresh launches with evdevhook2 stopped.
The original SteamOS HID regression has not yet been confirmed on this local
SDL2 build; the successful SDL3 results do not substitute for stable testing.

The installed stable AppImage is unchanged. No commit, PR, or push was created.

## Personal AppImage

After building, run this inside eden-dev from the stable checkout:

```sh
./tools/package-stable-appimage.sh
```

The expected output is:

```text
~/Developer/eden-stable-gyro/artifacts/Eden-v0.2.1-gyro-fix-x86_64.AppImage
```

The wrapper uses the quick-sharun packager used by Eden's current Linux CI.
It pins and checksums the helper, which downloads its own packaging tools.
Run it in the build container so it bundles that environment's Qt and libraries.
It does not build Eden, install anything system-wide, or replace the official
AppImage. It omits the CI self-updater hook and release update URL so this personal
artifact is not configured to replace itself with an unpatched official release.
It disables application tracing during packaging to avoid launching the emulator.

The bundle includes Qt, OpenGL, and Vulkan support and uses CI's Wayland hook.
This follows the current CI packaging approach, not a reproduction of the exact
June 2026 release toolchain or its PGO build. AppImage portability and the SDL2
fix still need testing on the host in Desktop and Game Mode after packaging.
Use development XDG paths for the first launch; the AppImage itself does not
hardcode those paths, and otherwise uses Eden's normal user profile.

The wrapper needs curl, sha256sum, patchelf, strings, tar, and ldd; the helper
checks its remaining prerequisites. If it fails, preserve its output for diagnosis.
The packaging workspace remains under build/appimage for inspection.
