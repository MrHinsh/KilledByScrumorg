# Copilot Instructions for Killed by Scrum.org

This document contains important instructions for GitHub Copilot when working with this project.

## Project Overview

This is a Hugo-based static website for the "Killed by Scrum.org" project, which tracks obituaries of discontinued Scrum.org initiatives, tools, and programmes.

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
- `.powershell/` - PowerShell automation scripts

## Key Features

### GitHub Discussions Integration

- **Automated Discussion Creation**: PowerShell script `.powershell/Create-GitHubDiscussions.ps1` creates GitHub discussions
- **Data Integration**: Script adds `discussionId` and `discussionUrl` fields to obituaries in `site/data/register.json`
- **Template Integration**: Hugo templates read these fields directly to display discussion buttons
- **Category Management**: Creates discussions in the "Obituary" category
- **Idempotent Operation**: Safe to run multiple times, skips existing discussions

### Configuration

- GitHub repository is configured in `site.Params.githubRepo` (hugo.yaml)
- Currently set to: `https://github.com/MrHinsh/killed-by-scrumorg`

## Development Notes

### GitHub Discussions Workflow

**Prerequisites:**

1. Set `HUGO_GITHUB_TOKEN` environment variable with a GitHub Personal Access Token
2. Token must have `public_repo` or `repo` scope (not just `write:discussion`)
3. GitHub Discussions must be enabled on the repository
4. "Obituary" category must exist in GitHub Discussions

**Running the Script:**

```powershell
.\.powershell\Create-GitHubDiscussions.ps1
```

**How it works:**

1. The script scans `site/data/register.json` for obituaries without `discussionId` fields
2. Creates GitHub discussions for those obituaries in the "Obituary" category
3. Updates the JSON file with `discussionId` and `discussionUrl` fields
4. Hugo templates automatically display discussion buttons for linked obituaries
5. Script is idempotent - skips obituaries that already have discussion IDs

**Integration with Hugo:**

- Hugo templates check for `{{ if .discussionUrl }}` to conditionally show discussion buttons
- No Hugo functions or build-time API calls required
- All data is pre-populated in the JSON file by the PowerShell script

### Data Format

- Obituaries are stored in `site/data/register.json`
- Each obituary should have at least a `title`, `description`, `birth_date`, and `death_date` field
- Optional fields: `type`, `url`
- After running the PowerShell script, obituaries will have `discussionId` and `discussionUrl` fields

## Common Tasks

### Adding New Obituaries

1. Edit `site/data/register.json`
2. Add new obituary object with required fields (`title`, `description`, `birth_date`, `death_date`)
3. Run the PowerShell script to create discussions: `.\.powershell\Create-GitHubDiscussions.ps1`
4. Build the site with Hugo

### Creating GitHub Discussions

The PowerShell script automatically handles this:

```powershell
# Using environment variable (recommended)
.\.powershell\Create-GitHubDiscussions.ps1

# Or passing token directly
.\.powershell\Create-GitHubDiscussions.ps1 -GitHubToken "your-github-token"
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
- **Note**: No discussion function needed - discussions are handled via data fields

### Styling

- CSS: `site/static/css/style.css`
- Images: `site/static/images/`

### Content

- Homepage: `site/content/_index.md`
- Data: `site/data/register.json`

### PowerShell Scripts

- GitHub Discussions: `.powershell/Create-GitHubDiscussions.ps1`

## Important Notes

- Always use the correct Hugo command with `--source site` flag
- The project has multiple configuration files - use both `hugo.yaml` and `hugo.local.yaml` for development
- GitHub discussions are created via PowerShell script, not during Hugo build
- The site is statically generated - discussion data is pre-populated in JSON
- PowerShell script is idempotent and safe to run multiple times
- **Token Requirements**: GitHub token needs `public_repo` or `repo` scope, not just `write:discussion`
- **No backup files**: PowerShell script doesn't create backup files to avoid Hugo build conflicts
