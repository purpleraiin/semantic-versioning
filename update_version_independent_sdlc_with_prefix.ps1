#!/bin/bash

# Fetch tags from remote
git fetch --tags

# Get the latest tag, or use the base tag if no tags exist
latest_tag=$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null)

if [ -z "$latest_tag" ]; then
  latest_tag="0.0.0"
fi

# Extract the version part of the latest tag
version_part=$(echo $latest_tag | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')

# Parse the version into major, minor, and patch
IFS='.' read -r -a version_parts <<< "$version_part"
major=${version_parts[0]}
minor=${version_parts[1]}
patch=${version_parts[2]}

# Get the latest commit message
latest_commit_message=$(git log -1 --pretty=%B)

# Determine the environment and version increment type
if [[ $latest_commit_message == dev-* ]]; then
  env="Dev"
elif [[ $latest_commit_message == qa-* ]]; then
  env="Qa"
elif [[ $latest_commit_message == prod-* ]]; then
  env="Prod"
fi

# Determine the version increment type
if [[ $latest_commit_message == *-breakout ]]; then
  major=$((major + 1))
  minor=0
  patch=0
elif [[ $latest_commit_message == *-feat ]]; then
  minor=$((minor + 1))
  patch=0
elif [[ $latest_commit_message == *-fix ]]; then
  patch=$((patch + 1))
else
  echo "No version change needed."
  exit 0
fi

# Construct the new version
new_version="$major.$minor.$patch"

# Construct the new tag
new_tag="$env/feature-$new_version"

# Create a new tag
git tag -a "$new_tag" -m "Release $new_tag"

# Push the new tag to remote
git -c http.extraHeader="Authorization: Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":$GIT_PAT")))" push origin "$new_tag"

# Output the new version
echo "##vso[build.updatebuildnumber]$new_version"
echo "Version updated to $new_version"
