#!/bin/bash
# setup.sh - First Dollar macOS Development Environment Setup
# Usage: ./setup.sh [--profile <name>] [--auto-update] [--skip-updates] [--help] [--list-profiles]

set -e  # Exit on error

# =============================================================================
# SCRIPT DIRECTORY
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# SOURCE UTILITIES
# =============================================================================
source "${SCRIPT_DIR}/scripts/utils.sh"

# =============================================================================
# DEFAULT VALUES
# =============================================================================
declare -a PROFILES=()
TOTAL_PHASES=8
MANUAL_APPS=false
DRY_RUN=false

# =============================================================================
# USAGE
# =============================================================================
usage() {
    echo "Usage: ./setup.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --profile <name>   Run optional scripts for the specified profile(s)"
    echo "                     Can be comma-separated or specified multiple times"
    echo "  --auto-update      Automatically update all outdated packages"
    echo "  --skip-updates     Skip all updates, only install missing packages"
    echo "  --manual-apps      Skip Homebrew Cask, show download URLs instead"
    echo "  --dry-run          Show what would be done without making changes"
    echo "  --list-profiles    List available profiles"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./setup.sh                              # Required setup only"
    echo "  ./setup.sh --profile jcrider            # Include jcrider's preferences"
    echo "  ./setup.sh --profile jcrider,alice      # Multiple profiles (comma)"
    echo "  ./setup.sh --profile jcrider --profile alice  # Multiple profiles (flags)"
    echo "  ./setup.sh --auto-update                # Auto-update all packages"
    echo "  ./setup.sh --manual-apps                # Show download URLs for apps"
}

list_profiles() {
    echo "Available profiles:"
    local found=false
    for script in "${SCRIPT_DIR}"/scripts/optional/*_00_*.sh; do
        if [[ -f "$script" ]]; then
            local profile=$(basename "$script" | sed 's/\([^_]*\)_.*/\1/')
            echo "  - $profile"
            found=true
        fi
    done
    if [[ "$found" == "false" ]]; then
        echo "  (no profiles found)"
    fi
}

# =============================================================================
# PARSE ARGUMENTS
# =============================================================================
parse_profiles() {
    local input="$1"
    # Split by comma and add to PROFILES array
    IFS=',' read -ra parts <<< "$input"
    for part in "${parts[@]}"; do
        # Trim whitespace
        part=$(echo "$part" | xargs)
        if [[ -n "$part" ]]; then
            # Avoid duplicates
            local exists=false
            for existing in "${PROFILES[@]}"; do
                if [[ "$existing" == "$part" ]]; then
                    exists=true
                    break
                fi
            done
            if [[ "$exists" == "false" ]]; then
                PROFILES+=("$part")
            fi
        fi
    done
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            parse_profiles "$2"
            shift 2
            ;;
        --auto-update)
            AUTO_UPDATE=true
            shift
            ;;
        --skip-updates)
            SKIP_UPDATES=true
            shift
            ;;
        --manual-apps)
            MANUAL_APPS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --list-profiles)
            list_profiles
            exit 0
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Dry-run implies skip-updates (no actual changes)
if [[ "$DRY_RUN" == "true" ]]; then
    SKIP_UPDATES=true
fi

# =============================================================================
# VALIDATE PROFILES
# =============================================================================
validate_profiles() {
    for profile in "${PROFILES[@]}"; do
        if ! ls "${SCRIPT_DIR}"/scripts/optional/${profile}_*.sh &>/dev/null; then
            log_error "Profile '$profile' not found."
            list_profiles
            exit 1
        fi
    done
}

if [[ ${#PROFILES[@]} -gt 0 ]]; then
    validate_profiles
fi

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
preflight_checks() {
    # Check macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is designed for macOS only."
        exit 1
    fi

    # Load environment variables from .env if it exists
    # (values will be prompted just-in-time if not set)
    if [[ -f "${SCRIPT_DIR}/.env" ]]; then
        load_env "${SCRIPT_DIR}/.env"
    fi
}

# =============================================================================
# RUN SCRIPTS
# =============================================================================
run_required_scripts() {
    local phase=1
    for script in "${SCRIPT_DIR}"/scripts/install_*.sh; do
        if [[ -f "$script" ]]; then
            local script_name=$(basename "$script" .sh | sed 's/install_[0-9]*_//')
            print_phase $phase $TOTAL_PHASES "$script_name"
            source "$script"
            ((phase++))
        fi
    done
}

run_profile_scripts() {
    if [[ ${#PROFILES[@]} -eq 0 ]]; then
        return 0
    fi

    echo ""
    local profiles_str=$(IFS=', '; echo "${PROFILES[*]}")
    log_info "Running optional scripts for profile(s): ${profiles_str}"

    for profile in "${PROFILES[@]}"; do
        echo ""
        log_step "Profile: ${profile}"
        for script in "${SCRIPT_DIR}"/scripts/optional/${profile}_*.sh; do
            if [[ -f "$script" ]]; then
                local script_name=$(basename "$script" .sh | sed "s/${profile}_[0-9]*_//")
                log_info "Running: $script_name"
                source "$script"
            fi
        done
    done
}

# =============================================================================
# MANUAL STEPS
# =============================================================================
print_manual_steps() {
    echo ""
    echo -e "${BOLD}Manual Steps Required:${NC}"
    echo "  1. Sign in to GitHub: gh auth login (or set up SSH keys)"
    echo "  2. Request GCP/Firebase access from IT (#it-support)"
    echo "  3. Request Jira/Confluence access from IT"
    echo "  4. Request Sentry access from IT"
    echo "  5. Request FD admin dev account"
    echo "  6. Run 'npm install' in each cloned repo"
    echo "  7. Run 'npm run docker' in fd-backend for local database"
    echo "  8. Run 'npm run dbMigrateToLatest' in fd-backend"

    # Profile-specific manual steps
    for profile in "${PROFILES[@]}"; do
        if [[ "$profile" == "jonathan" ]]; then
            echo ""
            echo -e "${BOLD}Profile-specific steps (${profile}):${NC}"
            echo "  - Sign in to 1Password"
            echo "  - Sign in to Slack"
            echo "  - Configure terminal to use Hack Nerd Font"
            echo "  - Set terminal theme (Pro profile recommended)"
        fi
        # Add other profile-specific steps here as needed
    done
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    # Build profile display string
    local profile_display=""
    if [[ ${#PROFILES[@]} -gt 0 ]]; then
        profile_display=$(IFS=', '; echo "${PROFILES[*]}")
    fi

    print_banner "$profile_display" "$DRY_RUN"

    preflight_checks

    prompt_update_mode

    # Initialize status bar (currently simplified - no visual progress bar)
    # Phase 1: 2, Phase 2: 1, Phase 3: 9, Phase 4: 2, Phase 5: 1, Phase 6: 8, Phase 7: 3, Phase 8: 3 = 29
    statusbar_init
    statusbar_set_total 29

    run_required_scripts

    run_profile_scripts

    print_complete
    print_summary
    print_manual_steps
}

main
