#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# --- Prerequisites Check ---
echo "Checking prerequisites..."

if ! command_exists git; then
  echo "Error: Git is not installed. Please install it (e.g., brew install git)." >&2
  exit 1
fi

if ! command_exists helm; then
  echo "Error: Helm is not installed. Please install it (e.g., brew install helm)." >&2
  exit 1
fi

if ! command_exists gh; then
  echo "Error: GitHub CLI (gh) is not installed. Please install it (e.g., brew install gh)." >&2
  exit 1
fi

# Check if gh is logged in
if ! gh auth status > /dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is not logged in. Please run 'gh auth login'." >&2
    exit 1
fi

echo "Prerequisites met."

# --- Version Argument ---
if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 1.2.3"
  exit 1
fi

VERSION=$1
RELEASE_TAG="vivaa-permify-$VERSION"
CHART_NAME="vivaa-permify" # Assuming this is the name in Chart.yaml
EXPECTED_PACKAGE_FILE="${CHART_NAME}-${VERSION}.tgz"
RELEASE_PACKAGE_FILE="${RELEASE_TAG}.tgz"

echo "Starting release process for version: $VERSION"
echo "Release tag: $RELEASE_TAG"

# --- Git State Check ---
echo "Checking Git repository state..."
if ! git diff --quiet HEAD; then
    echo "Error: Working directory is not clean. Please commit or stash your changes." >&2
    exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    read -p "Warning: You are not on the 'main' branch (current: $CURRENT_BRANCH). Continue anyway? (y/N): " confirm_branch
    if [[ ! "$confirm_branch" =~ ^[Yy]$ ]]; then
        echo "Aborting."
        exit 1
    fi
fi
echo "Git state checks passed."


# --- Chart.yaml Check ---
CHART_YAML_PATH="./charts/permify/Chart.yaml"
if [ ! -f "$CHART_YAML_PATH" ]; then
    echo "Error: $CHART_YAML_PATH not found." >&2
    exit 1
fi

echo "Please ensure the 'version' in '$CHART_YAML_PATH' is set to '$VERSION'."
read -p "Have you updated the version in Chart.yaml? (y/N): " confirm_yaml
if [[ ! "$confirm_yaml" =~ ^[Yy]$ ]]; then
    echo "Aborting. Please update $CHART_YAML_PATH first."
    exit 1
fi

# --- Release Steps ---

echo "1. Updating Helm dependencies..."
helm dependency update ./charts/permify

echo "2. Packaging Helm chart..."
helm package ./charts/permify

# Check if the expected package file exists
if [ ! -f "$EXPECTED_PACKAGE_FILE" ]; then
    echo "Error: Expected package file '$EXPECTED_PACKAGE_FILE' not found after 'helm package'." >&2
    echo "Please check the 'name' and 'version' in $CHART_YAML_PATH." >&2
    exit 1
fi

# Rename the package file for the release
echo "Renaming '$EXPECTED_PACKAGE_FILE' to '$RELEASE_PACKAGE_FILE'..."
mv "$EXPECTED_PACKAGE_FILE" "$RELEASE_PACKAGE_FILE"

echo "3. Committing and pushing changes..."
git add .
git commit -m "Release $RELEASE_TAG"
git push origin "$CURRENT_BRANCH" # Push to the current branch (might not be main)

echo "4. Tagging release..."
git tag "$RELEASE_TAG"
git push origin "$RELEASE_TAG"

echo "5. Creating GitHub release..."
gh release create "$RELEASE_TAG" ./"$RELEASE_PACKAGE_FILE" --notes "Release $RELEASE_TAG"

echo "----------------------------------------"
echo "Release $RELEASE_TAG created successfully!"
echo "----------------------------------------"

exit 0
