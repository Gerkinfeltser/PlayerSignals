# PlayerSignals native plugin

This SKSE plugin provides the `PlayerSignals_Native` Papyrus functions used by raw-key hotkey slots. It targets Skyrim SE/AE/VR through the pinned MinLL CommonLibVR revision and is not required for layouts without raw slots.

## Prerequisites

- Windows x64.
- Visual Studio 2022 Community with the Desktop development with C++ workload, MSVC, CMake, and Ninja.
- Visual Studio's bundled vcpkg (`VC\vcpkg`) and CMake toolchain.
- Git, for CMake FetchContent to retrieve the pinned CommonLibVR source and its `extern/openvr` submodule.

The build uses CommonLibVR commit `550cc4fb9114649dcf526d1f3d73d710c5d7003b`, vcpkg manifest mode, the `x64-windows-static` triplet, and the static MSVC runtime. All Skyrim SE, AE, and VR target flags are enabled. The output DLL is copied only to this worktree's `PlayerSignals/SKSE/Plugins/PlayerSignals.dll`; there are no game or MO2 deployment actions.

## Build

From the repository root:

```powershell
.\PlayerSignals_native\build.ps1
```

Or build the full payload, including the native plugin, with:

```powershell
.\build\build.ps1 -Native
```

The native intermediate build directory is `PlayerSignals_native/.build/` and is ignored. The first build downloads dependencies and may take several minutes.

## Runtime requirements and behavior

Raw slots require the matching `PlayerSignals.dll` in `Data/SKSE/Plugins`, SKSE, and Address Library for SKSE Plugins (the VR Address Library on VR). Non-raw slots do not require this DLL. Raw dispatch uses Windows scan-code input only while the Skyrim process owns the foreground window; it sends key-up after the requested hold even if focus changes after key-down. For overlapping presses of the same scan code, only the latest press's worker sends key-up; earlier workers log that they skipped it. Scan codes are 1–255, and hold time is 1–2000 ms.

## 1.0.1 payload build receipt

Offline Windows Release build: `PlayerSignals/SKSE/Plugins/PlayerSignals.dll`, 866816 bytes.

SHA-256: `40395C55F5958C6DF88180EA34FF82F42C82C22C2C768B1703B9436721ED4742`.

`dumpbin /exports` reports `SKSEPlugin_Load`, `SKSEPlugin_Query`, and `SKSEPlugin_Version`. `/dependents` reports only `KERNEL32.dll`, `USER32.dll`, `ole32.dll`, `VERSION.dll`, and `SHELL32.dll`; no external CRT DLL is imported. Generated metadata identifies plugin version 1.0.1; `GetNativeVersion()` returns API version 1.

This receipt proves the built payload, not installation or runtime acceptance. The owner verified the two dashboards in the 1.6.1170 spike only. Production cases 1–6 still need in-game testing on 1.6.1170 and 1.7.104; 1.5.97 and VR remain build-only, untested.
