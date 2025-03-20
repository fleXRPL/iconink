#!/bin/bash

# IconInk Build and Test Script
# This script runs SwiftLint and builds the project for iPhone 16 Pro simulator
# without writing to log files

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
XCODE_PROJECT_DIR="$PROJECT_ROOT/iconink"

# Change to project root
cd "$PROJECT_ROOT" || { echo -e "${RED}Error: Could not navigate to project root directory${NC}"; exit 1; }

echo -e "${BLUE}=== IconInk Build and Test ===${NC}"
echo -e "${BLUE}Starting build process for IconInk...${NC}"
echo -e "${BLUE}Project root: $PROJECT_ROOT${NC}"
echo -e "${BLUE}Xcode project directory: $XCODE_PROJECT_DIR${NC}"

# Step 1: Run SwiftLint
echo -e "${YELLOW}Step 1: Running SwiftLint...${NC}"
bash "$SCRIPT_DIR/run_swiftlint.sh"
LINTING_RESULT=$?

if [ $LINTING_RESULT -ne 0 ]; then
    echo -e "${RED}SwiftLint checks failed. Please fix the issues before building.${NC}"
    exit 1
else
    echo -e "${GREEN}SwiftLint checks passed!${NC}"
fi

# Step 2: Clean Xcode build
echo -e "${YELLOW}Step 2: Cleaning Xcode build...${NC}"
cd "$XCODE_PROJECT_DIR" || { echo -e "${RED}Error: Could not navigate to Xcode project directory${NC}"; exit 1; }
xcodebuild clean
CLEAN_RESULT=$?

if [ $CLEAN_RESULT -ne 0 ]; then
    echo -e "${RED}Failed to clean Xcode build${NC}"
    exit 1
else
    echo -e "${GREEN}Xcode build cleaned successfully${NC}"
fi

# Step 3: Remove derived data
echo -e "${YELLOW}Step 3: Removing derived data...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/iconink-*
echo -e "${GREEN}Derived data removed${NC}"

# Step 4: Build the project
echo -e "${YELLOW}Step 4: Building project for iPhone 16 Pro simulator...${NC}"
xcodebuild -project iconink.xcodeproj -scheme iconink -configuration Debug -destination "platform=iOS Simulator,name=iPhone 16 Pro" clean build
BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
    echo -e "${RED}Build failed. See output above for details.${NC}"
    exit 1
else
    echo -e "${GREEN}Build completed successfully!${NC}"
fi

# Return to project root directory
cd "$PROJECT_ROOT" || { echo -e "${RED}Error: Could not navigate back to project root directory${NC}"; exit 1; }

echo -e "${BLUE}=== Build and Test Process Complete ===${NC}" 