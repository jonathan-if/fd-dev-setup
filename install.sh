#!/bin/bash
# install.sh - Bootstrap script for First Dollar dev setup
# Works on a completely fresh Mac with no dependencies
# Usage: curl -fsSL https://raw.githubusercontent.com/jonathan-if/fd-dev-setup/main/install.sh | bash

set -e

# =============================================================================
# COLORS
# =============================================================================
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'

# =============================================================================
# BANNER
# =============================================================================
echo ""
echo -e "${BOLD}================================================================================${NC}"
echo -e "${BOLD}  First Dollar Dev Setup - Installer${NC}"
echo -e "${BOLD}================================================================================${NC}"
echo ""

# =============================================================================
# GET CURRENT USER
# =============================================================================
CURRENT_USER=$(whoami)

# =============================================================================
# ASK FOR INSTALL DIRECTORY
# =============================================================================
echo -e "Where would you like to create your development folder?"
echo -e "${CYAN}  This is where fd-backend, fd-web, fd-admin-web, and this setup will live.${NC}"
echo -e "${YELLOW}  Note: Avoid ~/Documents due to macOS security restrictions.${NC}"
echo ""
echo -e "  Examples: ${CURRENT_USER}/fd, /fd, ~/fd"
echo ""
printf "Press Enter for default (${CURRENT_USER}/fd) or type your path: "
read dev_path_input < /dev/tty

# Default to ~/fd
DEV_PATH="${dev_path_input:-$HOME/fd}"

# Handle different input formats:
# - "fd" or "jonathan/fd" → ~/fd or ~/jonathan/fd (relative to home)
# - "/fd" → /Users/jonathan/fd (leading slash = relative to home)
# - "~/fd" → ~/fd (explicit home)
# - "/Users/..." → absolute path (leave as-is)
if [[ "$DEV_PATH" == /* ]] && [[ "$DEV_PATH" != /Users/* ]]; then
    # Leading slash but not absolute /Users path → treat as relative to home
    DEV_PATH="$HOME${DEV_PATH}"
elif [[ "$DEV_PATH" != /* ]] && [[ "$DEV_PATH" != ~* ]]; then
    # No leading slash or ~ → relative to home
    DEV_PATH="$HOME/$DEV_PATH"
fi

# Expand ~ to $HOME if used
DEV_PATH="${DEV_PATH/#\~/$HOME}"

echo ""
echo -e "  ${CYAN}→${NC} Will install to: ${BOLD}${DEV_PATH}/fd-dev-setup${NC}"
echo ""

# Confirm
printf "Continue? [Y/n]: "
read -n 1 confirm < /dev/tty
echo ""
if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo "Aborted."
    exit 0
fi

# =============================================================================
# CREATE DIRECTORY
# =============================================================================
echo ""
if [[ ! -d "$DEV_PATH" ]]; then
    echo -e "  ${CYAN}→${NC} Creating ${DEV_PATH}..."
    mkdir -p "$DEV_PATH"
fi

# =============================================================================
# DOWNLOAD REPO (using curl + unzip - both native to macOS)
# =============================================================================
REPO_URL="https://github.com/jonathan-if/fd-dev-setup/archive/refs/heads/main.zip"
ZIP_FILE="/tmp/fd-dev-setup.zip"
EXTRACT_DIR="/tmp/fd-dev-setup-main"
TARGET_DIR="${DEV_PATH}/fd-dev-setup"

echo -e "  ${CYAN}→${NC} Downloading fd-dev-setup..."
curl -fsSL "$REPO_URL" -o "$ZIP_FILE"

echo -e "  ${CYAN}→${NC} Extracting..."
unzip -q -o "$ZIP_FILE" -d /tmp

# Remove existing if present
if [[ -d "$TARGET_DIR" ]]; then
    echo -e "  ${YELLOW}!${NC} Removing existing ${TARGET_DIR}..."
    rm -rf "$TARGET_DIR"
fi

# Move to target
mv "$EXTRACT_DIR" "$TARGET_DIR"

# Cleanup
rm -f "$ZIP_FILE"

# Make scripts executable
chmod +x "$TARGET_DIR/setup.sh"
chmod +x "$TARGET_DIR/install.sh"

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${GREEN}✓${NC} Download complete!"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo -e "  ${CYAN}cd ${TARGET_DIR}${NC}"
echo -e "  ${CYAN}./setup.sh${NC}                        # Run setup"
echo -e "  ${CYAN}./setup.sh --profile jonathan${NC}     # Include optional extras"
echo ""
echo -e "  ${GREY}The script will prompt for any required information as needed.${NC}"
echo -e "  ${GREY}Your answers will be saved for future runs.${NC}"
echo ""
echo -e "For help: ${CYAN}./setup.sh --help${NC}"
echo ""

# =============================================================================
# OFFER TO START SETUP NOW
# =============================================================================
printf "Start setup now? [Y/n]: "
read -n 1 start_now < /dev/tty
echo ""

if [[ ! "$start_now" =~ ^[Nn]$ ]]; then
    echo ""
    cd "$TARGET_DIR"

    # Export DEV_PATH so setup.sh and its scripts know where repos go
    export DEV_DIR="$DEV_PATH"

    # Ask about profile
    printf "Include optional extras (jonathan profile)? [y/N]: "
    read -n 1 use_profile < /dev/tty
    echo ""

    if [[ "$use_profile" =~ ^[Yy]$ ]]; then
        exec ./setup.sh --profile jonathan
    else
        exec ./setup.sh
    fi
fi
