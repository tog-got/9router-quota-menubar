#!/bin/bash
set -euo pipefail

# Direktori proyek
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

APP_NAME="QuotaMenuBar"
APP_DISPLAY_NAME="9Router Tracker"
BUILD_DIR="$PROJECT_ROOT/build"
APP_BUNDLE="$BUILD_DIR/$APP_DISPLAY_NAME.app"
BIN_SRC="$PROJECT_ROOT/.build/release/$APP_NAME"

echo "=================================================="
echo "🚀 Memulai build release native ARM64: $APP_DISPLAY_NAME"
echo "=================================================="

# 1. Jalankan unit test
echo "🧪 Menjalankan unit tests suite..."
swift run QuotaTrackerCoreTestRunner

# 2. Build binary release untuk arm64
echo "🔨 Meng-compile Swift release binary..."
swift build -c release --arch arm64

if [ ! -f "$BIN_SRC" ]; then
    echo "❌ Binary $BIN_SRC tidak ditemukan!"
    exit 1
fi

# 3. Siapkan struktur bundle .app
echo "📦 Membuat bundle macOS .app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 4. Salin binary, Info.plist, dan Assets
cp "$BIN_SRC" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$PROJECT_ROOT/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
if [ -f "$PROJECT_ROOT/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_ROOT/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# 5. Bersihkan atribut extended & Codesign secara ad-hoc untuk macOS Apple Silicon
xattr -cr "$APP_BUNDLE"
echo "🔏 Menandatangani app bundle (ad-hoc codesign)..."
codesign --force --deep --sign - "$APP_BUNDLE"

# 6. Buat archive release .zip
cd "$BUILD_DIR"
rm -f "9RouterTracker-macOS-arm64.zip" "QuotaMenuBar-macOS-arm64.zip"
zip -r -y -q "9RouterTracker-macOS-arm64.zip" "$APP_DISPLAY_NAME.app"
cd "$PROJECT_ROOT"

echo "=================================================="
echo "✅ Build Sukses 100%!"
echo "📍 Lokasi App: $APP_BUNDLE"
echo "=================================================="
