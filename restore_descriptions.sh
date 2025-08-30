#!/bin/bash

# Script to copy the English description to all language files
# This will restore the corrupted files with the updated English content

# Get all language directories (excluding review_information and en-US)
LANGUAGES=$(find fastlane/metadata -maxdepth 1 -type d -name "*" | grep -v "^fastlane/metadata$" | grep -v "review_information" | grep -v "en-US" | sort)

# Counter for tracking progress
TOTAL=$(echo "$LANGUAGES" | wc -l)
CURRENT=0

echo "Restoring descriptions for $TOTAL language files..."

for lang_dir in $LANGUAGES; do
    CURRENT=$((CURRENT + 1))
    lang_name=$(basename "$lang_dir")
    description_file="$lang_dir/description.txt"
    
    echo "[$CURRENT/$TOTAL] Restoring $lang_name..."
    
    # Copy the English description to each language file
    cp "fastlane/metadata/en-US/description.txt" "$description_file"
    
    echo "  ✅ Restored $lang_name"
done

echo "✅ All language descriptions restored with English content!"
echo "⚠️  IMPORTANT: You need to manually translate each language file now!"
