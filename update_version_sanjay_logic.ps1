# Fetch tags from remote
git fetch --tags

# Get the latest tag, or use the base tag if no tags exist
$latestTag = git describe --tags $(git rev-list --tags --max-count=1) 2>$null

if (-not $latestTag) {
    $latestTag = "0.0.0"
}

# Extract the version part of the latest tag
$versionPart = $latestTag -match '[0-9]+\.[0-9]+\.[0-9]+' | Out-Null
$versionPart = $matches[0]

# Parse the version into major, minor, and patch
$versionParts = $versionPart -split '\.'
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$patch = [int]$versionParts[2]

# Get the latest commit message
$latestCommitMessage = git log -1 --pretty=%B

# Debugging: Output the latest commit message
Write-Output "Latest commit message: $latestCommitMessage"

# Determine the environment and increment type
if ($latestCommitMessage -like "*dev-feat*") {
    $env = "Dev"
    $minor++
    $patch = 0
} elseif ($latestCommitMessage -like "*dev-fix*") {
    $env = "Dev"
    $patch++
} elseif ($latestCommitMessage -like "*qa-feat*") {
    $env = "Qa"
    $minor++
    $patch = 0
} elseif ($latestCommitMessage -like "*qa-fix*") {
    $env = "Qa"
    $patch++
} elseif ($latestCommitMessage -like "*prod-breakout*") {
    $env = "Prod"
    $major++
    $minor = 0
    $patch = 0
} else {
    Write-Output "No version change needed."
    exit 0
}

# Construct the new version
$newVersion = "$major.$minor.$patch"

# Construct the new tag
$newTag = "$env/feature-$newVersion"

# Debugging: Output the new version and new tag
Write-Output "New version: $newVersion"
Write-Output "New tag: $newTag"

# Create a new tag
git tag -a "$newTag" -m "Release $newTag"

# Encode the GIT_PAT using base64
$encodedPat = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(":$env:GIT_PAT"))

# Push the new tag to remote
git -c http.extraHeader="Authorization: Basic $encodedPat" push origin "$newTag"

# Output the new version
Write-Output "##vso[build.updatebuildnumber]$newVersion"
Write-Output "Version updated to $newVersion"

