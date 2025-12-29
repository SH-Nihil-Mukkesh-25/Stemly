#!/bin/bash

# Exit on error
set -e

echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter installed at: `which flutter`"
flutter doctor -v

echo "Enabling web support..."
flutter config --enable-web

echo "Getting dependencies..."
flutter pub get

echo "Building specific web target..."
# Note: Using html renderer for better compatibility, or canvaskit for performance
flutter build web --release --web-renderer html

echo "Build complete."
