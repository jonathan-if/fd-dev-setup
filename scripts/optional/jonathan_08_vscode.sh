#!/bin/bash
# jonathan_08_vscode.sh - Jonathan's VSCode extensions

# Check if VSCode/code CLI is available
if ! command_exists code; then
    log_error "VSCode 'code' command not found"
    log_info "Open VSCode and run: Shell Command: Install 'code' command in PATH"
    track_failed "VSCode extensions (jonathan)"
    return 1
fi

EXTENSIONS=(
    "eamodio.gitlens"
    "ms-azuretools.vscode-docker"
    "bradlc.vscode-tailwindcss"
    "prisma.prisma"
    "graphql.vscode-graphql"
    "graphql.vscode-graphql-syntax"
)

log_step "Installing Jonathan's VSCode extensions..."

for ext in "${EXTENSIONS[@]}"; do
    install_vscode_extension "$ext"
done
