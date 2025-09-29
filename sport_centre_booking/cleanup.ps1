# Flutter Cleanup Script for Windows (Android + Web Development)
# Run this when you encounter file permission issues

Write-Host "Cleaning Flutter build artifacts..." -ForegroundColor Green

# Stop any running Flutter processes
Stop-Process -Name "flutter" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "dart" -Force -ErrorAction SilentlyContinue

# Clean Flutter
flutter clean

# Remove only problematic directories (keep android and web)
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Cleanup complete! You can now run 'flutter run' for Android or 'flutter run -d chrome' for web" -ForegroundColor Green