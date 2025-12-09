#!/bin/bash
# jonathan_02_git.sh - Jonathan's git configuration

log_step "Configuring git aliases..."

# Check if aliases already exist
if git config --global --get alias.A &>/dev/null; then
    log_installed "Git aliases" "already configured"
    track_skipped "Git aliases"
else
    # Basic aliases
    git config --global alias.A "add -A"
    git config --global alias.cam "commit -am"
    git config --global alias.cm "commit -m"
    git config --global alias.chb "checkout -b"
    git config --global alias.ch "checkout"
    git config --global alias.chm "checkout main"
    git config --global alias.chms "checkout master"
    git config --global alias.main "checkout main"
    git config --global alias.master "checkout master"
    git config --global alias.up "checkout -"

    # Log with color and graph
    git config --global alias.l "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

    # Remote operations
    git config --global alias.pom '!git pull origin main'
    git config --global alias.pomr '!git pull origin main --rebase'
    git config --global alias.pusho '!git push origin "$(git symbolic-ref --short HEAD)"'
    git config --global alias.pullo '!git pull origin "$(git symbolic-ref --short HEAD)"'

    log_success "Git aliases configured"
    track_installed "Git aliases"
fi

# Configure fetch to auto-prune
if git config --global --get fetch.prune &>/dev/null; then
    log_installed "Git fetch.prune" "already configured"
else
    git config --global fetch.prune true
    log_success "Git fetch.prune enabled"
fi

# Set default branch to main
if git config --global --get init.defaultBranch &>/dev/null; then
    log_installed "Git init.defaultBranch" "already configured"
else
    git config --global init.defaultBranch main
    log_success "Git default branch set to main"
fi
