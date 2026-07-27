# Convert downloaded AoC 2021 dayNN.html files into dayNN.md files.
#
# Source + output directory: Problem_Statements\days  (this repo)
# Only dayNN.html -> dayNN.md; the dayNN_function_guide.md files are untouched.
#
# The scaffold ships placeholder dayNN.md files ("Placeholder for the Advent of
# Code 2021 Day NN problem statement notes."). Those are overwritten without
# needing -Overwrite; real statement text is only replaced with -Overwrite.
#
# Usage:
#   .\scripts\convert_aoc2021_html_to_md.ps1
#   .\scripts\convert_aoc2021_html_to_md.ps1 -StartDay 1 -EndDay 5
#   .\scripts\convert_aoc2021_html_to_md.ps1 -Overwrite -RemoveHtml

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 25)]
    [int]$StartDay = 1,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 25)]
    [int]$EndDay = 25,

    [Parameter(Mandatory = $false)]
    [switch]$Overwrite,

    [Parameter(Mandatory = $false)]
    [switch]$RemoveHtml
)

if ($StartDay -gt $EndDay) {
    Write-Host "ERROR: StartDay cannot be greater than EndDay." -ForegroundColor Red
    exit 1
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$DaysDir = Join-Path $RepoRoot "Problem_Statements\days"

if (-not (Test-Path $DaysDir)) {
    Write-Host "ERROR: Source directory not found: $DaysDir" -ForegroundColor Red
    exit 1
}

function Convert-AocHtmlToMarkdown {
    param([string]$Html)

    $articleMatches = [regex]::Matches(
        $Html,
        '<article\s+class="day-desc"[^>]*>(.*?)</article>',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    if ($articleMatches.Count -eq 0) {
        return $null
    }

    $parts = [System.Collections.Generic.List[string]]::new()

    foreach ($match in $articleMatches) {
        $text = $match.Groups[1].Value

        # Preserve code blocks first so later inline replacements do not damage them.
        $text = [regex]::Replace(
            $text,
            '<pre><code>(.*?)</code></pre>',
            {
                param($m)
                $inner = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
                $inner = $inner -replace "`r?`n", "`n"
                "`n" + '```text' + "`n" + $inner + "`n" + '```' + "`n"
            },
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

        # Headings and paragraph breaks.
        $text = $text -replace '</h2>', "`n`n"
        $text = $text -replace '<h2[^>]*>', '## '
        $text = $text -replace '</p>', "`n`n"
        $text = $text -replace '<p[^>]*>', ''

        # Lists.
        $text = $text -replace '<ul[^>]*>', "`n"
        $text = $text -replace '</ul>', "`n"
        $text = $text -replace '<li[^>]*>', '- '
        $text = $text -replace '</li>', "`n"

        # Inline formatting.
        $text = $text -replace '<code>', '`'
        $text = $text -replace '</code>', '`'
        $text = $text -replace '<em>', '*'
        $text = $text -replace '</em>', '*'

        # Links.
        $text = [regex]::Replace(
            $text,
            '<a\s+href="([^"]+)"[^>]*>(.*?)</a>',
            {
                param($m)
                $url = $m.Groups[1].Value
                $label = [System.Net.WebUtility]::HtmlDecode($m.Groups[2].Value)
                "[$label]($url)"
            },
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

        # Strip any remaining tags and decode entities.
        $text = [regex]::Replace($text, '<[^>]+>', '')
        $text = [System.Net.WebUtility]::HtmlDecode($text)

        # Normalize blank lines.
        $text = $text -replace "`r?`n", "`n"
        $text = $text -replace "`n{3,}", "`n`n"
        $text = $text.Trim()

        if (-not [string]::IsNullOrWhiteSpace($text)) {
            $parts.Add($text)
        }
    }

    if ($parts.Count -eq 0) {
        return $null
    }

    return ($parts -join "`n`n") + "`n"
}

# A scaffold placeholder is safe to clobber; a real statement is not.
function Test-IsPlaceholderMarkdown {
    param([string]$Path)

    $existing = Get-Content -Path $Path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue

    if ([string]::IsNullOrWhiteSpace($existing)) {
        return $true
    }

    return $existing -match 'Placeholder for the Advent of Code'
}

Write-Host "=== Convert AoC 2021 HTML to Markdown ===" -ForegroundColor Cyan
Write-Host "Source directory: $DaysDir" -ForegroundColor Gray
Write-Host ""

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$converted = 0
$skipped = 0
$missing = 0
$failed = 0

for ($Day = $StartDay; $Day -le $EndDay; $Day++) {
    $DayPadded = "{0:D2}" -f $Day
    $HtmlFile = Join-Path $DaysDir "day$DayPadded.html"
    $MdFile = Join-Path $DaysDir "day$DayPadded.md"

    Write-Host "Day ${DayPadded}: " -NoNewline -ForegroundColor Yellow

    if (-not (Test-Path $HtmlFile)) {
        Write-Host "MISSING html" -ForegroundColor DarkYellow
        $missing++
        continue
    }

    if ((Test-Path $MdFile) -and (-not $Overwrite) -and (-not (Test-IsPlaceholderMarkdown -Path $MdFile))) {
        Write-Host "SKIP md has real content (use -Overwrite)" -ForegroundColor DarkYellow
        $skipped++
        continue
    }

    try {
        $html = Get-Content -Path $HtmlFile -Raw -Encoding UTF8
        $markdown = Convert-AocHtmlToMarkdown -Html $html

        if ([string]::IsNullOrWhiteSpace($markdown)) {
            Write-Host "FAIL no day-desc content" -ForegroundColor Red
            $failed++
            continue
        }

        [System.IO.File]::WriteAllText($MdFile, $markdown, $Utf8NoBom)
        Write-Host "OK -> $(Split-Path -Leaf $MdFile)" -NoNewline -ForegroundColor Green

        if ($RemoveHtml) {
            Remove-Item -Path $HtmlFile -Force -Confirm:$false
            Write-Host " (html removed)" -NoNewline -ForegroundColor DarkGray
        }

        Write-Host ""
        $converted++
    }
    catch {
        Write-Host "FAIL ($($_.Exception.Message))" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "=== Convert Complete ===" -ForegroundColor Cyan
Write-Host "Converted: $converted" -ForegroundColor Gray
Write-Host "Skipped:   $skipped" -ForegroundColor Gray
Write-Host "Missing:   $missing" -ForegroundColor Gray
Write-Host "Failed:    $failed" -ForegroundColor Gray
Write-Host ""
Write-Host "Examples:" -ForegroundColor Yellow
Write-Host '  .\scripts\convert_aoc2021_html_to_md.ps1 -StartDay 1 -EndDay 5'
Write-Host '  .\scripts\convert_aoc2021_html_to_md.ps1 -Overwrite -RemoveHtml'
