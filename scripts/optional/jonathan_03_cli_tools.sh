#!/bin/bash
# jonathan_03_cli_tools.sh - Jonathan's preferred CLI tools

# Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_installed "Oh My Zsh" "exists"
    track_skipped "Oh My Zsh"
else
    log_step "Installing Oh My Zsh..."
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended &>/dev/null; then
        log_success "Oh My Zsh"
        track_installed "Oh My Zsh"
    else
        log_error "Oh My Zsh installation failed"
        track_failed "Oh My Zsh"
    fi
fi

# Hack Nerd Font (required for lsd icons)
if [[ -f "$HOME/Library/Fonts/HackNerdFont-Regular.ttf" ]] || [[ -f "/Library/Fonts/HackNerdFont-Regular.ttf" ]]; then
    log_installed "Hack Nerd Font" "installed"
    track_skipped "Hack Nerd Font"
else
    log_step "Installing Hack Nerd Font..."
    if brew install --cask font-hack-nerd-font &>/dev/null; then
        log_success "Hack Nerd Font"
        track_installed "Hack Nerd Font"
        echo ""
        log_info "Configure your terminal to use 'Hack Nerd Font' for icons to display"
    else
        log_error "Hack Nerd Font installation failed"
        track_failed "Hack Nerd Font"
    fi
fi

# Additional CLI tools via Homebrew
install_brew_package "lsd"        # Modern ls replacement (uses nerd font icons)
install_brew_package "ripgrep"    # Fast grep replacement (rg)
install_brew_package "duf"        # Disk usage utility
install_brew_package "ncdu"       # NCurses disk usage
