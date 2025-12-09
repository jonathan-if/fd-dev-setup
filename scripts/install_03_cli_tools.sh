#!/bin/bash
# install_03_cli_tools.sh - Essential CLI tools via Homebrew

# Required CLI tools
install_brew_package "wget"
install_brew_package "docker"
install_brew_package "docker-compose"
install_brew_package "colima"
install_brew_package "git-crypt"
install_brew_package "jq"

# Claude Code CLI
statusbar_update "Checking Claude CLI..."
if command_exists claude; then
    version=$(claude --version 2>/dev/null | head -1 || echo "installed")
    log_installed "Claude CLI" "$version"
    track_skipped "Claude CLI"
    statusbar_item_done
else
    claude_choice=$(prompt_choice_or_default "How would you like to install Claude Code CLI?" "1" \
        "Standalone installer ${GREY}(recommended - installs to ~/.local/bin)${NC}" \
        "npm global package ${GREY}(tied to current Node/nvm version)${NC}" \
        "Skip ${GREY}(install later)${NC}")

    case "$claude_choice" in
        2)
            if is_dry_run; then
                log_dry_run "install Claude CLI via npm"
            else
                log_step "Installing Claude CLI via npm..."
                statusbar_update "Installing Claude CLI..."
                if npm install -g @anthropic-ai/claude-code &>/dev/null; then
                    log_success "Claude CLI (npm)"
                    track_installed "Claude CLI"
                else
                    log_error "Claude CLI installation failed"
                    track_failed "Claude CLI"
                fi
            fi
            ;;
        3)
            log_skip "Claude CLI"
            ;;
        *)
            if is_dry_run; then
                log_dry_run "install Claude CLI (standalone)"
            else
                log_step "Installing Claude CLI (standalone)..."
                statusbar_update "Installing Claude CLI..."
                if curl -fsSL https://claude.ai/install.sh | sh &>/dev/null; then
                    log_success "Claude CLI (standalone)"
                    track_installed "Claude CLI"
                else
                    log_error "Claude CLI installation failed"
                    track_failed "Claude CLI"
                fi
            fi
            ;;
    esac
    statusbar_item_done
fi

# Google Cloud SDK (cask)
statusbar_update "Checking Google Cloud SDK..."
if command_exists gcloud; then
    version=$(gcloud --version 2>/dev/null | head -1 | awk '{print $NF}')
    log_installed "Google Cloud SDK" "$version"
    track_skipped "Google Cloud SDK"
    statusbar_item_done
else
    log_step "Installing Google Cloud SDK..."
    statusbar_update "Installing Google Cloud SDK..."
    if brew install --cask google-cloud-sdk &>/dev/null; then
        # Source gcloud paths
        if [[ -f "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc" ]]; then
            source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
        fi
        version=$(gcloud --version 2>/dev/null | head -1 | awk '{print $NF}' || echo "installed")
        log_success "Google Cloud SDK ${GREY}(${version})${NC}"
        track_installed "Google Cloud SDK"
    else
        log_error "Google Cloud SDK failed to install"
        track_failed "Google Cloud SDK"
    fi
    statusbar_item_done
fi

# Configure Colima auto-start
statusbar_update "Configuring Colima..."
if command_exists colima; then
    # Check if already configured for auto-start
    if brew services list 2>/dev/null | grep -q "colima.*started"; then
        log_installed "Colima auto-start" "enabled"
    else
        colima_choice=$(prompt_choice_or_default "Colima is a Docker runtime. How should it start?" "1" \
            "Auto-start on login ${GREY}(recommended - always ready for dev work)${NC}" \
            "Manual start ${GREY}(run 'colima start' when needed)${NC}")

        if [[ "$colima_choice" != "2" ]]; then
            if is_dry_run; then
                log_dry_run "enable Colima auto-start"
            else
                log_step "Enabling Colima auto-start..."
                if brew services start colima &>/dev/null; then
                    log_success "Colima auto-start enabled"
                else
                    log_error "Failed to enable Colima auto-start"
                fi
            fi
        else
            log_info "Colima set to manual start (run 'colima start' when needed)"

            # Start it now for the rest of the setup (skip in dry-run)
            if ! is_dry_run && ! docker info &>/dev/null; then
                log_step "Starting Colima for setup..."
                colima start &>/dev/null
            fi
        fi
    fi

    # Ensure Docker is running for subsequent steps (skip in dry-run)
    if ! is_dry_run && ! docker info &>/dev/null; then
        log_step "Starting Colima..."
        colima start &>/dev/null
        if docker info &>/dev/null; then
            log_success "Colima started"
        else
            log_error "Failed to start Colima - Docker commands may not work"
        fi
    fi
    statusbar_item_done
fi
