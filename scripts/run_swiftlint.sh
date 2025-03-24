#!/bin/bash

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo "SwiftLint is not installed. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Please install Homebrew first."
        echo "Visit https://brew.sh for installation instructions."
        exit 1
    fi
    brew install swiftlint
fi

# Navigate to the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
cd "$PROJECT_ROOT"

echo "Running SwiftLint..."
echo "===================="

# Run SwiftLint and capture output to parse for warnings count
LINT_OUTPUT=$(swiftlint --config .swiftlint.yml 2>&1)
EXIT_CODE=$?
echo "$LINT_OUTPUT"

# Extract warning count from last line
WARNING_COUNT=$(echo "$LINT_OUTPUT" | grep -o 'Found [0-9]* violations' | grep -o '[0-9]*')
SERIOUS_COUNT=$(echo "$LINT_OUTPUT" | grep -o '[0-9]* serious' | grep -o '[0-9]*')

echo "===================="
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "✅ SwiftLint completed with $WARNING_COUNT warnings, $SERIOUS_COUNT serious issues."
else
    echo "⚠️ SwiftLint found $SERIOUS_COUNT serious issues. Exit code: $EXIT_CODE"
    echo "Fix the issues or update the configuration in .swiftlint.yml"
fi

# Run SwiftLint in autocorrect mode if requested
if [ "$1" == "--fix" ]; then
    echo ""
    echo "Attempting to automatically fix issues..."
    echo "===================="
    swiftlint --fix --config .swiftlint.yml
    echo "===================="
    echo "Autocorrection completed. Please review the changes."
fi 