# Copilot Instructions for Killed by Scrum.org

This document contains important instructions for GitHub Copilot when working with this project.

## Project Overview

This is a Hugo-based static website for the "Killed by Scrum.org" project, which tracks obituaries of practices, people, and organizations affected by poor Scrum implementations.

## Build Commands

### Development Server

To run the Hugo development server:

```powershell
hugo serve --source site --config hugo.yaml,hugo.local.yaml
```

### Production Build

To build the site for production:

```powershell
hugo --source site --config hugo.yaml
```

## Project Structure

- `site/` - Hugo source code
  - `hugo.yaml` - Main Hugo configuration
  - `hugo.local.yaml` - Local development configuration (if exists)
  - `content/` - Markdown content files
  - `data/register.json` - Obituary data
  - `layouts/` - Hugo templates
  - `static/` - Static assets
- `public/` - Generated Hugo output (after build)

## Key Features

### GitHub Discussions Integration

- GitHub discussions are created using the PowerShell script `.powershell/Create-GitHubDiscussions.ps1`
- The script adds `discussionId` and `discussionUrl` fields to obituaries in `site/data/register.json`
- Hugo templates read these fields directly to display discussion buttons
- Creates discussions in the "obituary" category

### Configuration

- GitHub repository is configured in `site.Params.githubRepo` (hugo.yaml)
- Currently set to: `https://github.com/MrHinsh/killed-by-scrumorg`

## Development Notes

### GitHub Discussions Workflow

1. Run the PowerShell script: `.powershell/Create-GitHubDiscussions.ps1 -GitHubToken $env:HUGO_GITHUB_TOKEN`
2. The script creates GitHub discussions for obituaries that don't have them
3. The script updates `site/data/register.json` with `discussionId` and `discussionUrl` fields
4. Hugo reads these fields and displays discussion buttons automatically

### Data Format

- Obituaries are stored in `site/data/register.json`
- Each obituary should have at least a `title` and `description` field
- After running the PowerShell script, obituaries will have `discussionId` and `discussionUrl` fields

## Common Tasks

### Adding New Obituaries

1. Edit `site/data/register.json`
2. Add new obituary object with required fields
3. Run the PowerShell script to create discussions: `.powershell/Create-GitHubDiscussions.ps1 -GitHubToken $env:HUGO_GITHUB_TOKEN`
4. Build the site

### Creating GitHub Discussions

Run the PowerShell script with your GitHub token:

```powershell
.powershell/Create-GitHubDiscussions.ps1 -GitHubToken "your-github-token"
```

### Testing Changes

1. Use `hugo serve --source site --config hugo.yaml,hugo.local.yaml` for live reload
2. Access the site at `http://localhost:1313`

### Deployment

- The site uses Azure Static Web Apps
- Configuration files: `staticwebapp.config.*.json`
- Different configs for different environments (production, preview, canary)

## File Locations

### Hugo Templates

- Main page: `site/layouts/index.html`
- Base template: `site/layouts/_default/baseof.html`
- Discussion function: `site/layouts/partials/functions/Get-GithubDiscussionId.html`

### Styling

- CSS: `site/static/css/style.css`
- Images: `site/static/images/`

### Content

- Homepage: `site/content/_index.md`
- Data: `site/data/register.json`

## Important Notes

- Always use the correct Hugo command with `--source site` flag
- The project has multiple configuration files - use both `hugo.yaml` and `hugo.local.yaml` for development
- GitHub API integration happens at build time, not runtime
- The site is statically generated but can make API calls during the build process
