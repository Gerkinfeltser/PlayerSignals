param(
    [string]$GameRoot = 'D:/Modlists/ADT/Game Root',
    [string]$ModsRoot = 'D:/Modlists/ADT/mods',
    [string]$UiExtensionsSources = 'D:/git/SkyrimNet-GamePlugin/headers',
    [string]$FallbackHeaders = 'D:/git/SkyrimNet-GamePlugin/headers',
    [string]$MagelightSources = 'D:/git/MagelightUI/papyrus',
    [string]$Spriggit = 'D:/SkyrimMisc/SpriggitCLI/Spriggit.CLI.exe'
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$mod = Join-Path $repo 'PlayerSignals'
$compiler = Join-Path $GameRoot 'Papyrus Compiler/PapyrusCompiler.exe'
$flags = Join-Path $PSScriptRoot 'TESV_Papyrus_Flags.flg'
$imports = @(
    (Join-Path $mod 'Source/Scripts'),
    (Join-Path $ModsRoot 'Skyrim Script Extender (SKSE64)/Scripts/Source'),
    (Join-Path $ModsRoot 'JContainers SE/scripts/source'),
    (Join-Path $ModsRoot 'SkyrimNet/Source/Scripts'),
    (Join-Path $GameRoot 'Data/Source/Scripts'),
    $MagelightSources,
    $UiExtensionsSources,
    $FallbackHeaders
) -join ';'
# Keep the editor SVG authoritative; embed its named regions before Papyrus compilation.
$art = New-Object System.Xml.XmlDocument
$art.PreserveWhitespace = $true
$art.XmlResolver = $null
$art.Load((Join-Path $repo 'media/src/RadialUI.svg'))
$svg = $art.DocumentElement
foreach ($id in @('center', 'center-hit') + @(0..7 | ForEach-Object {
    "slot-$_"; "slot-$_-target"; "slot-$_-target-hit"; "slot-$_-nearby"; "slot-$_-nearby-hit"
})) {
    if ($svg.SelectNodes("//*[@id='$id']").Count -ne 1) { throw "Missing or duplicate radial region: $id" }
}
$background = $svg.SelectSingleNode("*[local-name()='rect' and @id='Artboard1']")
if ($background) { [void]$svg.RemoveChild($background) }
$svg.SetAttribute('id', 'wheelSvg')
$svg.SetAttribute('role', 'group')
$svg.SetAttribute('aria-label', 'Choose a gesture or action')
$svg.RemoveAttribute('width')
$svg.RemoveAttribute('height')
$viewPath = Join-Path $mod 'Magelight/PlayerSignals/index.html'
$view = [IO.File]::ReadAllText($viewPath)
$artBegin = '<!-- RADIAL_ART_BEGIN -->'
$artEnd = '<!-- RADIAL_ART_END -->'
$begin = $view.IndexOf($artBegin, [StringComparison]::Ordinal)
$end = $view.IndexOf($artEnd, [StringComparison]::Ordinal)
if ($begin -lt 0 -or $end -le $begin) { throw 'Missing radial art markers in Magelight view' }
$view = $view.Substring(0, $begin + $artBegin.Length) + "`n" + $svg.OuterXml + "`n" + $view.Substring($end)
[IO.File]::WriteAllText($viewPath, $view, (New-Object Text.UTF8Encoding($false)))
$output = Join-Path $mod 'Scripts'
New-Item -ItemType Directory -Force $output | Out-Null
foreach ($name in @('PlayerSignals_Controller', 'PlayerSignals_PlayerAlias')) {
    & $compiler (Join-Path $mod "Source/Scripts/$name.psc") "-flags=$flags" "-import=$imports" "-output=$output"
    if ($LASTEXITCODE -ne 0) { throw "Papyrus compilation failed: $name" }
}
& $Spriggit deserialize -i (Join-Path $repo 'PlayerSignals_spriggit') -o (Join-Path $mod 'PlayerSignals.esp')
if ($LASTEXITCODE -ne 0) { throw 'Spriggit deserialization failed' }
# SEQ holds little-endian startup quest FormIDs, not load-order-prefixed runtime IDs.
$quest = Get-Content -Raw (Join-Path $repo 'PlayerSignals_spriggit/Quests/PlayerSignals_Quest - 000800_PlayerSignals.esp.yaml')
if ($quest -notmatch '(?m)^FormKey: ([0-9A-Fa-f]{6}):PlayerSignals\.esp\s*$') { throw 'Missing startup quest FormKey' }
$formId = [Convert]::ToUInt32($Matches[1], 16)
$seqDir = Join-Path $mod 'SEQ'
New-Item -ItemType Directory -Force $seqDir | Out-Null
[IO.File]::WriteAllBytes((Join-Path $seqDir 'PlayerSignals.seq'), [BitConverter]::GetBytes($formId))
Write-Output ('Built PlayerSignals radial view and PEX/ESP/SEQ; startup quest {0:X8}. No deployment or MO2 changes.' -f $formId)
