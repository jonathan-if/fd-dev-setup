#!/bin/bash
# install_08_vscode_extensions.sh - Required VSCode extensions

# Check if VSCode/code CLI is available
if ! command_exists code; then
    log_error "VSCode 'code' command not found"
    log_info "Open VSCode and run: Shell Command: Install 'code' command in PATH"
    track_failed "VSCode extensions"
    return 1
fi

REQUIRED_EXTENSIONS=(
    "anthropics.claude-code"
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
)

log_step "Installing required VSCode extensions..."

for ext in "${REQUIRED_EXTENSIONS[@]}"; do
    install_vscode_extension "$ext"
done
