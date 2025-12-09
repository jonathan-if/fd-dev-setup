# First Dollar Dev Setup

Automated macOS development environment setup for First Dollar engineering.

## Quick Start

Run this command on a fresh Mac:

```bash
curl -fsSL https://raw.githubusercontent.com/jonathan-if/fd-dev-setup/main/install.sh | bash
```

That's it! The installer will:
1. Ask where to create your dev folder (default: `~/fd`)
2. Download the setup scripts
3. Offer to start setup immediately
4. Prompt for any required information as needed (saved for future runs)

## What Gets Installed

### Required (Everyone)

| Category | Tools |
|----------|-------|
| Prerequisites | Xcode CLT, Rosetta 2 (Apple Silicon) |
| CLI Tools | wget, docker, docker-compose, colima, git-crypt, jq, Claude CLI, gcloud |
| Node.js | nvm, Node.js (from fd-backend/.nvmrc) |
| Apps | VSCode, Slack, Chrome, Firefox, 1Password, SQL GUI (choice) |
| VSCode Extensions | Claude Code, ESLint, Prettier |
| Repos | fd-backend, fd-web, fd-admin-web |

### Optional Profiles

Run with `--profile <name>` to include personal preferences.

**jonathan**: oh-my-zsh, lsd, ripgrep, Hack Nerd Font, shell aliases, git aliases, Zoom

## Options

```bash
./setup.sh [OPTIONS]

--profile <name>   Include optional profile(s) (comma-separated or multiple flags)
--auto-update      Auto-update all outdated packages
--skip-updates     Skip updates, only install missing packages
--manual-apps      Show download URLs instead of using Homebrew
--list-profiles    List available profiles
--help             Show help
```

## Creating Your Own Profile

1. Create scripts in `scripts/optional/` with naming pattern `<yourname>_XX_<description>.sh`
2. Use existing scripts as templates
3. Number scripts to match install order (00=foundational, 03=cli, 06=apps, 08=vscode)

Example:
```
scripts/optional/
├── alice_00_shell.sh
├── alice_03_cli_tools.sh
└── alice_08_vscode.sh
```

## Post-Setup Manual Steps

1. Sign in to GitHub: `gh auth login` or set up SSH keys
2. Request access from IT (#it-support):
   - GCP/Firebase
   - Jira/Confluence
   - Sentry
   - FD admin dev account
3. In each cloned repo: `npm install`
4. In fd-backend:
   - `npm run docker` (start local database)
   - `npm run dbMigrateToLatest`

## Troubleshooting

**Script fails with permission error:**
```bash
chmod 755 setup.sh
```

**Homebrew not found after install:**
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Docker commands fail:**
```bash
colima start
```
