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
# Affinity symbol children share layer names; assign runtime IDs only in this document.
$art = New-Object System.Xml.XmlDocument
$art.PreserveWhitespace = $true
$art.XmlResolver = $null
$art.Load((Join-Path $repo 'media/src/RadialUI.svg'))
$svg = $art.DocumentElement
$background = $svg.SelectSingleNode("*[local-name()='rect' and @id='Artboard1']")
if ($background) { [void]$svg.RemoveChild($background) }
function Find-Layers($parent, $name) {
    $parent.SelectNodes("./*[local-name()='g']") | Where-Object {
        $_.GetAttribute('id', 'http://www.serif.com/') -eq $name -or
        $_.GetAttribute('id') -match ('^' + [regex]::Escape($name) + '\d*$')
    }
}
function Get-FillPath($group, $name) {
    $paths = @($group.SelectNodes(".//*[local-name()='path']") | Where-Object {
        $d = $_.GetAttribute('d')
        $d -match '[zZ]\s*$' -and [regex]::Matches($d, '[Mm]').Count -eq 1 -and
        $_.GetAttribute('fill') -ne 'none' -and $_.GetAttribute('style') -notmatch 'fill\s*:\s*none\b'
    })
    if ($paths.Count -ne 1) { throw "$name needs exactly one closed, filled single-contour hit path" }
    $paths[0]
}
$rings = @($svg.SelectNodes(".//*[local-name()='g']") | Where-Object {
    $_.GetAttribute('id', 'http://www.serif.com/') -eq 'Ring' -or $_.GetAttribute('id') -eq 'Ring'
})
if ($rings.Count -ne 1) { throw 'Expected exactly one Ring group' }
$pieces = @(Find-Layers $rings[0] 'Piece')
$centers = @(Find-Layers $rings[0].ParentNode 'center')
if ($pieces.Count -ne 8 -or $centers.Count -ne 1) { throw 'Expected eight Piece groups and one center beside Ring' }
$center = $centers[0]
$centerHit = Get-FillPath $center 'center'
$slots = [Collections.Generic.HashSet[int]]::new()
$regions = foreach ($piece in $pieces) {
    $matrix = @(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
    $transform = $piece.GetAttribute('transform')
    if ($transform) {
        if ($transform -notmatch '^matrix\(([^)]+)\)$') { throw "Unsupported Piece transform: $transform" }
        $matrix = @($Matches[1].Trim() -split '[,\s]+' | ForEach-Object {
            [double]::Parse($_, [Globalization.CultureInfo]::InvariantCulture)
        })
        if ($matrix.Count -ne 6) { throw "Expected six matrix components: $transform" }
    }
    $a, $b, $c, $d, $e, $f = $matrix
    if ($a * $a + $b * $b -eq 0 -or [math]::Abs($a - $d) -gt .00001 -or [math]::Abs($b + $c) -gt .00001) {
        throw "Piece transform must be a rotation with uniform positive scale: $transform"
    }
    $angle = [math]::Atan2($b, $a) * 180 / [math]::PI
    $step = [int][math]::Round($angle / 45)
    $slot = ($step % 8 + 8) % 8
    if ([math]::Abs($angle - $step * 45) -gt .01 -or -not $slots.Add($slot)) {
        throw "Piece rotation must identify a distinct 45-degree slot: $transform"
    }
    $parts = @{}
    foreach ($name in @('Pie', 'Chevron', 'ChevronKnot', 'Submenu', 'Upmenu')) {
        $layers = @(Find-Layers $piece $name)
        if ($layers.Count -ne 1) { throw "Slot $slot needs exactly one $name layer" }
        $parts[$name] = $layers[0]
    }
    @{ Piece = $piece; Slot = $slot; Parts = $parts
       TargetHit = (Get-FillPath $parts.Pie "Slot $slot Pie")
       NearbyHit = (Get-FillPath $parts.Chevron "Slot $slot Chevron") }
}
# Only reference targets need their Affinity IDs; layer lookup above is already complete.
$references = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($attribute in $svg.SelectNodes('.//@*')) {
    foreach ($match in [regex]::Matches($attribute.Value, 'url\(\s*[''"]?#([^''")\s]+)')) { [void]$references.Add($match.Groups[1].Value) }
    if ($attribute.LocalName -eq 'href' -and $attribute.Value.StartsWith('#')) { [void]$references.Add($attribute.Value.Substring(1)) }
}
foreach ($node in $svg.SelectNodes('.//*[@id]')) {
    if (-not $references.Contains($node.GetAttribute('id'))) { $node.RemoveAttribute('id') }
}
foreach ($region in $regions) {
    $piece = $region.Piece; $slot = $region.Slot; $parts = $region.Parts
    $piece.SetAttribute('id', "slot-$slot"); $piece.SetAttribute('class', 'sector'); $piece.SetAttribute('data-index', [string]$slot)
    foreach ($mode in @('target', 'nearby')) {
        $wrapper = $art.CreateElement('g', $svg.NamespaceURI)
        $wrapper.SetAttribute('id', "slot-$slot-$mode"); $wrapper.SetAttribute('class', "region $mode-region")
        [void]$piece.AppendChild($wrapper)
        $names = if ($mode -eq 'target') { @('Pie', 'Submenu', 'Upmenu') } else { @('Chevron', 'ChevronKnot') }
        foreach ($name in $names) { [void]$wrapper.AppendChild($parts[$name]) }
        $hit = if ($mode -eq 'target') { $region.TargetHit } else { $region.NearbyHit }
        $hit.SetAttribute('id', "slot-$slot-$mode-hit"); $hit.SetAttribute('class', 'hit-area')
    }
    $parts.Submenu.SetAttribute('class', 'navigation-art submenu-art')
    $parts.Upmenu.SetAttribute('class', 'navigation-art back-art')
    $parts.Submenu.SetAttribute('aria-hidden', 'true'); $parts.Upmenu.SetAttribute('aria-hidden', 'true')
}
$center.SetAttribute('id', 'center')
$centerHit.SetAttribute('id', 'center-hit'); $centerHit.SetAttribute('class', 'hit-area')
$ids = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($node in $svg.SelectNodes('descendant-or-self::*[@id]')) {
    if (-not $ids.Add($node.GetAttribute('id'))) { throw "Duplicate generated SVG ID: $($node.GetAttribute('id'))" }
}
foreach ($id in $references) {
    if (-not $ids.Contains($id)) { throw "Unresolved SVG reference: $id" }
}
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
