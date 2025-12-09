#!/bin/bash
# install_04_node.sh - nvm and Node.js

# Install nvm via Homebrew (statusbar_item_done called inside)
install_brew_package "nvm"

# Set up nvm directory
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"

# Source nvm
if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
    source "/opt/homebrew/opt/nvm/nvm.sh"
elif [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
    source "/usr/local/opt/nvm/nvm.sh"
fi

# Check if nvm is working
if ! command_exists nvm; then
    log_error "nvm not available - Node.js installation skipped"
    track_failed "nvm"
    statusbar_item_done
    return 1
fi

# Determine which Node version to install
# Priority: fd-backend/.nvmrc > LTS
NODE_VERSION=""
NVMRC_PATH="$HOME/dev/fd-backend/.nvmrc"

if [[ -f "$NVMRC_PATH" ]]; then
    NODE_VERSION=$(cat "$NVMRC_PATH" | tr -d '[:space:]')
    log_info "Found .nvmrc in fd-backend: v${NODE_VERSION}"
else
    NODE_VERSION="--lts"
    log_info "No .nvmrc found, will install LTS version"
fi

statusbar_update "Checking Node.js..."

# Check if this version is already installed
if [[ "$NODE_VERSION" != "--lts" ]]; then
    if nvm ls "$NODE_VERSION" 2>/dev/null | grep -q "$NODE_VERSION"; then
        current=$(node --version 2>/dev/null || echo "")
        log_installed "Node.js" "$current"
        track_skipped "Node.js"

        # Make sure it's the default
        nvm alias default "$NODE_VERSION" &>/dev/null
        statusbar_item_done
        return 0
    fi
fi

# Install Node.js
log_step "Installing Node.js ${NODE_VERSION}..."
statusbar_update "Installing Node.js..."
if nvm install "$NODE_VERSION" &>/dev/null; then
    nvm alias default "$NODE_VERSION" &>/dev/null
    version=$(node --version 2>/dev/null)
    log_success "Node.js ${GREY}(${version})${NC}"
    track_installed "Node.js"

    # Verify npm is available
    if command_exists npm; then
        npm_version=$(npm --version 2>/dev/null)
        log_installed "npm" "$npm_version"
    fi
else
    log_error "Node.js installation failed"
    track_failed "Node.js"
fi
statusbar_item_done
