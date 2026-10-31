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
if ($art.SelectNodes("//*[local-name()='image']").Count) {
    throw 'Source SVG contains <image>; export vector-only artwork.'
}
$background = $svg.SelectSingleNode("*[local-name()='rect' and @id='Artboard1']")
if ($background) { [void]$svg.RemoveChild($background) }
function Find-Layers($parent, $name) {
    $parent.SelectNodes("./*[local-name()='g']") | Where-Object {
        $_.GetAttribute('id', 'http://www.serif.com/') -ieq $name -or
        $_.GetAttribute('id') -imatch ('^' + [regex]::Escape($name) + '\d*$')
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
function Set-CloneIds($node, $suffix) {
    $localIds = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach ($child in $node.SelectNodes('descendant-or-self::*[@id]')) {
        $id = $child.GetAttribute('id')
        $localIds.Add($id, "$id-$suffix")
        $child.SetAttribute('id', $localIds[$id])
    }
    foreach ($attribute in $node.SelectNodes('.//@*')) {
        $attribute.Value = [regex]::Replace($attribute.Value, 'url\(\s*[''"]?#([^''")\s]+)[''"]?\s*\)', {
            param($match)
            $id = $match.Groups[1].Value
            if ($localIds.ContainsKey($id)) { "url(#$($localIds[$id]))" } else { $match.Value }
        })
        if ($attribute.LocalName -eq 'href' -and $attribute.Value.StartsWith('#')) {
            $id = $attribute.Value.Substring(1)
            if ($localIds.ContainsKey($id)) { $attribute.Value = '#' + $localIds[$id] }
        }
    }
}
$rings = @($svg.SelectNodes(".//*[local-name()='g']") | Where-Object {
    $_.GetAttribute('id', 'http://www.serif.com/') -eq 'Ring' -or $_.GetAttribute('id') -eq 'Ring'
})
if ($rings.Count -ne 1) { throw 'Expected exactly one Ring group' }
$pieces = @(Find-Layers $rings[0] 'Piece')
$centers = @(Find-Layers $rings[0].ParentNode 'center')
if ($centers.Count -ne 1) { throw 'Expected one center beside Ring' }
$center = $centers[0]
$centerHit = Get-FillPath $center 'center'
$splitTemplates = @(Find-Layers $rings[0].ParentNode 'CenterSplit')
if ($splitTemplates.Count -eq 0) { $splitTemplates = @(Find-Layers $rings[0].ParentNode 'CenterSplitTop') }
if ($splitTemplates.Count -ne 1) { throw 'Expected one CenterSplit top-half template (CenterSplitTop is also accepted)' }
$splitTemplate = $splitTemplates[0]
$sourceBottoms = @(Find-Layers $rings[0].ParentNode 'CenterSplitBottom')
if ($sourceBottoms.Count) { Write-Warning 'Ignoring source CenterSplitBottom; rotating the top-half template instead.' }
$templates = @($pieces | Where-Object {
    $transform = $_.GetAttribute('transform')
    $identity = -not $transform
    if ($transform -match '^matrix\(([^)]+)\)$') {
        $matrix = @($Matches[1].Trim() -split '[,\s]+' | ForEach-Object {
            [double]::Parse($_, [Globalization.CultureInfo]::InvariantCulture)
        })
        $identity = $matrix.Count -eq 6 -and $matrix[0] -eq 1 -and $matrix[1] -eq 0 -and
            $matrix[2] -eq 0 -and $matrix[3] -eq 1 -and $matrix[4] -eq 0 -and $matrix[5] -eq 0
    }
    $identity
})
if ($templates.Count -ne 1) { throw 'Expected exactly one identity Piece template (slot 0)' }
if ($pieces.Count -gt 1) { Write-Warning "Ignoring $($pieces.Count - 1) non-identity Piece copies; using the slot-0 template." }
$template = $templates[0]
# Definitions use the referencing element's coordinate system; keep them once, outside the clones.
$defs = $svg.SelectSingleNode("./*[local-name()='defs']")
if (-not $defs) { $defs = $art.CreateElement('defs', $svg.NamespaceURI); [void]$svg.AppendChild($defs) }
$definitionKinds = "local-name()='defs' or local-name()='clipPath' or local-name()='linearGradient' or local-name()='radialGradient' or local-name()='filter' or local-name()='mask' or local-name()='pattern' or local-name()='marker' or local-name()='symbol'"
foreach ($layer in @($template, $splitTemplate)) {
    foreach ($definition in @($layer.SelectNodes(".//*[$definitionKinds][not(ancestor::*[$definitionKinds])]"))) {
        [void]$defs.AppendChild($definition)
    }
}
$splitParent = $splitTemplate.ParentNode
foreach ($name in @('CenterSplit', 'CenterSplitTop', 'CenterSplitBottom')) {
    foreach ($layer in @(Find-Layers $splitParent $name)) { [void]$splitParent.RemoveChild($layer) }
}
$centerSplits = @{}
foreach ($part in @('Top', 'Bottom')) {
    $split = $splitTemplate.CloneNode($true)
    Set-CloneIds $split "centerSplit$part"
    if ($part -eq 'Bottom') { $split.SetAttribute('transform', ('rotate(180 1800 1800) ' + $splitTemplate.GetAttribute('transform')).Trim()) }
    [void]$splitParent.AppendChild($split)
    $centerSplits[$part] = $split
}
foreach ($piece in $pieces) { [void]$rings[0].RemoveChild($piece) }
function Point($radius, $degrees) {
    $radians = ($degrees - 90) * [Math]::PI / 180
    $x = 1800 + $radius * [Math]::Cos($radians); $y = 1800 + $radius * [Math]::Sin($radians)
    [string]::Format([Globalization.CultureInfo]::InvariantCulture, '{0:0.###},{1:0.###}', $x, $y)
}
$half = 15
$coreInner = 432; $coreOuter = 1296; $coreGap = 36
$tipInner = 1339.2; $tipOuter = 1692; $tipGap = 50.4
$coreInnerGap = $coreGap / $coreInner * 90 / [Math]::PI
$coreOuterGap = $coreGap / $coreOuter * 90 / [Math]::PI
$tipAngleGap = $tipGap / $tipInner * 90 / [Math]::PI
$tipInnerText = $tipInner.ToString('0.###', [Globalization.CultureInfo]::InvariantCulture)
$coreD = 'M{0}L{1}A{2},{2} 0 0 1 {3}L{4}A{5},{5} 0 0 0 {0}Z' -f `
    (Point $coreInner (-$half + $coreInnerGap)), (Point $coreOuter (-$half + $coreOuterGap)), $coreOuter,
    (Point $coreOuter ($half - $coreOuterGap)), (Point $coreInner ($half - $coreInnerGap)), $coreInner
$tipD = 'M{0}A{1},{1} 0 0 1 {2}L{3}Z' -f `
    (Point $tipInner (-$half + $tipAngleGap)), $tipInnerText, (Point $tipInner ($half - $tipAngleGap)), (Point $tipOuter 0)
$edgeInset = 20; $edgeChamfer = 12
function Core-EdgePath {
    $inner = $coreInner + $edgeInset; $outer = $coreOuter - $edgeInset
    $innerGap = ($coreGap + 2 * $edgeInset) / $inner * 90 / [Math]::PI
    $outerGap = ($coreGap + 2 * $edgeInset) / $outer * 90 / [Math]::PI
    $bevel = $edgeChamfer
    $innerChamfer = $bevel / $inner * 90 / [Math]::PI
    $outerChamfer = $bevel / $outer * 90 / [Math]::PI
    $loInner = -$half + $innerGap; $loOuter = -$half + $outerGap
    $hiInner = $half - $innerGap; $hiOuter = $half - $outerGap
    $sideOuter = $outer - $bevel
    $sideOuterAngle = $loInner + ($loOuter - $loInner) * (($sideOuter - $inner) / ($outer - $inner))
    $sideInner = $inner + $bevel
    $sideInnerAngle = $loInner + ($loOuter - $loInner) * (($sideInner - $inner) / ($outer - $inner))
    'M{0}L{1}L{2}L{3}A{4},{4} 0 0 1 {5}L{6}L{7}L{8}A{9},{9} 0 0 0 {0}Z' -f `
        (Point $inner ($loInner + $innerChamfer)), (Point $sideInner $sideInnerAngle),
        (Point $sideOuter $sideOuterAngle), (Point $outer ($loOuter + $outerChamfer)), $outer,
        (Point $outer ($hiOuter - $outerChamfer)), (Point $sideOuter (-$sideOuterAngle)),
        (Point $sideInner (-$sideInnerAngle)), (Point $inner ($hiInner - $innerChamfer)), $inner
}
function Tip-EdgePath {
    # Offset the actual straight sides, then intersect them with the inset arc.
    # Interpolating polar angles bows outside the triangular tip.
    $inner = $tipInner + $edgeInset; $angle = ($half - $tipAngleGap) * [Math]::PI / 180
    $x = -$tipInner * [Math]::Sin($angle); $y = -$tipInner * [Math]::Cos($angle)
    $dx = -$x; $dy = -$tipOuter - $y; $length = [Math]::Sqrt($dx * $dx + $dy * $dy)
    $vx = $dx / $length; $vy = $dy / $length
    $px = $x - $edgeInset * $vy; $py = $y + $edgeInset * $vx
    $dot = $px * $vx + $py * $vy
    $t = -$dot + [Math]::Sqrt($dot * $dot - ($px * $px + $py * $py - $inner * $inner))
    $ix = $px + $t * $vx; $iy = $py + $t * $vy
    $apexY = $py - $px / $vx * $vy
    $lo = [Math]::Atan2($ix, -$iy) * 180 / [Math]::PI
    $chamfer = $edgeChamfer / $inner * 180 / [Math]::PI
    function TipPoint($x, $y) {
        [string]::Format([Globalization.CultureInfo]::InvariantCulture, '{0:0.###},{1:0.###}', (1800 + $x), (1800 + $y))
    }
    $sideX = $ix + $edgeChamfer * $vx; $sideY = $iy + $edgeChamfer * $vy
    $apexX = -$edgeChamfer * $vx; $apexY -= $edgeChamfer * $vy
    'M{0}L{1}L{2}A{3},{3} 0 0 1 {4}L{5}L{6}Z' -f `
        (TipPoint $apexX $apexY), (TipPoint $sideX $sideY), (Point $inner ($lo + $chamfer)),
        ($inner.ToString('0.###', [Globalization.CultureInfo]::InvariantCulture)),
        (Point $inner (-$lo - $chamfer)), (TipPoint (-$sideX) $sideY), (TipPoint (-$apexX) $apexY)
}
$coreEdgeD = Core-EdgePath
$tipEdgeD = Tip-EdgePath
$regions = foreach ($slot in 0..11) {
    $piece = $template.CloneNode($true)
    $piece.SetAttribute('transform', "rotate($($slot * 30) 1800 1800)")
    [void]$rings[0].AppendChild($piece)
    $parts = @{}
    foreach ($name in @('Pie', 'Chevron', 'ChevronKnot', 'Submenu', 'Upmenu')) {
        $layers = @(Find-Layers $piece $name)
        if ($layers.Count -ne 1) { throw "Slot $slot needs exactly one $name layer" }
        $parts[$name] = $layers[0]
    }
    Set-CloneIds $piece "slot-$slot"
    [void](Get-FillPath $parts.Pie "Slot $slot Pie")
    [void](Get-FillPath $parts.Chevron "Slot $slot Chevron")
    [void]$parts.Pie.ParentNode.RemoveChild($parts.Pie)
    [void]$parts.Chevron.ParentNode.RemoveChild($parts.Chevron)
    @{ Piece = $piece; Slot = $slot; Parts = $parts }
}
function Get-SvgReferences($node, $contentOnly = $false) {
    $references = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $attributes = if ($contentOnly) { ".//@*[not(ancestor::*[local-name()='defs'])]" } else { './/@*' }
    foreach ($value in $node.SelectNodes("$attributes | .//*[local-name()='style']/text()")) {
        foreach ($match in [regex]::Matches($value.Value, 'url\(\s*[''"]?#([^''")\s]+)')) { [void]$references.Add($match.Groups[1].Value) }
        if ($value.LocalName -eq 'href' -and $value.Value.StartsWith('#')) { [void]$references.Add($value.Value.Substring(1)) }
    }
    return ,$references
}
# Layer lookup is complete; editor attributes no longer have a runtime purpose.
foreach ($attribute in @($svg.SelectNodes(".//@*[namespace-uri()='http://www.serif.com/']"))) {
    [void]$attribute.OwnerElement.RemoveAttributeNode($attribute)
}
$unusedSerif = $svg.SelectNodes("descendant-or-self::*[namespace-uri()='http://www.serif.com/']").Count -eq 0
$unusedSpace = $svg.SelectNodes(".//*[local-name()='text' or local-name()='tspan' or local-name()='textPath']").Count -eq 0
foreach ($node in $svg.SelectNodes('descendant-or-self::*')) {
    if ($unusedSerif) { $node.RemoveAttribute('xmlns:serif') }
    if ($unusedSpace) { $node.RemoveAttribute('space', 'http://www.w3.org/XML/1998/namespace') }
}
# Trace from retained artwork, not from defs: unreachable chains and cycles are dead.
$definitionsById = [Collections.Generic.Dictionary[string,Xml.XmlElement]]::new([StringComparer]::Ordinal)
foreach ($definition in $svg.SelectNodes(".//*[local-name()='defs']/*[local-name()!='defs']")) {
    foreach ($node in $definition.SelectNodes('descendant-or-self::*[@id]')) {
        $id = $node.GetAttribute('id')
        if (-not $definitionsById.ContainsKey($id)) { $definitionsById.Add($id, $definition) }
    }
}
$needed = Get-SvgReferences $svg $true
$pending = [Collections.Generic.Queue[string]]::new()
foreach ($id in $needed) { $pending.Enqueue($id) }
while ($pending.Count) {
    $id = $pending.Dequeue()
    if ($definitionsById.ContainsKey($id)) {
        foreach ($reference in (Get-SvgReferences $definitionsById[$id])) {
            if ($needed.Add($reference)) { $pending.Enqueue($reference) }
        }
    }
}
do {
    $removed = 0
    foreach ($definition in @($svg.SelectNodes(".//*[local-name()='defs']/*[local-name()!='defs']"))) {
        $keep = $definition.LocalName -eq 'style'
        foreach ($node in $definition.SelectNodes('descendant-or-self::*[@id]')) {
            if ($needed.Contains($node.GetAttribute('id'))) { $keep = $true; break }
        }
        if (-not $keep) { [void]$definition.ParentNode.RemoveChild($definition); $removed++ }
    }
    foreach ($empty in @($svg.SelectNodes(".//*[local-name()='defs' and not(*)]"))) {
        [void]$empty.ParentNode.RemoveChild($empty); $removed++
    }
} while ($removed)
$references = Get-SvgReferences $svg
foreach ($node in $svg.SelectNodes('.//*[@id]')) {
    if (-not $references.Contains($node.GetAttribute('id'))) { $node.RemoveAttribute('id') }
}
foreach ($region in $regions) {
    $piece = $region.Piece; $slot = $region.Slot; $parts = $region.Parts
    $piece.SetAttribute('id', "slot-$slot"); $piece.SetAttribute('class', 'sector'); $piece.SetAttribute('data-index', [string]$slot)
    $pop = $art.CreateElement('g', $svg.NamespaceURI); $pop.SetAttribute('class', 'pop')
    [void]$piece.AppendChild($pop)
    foreach ($mode in @('target', 'nearby')) {
        $wrapper = $art.CreateElement('g', $svg.NamespaceURI)
        $wrapper.SetAttribute('id', "slot-$slot-$mode"); $wrapper.SetAttribute('class', "region $mode-region")
        [void]$pop.AppendChild($wrapper)
        $names = if ($mode -eq 'target') { @('Submenu', 'Upmenu') } else { @('ChevronKnot') }
        foreach ($name in $names) { [void]$wrapper.AppendChild($parts[$name]) }
        $hit = $art.CreateElement('path', $svg.NamespaceURI)
        $hit.SetAttribute('id', "slot-$slot-$mode-hit")
        $hit.SetAttribute('class', 'hit-area')
        $hit.SetAttribute('d', $(if ($mode -eq 'target') { $coreD } else { $tipD }))
        [void]$wrapper.PrependChild($hit)
        $edge = $art.CreateElement('path', $svg.NamespaceURI)
        $edge.SetAttribute('class', 'edge-line')
        $edge.SetAttribute('style', 'pointer-events:none;')
        $edge.SetAttribute('d', $(if ($mode -eq 'target') { $coreEdgeD } else { $tipEdgeD }))
        [void]$wrapper.AppendChild($edge)
    }
    $parts.ChevronKnot.SetAttribute('class', 'chevron-knot')
    $parts.Submenu.SetAttribute('class', 'navigation-art submenu-art')
    $parts.Upmenu.SetAttribute('class', 'navigation-art back-art')
    $parts.Submenu.SetAttribute('aria-hidden', 'true'); $parts.Upmenu.SetAttribute('aria-hidden', 'true')
    # Browser-measured bounds in sector-local coordinates; preserve authored aspect ratios.
    # Maximal fits use 10-unit clearance beyond arrow strokes and the inset edge.
    $parts.Submenu.SetAttribute('transform', ('translate(1800 1001.6) scale(0.5974) translate(-1804.650024 -1227.895203) ' + $parts.Submenu.GetAttribute('transform')).Trim())
    $parts.Upmenu.SetAttribute('transform', ('translate(1800 970.9) scale(0.8541) translate(-1805.724976 -1237.673584) ' + $parts.Upmenu.GetAttribute('transform')).Trim())
}
$center.SetAttribute('id', 'center')
$centerHit.SetAttribute('id', 'center-hit'); $centerHit.SetAttribute('class', 'hit-area')
foreach ($part in @('Top', 'Bottom')) {
    $split = $centerSplits[$part]
    $split.SetAttribute('id', "centerSplit$part")
    $split.SetAttribute('style', 'display:none;pointer-events:none;')
    $split.SetAttribute('aria-hidden', 'true')
}
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
# Remove export indentation, not authored SVG text spacing, from the runtime payload.
foreach ($space in @($svg.SelectNodes(".//text()[normalize-space(.)='' and not(ancestor::*[local-name()='text' or local-name()='tspan' or local-name()='textPath'])]"))) {
    [void]$space.ParentNode.RemoveChild($space)
}
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
