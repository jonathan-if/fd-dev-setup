#!/bin/bash
# install_06_apps.sh - Desktop applications via Homebrew Cask

# App definitions: cask_name|app_name|download_url
REQUIRED_APPS=(
    "visual-studio-code|Visual Studio Code|https://code.visualstudio.com/download"
    "slack|Slack|https://slack.com/downloads/mac"
    "google-chrome|Google Chrome|https://www.google.com/chrome/"
    "firefox|Firefox|https://www.mozilla.org/firefox/new/"
    "1password|1Password|https://1password.com/downloads/mac/"
)

SQL_APPS=(
    "beekeeper-studio|Beekeeper Studio|https://www.beekeeperstudio.io/download/"
    "dbeaver-community|DBeaver|https://dbeaver.io/download/"
    "pgadmin4|pgAdmin 4|https://www.pgadmin.org/download/pgadmin-4-macos/"
)

# Microsoft 365 - browser download only (no Cask)
MS365_URL="https://www.office.com/login?from=OfficeHome"

if [[ "$MANUAL_APPS" == "true" ]]; then
    # Manual mode - print download URLs
    echo ""
    log_info "Manual app installation mode. Please download and install:"
    echo ""
    echo -e "  ${BOLD}Required Apps:${NC}"
    for app in "${REQUIRED_APPS[@]}"; do
        IFS='|' read -r cask name url <<< "$app"
        echo -e "    ${SYM_BULLET} ${name}: ${CYAN}${url}${NC}"
    done
    echo ""
    echo -e "  ${BOLD}SQL GUI (choose one):${NC}"
    for app in "${SQL_APPS[@]}"; do
        IFS='|' read -r cask name url <<< "$app"
        echo -e "    ${SYM_BULLET} ${name}: ${CYAN}${url}${NC}"
    done
    echo ""
    echo -e "  ${BOLD}Microsoft 365:${NC}"
    echo -e "    ${SYM_BULLET} Office Apps: ${CYAN}${MS365_URL}${NC}"
    echo ""

    if prompt_yes_no "Open all download pages in browser?"; then
        for app in "${REQUIRED_APPS[@]}"; do
            IFS='|' read -r cask name url <<< "$app"
            open "$url"
            sleep 0.5
        done
        open "$MS365_URL"
    fi

    read -p "  Press Enter when you've finished installing apps..."

else
    # Cask mode - install via Homebrew
    for app in "${REQUIRED_APPS[@]}"; do
        IFS='|' read -r cask name url <<< "$app"
        install_brew_cask "$cask" "$name"
    done

    # SQL GUI - check if any already installed
    echo ""
    sql_installed=false
    for app in "${SQL_APPS[@]}"; do
        IFS='|' read -r cask name url <<< "$app"
        if brew_cask_installed "$cask" || app_installed "$name"; then
            install_brew_cask "$cask" "$name"  # Handles version check/upgrade
            sql_installed=true
            break
        fi
    done

    # If none installed, prompt user to choose
    if [[ "$sql_installed" == "false" ]]; then
        sql_choice=$(prompt_choice_or_default "Select a SQL GUI client for PostgreSQL/GCP:" "1" \
            "Beekeeper Studio ${GREY}(open source, cross-platform)${NC}" \
            "DBeaver ${GREY}(open source, supports many databases)${NC}" \
            "pgAdmin 4 ${GREY}(free, official PostgreSQL tool)${NC}" \
            "Skip ${GREY}(install later)${NC}")

        case "$sql_choice" in
            2) install_brew_cask "dbeaver-community" "DBeaver" ;;
            3) install_brew_cask "pgadmin4" "pgAdmin 4" ;;
            4) log_skip "SQL GUI client"; statusbar_item_done ;;
            *) install_brew_cask "beekeeper-studio" "Beekeeper Studio" ;;
        esac
    fi

    # Microsoft 365 - check if required apps are installed
    echo ""
    statusbar_update "Checking Microsoft 365..."
    ms365_missing=()
    open -Ra "Microsoft Teams" 2>/dev/null || ms365_missing+=("Teams")
    open -Ra "Microsoft Outlook" 2>/dev/null || ms365_missing+=("Outlook")
    open -Ra "Microsoft AutoUpdate" 2>/dev/null || ms365_missing+=("AutoUpdate")

    if [[ ${#ms365_missing[@]} -eq 0 ]]; then
        log_installed "Microsoft 365" "detected"
        track_skipped "Microsoft 365"
    else
        missing_str=$(IFS=', '; echo "${ms365_missing[*]}")
        if is_dry_run; then
            log_dry_run "prompt to open Microsoft 365 download page (missing: $missing_str)"
        else
            echo -e "  ${YELLOW}Microsoft 365${NC} missing: ${missing_str}"
            echo -e "    ${CYAN}${MS365_URL}${NC}"

            if prompt_yes_no "Open Microsoft 365 download page?"; then
                open "$MS365_URL"
            fi
        fi
    fi
    statusbar_item_done
fi

# Install VSCode 'code' CLI command
statusbar_update "Checking VSCode CLI..."
if command_exists code; then
    log_installed "VSCode 'code' CLI" "available"
    statusbar_item_done
else
    if [[ -d "/Applications/Visual Studio Code.app" ]]; then
        log_step "Installing VSCode 'code' CLI command..."
        statusbar_update "Installing VSCode CLI..."
        # Create symlink to code CLI
        VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
        if [[ -f "$VSCODE_BIN" ]]; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$VSCODE_BIN" "$HOME/.local/bin/code"
            # Ensure ~/.local/bin is in PATH for this session
            export PATH="$HOME/.local/bin:$PATH"
            if command_exists code; then
                log_success "VSCode 'code' CLI"
                track_installed "VSCode 'code' CLI"
            else
                log_error "VSCode 'code' CLI - symlink created but not in PATH"
                log_info "Add ~/.local/bin to your PATH"
            fi
        else
            log_error "VSCode binary not found at expected location"
        fi
    else
        log_info "VSCode not installed - skipping 'code' CLI setup"
    fi
    statusbar_item_done
fi
