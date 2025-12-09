#!/bin/bash
# install_02_homebrew.sh - Homebrew package manager

statusbar_update "Checking Homebrew..."

if command_exists brew; then
    version=$(brew --version | head -1 | awk '{print $2}')
    log_installed "Homebrew" "$version"
    track_skipped "Homebrew"

    # Update Homebrew
    if is_dry_run; then
        log_dry_run "update Homebrew"
    else
        statusbar_update "Updating Homebrew..."
        log_step "Updating Homebrew..."
        brew update &>/dev/null
        log_success "Homebrew updated"
    fi
    statusbar_item_done
else
    log_step "Installing Homebrew..."
    statusbar_update "Installing Homebrew..."

    # Homebrew install script (non-interactive)
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"

        # Also add to current shell profile for persistence
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi

    if command_exists brew; then
        version=$(brew --version | head -1 | awk '{print $2}')
        log_success "Homebrew ${GREY}(${version})${NC}"
        track_installed "Homebrew"
        statusbar_item_done
    else
        log_error "Homebrew installation failed"
        track_failed "Homebrew"
        statusbar_item_done

        # This is critical - can't continue without Homebrew
        echo ""
        echo -e "  ${RED}Cannot continue without Homebrew. Please install manually:${NC}"
        echo -e "  ${CYAN}https://brew.sh${NC}"
        exit 1
    fi
fi
