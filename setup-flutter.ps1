# Flutter Setup Script
Write-Host "Setting up Flutter..." -ForegroundColor Green

# Wait for download to complete
$zipFile = "C:\flutter\flutter-sdk.zip"
while (!(Test-Path $zipFile) -or (Get-Item $zipFile).Length -eq 0) {
    Write-Host "Waiting for Flutter download to complete..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}

Write-Host "Flutter SDK downloaded successfully!" -ForegroundColor Green

# Extract Flutter SDK
Write-Host "Extracting Flutter SDK..." -ForegroundColor Yellow
Expand-Archive -Path $zipFile -DestinationPath "C:\flutter" -Force
Remove-Item $zipFile -Force

# Add Flutter to PATH
$flutterPath = "C:\flutter\flutter\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($currentPath -notlike "*$flutterPath*") {
    Write-Host "Adding Flutter to PATH..." -ForegroundColor Yellow
    $newPath = if ($currentPath.EndsWith(";")) { 
        $currentPath + $flutterPath 
    } else { 
        $currentPath + ";" + $flutterPath 
    }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Flutter added to PATH successfully!" -ForegroundColor Green
} else {
    Write-Host "Flutter already in PATH" -ForegroundColor Green
}

Write-Host "`nFlutter installation completed!" -ForegroundColor Green
Write-Host "Please close and reopen your terminal, then run:" -ForegroundColor Yellow
Write-Host "flutter --version" -ForegroundColor Cyan
Write-Host "flutter doctor" -ForegroundColor Cyan