#!/bin/bash

cd "$(dirname "$0")/.."

# icon with transparent background
SOURCE="iconink/Assets.xcassets/IconInk.imageset/IconInk.png"

DEST_DIR="iconink/Assets.xcassets/AppIcon.appiconset"

# Function to generate icon
generate_icon() {
    local size=$1
    local scale=$2
    local output_size=$((size * scale))
    local filename="IconInk-${size}@${scale}x.png"
    
    sips -z $output_size $output_size "$SOURCE" --out "$DEST_DIR/$filename"
    echo "Generated $filename ($output_size x $output_size)"
}

# Generate all required sizes
generate_icon 20 2  # 40x40
generate_icon 20 3  # 60x60
generate_icon 29 2  # 58x58
generate_icon 29 3  # 87x87
generate_icon 40 2  # 80x80
generate_icon 40 3  # 120x120
generate_icon 60 2  # 120x120
generate_icon 60 3  # 180x180

# Generate App Store icon (1024x1024)
cp "$SOURCE" "$DEST_DIR/IconInk-1024.png"
echo "Created IconInk-1024.png"

echo "All icons generated successfully!" 