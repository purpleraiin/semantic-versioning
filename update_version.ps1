# Fetch tags from remote
git fetch --tags

# Get the latest tag, or use the base tag if no tags exist
$latestTag = git describe --tags (git rev-list --tags --max-count=1) 2>$null

if (-not $latestTag) {
  $latestTag = "1.0.0"
}

# Parse the version into major, minor, and patch
$versionParts = $latestTag -split '\.'
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$patch = [int]$versionParts[2]

# Get the latest commit message
$latestCommitMessage = git log -1 --pretty=%B

# Determine the version increment type
if ($latestCommitMessage -like "*breakout*") {
  $major++
  $minor = 0
  $patch = 0
} elseif ($latestCommitMessage -like "*feat*") {
  $minor++
  $patch = 0
} elseif ($latestCommitMessage -like "*fix*") {
  $patch++
} else {
  Write-Output "No version change needed."
  exit 0
}

# Construct the new version
$newVersion = "$major.$minor.$patch"

# Create a new tag
git tag -a "$newVersion" -m "Release $newVersion"

# Push the new tag to remote
git -c http.extraHeader="Authorization: Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":$env:GIT_PAT")))" push origin "$newVersion"

# Output the new version
Write-Output "##vso[build.updatebuildnumber]$newVersion"
Write-Output "Version updated to $newVersion"
