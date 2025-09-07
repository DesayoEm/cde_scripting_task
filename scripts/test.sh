#!/bin/bash

# Debug: Show current directory
echo "Current directory: $(pwd)"
echo "Looking for .env file..."

# Load environment variables
if [ -f ".env" ]; then
    echo "✅ .env file found"
    source .env
    echo "✅ Loaded configuration from .env file"
else
    echo "❌ ERROR: .env file not found in $(pwd)"
    ls -la
    exit 1
fi

# Debug: Print loaded variables
echo "DEBUG: CSV_URL = $CSV_URL"
echo "DEBUG: RAW_FOLDER = $RAW_FOLDER" 
echo "DEBUG: GOLD_FOLDER = $GOLD_FOLDER"