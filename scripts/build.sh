#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="dist/Ember.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Sources/Ember/Flame.metal "$APP/Contents/Resources/"

IFS=' ' read -r -a ARCHITECTURES <<< "${ARCHS:-$(uname -m)}"
BUILD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ember.XXXXXX")
trap 'rm -rf "$BUILD_DIR"' EXIT
BINARIES=()

for ARCH in "${ARCHITECTURES[@]}"; do
    BINARY="$BUILD_DIR/Ember-$ARCH"
    xcrun swiftc -O -swift-version 5 -target "$ARCH-apple-macosx13.0" \
        Sources/Ember/Renderer.swift Sources/Ember/Pomodoro.swift Sources/Ember/main.swift \
        -o "$BINARY"
    BINARIES+=("$BINARY")
done

if [[ ${#BINARIES[@]} -eq 1 ]]; then
    cp "${BINARIES[0]}" "$APP/Contents/MacOS/Ember"
else
    lipo -create "${BINARIES[@]}" -output "$APP/Contents/MacOS/Ember"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Ember</string>
<key>CFBundleIdentifier</key><string>local.ember.wallpaper</string>
<key>CFBundleName</key><string>Ember</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP"
echo "Built $APP"
