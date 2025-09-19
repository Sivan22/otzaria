#!/bin/bash

# Script to validate that the current version follows semantic versioning (semver)
# This script is used to ensure tags created are semver compliant

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Semantic Versioning Validator ==="
echo

# Read version from pubspec.yaml
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found!${NC}"
    exit 1
fi

VERSION=$(grep '^version:' pubspec.yaml | cut -d ' ' -f 2 | cut -d '+' -f 1)

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Could not extract version from pubspec.yaml${NC}"
    exit 1
fi

echo "Current version: $VERSION"
echo

# Semver regex pattern (according to https://semver.org/)
SEMVER_REGEX='^([0-9]+)\.([0-9]+)\.([0-9]+)(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'

if echo "$VERSION" | grep -qE "$SEMVER_REGEX"; then
    echo -e "${GREEN}✓ Version '$VERSION' is valid semver format${NC}"
    
    # Extract components
    MAJOR=$(echo "$VERSION" | sed -E 's/^([0-9]+)\..*/\1/')
    MINOR=$(echo "$VERSION" | sed -E 's/^[0-9]+\.([0-9]+)\..*/\1/')
    PATCH=$(echo "$VERSION" | sed -E 's/^[0-9]+\.[0-9]+\.([0-9]+).*/\1/')
    
    echo "  Major: $MAJOR"
    echo "  Minor: $MINOR"
    echo "  Patch: $PATCH"
    
    # Check for pre-release
    if echo "$VERSION" | grep -q '-'; then
        PRERELEASE=$(echo "$VERSION" | sed -E 's/^[0-9]+\.[0-9]+\.[0-9]+-([^+]*).*/\1/')
        echo "  Pre-release: $PRERELEASE"
    fi
    
    # Check for build metadata
    if echo "$VERSION" | grep -q '+'; then
        BUILD=$(echo "$VERSION" | sed -E 's/^[^+]*\+(.*)$/\1/')
        echo "  Build metadata: $BUILD"
    fi
    
    echo
    echo -e "${GREEN}✓ Tags will be created in the following formats:${NC}"
    echo "  Main branch: v$VERSION"
    echo "  Dev branches: v$VERSION-dev.123 (where 123 is run number)"
    echo "  PR builds: v$VERSION-pr.45.123 (where 45 is PR number, 123 is run number)"
    
    exit 0
else
    echo -e "${RED}✗ Version '$VERSION' is NOT valid semver format${NC}"
    echo
    echo -e "${YELLOW}Valid semver examples:${NC}"
    echo "  1.0.0"
    echo "  1.2.3"
    echo "  1.0.0-alpha"
    echo "  1.0.0-alpha.1"
    echo "  1.0.0-alpha.1+build.123"
    echo "  1.0.0+build.123"
    echo
    echo -e "${YELLOW}Current version issues:${NC}"
    echo "  - Must follow MAJOR.MINOR.PATCH format"
    echo "  - Each component must be a non-negative integer"
    echo "  - Pre-release identifiers must be alphanumeric plus hyphens"
    echo "  - Build metadata must be alphanumeric plus hyphens"
    echo
    exit 1
fi
