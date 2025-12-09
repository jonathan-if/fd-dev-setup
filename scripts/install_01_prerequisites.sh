#!/bin/bash
# install_01_prerequisites.sh - Xcode Command Line Tools and Rosetta 2

statusbar_update "Checking Xcode Command Line Tools..."

# Xcode Command Line Tools (includes git)
if xcode-select -p &>/dev/null; then
    version=$(xcode-select -v 2>/dev/null | awk '{print $NF}' || echo "unknown")
    log_installed "Xcode Command Line Tools" "$version"
    track_skipped "Xcode Command Line Tools"
    statusbar_item_done
else
    while true; do
        log_step "Installing Xcode Command Line Tools..."
        xcode-select --install 2>/dev/null

        # Wait for installation to complete
        echo ""
        echo -e "  ${YELLOW}Xcode Command Line Tools installer launched.${NC}"
        echo -e "  ${YELLOW}Please complete the installation in the popup window.${NC}"
        echo ""
        printf "  Press Enter when installation is complete..."
        tty_read

        if xcode-select -p &>/dev/null; then
            log_success "Xcode Command Line Tools"
            track_installed "Xcode Command Line Tools"
            break
        else
            log_error "Xcode Command Line Tools installation failed"
            if prompt_yes_no "Try again?" "y"; then
                continue
            else
                track_failed "Xcode Command Line Tools"
                break
            fi
        fi
    done
    statusbar_item_done
fi

statusbar_update "Checking Rosetta 2..."

# Rosetta 2 (only needed on Apple Silicon)
if [[ "$(uname -m)" == "arm64" ]]; then
    if /usr/bin/pgrep -q oahd; then
        log_installed "Rosetta 2" "running"
        track_skipped "Rosetta 2"
        statusbar_item_done
    elif [[ -f "/Library/Apple/usr/share/rosetta/rosetta" ]]; then
        log_installed "Rosetta 2" "installed"
        track_skipped "Rosetta 2"
        statusbar_item_done
    else
        log_step "Installing Rosetta 2 (required for some Docker images)..."
        if softwareupdate --install-rosetta --agree-to-license &>/dev/null; then
            log_success "Rosetta 2"
            track_installed "Rosetta 2"
        else
            log_error "Rosetta 2 installation failed"
            track_failed "Rosetta 2"
        fi
        statusbar_item_done
    fi
else
    log_info "Rosetta 2 not needed (Intel Mac)"
    statusbar_item_done
fi
