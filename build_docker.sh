#!/bin/bash

# FlowKat GoAccess Docker Build Script
# This script prepares branding resources and builds the project using Docker.

set -e

# 1. Prepare Resources
echo "Preparing branding resources..."

# Create resources directory if it doesn't exist
mkdir -p resources

# Copy banner.txt to resources
if [ -f "banner.txt" ]; then
    cp banner.txt resources/banner.txt
    echo "✔ banner.txt copied to resources/"
else
    echo "✘ Error: banner.txt not found in root directory."
    exit 1
fi

# Convert 180x180.png to Base64 logo
if [ -f "180x180.png" ]; then
    if command -v base64 >/dev/null 2>&1; then
        base64 -w 0 180x180.png > resources/logo.base64
        echo "✔ 180x180.png converted to resources/logo.base64"
    else
        echo "✘ Error: 'base64' command not found."
        exit 1
    fi
else
    echo "✘ Error: 180x180.png not found in root directory."
    exit 1
fi

# 2. Build Docker Image
echo "Building Docker image 'goaccess-flowkat'..."
docker build -t goaccess-flowkat .

echo ""
echo "===================================================="
echo "✔ Build Successful!"
echo "You can run the container with:"
echo "  docker run --rm -it goaccess-flowkat [ARGS]"
echo "===================================================="
