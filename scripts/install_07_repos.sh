#!/bin/bash
# install_07_repos.sh - Clone First Dollar repositories

# Use DEV_DIR from environment if set (by install.sh), otherwise default
DEV_DIR="${DEV_DIR:-$HOME/fd}"

# Ensure dev directory exists
mkdir -p "$DEV_DIR"

# Repository list
REPOS=(
    "fd-backend"
    "fd-web"
    "fd-admin-web"
)

# Check if GitHub CLI is available and authenticated
gh_authenticated() {
    if command_exists gh && gh auth status &>/dev/null; then
        return 0
    fi
    return 1
}

# Check if SSH keys are available
ssh_available() {
    [[ -f "$HOME/.ssh/id_rsa" ]] || [[ -f "$HOME/.ssh/id_ed25519" ]]
}

# Configure git user if not already configured
configure_git_user() {
    local current_name=$(git config --global user.name 2>/dev/null)
    local current_email=$(git config --global user.email 2>/dev/null)

    # If both already configured, use existing values
    if [[ -n "$current_name" ]] && [[ -n "$current_email" ]]; then
        log_installed "Git user" "${current_name} <${current_email}>"
        return 0
    fi

    echo ""
    log_step "Git user configuration required for commits"

    # Prompt for name
    if [[ -z "$current_name" ]]; then
        GIT_USER_NAME=$(prompt_and_save "GIT_USER_NAME" "Your full name")
        if [[ "$GIT_USER_NAME" != "__DRY_RUN_PLACEHOLDER__" ]]; then
            git config --global user.name "$GIT_USER_NAME"
        fi
    fi

    # Prompt for email
    if [[ -z "$current_email" ]]; then
        echo ""
        echo -e "  ${GREY}Tip: If you have 'Keep my email private' enabled on GitHub,${NC}"
        echo -e "  ${GREY}use your GitHub noreply email: username@users.noreply.github.com${NC}"
        GIT_USER_EMAIL=$(prompt_and_save "GIT_USER_EMAIL" "Your git email" "email")
        if [[ "$GIT_USER_EMAIL" != "__DRY_RUN_PLACEHOLDER__" ]]; then
            git config --global user.email "$GIT_USER_EMAIL"
        fi
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        log_success "Git user configured"
    fi
}

# Clone a repository
clone_repo() {
    local repo="$1"
    local target_dir="$DEV_DIR/$repo"

    statusbar_update "Checking $repo..."

    if [[ -d "$target_dir" ]]; then
        log_installed "$repo" "already cloned"
        track_skipped "$repo"
        statusbar_item_done
        return 0
    fi

    # Dry-run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "clone $repo to $target_dir"
        statusbar_item_done
        return 0
    fi

    log_step "Cloning $repo..."
    statusbar_update "Cloning $repo..."

    local clone_url=""
    local clone_success=false

    # Try methods in order: gh CLI, SSH, HTTPS
    if gh_authenticated; then
        if gh repo clone "firstdollar/$repo" "$target_dir" &>/dev/null; then
            clone_success=true
        fi
    fi

    if [[ "$clone_success" == "false" ]] && ssh_available; then
        clone_url="git@github.com:firstdollar/$repo.git"
        if git clone "$clone_url" "$target_dir" &>/dev/null; then
            clone_success=true
        fi
    fi

    if [[ "$clone_success" == "false" ]]; then
        # HTTPS - may require GitHub username for private repos
        clone_url="https://github.com/firstdollar/$repo.git"
        if git clone "$clone_url" "$target_dir" 2>/dev/null; then
            clone_success=true
        fi
    fi

    if [[ "$clone_success" == "true" ]]; then
        log_success "$repo cloned"
        track_installed "$repo"
        statusbar_item_done
        return 0
    fi

    # Clone failed - offer help
    log_error "Failed to clone $repo"
    echo ""
    echo -e "  ${YELLOW}GitHub authentication required for private repos.${NC}"
    echo -e "  Options:"
    echo -e "    1. ${CYAN}gh auth login${NC} (recommended)"
    echo -e "    2. Set up SSH keys"
    echo -e "    3. Use a personal access token"
    echo ""

    track_failed "$repo"
    track_it_support "GitHub access for $repo"
    statusbar_item_done
    return 1
}

# Main execution
echo ""
log_info "Cloning First Dollar repositories to $DEV_DIR"

# Configure git user before cloning (needed for any future commits)
configure_git_user

echo ""

for repo in "${REPOS[@]}"; do
    clone_repo "$repo"
done

# Check if any repos were cloned and remind about npm install
cloned_count=0
for repo in "${REPOS[@]}"; do
    if [[ -d "$DEV_DIR/$repo" ]]; then
        ((cloned_count++))
    fi
done

if [[ $cloned_count -gt 0 ]]; then
    echo ""
    log_info "Remember to run 'npm install' in each cloned repository"
fi
