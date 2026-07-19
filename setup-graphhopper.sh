#!/bin/bash
# ============================================
# Rabt - GraphHopper Setup for GitHub Codespaces
# ============================================

set -e

echo "Rabt GraphHopper Setup"
echo "========================="

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Please install Docker first."
    exit 1
fi

# Navigate to backend directory
cd "$(dirname "$0")/backend"

# Check if Jordan map data exists
if [ ! -f "graphhopper-data/jordan-latest.osm.pbf" ]; then
    echo "Downloading Jordan map data..."
    curl -L -o graphhopper-data/jordan-latest.osm.pbf https://download.geofabrik.de/asia/jordan-latest.osm.pbf
fi

# Ensure graph-cache dir exists
mkdir -p graphhopper-data/graph-cache

# Stop any existing container
docker stop rabt_graphhopper_jo 2>/dev/null || true
docker rm rabt_graphhopper_jo 2>/dev/null || true

# Start GraphHopper
echo "Starting GraphHopper..."
docker-compose up -d graphhopper

# Wait for GraphHopper to be ready
echo "Waiting for GraphHopper to start..."
MAX_RETRIES=60
RETRY_COUNT=0

until curl -s http://localhost:8989/health > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "GraphHopper failed to start after $MAX_RETRIES seconds"
        docker-compose logs graphhopper
        exit 1
    fi
    echo "   Waiting... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

# Test GraphHopper
echo ""
echo "GraphHopper is running!"
echo ""
echo "Health check:"
curl -s http://localhost:8989/health
echo ""
echo ""
echo "Test route (Amman to Zarqa):"
curl -s "http://localhost:8989/route?point=31.9539,35.9106&point=32.0710,36.1028&profile=car" | head -c 200
echo ""
echo ""

# Get Codespace URL
if [ -n "$CODESPACE_NAME" ]; then
    CODESPACE_URL="https://${CODESPACE_NAME}-8989.app.github.dev"
    echo "============================================"
    echo "Your GraphHopper URL:"
    echo "   $CODESPACE_URL"
    echo ""
    echo "IMPORTANT: Make port public with:"
    echo "   gh codespace ports visibility 8989:public"
    echo ""
    echo "Update this URL in Render environment:"
    echo "   GRAPHHOPPER_URL=$CODESPACE_URL"
    echo "============================================"
else
    echo "Not running in Codespace"
    echo "GraphHopper available at: http://localhost:8989"
fi
