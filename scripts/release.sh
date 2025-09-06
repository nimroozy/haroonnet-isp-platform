#!/bin/bash

# HaroonNet ISP Platform Release Script
# This script helps create a new release with proper tagging

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the version from VERSION file
VERSION=$(cat VERSION)

echo -e "${GREEN}🚀 HaroonNet ISP Platform Release Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "📦 Preparing to release version: ${YELLOW}$VERSION${NC}"
echo ""

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo -e "${YELLOW}⚠️  Warning: You are not on the main/master branch (current: $CURRENT_BRANCH)${NC}"
    read -p "Do you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Release cancelled${NC}"
        exit 1
    fi
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}❌ Error: You have uncommitted changes${NC}"
    echo "Please commit or stash your changes before releasing"
    exit 1
fi

# Create git tag
echo -e "${GREEN}📌 Creating git tag v$VERSION...${NC}"
git tag -a "v$VERSION" -m "Release version $VERSION

See CHANGELOG.md and RELEASE_NOTES.md for details."

echo -e "${GREEN}✅ Tag created successfully${NC}"
echo ""

# Show release summary
echo -e "${GREEN}📋 Release Summary:${NC}"
echo -e "   Version: ${YELLOW}$VERSION${NC}"
echo -e "   Tag: ${YELLOW}v$VERSION${NC}"
echo -e "   Branch: ${YELLOW}$CURRENT_BRANCH${NC}"
echo ""

echo -e "${GREEN}📝 Next steps:${NC}"
echo -e "   1. Push the tag: ${YELLOW}git push origin v$VERSION${NC}"
echo -e "   2. Push the branch: ${YELLOW}git push origin $CURRENT_BRANCH${NC}"
echo -e "   3. Create a GitHub release from the tag"
echo -e "   4. Build and push Docker images:"
echo -e "      ${YELLOW}docker-compose build${NC}"
echo -e "      ${YELLOW}docker-compose push${NC} (if using a registry)"
echo ""

echo -e "${GREEN}🎉 Release preparation complete!${NC}"