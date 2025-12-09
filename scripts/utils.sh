#!/bin/bash
# utils.sh - Shared utilities for First Dollar dev setup
# Colors, progress bar, logging, and prompts

# =============================================================================
# GLOBAL FLAGS (set by setup.sh)
# =============================================================================
AUTO_UPDATE=${AUTO_UPDATE:-false}
SKIP_UPDATES=${SKIP_UPDATES:-false}
UPDATE_MODE_SET=${UPDATE_MODE_SET:-false}

# =============================================================================
# TERMINAL INPUT
# =============================================================================
# Read from /dev/tty to support both direct execution and curl|bash piped execution.
# When piped, stdin is the script itself, so we must explicitly read from the terminal.
tty_read() {
    read "$@" < /dev/tty
}

# =============================================================================
# STATUS BAR - Disabled for now (placeholder functions)
# =============================================================================
statusbar_init() { :; }
statusbar_cleanup() { :; }
statusbar_set_total() { :; }
statusbar_phase() { :; }
statusbar_update() { :; }
statusbar_item_done() { :; }
statusbar_clear_message() { :; }

# Print a log line (simple echo)
_statusbar_print() {
    echo -e "$1"
}

# =============================================================================
# COLORS
# =============================================================================
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREY='\033[0;37m'
BOLD='\033[1m'

# =============================================================================
# SYMBOLS
# =============================================================================
SYM_CHECK="${GREEN}✓${NC}"
SYM_CROSS="${RED}✗${NC}"
SYM_SKIP="${YELLOW}~${NC}"
SYM_ARROW="${CYAN}→${NC}"
SYM_BULLET="${GREY}•${NC}"
SYM_UPDATE="${BLUE}↑${NC}"

# =============================================================================
# LOGGING
# =============================================================================
log_info()    { _statusbar_print "  ${SYM_BULLET} $1"; }
log_success() { _statusbar_print "  [${SYM_CHECK}] $1"; }
log_error()   { _statusbar_print "  [${SYM_CROSS}] $1"; }
log_skip()    { _statusbar_print "  [${SYM_SKIP}] $1 ${GREY}(skipped)${NC}"; }
log_step()    { _statusbar_print "  ${SYM_ARROW} $1"; }
log_installed() {
    local name=$1
    local version=$2
    _statusbar_print "  [${SYM_CHECK}] ${name} ${GREY}(installed: ${version})${NC}"
}
log_update_available() {
    local name=$1
    local current=$2
    local latest=$3
    _statusbar_print "  [${SYM_UPDATE}] ${name} ${GREY}(installed: ${current} ${SYM_ARROW} available: ${latest})${NC}"
}

# =============================================================================
# HEADERS
# =============================================================================
print_banner() {
    local profile=${1:-}
    local dry_run=${2:-false}
    echo ""
    echo -e "${BOLD}================================================================================${NC}"
    if [[ "$dry_run" == "true" ]]; then
        echo -e "${BOLD}  First Dollar Dev Setup ${YELLOW}(DRY RUN)${NC}"
    else
        echo -e "${BOLD}  First Dollar Dev Setup${NC}"
    fi
    if [[ -n "$profile" ]]; then
        echo -e "  Profile: ${CYAN}${profile}${NC}"
    fi
    if [[ "$AUTO_UPDATE" == "true" ]]; then
        echo -e "  Mode: ${GREEN}Auto-update enabled${NC}"
    elif [[ "$SKIP_UPDATES" == "true" ]]; then
        echo -e "  Mode: ${YELLOW}Skip updates${NC}"
    fi
    echo -e "${BOLD}================================================================================${NC}"
    echo ""
}

print_phase() {
    local phase_num=$1
    local total_phases=$2
    local phase_name=$3

    # Clear status bar before printing phase header
    if [[ "$STATUSBAR_ENABLED" == "true" ]]; then
        printf "\r\033[K"
    fi
    echo ""
    echo -e "${BOLD}[Phase ${phase_num}/${total_phases}]${NC} ${phase_name}"

    # Update status bar state (will be shown when statusbar_update is called)
    # Note: Do NOT overwrite STATUSBAR_TOTAL - it's set to item count, not phase count
    STATUSBAR_PHASE=$phase_num
    STATUSBAR_PHASE_NAME=$phase_name
    STATUSBAR_MESSAGE=""
}

print_complete() {
    # Clean up status bar before showing completion message
    statusbar_cleanup
    echo ""
    echo -e "${BOLD}================================================================================${NC}"
    echo -e "${BOLD}  ${GREEN}Setup Complete!${NC}"
    echo -e "${BOLD}================================================================================${NC}"
    echo ""
}

# =============================================================================
# PROGRESS BAR
# =============================================================================
progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "\r["
    printf "${GREEN}"
    printf '%0.s=' $(seq 1 $filled 2>/dev/null) 2>/dev/null
    printf "${NC}"
    printf '%0.s ' $(seq 1 $empty 2>/dev/null) 2>/dev/null
    printf "] %3d%%" "$percent"

    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# =============================================================================
# SPINNER (for long operations)
# =============================================================================
SPIN_CHARS='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
SPINNER_PID=""

spinner_start() {
    local message=$1
    (
        local i=0
        while true; do
            printf "\r  [${CYAN}%s${NC}] %s" "${SPIN_CHARS:i++%10:1}" "$message"
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
}

spinner_stop() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill $SPINNER_PID 2>/dev/null
        wait $SPINNER_PID 2>/dev/null
        SPINNER_PID=""
    fi
    printf "\r\033[K"  # Clear line
}

# =============================================================================
# PROMPTS
# =============================================================================
prompt_choice() {
    local prompt=$1
    shift
    local options=("$@")
    local choice

    echo -e "  ${YELLOW}?${NC} ${prompt}"
    for i in "${!options[@]}"; do
        if [[ $i -eq 0 ]]; then
            echo -e "    ${BOLD}$((i+1)))${NC} ${options[$i]} ${GREY}(default)${NC}"
        else
            echo -e "    ${BOLD}$((i+1)))${NC} ${options[$i]}"
        fi
    done

    printf "  Enter choice [1]: "
    tty_read choice
    choice=${choice:-1}

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#options[@]}" ]]; then
        echo $((choice - 1))
    else
        echo 0  # Default to first option
    fi
}

prompt_yes_no() {
    local prompt=$1
    local default=${2:-n}
    local choice

    if [[ "$default" == "y" ]]; then
        printf "  ${prompt} [Y/n]: "
        tty_read -n 1 choice
        echo ""
        choice=${choice:-y}
    else
        printf "  ${prompt} [y/N]: "
        tty_read -n 1 choice
        echo ""
        choice=${choice:-n}
    fi

    [[ "$choice" =~ ^[Yy]$ ]]
}

prompt_upgrade() {
    local name=$1
    local current=$2
    local latest=$3

    # Handle based on flags
    if [[ "$AUTO_UPDATE" == "true" ]]; then
        return 0  # Yes, upgrade
    elif [[ "$SKIP_UPDATES" == "true" ]]; then
        return 1  # No, skip
    fi

    # Interactive prompt - show update available, then ask with version
    log_update_available "$name" "$current" "$latest"
    prompt_yes_no "Update to ${latest}?"
}

# =============================================================================
# UPDATE MODE SELECTION
# =============================================================================
prompt_update_mode() {
    # Skip if already set via flag or previous prompt
    if [[ "$UPDATE_MODE_SET" == "true" ]] || [[ "$AUTO_UPDATE" == "true" ]] || [[ "$SKIP_UPDATES" == "true" ]]; then
        return 0
    fi

    echo -e "  ${YELLOW}?${NC} How would you like to handle updates for already-installed packages?"
    echo -e "    ${BOLD}1)${NC} Ask me each time ${GREY}(default)${NC}"
    echo -e "    ${BOLD}2)${NC} Auto-update all"
    echo -e "    ${BOLD}3)${NC} Skip all updates"

    printf "  Enter choice [1]: "
    tty_read -n 1 choice
    echo ""

    case "$choice" in
        2)
            AUTO_UPDATE=true
            echo -e "  ${SYM_ARROW} Auto-update ${GREEN}enabled${NC}"
            ;;
        3)
            SKIP_UPDATES=true
            echo -e "  ${SYM_ARROW} Updates will be ${YELLOW}skipped${NC}"
            ;;
        *)
            echo -e "  ${SYM_ARROW} Will prompt for each update"
            ;;
    esac

    UPDATE_MODE_SET=true
    echo ""
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
command_exists() {
    command -v "$1" &>/dev/null
}

brew_package_installed() {
    brew list "$1" &>/dev/null 2>&1
}

brew_cask_installed() {
    brew list --cask "$1" &>/dev/null 2>&1
}

app_installed() {
    local app_name=$1
    [[ -d "/Applications/${app_name}.app" ]] || [[ -d "$HOME/Applications/${app_name}.app" ]]
}

load_env() {
    local env_file="${1:-.env}"
    if [[ -f "$env_file" ]]; then
        set -a
        source "$env_file"
        set +a
        return 0
    else
        return 1
    fi
}

# =============================================================================
# VERSION CHECKING
# =============================================================================
get_brew_package_version() {
    local package=$1
    brew list --versions "$package" 2>/dev/null | awk '{print $2}'
}

get_brew_package_latest() {
    local package=$1
    brew info "$package" 2>/dev/null | head -1 | awk '{print $3}' | tr -d ','
}

get_cask_version() {
    local cask=$1
    brew list --cask --versions "$cask" 2>/dev/null | awk '{print $2}'
}

get_cask_latest() {
    local cask=$1
    brew info --cask "$cask" 2>/dev/null | head -1 | awk '{print $2}' | tr -d ','
}

# =============================================================================
# INSTALLATION HELPERS
# =============================================================================
install_brew_package() {
    local package=$1
    local name=${2:-$package}

    statusbar_update "Checking $name..."

    if brew_package_installed "$package"; then
        local current=$(get_brew_package_version "$package")
        local latest=$(get_brew_package_latest "$package")

        if [[ -n "$latest" ]] && [[ "$current" != "$latest" ]]; then
            if [[ "$SKIP_UPDATES" == "true" ]]; then
                log_installed "$name" "$current"
                track_skipped "$name"
                statusbar_item_done
                return 0
            fi
            if [[ "$DRY_RUN" == "true" ]]; then
                log_dry_run "upgrade $name ($current → $latest)"
                statusbar_item_done
                return 0
            fi
            if prompt_upgrade "$name" "$current" "$latest"; then
                log_step "Upgrading $name..."
                statusbar_update "Upgrading $name..."
                if brew upgrade "$package" &>/dev/null; then
                    local new_version=$(get_brew_package_version "$package")
                    log_success "$name upgraded to ${new_version}"
                    track_upgraded "$name"
                    statusbar_item_done
                    return 0
                else
                    log_error "$name failed to upgrade"
                    track_failed "$name"
                    statusbar_item_done
                    return 1
                fi
            else
                log_installed "$name" "$current"
                track_skipped "$name"
                statusbar_item_done
                return 0
            fi
        else
            log_installed "$name" "$current"
            track_skipped "$name"
            statusbar_item_done
            return 0
        fi
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "install $name via brew"
        statusbar_item_done
        return 0
    fi

    log_step "Installing $name..."
    statusbar_update "Installing $name..."
    if brew install "$package" &>/dev/null; then
        local version=$(get_brew_package_version "$package")
        log_success "$name ${GREY}(${version})${NC}"
        track_installed "$name"
        statusbar_item_done
        return 0
    else
        log_error "$name failed to install"
        track_failed "$name"
        statusbar_item_done
        return 1
    fi
}

install_brew_cask() {
    local cask=$1
    local app_name=$2

    statusbar_update "Checking $app_name..."

    if brew_cask_installed "$cask" || app_installed "$app_name"; then
        local current=$(get_cask_version "$cask")
        local latest=$(get_cask_latest "$cask")

        # If installed outside of brew, just note it
        if [[ -z "$current" ]] && app_installed "$app_name"; then
            log_installed "$app_name" "manual install"
            track_skipped "$app_name"
            statusbar_item_done
            return 0
        fi

        if [[ -n "$latest" ]] && [[ -n "$current" ]] && [[ "$current" != "$latest" ]]; then
            if [[ "$SKIP_UPDATES" == "true" ]]; then
                log_installed "$app_name" "$current"
                track_skipped "$app_name"
                statusbar_item_done
                return 0
            fi
            if [[ "$DRY_RUN" == "true" ]]; then
                log_dry_run "upgrade $app_name ($current → $latest)"
                statusbar_item_done
                return 0
            fi
            if prompt_upgrade "$app_name" "$current" "$latest"; then
                log_step "Upgrading $app_name..."
                statusbar_update "Upgrading $app_name..."
                if brew upgrade --cask "$cask" &>/dev/null; then
                    local new_version=$(get_cask_version "$cask")
                    log_success "$app_name upgraded to ${new_version}"
                    track_upgraded "$app_name"
                    statusbar_item_done
                    return 0
                else
                    log_error "$app_name failed to upgrade"
                    track_failed "$app_name"
                    statusbar_item_done
                    return 1
                fi
            else
                log_installed "$app_name" "$current"
                track_skipped "$app_name"
                statusbar_item_done
                return 0
            fi
        else
            log_installed "$app_name" "${current:-unknown}"
            track_skipped "$app_name"
            statusbar_item_done
            return 0
        fi
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "install $app_name via brew cask"
        statusbar_item_done
        return 0
    fi

    log_step "Installing $app_name..."
    statusbar_update "Installing $app_name..."
    if brew install --cask "$cask" &>/dev/null; then
        local version=$(get_cask_version "$cask")
        log_success "$app_name ${GREY}(${version})${NC}"
        track_installed "$app_name"
        statusbar_item_done
        return 0
    else
        log_error "$app_name failed to install"
        track_failed "$app_name"
        statusbar_item_done
        return 1
    fi
}

install_vscode_extension() {
    local extension=$1
    local name=${2:-$extension}

    statusbar_update "Checking $name..."

    if code --list-extensions 2>/dev/null | grep -qi "^${extension}$"; then
        log_installed "$name" "installed"
        track_skipped "$name"
        statusbar_item_done
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "install VSCode extension: $name"
        statusbar_item_done
        return 0
    fi

    log_step "Installing $name..."
    statusbar_update "Installing $name..."
    if code --install-extension "$extension" &>/dev/null; then
        log_success "$name"
        track_installed "$name"
        statusbar_item_done
        return 0
    else
        log_error "$name failed to install"
        track_failed "$name"
        statusbar_item_done
        return 1
    fi
}

# =============================================================================
# SUMMARY TRACKING
# =============================================================================
declare -a INSTALLED_ITEMS=()
declare -a SKIPPED_ITEMS=()
declare -a UPGRADED_ITEMS=()
declare -a FAILED_ITEMS=()

track_installed() { INSTALLED_ITEMS+=("$1"); }
track_skipped()   { SKIPPED_ITEMS+=("$1"); }
track_upgraded()  { UPGRADED_ITEMS+=("$1"); }
track_failed()    { FAILED_ITEMS+=("$1"); }

print_summary() {
    echo ""
    if [[ ${#INSTALLED_ITEMS[@]} -gt 0 ]]; then
        echo -e "${GREEN}Installed:${NC}"
        printf '  - %s\n' "${INSTALLED_ITEMS[@]}"
    fi

    if [[ ${#UPGRADED_ITEMS[@]} -gt 0 ]]; then
        echo -e "${BLUE}Upgraded:${NC}"
        printf '  - %s\n' "${UPGRADED_ITEMS[@]}"
    fi

    if [[ ${#SKIPPED_ITEMS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Already installed:${NC}"
        printf '  - %s\n' "${SKIPPED_ITEMS[@]}"
    fi

    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        echo -e "${RED}Failed:${NC}"
        printf '  - %s\n' "${FAILED_ITEMS[@]}"
    fi

    if [[ ${#IT_SUPPORT_ITEMS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Requires IT Support (#it-support):${NC}"
        printf '  - %s\n' "${IT_SUPPORT_ITEMS[@]}"
    fi
}

# =============================================================================
# IT SUPPORT HELPER
# =============================================================================
# Slack configuration
SLACK_TEAM_ID="TPCSSUVSL"
SLACK_IT_SUPPORT_CHANNEL_ID="C05FKBU54U8"
SECRETS_LOADED=false

# Try to decrypt and load secrets using GIT_CRYPT_KEY from .env
try_load_secrets() {
    local secrets_file="${SCRIPT_DIR}/.secrets"

    # Already loaded
    if [[ "$SECRETS_LOADED" == "true" ]]; then
        return 0
    fi

    # Check if GIT_CRYPT_KEY is set
    if [[ -z "$GIT_CRYPT_KEY" ]]; then
        return 1
    fi

    # Check if secrets file exists
    if [[ ! -f "$secrets_file" ]]; then
        return 1
    fi

    # Check if file is encrypted (binary) or already decrypted (text)
    if file "$secrets_file" | grep -q "text"; then
        # Already decrypted, just source it
        source "$secrets_file"
        SECRETS_LOADED=true
        return 0
    fi

    # Try to decrypt using openssl
    # git-crypt uses AES-256-CTR, but the key format is specific
    # For simplicity, we'll use a temp file approach
    local temp_file=$(mktemp)
    trap "rm -f $temp_file" RETURN

    # Decode base64 key and decrypt
    if echo "$GIT_CRYPT_KEY" | base64 -d > "$temp_file.key" 2>/dev/null; then
        if openssl enc -aes-256-ctr -d -in "$secrets_file" -out "$temp_file" -pass file:"$temp_file.key" 2>/dev/null; then
            source "$temp_file"
            SECRETS_LOADED=true
            rm -f "$temp_file.key"
            return 0
        fi
        rm -f "$temp_file.key"
    fi

    return 1
}

# Post message to Slack via API
slack_post_message() {
    local channel=$1
    local message=$2

    if [[ -z "$SLACK_BOT_TOKEN" ]]; then
        return 1
    fi

    local response=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"channel\": \"$channel\", \"text\": \"$message\"}")

    if echo "$response" | grep -q '"ok":true'; then
        return 0
    fi
    return 1
}

# Copy text to clipboard (macOS)
copy_to_clipboard() {
    echo -n "$1" | pbcopy
}

# Track IT support items
declare -a IT_SUPPORT_ITEMS=()
track_it_support() { IT_SUPPORT_ITEMS+=("$1"); }

# Main IT support prompt function
prompt_it_support() {
    local issue=$1
    local message=$2
    local channel_id="$SLACK_IT_SUPPORT_CHANNEL_ID"

    log_error "$issue"
    track_it_support "$issue"

    # Try to load secrets for auto-posting
    try_load_secrets

    if [[ "$SECRETS_LOADED" == "true" ]] && [[ -n "$SLACK_BOT_TOKEN" ]]; then
        # Auto-post mode
        echo ""
        echo -e "  ${CYAN}Posting to #it-support...${NC}"

        if slack_post_message "$channel_id" "$message"; then
            log_success "Message posted to #it-support"
            return 0
        else
            log_error "Failed to post message, falling back to manual mode"
        fi
    fi

    # Manual mode - show message and offer to open Slack
    echo ""
    echo -e "  ${YELLOW}This requires IT support.${NC}"
    echo ""
    echo -e "  Suggested message for ${BOLD}#it-support${NC}:"
    echo -e "  ${GREY}────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}${message}${NC}"
    echo -e "  ${GREY}────────────────────────────────────────${NC}"
    echo ""

    # Copy to clipboard
    copy_to_clipboard "$message"
    echo -e "  ${GREEN}Message copied to clipboard${NC}"
    echo ""

    if prompt_yes_no "Open #it-support in Slack?"; then
        # Try Slack deep link, fall back to web
        open "slack://channel?team=${SLACK_TEAM_ID}&id=${channel_id}" 2>/dev/null || \
            open "https://app.slack.com/client/${SLACK_TEAM_ID}/${channel_id}"
    fi
}

# =============================================================================
# DRY RUN MODE
# =============================================================================

# Log a dry-run action
log_dry_run() {
    local action="$1"
    _statusbar_print "  ${YELLOW}[DRY RUN]${NC} Would $action"
}

# Check if in dry-run mode
is_dry_run() {
    [[ "$DRY_RUN" == "true" ]]
}

# Run a command or log what would happen in dry-run mode
# Usage: run_cmd "description" command arg1 arg2
# Returns: 0 on success (or dry-run), 1 on failure
run_cmd() {
    local description="$1"
    shift
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "$description"
        return 0
    else
        "$@"
    fi
}

# Prompt user for choice, or return default in dry-run mode
# Usage: choice=$(prompt_choice_or_default "prompt text" "default_value" "Option 1" "Option 2" ...)
# In dry-run: logs and returns default_value
# In real run: shows prompt and returns user choice (1-based index as string)
prompt_choice_or_default() {
    local prompt="$1"
    local default="$2"
    shift 2
    local options=("$@")

    if [[ "$DRY_RUN" == "true" ]]; then
        # Find the default option text for logging
        local default_idx=$((default - 1))
        local default_text="${options[$default_idx]:-option $default}"
        # Clean up the option text (remove leading number and parentheses)
        default_text=$(echo "$default_text" | sed 's/^[0-9]*)[[:space:]]*//' | sed 's/[[:space:]]*(default.*//')
        log_dry_run "prompt: $prompt (default: $default_text)"
        echo "$default"
        return 0
    fi

    echo ""
    echo -e "  ${YELLOW}?${NC} ${prompt}"
    for i in "${!options[@]}"; do
        echo -e "    ${BOLD}$((i+1)))${NC} ${options[$i]}"
    done

    printf "  Enter choice [${default}]: "
    tty_read -n 1 choice
    echo ""

    # Return user choice or default
    if [[ -z "$choice" ]] || [[ ! "$choice" =~ ^[0-9]+$ ]]; then
        echo "$default"
    else
        echo "$choice"
    fi
}

# Yes/No prompt, or return default in dry-run mode
# Usage: if prompt_yes_no_or_default "Open page?" "n"; then open_page; fi
# In dry-run: logs and returns based on default (0 for y, 1 for n)
# In real run: shows prompt and returns based on user input
prompt_yes_no_or_default() {
    local prompt="$1"
    local default="${2:-n}"

    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ "$default" == "y" ]]; then
            log_dry_run "prompt: $prompt (default: yes)"
            return 0
        else
            log_dry_run "prompt: $prompt (default: no)"
            return 1
        fi
    fi

    # Use existing prompt_yes_no for real runs
    prompt_yes_no "$prompt" "$default"
}

# Alias for backwards compatibility
run_or_dry() { run_cmd "$@"; }
dry_run_cmd() { run_cmd "$@"; }

# =============================================================================
# ENV VALIDATION
# =============================================================================

# Validate GitHub username exists
validate_github_user() {
    local username="$1"
    local http_code

    http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/users/${username}" 2>/dev/null)

    if [[ "$http_code" == "200" ]]; then
        # Fetch display name
        local display_name
        display_name=$(curl -s "https://api.github.com/users/${username}" | grep -o '"name":[^,]*' | cut -d'"' -f4)
        if [[ -n "$display_name" && "$display_name" != "null" ]]; then
            echo "$display_name"
        else
            echo ""
        fi
        return 0
    else
        return 1
    fi
}

# Validate .env file contents dynamically
validate_env() {
    local has_errors=false
    local env_example="${SCRIPT_DIR}/.env.example"

    echo ""
    echo -e "${BOLD}[Validating .env]${NC}"

    if [[ ! -f "$env_example" ]]; then
        echo -e "  ${SYM_ERROR} .env.example not found"
        return 1
    fi

    # Read each non-comment, non-empty line from .env.example
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Parse VAR_NAME="placeholder"
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)= ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local placeholder=$(echo "$line" | sed 's/^[^=]*=//' | tr -d '"'"'")
            local current_value="${!var_name}"

            # Check if variable is set
            if [[ -z "$current_value" ]]; then
                # Empty is OK for optional vars (those with empty placeholder)
                if [[ -z "$placeholder" ]]; then
                    echo -e "  [${SYM_SKIP}] ${var_name}: ${GREY}(not set)${NC}"
                else
                    echo -e "  [${SYM_CROSS}] ${var_name}: ${RED}(empty)${NC}"
                    has_errors=true
                fi
                continue
            fi

            # Check if still using placeholder
            if [[ "$current_value" == "$placeholder" && -n "$placeholder" ]]; then
                echo -e "  [${SYM_CROSS}] ${var_name}: ${RED}\"$current_value\" (still using placeholder)${NC}"
                has_errors=true
                continue
            fi

            # Special validations
            case "$var_name" in
                *EMAIL*)
                    if [[ ! "$current_value" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                        echo -e "  [${SYM_CROSS}] ${var_name}: ${RED}\"$current_value\" (invalid email format)${NC}"
                        has_errors=true
                        continue
                    fi
                    ;;
                GITHUB_USERNAME)
                    local github_name
                    if github_name=$(validate_github_user "$current_value"); then
                        if [[ -n "$github_name" ]]; then
                            echo -e "  [${SYM_CHECK}] ${var_name}: \"$current_value\" ${GREY}(verified: $github_name)${NC}"
                        else
                            echo -e "  [${SYM_CHECK}] ${var_name}: \"$current_value\" ${GREY}(verified)${NC}"
                        fi
                        continue
                    else
                        echo -e "  [${SYM_CROSS}] ${var_name}: ${RED}\"$current_value\" (user not found on GitHub)${NC}"
                        has_errors=true
                        continue
                    fi
                    ;;
                *_KEY|*_PW|*_AUTH)
                    # Don't print actual values for secrets
                    echo -e "  [${SYM_CHECK}] ${var_name}: ${GREY}(set)${NC}"
                    continue
                    ;;
            esac

            # Default: show as valid
            echo -e "  [${SYM_CHECK}] ${var_name}: \"$current_value\""
        fi
    done < "$env_example"

    if [[ "$has_errors" == "true" ]]; then
        return 1
    fi
    return 0
}

# =============================================================================
# JUST-IN-TIME PROMPTING WITH PERSISTENCE
# =============================================================================

# Save a variable to .env file
# Usage: save_to_env "VAR_NAME" "value"
save_to_env() {
    local var_name="$1"
    local value="$2"
    local env_file="${SCRIPT_DIR}/.env"

    # Don't save in dry-run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    # Create .env from .env.example if it doesn't exist
    if [[ ! -f "$env_file" ]] && [[ -f "${SCRIPT_DIR}/.env.example" ]]; then
        cp "${SCRIPT_DIR}/.env.example" "$env_file"
    fi

    # Create empty .env if neither exists
    if [[ ! -f "$env_file" ]]; then
        touch "$env_file"
    fi

    # Check if variable already exists in .env
    if grep -q "^${var_name}=" "$env_file" 2>/dev/null; then
        # Update existing value (macOS sed syntax)
        sed -i '' "s|^${var_name}=.*|${var_name}=\"${value}\"|" "$env_file"
    else
        # Append new variable
        echo "${var_name}=\"${value}\"" >> "$env_file"
    fi
}

# Prompt for a value, show existing default, save to .env
# Usage: result=$(prompt_and_save "VAR_NAME" "Prompt text" "validator")
# Validators: "email", "github", or empty for any non-empty value
# Returns: The value (either entered or existing)
# In dry-run mode: Shows what would be prompted, uses existing value or placeholder
prompt_and_save() {
    local var_name="$1"
    local prompt_text="$2"
    local validator="${3:-}"
    local current_value="${!var_name}"
    local input=""
    local valid=false

    # Dry-run mode: show what would happen, return existing or placeholder
    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ -n "$current_value" ]]; then
            log_dry_run "use existing ${var_name}=\"${current_value}\""
            echo "$current_value"
        else
            log_dry_run "prompt for ${var_name} (${prompt_text})"
            echo "__DRY_RUN_PLACEHOLDER__"
        fi
        return 0
    fi

    while [[ "$valid" == "false" ]]; do
        if [[ -n "$current_value" ]]; then
            printf "  ${prompt_text} ${GREY}[${current_value}]${NC}: "
            tty_read input
            input="${input:-$current_value}"
        else
            printf "  ${prompt_text}: "
            tty_read input
        fi

        # Validate if validator specified
        case "$validator" in
            email)
                if [[ "$input" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                    valid=true
                else
                    echo -e "  ${RED}Invalid email format. Please try again.${NC}"
                    current_value=""
                fi
                ;;
            github)
                # Verify GitHub username exists
                local http_code
                http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/users/${input}" 2>/dev/null)
                if [[ "$http_code" == "200" ]]; then
                    valid=true
                    # Fetch display name for confirmation
                    local display_name
                    display_name=$(curl -s "https://api.github.com/users/${input}" | grep -o '"name":[^,]*' | cut -d'"' -f4)
                    if [[ -n "$display_name" && "$display_name" != "null" ]]; then
                        echo -e "  ${GREEN}✓${NC} Verified: ${display_name}"
                    fi
                else
                    echo -e "  ${RED}GitHub user '${input}' not found. Please try again.${NC}"
                    current_value=""
                fi
                ;;
            *)
                # No validation, accept any non-empty input
                if [[ -n "$input" ]]; then
                    valid=true
                else
                    echo -e "  ${RED}Value cannot be empty. Please try again.${NC}"
                fi
                ;;
        esac
    done

    # Save to .env
    save_to_env "$var_name" "$input"

    # Export for current session
    export "$var_name=$input"

    echo "$input"
}

# Prompt for optional value (can be empty), save to .env
# Usage: result=$(prompt_and_save_optional "VAR_NAME" "Prompt text" "default")
# In dry-run mode: Shows what would be prompted, uses existing value or default
prompt_and_save_optional() {
    local var_name="$1"
    local prompt_text="$2"
    local default="${3:-}"
    local current_value="${!var_name:-$default}"
    local input=""

    # Dry-run mode: show what would happen, return existing or default
    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ -n "$current_value" ]]; then
            log_dry_run "use existing ${var_name}=\"${current_value}\""
        else
            log_dry_run "prompt for ${var_name} (${prompt_text}) - optional"
        fi
        echo "$current_value"
        return 0
    fi

    if [[ -n "$current_value" ]]; then
        printf "  ${prompt_text} ${GREY}[${current_value}]${NC}: "
    else
        printf "  ${prompt_text} ${GREY}(optional, press Enter to skip)${NC}: "
    fi
    tty_read input
    input="${input:-$current_value}"

    # Save to .env (even if empty, to show it was asked)
    save_to_env "$var_name" "$input"

    # Export for current session
    export "$var_name=$input"

    echo "$input"
}
