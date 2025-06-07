# Killed by Scrum.org

A tribute and log of initiatives, tools, and programmes discontinued by Scrum.org.

<div align="center">

[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](/LICENSE)

</div>

## Contribute

To add a discontinued Scrum.org initiative, gather the following information:

- Name (`title`) – Name of the initiative, programme, or tool
- Launch Date (`birth_date`) – Approximate or exact launch date (YYYY-MM-DD)
- Discontinued Date (`death_date`) – Date it was discontinued or de-emphasised (YYYY-MM-DD)
- Description (`description`) – One-sentence summary of what it was
- Link (`url`) – Relevant source confirming its launch or discontinuation

If you are not familiar with or do not want to use `git`, submit a [new issue](https://github.com/MrHinsh/killed-by-scrum-org/issues/new?template=add-an-obituary.md) requesting the change. If you are comfortable with `git`, follow these steps:

1. Fork this repository.
2. Create a new branch named after the initiative you're adding.
3. Open the `site\data\register.json` file and add the new entry manually.
4. Commit your changes and open a Pull Request (PR) using the new branch.

**Note**: GitHub discussions will be automatically created for new obituaries during the next deployment.

For contributions beyond `site\data\register.json`, see the [Contributing Guide](.github/CONTRIBUTING.md).

## Environments

- [Production](https://lemon-stone-0045b7f10.6.azurestaticapps.net)
- [Preview](https://lemon-stone-0045b7f10-preview.centralus.6.azurestaticapps.net/)
- Canary - There can be 2 canary environments at once that are built from Pull Requests. They are in the form https://lemon-stone-0045b7f10-{PullRequestId}.centralus.6.azurestaticapps.net/

Pull Requests automatically spawn environments. However, PR's from forks require approval to run.

## Editorial Guidelines

#### Description

Use a single sentence starting with the name of the initiative. For example:  
`"Agility Path was a continuous improvement framework based on the Evidence-Based Management approach."`

This will be shown as:  
“Killed in 2024, Agility Path was a continuous improvement framework based on the Evidence-Based Management approach.”

Write in the past tense. Be respectful and accurate.

#### Link

Link to a source confirming its existence and end-of-life, ideally from Scrum.org or a credible archive (e.g., archive.org, news, or training partners). Avoid internal marketing links or dead product pages.

---

Help us document the evolution of the Scrum.org ecosystem by capturing its discontinued efforts with clarity and respect.

## Technical Details

### Features

- **Interactive Obituaries**: Each discontinued initiative is displayed with tombstone or guillotine imagery
- **GitHub Discussions**: Community discussions are automatically created for each obituary
- **Hugo-Powered**: Fast, static site generation with responsive design
- **Automated Workflow**: PowerShell script manages GitHub discussions integration

### Contributing (Technical)

For technical contributors working on the site itself:

1. Fork this repository
2. Make your changes to the appropriate files
3. Test locally using the development workflow below
4. Submit a Pull Request

See the [Contributing Guide](.github/CONTRIBUTING.md) for detailed guidelines.

### Building and Development

#### Development Server

```powershell
hugo serve --source site --config hugo.yaml,hugo.local.yaml
```

#### Production Build

```powershell
hugo --source site --config hugo.yaml
```

#### Testing Changes

Run the development server and access the site at `http://localhost:1313` for live reload during development.

### GitHub Discussions Integration (PowerShell)

This site automatically creates GitHub discussions for each obituary. The integration is managed via a PowerShell script:

```powershell
.\.powershell\Create-GitHubDiscussions.ps1
```

**Requirements:**

- Set the `HUGO_GITHUB_TOKEN` environment variable with a GitHub Personal Access Token
- Token needs `public_repo` or `repo` scope (not just `write:discussion`)
- GitHub Discussions must be enabled on the repository
- An "Obituary" category must exist in GitHub Discussions

**How it works:**

1. Scans `site/data/register.json` for obituaries without `discussionId`
2. Creates GitHub discussions in the "Obituary" category
3. Updates the JSON file with `discussionId` and `discussionUrl` fields
4. Hugo templates automatically display discussion buttons for linked obituaries

The script is idempotent - you can run it multiple times safely. It will skip obituaries that already have discussions.
