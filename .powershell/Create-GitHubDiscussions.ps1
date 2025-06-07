# Create-GitHubDiscussions.ps1
# This script creates GitHub discussions for obituaries and updates the register.json file with discussion IDs

param(
    [Parameter(Mandatory = $false)]
    [string]$GitHubToken = $env:HUGO_GITHUB_TOKEN,
    
    [Parameter(Mandatory = $false)]
    [string]$SiteDataPath = "site/data/register.json",
    
    [Parameter(Mandatory = $false)]
    [string]$RepoOwner = "MrHinsh",
    
    [Parameter(Mandatory = $false)]
    [string]$RepoName = "killed-by-scrumorg",
    
    [Parameter(Mandatory = $false)]
    [string]$Category = "Obituary"
)

$ErrorActionPreference = 'Stop'

# Set script location as working directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptPath
Set-Location $repoRoot

Write-Host "Creating GitHub Discussions for obituaries..." -ForegroundColor Green
Write-Host "Repository: $RepoOwner/$RepoName" -ForegroundColor Cyan
Write-Host "Data file: $SiteDataPath" -ForegroundColor Cyan

# Validate parameters
if (-not $GitHubToken) {
    Write-Error "GitHub token not provided. Set HUGO_GITHUB_TOKEN environment variable or pass -GitHubToken parameter."
    exit 1
}

# Read the obituaries data
$dataFile = Join-Path $repoRoot $SiteDataPath
if (-not (Test-Path $dataFile)) {
    Write-Error "Data file not found: $dataFile"
    exit 1
}

Write-Host "Reading obituaries from: $dataFile" -ForegroundColor Yellow

try {
    $obituariesData = Get-Content $dataFile -Raw | ConvertFrom-Json
    Write-Host "Found $($obituariesData.Count) obituaries to process" -ForegroundColor Green
}
catch {
    Write-Error "Failed to parse JSON from $dataFile`: $($_.Exception.Message)"
    exit 1
}

# GitHub API headers
$headers = @{
    'Authorization' = "Bearer $GitHubToken"
    'Accept'        = 'application/vnd.github.v3+json'
    'Content-Type'  = 'application/json'
    'User-Agent'    = 'KilledByScrum-DiscussionCreator/1.0'
}

# Function to get repository ID
function Get-RepositoryId {
    param($repoOwner, $repoName)
    
    $repoUrl = "https://api.github.com/repos/$repoOwner/$repoName"
    
    try {
        $response = Invoke-RestMethod -Uri $repoUrl -Headers $headers -Method GET
        return $response.node_id
    }
    catch {
        Write-Warning "Failed to get repository ID: $($_.Exception.Message)"
        return $null
    }
}

# Function to get discussion categories using GraphQL
function Get-DiscussionCategories {
    param($repoOwner, $repoName)
    
    $graphqlQuery = @{
        query = "query { repository(owner: `"$repoOwner`", name: `"$repoName`") { discussionCategories(first: 20) { nodes { id name slug } } } }"
    }
    
    $graphqlHeaders = @{
        'Authorization' = "Bearer $GitHubToken"
        'Content-Type'  = 'application/json'
        'User-Agent'    = 'KilledByScrum-DiscussionCreator/1.0'
    }
    
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/graphql" -Headers $graphqlHeaders -Method POST -Body ($graphqlQuery | ConvertTo-Json)
        
        if ($response.errors) {
            Write-Warning "GraphQL errors getting categories: $($response.errors | ConvertTo-Json)"
            return @()
        }
        
        if ($response.data.repository.discussionCategories.nodes) {
            return $response.data.repository.discussionCategories.nodes
        }
        
        return @()
    }
    catch {
        Write-Warning "Failed to get discussion categories: $($_.Exception.Message)"
        return @()
    }
}

# Function to search for existing discussion
function Find-ExistingDiscussion {
    param($title, $repoOwner, $repoName)
    
    $searchQuery = "repo:$repoOwner/$repoName in:title `"$title`" type:discussion"
    $searchUrl = "https://api.github.com/search/issues?q=$([System.Uri]::EscapeDataString($searchQuery))"
    
    try {
        $response = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method GET
        if ($response.total_count -gt 0) {
            return $response.items[0]
        }
        return $null
    }
    catch {
        Write-Warning "Failed to search for discussion '$title': $($_.Exception.Message)"
        return $null
    }
}

# Function to create discussion using GraphQL
function New-GitHubDiscussion {
    param($title, $body, $repositoryId, $categoryId)
    
    $mutation = @{
        query     = "mutation(`$repositoryId: ID!, `$categoryId: ID!, `$title: String!, `$body: String!) { createDiscussion(input: {repositoryId: `$repositoryId, categoryId: `$categoryId, title: `$title, body: `$body}) { discussion { id url number } } }"
        variables = @{
            repositoryId = $repositoryId
            categoryId   = $categoryId
            title        = $title
            body         = $body
        }
    }
    
    $graphqlHeaders = @{
        'Authorization' = "Bearer $GitHubToken"
        'Content-Type'  = 'application/json'
        'User-Agent'    = 'KilledByScrum-DiscussionCreator/1.0'
    }
    
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/graphql" -Headers $graphqlHeaders -Method POST -Body ($mutation | ConvertTo-Json -Depth 10)
        
        if ($response.errors) {
            Write-Warning "GraphQL errors: $($response.errors | ConvertTo-Json)"
            return $null
        }
        
        if ($response.data.createDiscussion) {
            return $response.data.createDiscussion.discussion
        }
        
        return $null
    }
    catch {
        Write-Warning "Failed to create discussion '$title': $($_.Exception.Message)"
        return $null
    }
}

# Get repository ID
Write-Host "Getting repository information..." -ForegroundColor Yellow
$repositoryId = Get-RepositoryId $RepoOwner $RepoName
if (-not $repositoryId) {
    Write-Error "Failed to get repository ID for $RepoOwner/$RepoName"
    exit 1
}
Write-Host "Repository ID: $repositoryId" -ForegroundColor Green

# Get discussion categories
Write-Host "Getting discussion categories..." -ForegroundColor Yellow
$categories = Get-DiscussionCategories $RepoOwner $RepoName
$obituaryCategory = $categories | Where-Object { $_.slug -eq $Category.ToLower() }

if (-not $obituaryCategory) {
    Write-Warning "Category '$Category' not found. Available categories:"
    $categories | ForEach-Object { Write-Host "  - $($_.name) ($($_.slug))" -ForegroundColor Gray }
    
    # Try to find a suitable fallback category
    $generalCategory = $categories | Where-Object { $_.slug -eq "general" -or $_.name -eq "General" }
    if ($generalCategory) {
        Write-Host "Using 'General' category as fallback" -ForegroundColor Yellow
        $obituaryCategory = $generalCategory
    }
    else {
        Write-Error "No suitable category found. Please create an 'obituary' category in GitHub Discussions."
        exit 1
    }
}

Write-Host "Using category: $($obituaryCategory.name) (ID: $($obituaryCategory.id))" -ForegroundColor Green

# Track changes
$dataChanged = $false
$createdCount = 0
$skippedCount = 0
$errorCount = 0

# Process each obituary
foreach ($obituary in $obituariesData) {
    $title = $obituary.title
    Write-Host "`nProcessing: $title" -ForegroundColor Yellow
    
    # Check if discussion ID already exists
    if ($obituary.PSObject.Properties['discussionId'] -and $obituary.discussionId) {
        Write-Host "  → Discussion ID already exists: $($obituary.discussionId)" -ForegroundColor Gray
        $skippedCount++
        continue
    }
    
    # Search for existing discussion
    $existingDiscussion = Find-ExistingDiscussion $title $RepoOwner $RepoName
    if ($existingDiscussion) {
        Write-Host "  → Found existing discussion: $($existingDiscussion.html_url)" -ForegroundColor Green
        $obituary | Add-Member -NotePropertyName 'discussionId' -NotePropertyValue $existingDiscussion.number -Force
        $dataChanged = $true
        $skippedCount++
    }
    else {
        Write-Host "  → Creating new discussion..." -ForegroundColor Cyan
        
        # Create discussion body
        $body = @"
This is a discussion thread for the obituary: **$title**

$($obituary.description)

[View full obituary](https://killedbyscrumorg.com)

---

*This discussion was automatically generated for the Killed by Scrum.org project.*
"@
        # Create the discussion
        $newDiscussion = New-GitHubDiscussion $title $body $repositoryId $obituaryCategory.id
        if ($newDiscussion) {
            Write-Host "  ✓ Created discussion: $($newDiscussion.url)" -ForegroundColor Green
            $obituary | Add-Member -NotePropertyName 'discussionId' -NotePropertyValue $newDiscussion.number -Force
            $dataChanged = $true
            $createdCount++
            
            # Add a small delay to avoid rate limiting
            Start-Sleep -Milliseconds 500
        }
        else {
            Write-Host "  ✗ Failed to create discussion" -ForegroundColor Red
            $errorCount++
        }
    }
}

# Save updated data if changes were made
if ($dataChanged) {
    Write-Host "`nSaving updated data to $dataFile..." -ForegroundColor Yellow
    try {
        # Save updated data with proper formatting (no backup to avoid Hugo conflicts)
        $obituariesData | ConvertTo-Json -Depth 10 | Set-Content $dataFile -Encoding UTF8
        Write-Host "Data file updated successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to save updated data: $($_.Exception.Message)"
        exit 1
    }
}

# Summary
Write-Host "`nSummary:" -ForegroundColor Green
Write-Host "  Created: $createdCount discussions" -ForegroundColor Green
Write-Host "  Skipped: $skippedCount discussions (already exist or have IDs)" -ForegroundColor Yellow
Write-Host "  Errors:  $errorCount discussions" -ForegroundColor Red
Write-Host "  Total processed: $($obituariesData.Count) obituaries" -ForegroundColor Cyan

if ($dataChanged) {
    Write-Host "`nThe register.json file has been updated with discussion IDs." -ForegroundColor Green
    Write-Host "You can now rebuild your Hugo site to see the discussion links." -ForegroundColor Yellow
}

Write-Host "`nDone!" -ForegroundColor Green
