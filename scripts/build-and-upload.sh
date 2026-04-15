#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVE_PATH="$PROJECT_DIR/build/MyMedTimer.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
API_KEY="SQNHUVE5KO9T"
API_ISSUER="60591b19-a2c9-483d-85ab-152ef759da2f"
API_KEY_PATH="$HOME/Downloads/ApiKey_${API_KEY}.p8"

echo "=== Generating Xcode project ==="
cd "$PROJECT_DIR"
tuist generate --no-open

echo "=== Cleaning ==="
rm -rf "$PROJECT_DIR/build"

echo "=== Archiving ==="
xcodebuild archive \
    -project "$PROJECT_DIR/MyMedTimer.xcodeproj" \
    -scheme MyMedTimer \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=iOS' \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$API_KEY_PATH" \
    -authenticationKeyID "$API_KEY" \
    -authenticationKeyIssuerID "$API_ISSUER" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=H82APH3TK5

echo "=== Exporting ==="
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$PROJECT_DIR/ExportOptions.plist" \
    -exportPath "$EXPORT_PATH" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$API_KEY_PATH" \
    -authenticationKeyID "$API_KEY" \
    -authenticationKeyIssuerID "$API_ISSUER"

echo "=== Uploading to TestFlight ==="
xcrun altool --upload-app \
    --type ios \
    --file "$EXPORT_PATH/MyMedTimer.ipa" \
    --apiKey "$API_KEY" \
    --apiIssuer "$API_ISSUER"

echo "=== Done! Check App Store Connect for processing status ==="
