@echo off
setlocal

echo ===========================
echo 🚀 Cleaning old build...
echo ===========================
flutter clean

echo ===========================
echo 📦 Getting dependencies...
echo ===========================
flutter pub get

echo ===========================
echo 🏗️  Building release APK...
echo ===========================
flutter build apk --release

echo ===========================
echo ✅ Build finished!
echo ===========================

REM Der Standardpfad zur APK
set APK_PATH=build\app\outputs\flutter-apk\app-release.apk

if exist "%APK_PATH%" (
    echo 🔍 APK gefunden unter: %APK_PATH%
    for %%F in ("%APK_PATH%") do (
        echo 📏 Dateigröße: %%~zF Bytes
        echo 🕓 Letzte Änderung: %%~tF
    )
) else (
    echo ❌ Keine APK gefunden! Prüfe den Build-Output.
)

pause
endlocal