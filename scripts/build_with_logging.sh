#!/bin/bash

# Script to run a complete build process and log all output

# Get the absolute path to the project root (works regardless of where script is called from)
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Create logs directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/logs"

# Create a timestamp with format YYYY-MM-DD_HHMMSS
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
LOG_FILE="$PROJECT_ROOT/logs/build_log_${TIMESTAMP}.txt"

# Echo the start time and environment info to the log
echo "=== Build Started at $(date) ===" | tee -a "$LOG_FILE"
echo "=== Project Root: $PROJECT_ROOT ===" | tee -a "$LOG_FILE"
echo "=== macOS Version: $(sw_vers -productVersion) ===" | tee -a "$LOG_FILE"
echo "=== Xcode Version: $(xcodebuild -version | head -n 1) ===" | tee -a "$LOG_FILE"
echo "=== Swift Version: $(swift --version | head -n 1) ===" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Function to log a command with header and execute it
run_and_log() {
  local cmd="$1"
  echo "=== Running: $cmd ===" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
  # Execute the command and capture all output (stdout and stderr)
  eval "$cmd" 2>&1 | tee -a "$LOG_FILE"
  local status=${PIPESTATUS[0]}
  echo "" | tee -a "$LOG_FILE"
  echo "=== Command finished with status: $status ===" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
  return $status
}

# Run SwiftLint using the script in the scripts directory
run_and_log "bash $PROJECT_ROOT/scripts/run_swiftlint.sh"

# Change to the iconink directory (assuming the Xcode project is there)
cd "$PROJECT_ROOT/iconink" || {
  echo "Error: Cannot find iconink directory at $PROJECT_ROOT/iconink" | tee -a "$LOG_FILE"
  exit 1
}

# Clean Xcode build
run_and_log "xcodebuild clean"

# Remove derived data to ensure clean build
run_and_log "rm -rf ~/Library/Developer/Xcode/DerivedData/iconink-*"

# Build the project
run_and_log "xcodebuild -project iconink.xcodeproj -scheme iconink -configuration Debug -destination \"platform=iOS Simulator,name=iPhone 16 Pro\" clean build"

# Log the end time
echo "=== Build Completed at $(date) ===" | tee -a "$LOG_FILE"

# Report build outcome based on the final command's status
if [ $? -eq 0 ]; then
  echo "=== BUILD SUCCESSFUL ===" | tee -a "$LOG_FILE"
else
  echo "=== BUILD FAILED ===" | tee -a "$LOG_FILE"
fi

# Return to project root
cd "$PROJECT_ROOT" || true

echo "" | tee -a "$LOG_FILE"
echo "Log file saved to: $LOG_FILE" | tee -a "$LOG_FILE" 