#!/bin/bash

# Script to download Jordan OSM data for GraphHopper
# Run this script before starting Docker

set -e

DATA_DIR="./graphhopper-data"
JORDAN_PBF="$DATA_DIR/jordan-latest.osm.pbf"
URL="https://download.geofabrik.de/asia/jordan-latest.osm.pbf"

echo "=== Jordan OSM Data Downloader ==="
echo ""

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Check if data already exists
if [ -f "$JORDAN_PBF" ]; then
    echo "✓ Jordan OSM data already exists at: $JORDAN_PBF"
    echo "  File size: $(du -h "$JORDAN_PBF" | cut -f1)"
    echo ""
    echo "To re-download, delete the file first:"
    echo "  rm $JORDAN_PBF"
    exit 0
fi

echo "Downloading Jordan OSM data..."
echo "URL: $URL"
echo "Destination: $JORDAN_PBF"
echo ""

# Download with progress
if command -v wget &> /dev/null; then
    wget --progress=bar:force:noscroll -O "$JORDAN_PBF" "$URL"
elif command -v curl &> /dev/null; then
    curl -L --progress-bar -o "$JORDAN_PBF" "$URL"
else
    echo "Error: Neither wget nor curl is available"
    exit 1
fi

# Verify download
if [ -f "$JORDAN_PBF" ]; then
    echo ""
    echo "✓ Download completed successfully!"
    echo "  File size: $(du -h "$JORDAN_PBF" | cut -f1)"
    echo ""
    echo "Next steps:"
    echo "  1. Start GraphHopper: docker-compose up -d graphhopper"
    echo "  2. Wait for import to complete (check logs: docker logs -f rabt_graphhopper_jo)"
    echo "  3. Test: curl 'http://localhost:8989/route?point=31.9539,35.9106&point=32.0710,36.1028&profile=car'"
else
    echo ""
    echo "✗ Download failed!"
    exit 1
fi
