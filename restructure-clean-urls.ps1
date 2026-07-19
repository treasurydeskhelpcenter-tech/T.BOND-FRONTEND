$root = Get-Location
Write-Host "Working in: $root" -ForegroundColor Cyan

$htmlFiles = Get-ChildItem -Path . -Filter "*.html" -File | Where-Object { $_.Name -ne "index.html" }
Write-Host "Found $($htmlFiles.Count) pages to convert." -ForegroundColor Yellow

$renameMap = @{}
foreach ($file in $htmlFiles) {
    $baseName = $file.BaseName
    $renameMap[$file.Name] = "/$baseName/"
}

foreach ($file in $htmlFiles) {
    $baseName = $file.BaseName
    $folderPath = Join-Path $root $baseName
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
    }
    $destination = Join-Path $folderPath "index.html"
    Move-Item -Path $file.FullName -Destination $destination -Force
    Write-Host "Moved $($file.Name) -> $baseName/index.html"
}

Write-Host "`nAll files moved. Now fixing links and asset paths..." -ForegroundColor Cyan

$allHtmlFiles = Get-ChildItem -Path . -Filter "index.html" -Recurse
$allHtmlFiles += Get-ChildItem -Path . -Filter "index.html" -File
$allHtmlFiles = $allHtmlFiles | Sort-Object FullName -Unique

foreach ($file in $allHtmlFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    foreach ($oldName in $renameMap.Keys) {
        $newPath = $renameMap[$oldName]
        $pattern = [regex]::Escape($oldName)
        $content = $content -replace "href=`"$pattern`"", "href=`"$newPath`""
        $content = $content -replace "href='$pattern'", "href='$newPath'"
    }
    $content = $content -replace 'href="favicon\.jpg"', 'href="/favicon.jpg"'
    $content = $content -replace "href='favicon\.jpg'", "href='/favicon.jpg'"
    Set-Content -Path $file.FullName -Value $content -NoNewline
}

Write-Host "`nDone. Every internal link and favicon reference has been updated." -ForegroundColor Green
