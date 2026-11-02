$ErrorActionPreference = 'Stop'
$nativeDir = $PSScriptRoot
$repoRoot = Split-Path $nativeDir -Parent
$buildDir = Join-Path $nativeDir '.build'
$vsPath = 'C:\Program Files\Microsoft Visual Studio\2022\Community'
$vcpkgToolchain = Join-Path $vsPath 'VC\vcpkg\scripts\buildsystems\vcpkg.cmake'

if (!(Test-Path "$vsPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll")) {
    throw "VS 2022 Community is required at $vsPath"
}
if (!(Test-Path $vcpkgToolchain)) {
    throw "Visual Studio vcpkg CMake toolchain not found: $vcpkgToolchain"
}
Import-Module "$vsPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
Enter-VsDevShell -VsInstallPath $vsPath -Arch amd64 -SkipAutomaticLocation | Out-Null

$env:VCPKG_MAX_CONCURRENCY = 4
# Keep CommonLib's optional deployment hooks away from any game or mod installation.
Remove-Item Env:SKYRIM_FOLDER -ErrorAction SilentlyContinue
Remove-Item Env:SKYRIM_MODS_FOLDER -ErrorAction SilentlyContinue
cmake -S $nativeDir -B $buildDir -G Ninja `
    -DCMAKE_BUILD_TYPE=Release `
    "-DCMAKE_TOOLCHAIN_FILE=$vcpkgToolchain" `
    -DVCPKG_TARGET_TRIPLET=x64-windows-static `
    -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded
if ($LASTEXITCODE -ne 0) { throw "CMake configure failed ($LASTEXITCODE)" }

cmake --build $buildDir --config Release --parallel 4
if ($LASTEXITCODE -ne 0) { throw "Release build failed ($LASTEXITCODE)" }

$dll = Join-Path $buildDir 'PlayerSignals.dll'
if (!(Test-Path -LiteralPath $dll -PathType Leaf)) { throw "Built DLL not found: $dll" }
$destination = Join-Path $repoRoot 'PlayerSignals\SKSE\Plugins\PlayerSignals.dll'
New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
Copy-Item -LiteralPath $dll -Destination $destination -Force
Write-Host "Copied PlayerSignals.dll to $destination"
