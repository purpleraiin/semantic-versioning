#!/bin/bash

# Fetch tags from remotee
git fetch --tags

# Get the latest tag, or use the base tag if no tags exist
latest_tag=$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null)

if [ -z "$latest_tag" ]; then
  latest_tag="1.0.0"
fi

# Parse the version into major, minor, and patch
IFS='.' read -r -a version_parts <<< "$latest_tag"
major=${version_parts[0]}
minor=${version_parts[1]}
patch=${version_parts[2]}

# Get the latest commit message
latest_commit_message=$(git log -1 --pretty=%B)

# Determine the version increment type
if [[ $latest_commit_message == *"breakout"* ]]; then
  major=$((major + 1))
  minor=0
  patch=0
elif [[ $latest_commit_message == *"feat"* ]]; then
  minor=$((minor + 1))
  patch=0
elif [[ $latest_commit_message == *"fix"* ]]; then
  patch=$((patch + 1))
else
  echo "No version change needed."
  exit 0
fi

# Construct the new version
new_version="$major.$minor.$patch"

# Create a new tag
git tag -a "$new_version" -m "Release $new_version"

# Encode PAT for HTTP header
B64_PAT=$(printf ":%s" "$GIT_PAT" | base64)

# Push the new tag to remote using the PAT
git -c http.extraHeader="Authorization: Basic ${B64_PAT}" push origin "$new_version"

# Output the new version
echo "Version updated to $new_version"

echo "##vso[build.updatebuildnumber]$new_version"
