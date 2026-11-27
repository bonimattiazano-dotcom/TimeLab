#!/bin/bash
# Crea dist/TimeLab.app e dist/TimeLab-<versione>.zip (firma ad-hoc, senza Developer ID).
# Funziona su macOS; su Linux crea comunque lo zip ma senza firma.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DIST="$ROOT/dist"
APP="$DIST/TimeLab.app"

rm -rf "$APP" "$DIST"/TimeLab-*.zip "$DIST"/TimeLab-*.zip.sha256
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

sed "s/@VERSION@/$VERSION/g" "$ROOT/app/Info.plist" > "$APP/Contents/Info.plist"
cp "$ROOT/app/launcher" "$APP/Contents/MacOS/launcher"
chmod +x "$APP/Contents/MacOS/launcher"
cp "$ROOT/app/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$ROOT/src/runner.applescript" "$APP/Contents/Resources/runner.applescript"
# l'editor con la versione scritta nel titolo
sed -e "s/TimeLab · versione beta/TimeLab $VERSION · beta/" -e "s/const APP_VERSION='@VERSION@'/const APP_VERSION='$VERSION'/" \
  "$ROOT/src/editor.html" > "$APP/Contents/Resources/index.html"
grep -q "const APP_VERSION='$VERSION'" "$APP/Contents/Resources/index.html" || { echo "versione non scritta nell'editor"; exit 1; }

python3 "$ROOT/scripts/build_web.py" "$ROOT/src/editor.html" "$DIST/timelab-web.html" >/dev/null

if command -v codesign >/dev/null 2>&1; then
  xattr -cr "$APP" 2>/dev/null || true
  codesign --force --deep --sign - "$APP"
fi
cd "$DIST"
if command -v ditto >/dev/null 2>&1; then
  ditto -c -k --sequesterRsrc --keepParent "TimeLab.app" "TimeLab-$VERSION.zip"
else
  zip -qry "TimeLab-$VERSION.zip" "TimeLab.app"
fi
# file di controllo per l'aggiornamento automatico: va allegato alla release insieme allo zip
if command -v shasum >/dev/null 2>&1; then shasum -a 256 "TimeLab-$VERSION.zip" > "TimeLab-$VERSION.zip.sha256"
else sha256sum "TimeLab-$VERSION.zip" > "TimeLab-$VERSION.zip.sha256"; fi
echo "Pronto: dist/TimeLab-$VERSION.zip + dist/TimeLab-$VERSION.zip.sha256 (allegali entrambi alla release)"
