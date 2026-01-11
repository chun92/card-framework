#!/bin/bash
# Release creation script for Card Framework
# Usage: ./scripts/create-release.sh <version>
# Example: ./scripts/create-release.sh 1.3.1

set -e  # Exit on error

VERSION=$1
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Validate version argument
if [ -z "$VERSION" ]; then
    echo "Error: Version number required"
    echo "Usage: ./scripts/create-release.sh <version>"
    echo "Example: ./scripts/create-release.sh 1.3.1"
    exit 1
fi

# Validate version format (e.g., 1.3.1)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 1.3.1)"
    exit 1
fi

echo "=========================================="
echo "Creating release for version v${VERSION}"
echo "=========================================="

# Check if we're in the project root
if [ ! -f "project.godot" ]; then
    echo "Error: Must run from project root directory"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Warning: Uncommitted changes detected"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create releases directory if it doesn't exist
mkdir -p releases

# Output filename
OUTPUT_FILE="releases/card-framework-v${VERSION}-full.zip"

echo ""
echo "Step 1: Creating full project archive..."

# Create full project zip excluding unnecessary files
zip -r "$OUTPUT_FILE" . \
    -x ".git/*" \
    -x ".godot/*" \
    -x "*.import" \
    -x ".taskmaster/*" \
    -x ".vscode/*" \
    -x ".env" \
    -x "releases/*" \
    -x ".claude/*"

echo "✓ Created: $OUTPUT_FILE"

# Get file size
SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
echo "  File size: $SIZE"

echo ""
echo "Step 2: Verifying archive contents..."

# List archive contents to verify
echo "  Checking key directories..."
if unzip -l "$OUTPUT_FILE" | grep -q "addons/card-framework/"; then
    echo "  ✓ addons/card-framework/ found"
else
    echo "  ✗ addons/card-framework/ missing!"
    exit 1
fi

if unzip -l "$OUTPUT_FILE" | grep -q "example1/"; then
    echo "  ✓ example1/ found"
else
    echo "  ✗ example1/ missing!"
    exit 1
fi

if unzip -l "$OUTPUT_FILE" | grep -q "freecell/"; then
    echo "  ✓ freecell/ found"
else
    echo "  ✗ freecell/ missing!"
    exit 1
fi

if unzip -l "$OUTPUT_FILE" | grep -q "docs/"; then
    echo "  ✓ docs/ found"
else
    echo "  ✗ docs/ missing!"
    exit 1
fi

echo ""
echo "=========================================="
echo "Release archive created successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test the archive:"
echo "   unzip -q $OUTPUT_FILE -d test-extract/"
echo "   cd test-extract && godot project.godot"
echo ""
echo "2. Create git tag:"
echo "   git tag -a v${VERSION} -m \"Release v${VERSION}\""
echo "   git push origin v${VERSION}"
echo ""
echo "3. Create GitHub Release:"
echo "   - Go to: https://github.com/chun92/card-framework/releases/new"
echo "   - Tag: v${VERSION}"
echo "   - Title: Card Framework v${VERSION}"
echo "   - Upload: $OUTPUT_FILE"
echo ""
echo "4. Add release notes describing:"
echo "   - New features"
echo "   - Bug fixes"
echo "   - Breaking changes"
echo ""
echo "Archive location: $OUTPUT_FILE"
echo "=========================================="
