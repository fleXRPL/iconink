#!/bin/bash
#
# IconInk Xcode Cleanup Script
# This script cleans up Xcode caches, derived data, and project build folders
# Use when experiencing build issues or after recovering project files
#

# Set colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Set project directory
PROJECT_DIR="/Users/garotconklin/garotm/fleXRPL/iconink"

echo -e "${BLUE}=== IconInk Xcode Cleanup Script ===${NC}"
echo "This script will clean up Xcode caches and derived data to resolve common build issues."
echo ""

# Warn the user about closing Xcode
echo -e "${YELLOW}WARNING: Please make sure Xcode is completely closed before proceeding.${NC}"
echo -e "Press ENTER to continue or CTRL+C to cancel..."
read

# Clear Xcode Derived Data
echo -e "${BLUE}Clearing Xcode Derived Data...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo -e "${GREEN}✓ Derived data cleared${NC}"

# Clear Xcode Caches
echo -e "${BLUE}Clearing Xcode Caches...${NC}"
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
echo -e "${GREEN}✓ Xcode caches cleared${NC}"

# Clear Project Build Folder
echo -e "${BLUE}Clearing Project Build Folder...${NC}"
rm -rf "$PROJECT_DIR/build"
echo -e "${GREEN}✓ Project build folder cleared${NC}"

# Reset Xcode Preferences (optional)
echo -e "${YELLOW}Would you like to reset Xcode preferences? This will reset all Xcode settings. (y/n)${NC}"
read RESET_PREFS

if [[ $RESET_PREFS == "y" || $RESET_PREFS == "Y" ]]; then
    echo -e "${BLUE}Resetting Xcode Preferences...${NC}"
    defaults delete com.apple.dt.Xcode
    echo -e "${GREEN}✓ Xcode preferences reset${NC}"
else
    echo -e "Skipping Xcode preferences reset."
fi

# Verify project file existence
echo -e "${BLUE}Verifying project file...${NC}"
XCODEPROJ_COUNT=$(find "$PROJECT_DIR" -name "*.xcodeproj" -type d | wc -l)

if [ "$XCODEPROJ_COUNT" -eq 0 ]; then
    echo -e "${RED}WARNING: No .xcodeproj file found in $PROJECT_DIR${NC}"
    echo -e "${RED}Please check if your Xcode project file is missing${NC}"
else
    XCODEPROJ_PATH=$(find "$PROJECT_DIR" -name "*.xcodeproj" -type d)
    echo -e "${GREEN}✓ Xcode project file found at: $XCODEPROJ_PATH${NC}"
fi

echo ""
echo -e "${GREEN}Cleanup complete!${NC}"
echo "You can now reopen Xcode and build your project."
echo ""
echo -e "${BLUE}If you continue to experience issues:${NC}"
echo "1. Ensure all files are properly added to the Xcode project"
echo "2. Check that the Core Data model is included in the build"
echo "3. Verify that all dependencies are correctly configured"
echo "" 