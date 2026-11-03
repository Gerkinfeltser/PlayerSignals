param(
    [string]$GameRoot = 'D:/Modlists/ADT/Game Root',
    [string]$ModsRoot = 'D:/Modlists/ADT/mods',
    [string]$UiExtensionsSources = 'D:/git/SkyrimNet-GamePlugin/headers',
    [string]$FallbackHeaders = 'D:/git/SkyrimNet-GamePlugin/headers',
    [string]$MagelightSources = 'D:/git/MagelightUI/papyrus',
    [string]$Spriggit = 'D:/SkyrimMisc/SpriggitCLI/Spriggit.CLI.exe',
    [switch]$Native
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
$tipOuter = 1692
$coreInnerGap = $coreGap / $coreInner * 90 / [Math]::PI
$coreOuterGap = $coreGap / $coreOuter * 90 / [Math]::PI
$edgeInset = 20; $edgeChamfer = 12
function Local-Point($radius, $degrees) {
    $angle = $degrees * [Math]::PI / 180
    ,@(($radius * [Math]::Sin($angle)), (-$radius * [Math]::Cos($angle)))
}
function Svg-Point($point) {
    [string]::Format([Globalization.CultureInfo]::InvariantCulture, '{0:0.###},{1:0.###}', (1800 + $point[0]), (1800 + $point[1]))
}
function Compose-Matrix($a, $b) {
    ,@(
        ($a[0] * $b[0] + $a[2] * $b[1]), ($a[1] * $b[0] + $a[3] * $b[1]),
        ($a[0] * $b[2] + $a[2] * $b[3]), ($a[1] * $b[2] + $a[3] * $b[3]),
        ($a[0] * $b[4] + $a[2] * $b[5] + $a[4]), ($a[1] * $b[4] + $a[3] * $b[5] + $a[5])
    )
}
function Transform-PathData($path, $matrix) {
    $tokens = @([regex]::Matches($path.GetAttribute('d'), '[A-Za-z]|[-+]?(?:\d*\.)?\d+(?:[eE][-+]?\d+)?') | ForEach-Object Value)
    $out = [Text.StringBuilder]::new(); $command = ''; $x = 0.0; $y = 0.0; $startX = 0.0; $startY = 0.0
    $i = 0
    while ($i -lt $tokens.Count) {
        if ($tokens[$i] -match '^[A-Za-z]$') {
            $command = $tokens[$i++]
            if ($command -match '^[Zz]$') { [void]$out.Append('Z'); $x = $startX; $y = $startY; continue }
        }
        $upper = $command.ToUpperInvariant(); $relative = $command -cmatch '^[a-z]$'
        $count = if ($upper -eq 'C') { 6 } elseif ($upper -eq 'M' -or $upper -eq 'L') { 2 } else { throw "Unsupported ChevronKnot path command: $command" }
        $values = for ($j = 0; $j -lt $count; $j++) {
            [double]::Parse($tokens[$i++], [Globalization.CultureInfo]::InvariantCulture)
        }
        if ($upper -eq 'C') {
            for ($j = 0; $j -lt 6; $j += 2) { if ($relative) { $values[$j] += $x; $values[$j + 1] += $y } }
            $pairs = @(0, 2, 4)
            $x = $values[4]; $y = $values[5]
        } else {
            if ($relative) { $values[0] += $x; $values[1] += $y }
            $pairs = @(0); $x = $values[0]; $y = $values[1]
            if ($upper -eq 'M') { $startX = $x; $startY = $y }
            if ($upper -eq 'M') { $command = if ($relative) { 'l' } else { 'L' } }
        }
        [void]$out.Append($upper)
        foreach ($j in $pairs) {
            $tx = $matrix[0] * $values[$j] + $matrix[2] * $values[$j + 1] + $matrix[4]
            $ty = $matrix[1] * $values[$j] + $matrix[3] * $values[$j + 1] + $matrix[5]
            [void]$out.Append(([string]::Format([Globalization.CultureInfo]::InvariantCulture, '{0:0.######},{1:0.######}', $tx, $ty)))
            if ($j -ne $pairs[-1]) { [void]$out.Append(' ') }
        }
    }
    $path.SetAttribute('d', $out.ToString())
}
function Bake-Knot($group, $fit) {
    foreach ($path in $group.SelectNodes(".//*[local-name()='path']")) {
        $chain = [Collections.Generic.List[Xml.XmlElement]]::new()
        for ($node = $path; $node -and $node -ne $group.ParentNode; $node = $node.ParentNode) {
            if ($node -is [Xml.XmlElement]) { $chain.Add($node) }
            if ($node -eq $group) { break }
        }
        $matrix = @(1, 0, 0, 1, 0, 0)
        for ($n = $chain.Count - 1; $n -ge 0; $n--) {
            $transform = $chain[$n].GetAttribute('transform')
            if ($transform -match '^matrix\(([^)]+)\)$') {
                $part = @($Matches[1].Trim() -split '[,\s]+' | ForEach-Object { [double]::Parse($_, [Globalization.CultureInfo]::InvariantCulture) })
                $matrix = Compose-Matrix $matrix $part
            } elseif ($transform) { throw "Unsupported ChevronKnot transform: $transform" }
        }
        Transform-PathData $path (Compose-Matrix $fit $matrix)
    }
    foreach ($node in $group.SelectNodes('descendant-or-self::*[@transform]')) { $node.RemoveAttribute('transform') }
}
function Side-Line($a, $b, $inset) {
    $dx = $b[0] - $a[0]; $dy = $b[1] - $a[1]
    $length = [Math]::Sqrt($dx * $dx + $dy * $dy)
    $nx = -$dy / $length; $ny = $dx / $length
    $midX = ($a[0] + $b[0]) / 2; $midY = ($a[1] + $b[1]) / 2
    if (($nx * -$midX + $ny * (-900 - $midY)) -lt 0) { $nx = -$nx; $ny = -$ny }
    ,@(($a[0] + $inset * $nx), ($a[1] + $inset * $ny), ($dx / $length), ($dy / $length))
}
function Line-Crossing($a, $b) {
    $cross = $a[2] * $b[3] - $a[3] * $b[2]
    if ([Math]::Abs($cross) -lt 0.000001) { throw 'Slice sides do not converge' }
    $t = (($b[0] - $a[0]) * $b[3] - ($b[1] - $a[1]) * $b[2]) / $cross
    ,@(($a[0] + $t * $a[2]), ($a[1] + $t * $a[3]))
}
$innerLeft = Local-Point $coreInner (-$half + $coreInnerGap)
$outerLeft = Local-Point $coreOuter (-$half + $coreOuterGap)
$outerRight = Local-Point $coreOuter ($half - $coreOuterGap)
$innerRight = Local-Point $coreInner ($half - $coreInnerGap)
$apex = Line-Crossing (Side-Line $innerLeft $outerLeft 0) (Side-Line $outerRight $innerRight 0)
$coreD = 'M{0}L{1}L{2}Z' -f (Svg-Point $apex), (Svg-Point $outerLeft), (Svg-Point $outerRight)
$capCenter = @((($outerLeft[0] + $outerRight[0]) / 2), (($outerLeft[1] + $outerRight[1]) / 2))
$capRadius = [Math]::Sqrt(($outerRight[0] - $outerLeft[0]) * ($outerRight[0] - $outerLeft[0]) +
    ($outerRight[1] - $outerLeft[1]) * ($outerRight[1] - $outerLeft[1])) / 2
$capRadiusText = $capRadius.ToString('0.###', [Globalization.CultureInfo]::InvariantCulture)
$tipD = 'M{0}A{1},{1} 0 0 1 {2}Z' -f `
    (Svg-Point $outerLeft), $capRadiusText, (Svg-Point $outerRight)
# Variant B follows the approved preview coordinates; the slot transform rotates it into each slice.
$hybridD = 'M1481.989,543.622C1481.989,370 1630,250 1800,108C1970,250 2118.011,370 2118.011,543.622Z'
$hybridEdgeD = 'M1502.661,523.622C1502.661,375 1640,270 1800,145C1960,270 2097.339,375 2097.339,523.622Z'
$hotkeyPieD = $coreD
$capHalfTop = 0.4 * $capRadius
$capTopY = $outerLeft[1] + (($outerLeft[0] + $capHalfTop) / $outerLeft[0]) * ((Local-Point $tipOuter 0)[1] - $outerLeft[1])
$hotkeyCapD = 'M{0}L{1}L{2}L{3}Z' -f `
    (Svg-Point $outerLeft), (Svg-Point @(-$capHalfTop, $capTopY)),
    (Svg-Point @($capHalfTop, $capTopY)), (Svg-Point $outerRight)
$hotkeyUnionD = 'M{0}L{1}L{2}L{3}L{4}Z' -f `
    (Svg-Point $apex), (Svg-Point $outerLeft), (Svg-Point @(-$capHalfTop, $capTopY)),
    (Svg-Point @($capHalfTop, $capTopY)), (Svg-Point $outerRight)
$unionD = 'M{0}L{1}L{2}L{3}Z' -f `
    (Svg-Point $apex), (Svg-Point $outerLeft), (Point $tipOuter 0), (Svg-Point $outerRight)
$sidePoints = @($innerLeft, $outerLeft, (Local-Point $tipOuter 0), $outerRight, $innerRight)
$lines = @(for ($i = 0; $i -lt 4; $i++) { ,(Side-Line $sidePoints[$i] $sidePoints[($i + 1)] $edgeInset) })
$insetApex = Line-Crossing $lines[0] $lines[3]
$unionEdge = [Collections.Generic.List[string]]::new()
$unionEdge.Add(('M' + (Svg-Point $insetApex)))
for ($i = 1; $i -lt 4; $i++) {
    $a = $lines[$i - 1]; $b = $lines[$i]; $corner = Line-Crossing $a $b
    $unionEdge.Add(('L' + (Svg-Point @(($corner[0] - $edgeChamfer * $a[2]), ($corner[1] - $edgeChamfer * $a[3])))))
    $unionEdge.Add(('L' + (Svg-Point @(($corner[0] + $edgeChamfer * $b[2]), ($corner[1] + $edgeChamfer * $b[3])))))
}
$unionEdgeD = ($unionEdge -join '') + 'Z'
$hotkeyPieChord = Side-Line $outerLeft $outerRight $edgeInset
$hotkeyCapChord = Side-Line $outerLeft $outerRight (-$edgeInset)
$hotkeyPieLeft = Line-Crossing $lines[0] $hotkeyPieChord
$hotkeyPieRight = Line-Crossing $hotkeyPieChord $lines[3]
$hotkeyCapLeft = Line-Crossing $lines[1] $hotkeyCapChord
$hotkeyCapRight = Line-Crossing $hotkeyCapChord $lines[2]
$hotkeyPieEdgeD = 'M{0}L{1}L{2}Z' -f `
    (Svg-Point $insetApex), (Svg-Point $hotkeyPieLeft), (Svg-Point $hotkeyPieRight)
$hotkeyTopLine = @(-1, ($capTopY + $edgeInset), 1, 0)
$hotkeyCapTopLeft = Line-Crossing $lines[1] $hotkeyTopLine
$hotkeyCapTopRight = Line-Crossing $hotkeyTopLine $lines[2]
$hotkeyCapEdgeD = 'M{0}L{1}L{2}L{3}Z' -f `
    (Svg-Point $hotkeyCapLeft), (Svg-Point $hotkeyCapTopLeft),
    (Svg-Point $hotkeyCapTopRight), (Svg-Point $hotkeyCapRight)
$coreEdgeD = $hotkeyPieEdgeD
function Tip-EdgePath {
    $radius = $capRadius - $edgeInset
    $chordY = $outerLeft[1] - $edgeInset
    $offsetY = $chordY - $capCenter[1]
    $x = [Math]::Sqrt($radius * $radius - $offsetY * $offsetY)
    $left = @(-$x, $chordY); $right = @($x, $chordY)
    $radiusText = $radius.ToString('0.###', [Globalization.CultureInfo]::InvariantCulture)
    'M{0}A{1},{1} 0 0 1 {2}Z' -f `
        (Svg-Point $left), $radiusText, (Svg-Point $right)
}
$tipEdgeD = Tip-EdgePath
# Only Submenu/Back use these baked alternatives; strokes keep their original widths.
$navScale = 0.85
$subbackMatrix = @($navScale, 0, 0, $navScale, (1800 * (1 - $navScale)), (1800 * (1 - $navScale)))
function Subback-Path($d) {
    $path = $art.CreateElement('path', $svg.NamespaceURI); $path.SetAttribute('d', $d)
    Transform-PathData $path $subbackMatrix
    $path.GetAttribute('d')
}
# Narrow the core across its axis; slide shoulders along the unchanged knot arms.
$navWidth = 0.7
$navLeft = @(($outerLeft[0] * $navWidth), (-$tipOuter + ($outerLeft[1] + $tipOuter) * $navWidth))
$navRight = @(-$navLeft[0], $navLeft[1])
$navUnionD = 'M{0}L{1}L{2}L{3}Z' -f `
    (Svg-Point $apex), (Svg-Point $navLeft), (Point $tipOuter 0), (Svg-Point $navRight)
$navSidePoints = @($apex, $navLeft, (Local-Point $tipOuter 0), $navRight, $apex)
$navLines = @(for ($i = 0; $i -lt 4; $i++) { ,(Side-Line $navSidePoints[$i] $navSidePoints[$i + 1] $edgeInset) })
$navEdge = [Collections.Generic.List[string]]::new()
$navEdge.Add(('M' + (Svg-Point (Line-Crossing $navLines[0] $navLines[3]))))
for ($i = 1; $i -lt 4; $i++) {
    $a = $navLines[$i - 1]; $b = $navLines[$i]; $corner = Line-Crossing $a $b
    $navEdge.Add(('L' + (Svg-Point @(($corner[0] - $edgeChamfer * $a[2]), ($corner[1] - $edgeChamfer * $a[3])))))
    $navEdge.Add(('L' + (Svg-Point @(($corner[0] + $edgeChamfer * $b[2]), ($corner[1] + $edgeChamfer * $b[3])))))
}
$subbackUnionD = Subback-Path $navUnionD
$subbackEdgeD = Subback-Path (($navEdge -join '') + 'Z')
$svg.SetAttribute('data-nav-scale', $navScale.ToString('0.##', [Globalization.CultureInfo]::InvariantCulture))
# Fixed slice-local placement clears the hub's maximum pop; fit once at each glyph's outer extent.
$arrowRadius = 525
$sideSlope = [Math]::Abs(($outerLeft[0] - $innerLeft[0]) / ($outerLeft[1] - $innerLeft[1]))
$arrowFit = 0.85 * 2 * $sideSlope
# Use the clear interior between the existing inset edges, not the surrounding border.
# k = .85 * interiorWidth(525 + glyphHeight*k) / glyphWidth; solve directly.
$submenuScale = $arrowFit * ($arrowRadius + $insetApex[1]) / (446.280029 - $arrowFit * 201.989624)
$backScale = $arrowFit * ($arrowRadius + $insetApex[1]) / (316.469971 - $arrowFit * 174.432861)
$submenuY = 1800 - $arrowRadius - 201.989624 / 2 * $submenuScale
$backY = 1800 - $arrowRadius - 174.432861 / 2 * $backScale
$submenuPlacement = [string]::Format([Globalization.CultureInfo]::InvariantCulture, 'translate(1800 {0:0.######}) scale({1:0.######}) translate(-1804.650024 -1227.895203) ', $submenuY, $submenuScale)
$backPlacement = [string]::Format([Globalization.CultureInfo]::InvariantCulture, 'translate(1800 {0:0.######}) scale({1:0.######}) translate(-1805.724976 -1237.673584) ', $backY, $backScale)
$labelRadius = ($coreOuter + $coreInner * [Math]::Cos((-$half + $coreInnerGap) * [Math]::PI / 180)) / 2
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
# Final per-slot definitions are added after reference pruning so their clip IDs remain intact.
$references = Get-SvgReferences $svg
foreach ($node in $svg.SelectNodes('.//*[@id]')) {
    if (-not $references.Contains($node.GetAttribute('id'))) { $node.RemoveAttribute('id') }
}
$defs = $svg.SelectSingleNode("./*[local-name()='defs']")
if (-not $defs) { $defs = $art.CreateElement('defs', $svg.NamespaceURI); [void]$svg.PrependChild($defs) }
foreach ($region in $regions) {
    $piece = $region.Piece; $slot = $region.Slot; $parts = $region.Parts
    $piece.SetAttribute('id', "slot-$slot")
    $piece.SetAttribute('class', 'sector')
    $piece.SetAttribute('data-index', [string]$slot)
    $piece.SetAttribute('data-core-radius', $coreOuter.ToString([Globalization.CultureInfo]::InvariantCulture))
    $piece.SetAttribute('data-hotkey-union-d', $hotkeyUnionD)
    $piece.SetAttribute('data-label-radius', $labelRadius.ToString('0.######', [Globalization.CultureInfo]::InvariantCulture))
    $piece.SetAttribute('data-bulb-x', (1800 + $capCenter[0]).ToString('0.###', [Globalization.CultureInfo]::InvariantCulture))
    $piece.SetAttribute('data-bulb-y', (1800 + $capCenter[1]).ToString('0.###', [Globalization.CultureInfo]::InvariantCulture))
    $piece.SetAttribute('data-bulb-radius', $capRadiusText)
    $pop = $art.CreateElement('g', $svg.NamespaceURI); $pop.SetAttribute('class', 'pop')
    [void]$piece.AppendChild($pop)
    foreach ($mode in @('nearby', 'target')) {
        $wrapper = $art.CreateElement('g', $svg.NamespaceURI)
        $wrapper.SetAttribute('id', "slot-$slot-$mode"); $wrapper.SetAttribute('class', "region $mode-region")
        [void]$pop.AppendChild($wrapper)
        $hit = $art.CreateElement('path', $svg.NamespaceURI)
        $hit.SetAttribute('id', "slot-$slot-$mode-hit")
        $hit.SetAttribute('class', 'hit-area')
        $hit.SetAttribute('d', $(if ($mode -eq 'target') { $coreD } else { $tipD }))
        $hit.SetAttribute('data-hotkey-d', $(if ($mode -eq 'target') { $hotkeyPieD } else { $hotkeyCapD }))
        if ($mode -eq 'nearby') { $hit.SetAttribute('data-core-d', $tipD); $hit.SetAttribute('data-hybrid-d', $hybridD) }
        else {
            $hit.SetAttribute('data-core-d', $coreD)
            $hit.SetAttribute('data-nav-d', $unionD)
            $hit.SetAttribute('data-subback-d', $subbackUnionD)
        }
        [void]$wrapper.PrependChild($hit)
        $edge = $art.CreateElement('path', $svg.NamespaceURI)
        $edge.SetAttribute('class', 'edge-line')
        $edge.SetAttribute('style', 'pointer-events:none;')
        $edge.SetAttribute('d', $(if ($mode -eq 'target') { $coreEdgeD } else { $tipEdgeD }))
        $edge.SetAttribute('data-hotkey-d', $(if ($mode -eq 'target') { $hotkeyPieEdgeD } else { $hotkeyCapEdgeD }))
        if ($mode -eq 'nearby') { $edge.SetAttribute('data-core-d', $tipEdgeD); $edge.SetAttribute('data-hybrid-d', $hybridEdgeD) }
        else {
            $edge.SetAttribute('data-core-d', $coreEdgeD)
            $edge.SetAttribute('data-nav-d', $unionEdgeD)
            $edge.SetAttribute('data-subback-d', $subbackEdgeD)
        }
        $clip = $art.CreateElement('clipPath', $svg.NamespaceURI)
        $clip.SetAttribute('id', "slot-$slot-$mode-selected-band-clip")
        $clip.SetAttribute('clipPathUnits', 'userSpaceOnUse')
        $clipShape = $art.CreateElement('path', $svg.NamespaceURI)
        $clipShape.SetAttribute('class', 'selected-band-clip')
        $clipShape.SetAttribute('d', $(if ($mode -eq 'target') { $coreEdgeD } else { $tipEdgeD }))
        $clipShape.SetAttribute('data-hotkey-d', $(if ($mode -eq 'target') { $hotkeyPieEdgeD } else { $hotkeyCapEdgeD }))
        if ($mode -eq 'nearby') {
            $clipShape.SetAttribute('data-core-d', $tipEdgeD)
            $clipShape.SetAttribute('data-nav-d', $tipEdgeD)
            $clipShape.SetAttribute('data-hybrid-d', $hybridEdgeD)
        } else {
            $clipShape.SetAttribute('data-core-d', $coreEdgeD)
            $clipShape.SetAttribute('data-nav-d', $unionEdgeD)
            $clipShape.SetAttribute('data-subback-d', $subbackEdgeD)
        }
        [void]$clip.AppendChild($clipShape)
        [void]$wrapper.AppendChild($clip)
        $band = $art.CreateElement('path', $svg.NamespaceURI)
        $band.SetAttribute('class', 'selected-band')
        $band.SetAttribute('d', $(if ($mode -eq 'target') { $coreEdgeD } else { $tipEdgeD }))
        $band.SetAttribute('stroke-width', '90')
        $band.SetAttribute('clip-path', "url(#slot-$slot-$mode-selected-band-clip)")
        $band.SetAttribute('style', 'pointer-events:none;')
        $band.SetAttribute('data-hotkey-d', $(if ($mode -eq 'target') { $hotkeyPieEdgeD } else { $hotkeyCapEdgeD }))
        if ($mode -eq 'nearby') { $band.SetAttribute('data-core-d', $tipEdgeD); $band.SetAttribute('data-hybrid-d', $hybridEdgeD) }
        else {
            $band.SetAttribute('data-core-d', $coreEdgeD)
            $band.SetAttribute('data-nav-d', $unionEdgeD)
            $band.SetAttribute('data-subback-d', $subbackEdgeD)
        }
        [void]$wrapper.AppendChild($band)
        [void]$wrapper.AppendChild($edge)
    }
    $clip = $art.CreateElement('clipPath', $svg.NamespaceURI)
    $clip.SetAttribute('id', "slot-$slot-utility-clip")
    $clip.SetAttribute('clipPathUnits', 'userSpaceOnUse')
    $clipShape = $art.CreateElement('path', $svg.NamespaceURI)
    $clipShape.SetAttribute('d', $unionD)
    $clipShape.SetAttribute('data-nav-d', $unionD)
    $clipShape.SetAttribute('data-subback-d', $subbackUnionD)
    [void]$clip.AppendChild($clipShape); [void]$defs.AppendChild($clip)
    foreach ($radius in @(560, 610)) {
        $utilityArc = $art.CreateElement('path', $svg.NamespaceURI)
        $utilityArc.SetAttribute('class', 'edge-line utility-arc')
        $utilityArc.SetAttribute('d', ('M{0}A{1},{1} 0 0 1 {2}' -f (Point $radius (-$half)), $radius, (Point $radius $half)))
        $utilityArc.SetAttribute('clip-path', "url(#slot-$slot-utility-clip)")
        $utilityArc.SetAttribute('aria-hidden', 'true')
        $utilityArc.SetAttribute('style', 'pointer-events:none;')
        [void]$pop.AppendChild($utilityArc)
    }
    [void]$pop.AppendChild($parts.Submenu)
    [void]$pop.AppendChild($parts.Upmenu)
    $parts.ChevronKnot.SetAttribute('class', 'chevron-knot')
    # Retain the approved baked knot size; the page translates it for Submenu/Back.
    $knotSourceApex = @((1738.95 * 1.09023 - 91.5177), (815.264 * 1.05313 - 636.273))
    $knotSourceRight = @((1960.12 * 1.09023 - 91.5177), (1046.35 * 1.05313 - 636.273))
    $knotSourceLeft = @((1507.65 * 1.09023 - 91.5177), (1046.56 * 1.05313 - 636.273))
    $knotTargetApex = @(1800, (1800 - $tipOuter))
    $knotTargetRight = @((1800 + $outerRight[0]), (1800 + $outerRight[1]))
    $knotTargetLeft = @((1800 + $outerLeft[0]), (1800 + $outerLeft[1]))
    $knotEdgeInset = 31.1 / 2
    $knotRightDx = $knotTargetRight[0] - $knotTargetApex[0]
    $knotRightDy = $knotTargetRight[1] - $knotTargetApex[1]
    $knotRightLength = [Math]::Sqrt($knotRightDx * $knotRightDx + $knotRightDy * $knotRightDy)
    $knotLeftDx = $knotTargetLeft[0] - $knotTargetApex[0]
    $knotLeftDy = $knotTargetLeft[1] - $knotTargetApex[1]
    $knotLeftLength = [Math]::Sqrt($knotLeftDx * $knotLeftDx + $knotLeftDy * $knotLeftDy)
    $knotTargetRight[0] -= $knotEdgeInset * $knotRightDy / $knotRightLength
    $knotTargetRight[1] += $knotEdgeInset * $knotRightDx / $knotRightLength
    $knotTargetLeft[0] += $knotEdgeInset * $knotLeftDy / $knotLeftLength
    $knotTargetLeft[1] -= $knotEdgeInset * $knotLeftDx / $knotLeftLength
    $knotDet = ($knotSourceRight[0] - $knotSourceApex[0]) * ($knotSourceLeft[1] - $knotSourceApex[1]) -
        ($knotSourceLeft[0] - $knotSourceApex[0]) * ($knotSourceRight[1] - $knotSourceApex[1])
    $knotA = (($knotTargetRight[0] - $knotTargetApex[0]) * ($knotSourceLeft[1] - $knotSourceApex[1]) -
        ($knotTargetLeft[0] - $knotTargetApex[0]) * ($knotSourceRight[1] - $knotSourceApex[1])) / $knotDet
    $knotC = (($knotSourceRight[0] - $knotSourceApex[0]) * ($knotTargetLeft[0] - $knotTargetApex[0]) -
        ($knotSourceLeft[0] - $knotSourceApex[0]) * ($knotTargetRight[0] - $knotTargetApex[0])) / $knotDet
    $knotB = (($knotTargetRight[1] - $knotTargetApex[1]) * ($knotSourceLeft[1] - $knotSourceApex[1]) -
        ($knotTargetLeft[1] - $knotTargetApex[1]) * ($knotSourceRight[1] - $knotSourceApex[1])) / $knotDet
    $knotD = (($knotSourceRight[0] - $knotSourceApex[0]) * ($knotTargetLeft[1] - $knotTargetApex[1]) -
        ($knotSourceLeft[0] - $knotSourceApex[0]) * ($knotTargetRight[1] - $knotTargetApex[1])) / $knotDet
    $knotFit = @($knotA, $knotB, $knotC, $knotD,
        ($knotTargetApex[0] - $knotA * $knotSourceApex[0] - $knotC * $knotSourceApex[1]),
        ($knotTargetApex[1] - $knotB * $knotSourceApex[0] - $knotD * $knotSourceApex[1]))
    # The approved ornament includes its existing finite-edge length fit.
    $knotLengthScale = 0.56
    $knotFit = Compose-Matrix @($knotLengthScale, 0, 0, $knotLengthScale,
        (1800 * (1 - $knotLengthScale)), ((1800 - $tipOuter) * (1 - $knotLengthScale))) $knotFit
    Bake-Knot $parts.ChevronKnot $knotFit
    [void]$pop.AppendChild($parts.ChevronKnot)
    $parts.Submenu.SetAttribute('class', 'navigation-art submenu-art')
    $parts.Upmenu.SetAttribute('class', 'navigation-art back-art')
    $parts.Submenu.SetAttribute('aria-hidden', 'true'); $parts.Upmenu.SetAttribute('aria-hidden', 'true')
    $parts.Submenu.SetAttribute('transform', ($submenuPlacement + $parts.Submenu.GetAttribute('transform')).Trim())
    $parts.Upmenu.SetAttribute('transform', ($backPlacement + $parts.Upmenu.GetAttribute('transform')).Trim())
}
# Fixed quadrant diameters sit behind all wheel artwork, outside every lifted group.
$quadrants = $art.CreateElement('g', $svg.NamespaceURI)
$quadrants.SetAttribute('id', 'quadrant-lines')
$quadrants.SetAttribute('aria-hidden', 'true')
$quadrants.SetAttribute('style', 'fill:none;stroke:#fff;stroke-width:9;opacity:.9;pointer-events:none;')
foreach ($x in @(450, 3150)) {
    $line = $art.CreateElement('line', $svg.NamespaceURI)
    $line.SetAttribute('x1', [string]$x); $line.SetAttribute('y1', '450')
    $line.SetAttribute('x2', [string](3600 - $x)); $line.SetAttribute('y2', '3150')
    [void]$quadrants.AppendChild($line)
}
[void]$svg.PrependChild($quadrants)
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
foreach ($id in (Get-SvgReferences $svg)) {
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
$nativeDir = Join-Path $repo 'PlayerSignals_native'
# Build the DLL when requested, missing, or older than any native project source.
$nativeDll = Join-Path $mod 'SKSE/Plugins/PlayerSignals.dll'
$nativeSources = @(
    (Join-Path $nativeDir 'CMakeLists.txt'),
    (Join-Path $nativeDir 'build.ps1'),
    (Join-Path $nativeDir 'vcpkg.json'),
    (Join-Path $nativeDir 'vcpkg-configuration.json')
) + @(Get-ChildItem (Join-Path $nativeDir 'src') -File -Recurse | ForEach-Object FullName)
$nativeNeedsBuild = $Native -or !(Test-Path -LiteralPath $nativeDll -PathType Leaf)
if (-not $nativeNeedsBuild) {
    $dllTime = (Get-Item -LiteralPath $nativeDll).LastWriteTimeUtc
    $nativeNeedsBuild = @($nativeSources | Where-Object {
        (Test-Path -LiteralPath $_ -PathType Leaf) -and
        (Get-Item -LiteralPath $_).LastWriteTimeUtc -gt $dllTime
    }).Count -gt 0
}
if ($nativeNeedsBuild) {
    & (Join-Path $nativeDir 'build.ps1')
    if ($LASTEXITCODE -ne 0) { throw "Native build failed ($LASTEXITCODE)" }
}
foreach ($name in @('PlayerSignals_Controller', 'PlayerSignals_PlayerAlias', 'PlayerSignals_Native')) {
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
