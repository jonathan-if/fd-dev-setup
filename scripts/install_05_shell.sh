#!/bin/bash
# install_05_shell.sh - Basic shell configuration for nvm

ZSHRC="$HOME/.zshrc"

statusbar_update "Checking shell config..."

# Check if nvm config already exists in .zshrc
if grep -q "NVM_DIR" "$ZSHRC" 2>/dev/null; then
    log_installed "nvm shell config" "exists in .zshrc"
    track_skipped "nvm shell config"
    statusbar_item_done
else
    log_step "Adding nvm configuration to .zshrc..."
    statusbar_update "Configuring shell..."

    # Backup existing .zshrc
    if [[ -f "$ZSHRC" ]]; then
        cp "$ZSHRC" "$ZSHRC.backup.$(date +%Y%m%d%H%M%S)"
        log_info "Backed up existing .zshrc"
    fi

    # Add nvm configuration
    cat >> "$ZSHRC" << 'EOF'

# =============================================================================
# NVM Configuration (added by fd-dev-setup)
# =============================================================================
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Auto-switch node version based on .nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
        local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

        if [ "$nvmrc_node_version" = "N/A" ]; then
            nvm install
        elif [ "$nvmrc_node_version" != "$node_version" ]; then
            nvm use
        fi
    elif [ "$node_version" != "$(nvm version default)" ]; then
        echo "Reverting to nvm default version"
        nvm use default
    fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc
EOF

    log_success "nvm shell config added to .zshrc"
    track_installed "nvm shell config"
    statusbar_item_done
fi
