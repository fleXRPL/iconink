#!/bin/bash

# Change to script directory and then up one level to project root
cd "$(dirname "$0")/.."

echo "Running SwiftLint check..."
if ! ./scripts/run_swiftlint.sh; then
    echo "SwiftLint check failed. Attempting to auto-fix issues..."
    ./scripts/run_swiftlint.sh --fix
    echo "Re-running SwiftLint check after auto-fix..."
    if ! ./scripts/run_swiftlint.sh; then
        echo "SwiftLint check still failing after auto-fix. Please fix remaining issues manually."
        exit 1
    fi
    echo "Auto-fix successful!"
fi

echo "SwiftLint check passed. Proceeding with cleanup and fresh start of Xcode..."

# Check for running Xcode instances
if pgrep -x "Xcode" > /dev/null; then
    echo "Killing Xcode processes..."
    killall Xcode
    # Wait a moment to ensure Xcode is fully closed
    sleep 2
fi

echo "Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/iconink-*

# Ensure we're in the project directory
PROJECT_DIR="$(pwd)"
if [[ ! -d "$PROJECT_DIR/iconink" ]]; then
    echo "Error: Not in the correct project directory"
    exit 1
fi

echo "Starting Xcode..."
xed .

echo "Done! Xcode should be restarting with a clean environment." 