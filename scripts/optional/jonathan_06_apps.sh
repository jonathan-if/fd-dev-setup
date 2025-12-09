#!/bin/bash
# jonathan_06_apps.sh - Jonathan's preferred apps

OPTIONAL_APPS=(
    "zoom|Zoom|https://zoom.us/download"
)

if [[ "$MANUAL_APPS" == "true" ]]; then
    echo ""
    log_info "Optional apps (manual install):"
    for app in "${OPTIONAL_APPS[@]}"; do
        IFS='|' read -r cask name url <<< "$app"
        echo -e "    ${SYM_BULLET} ${name}: ${CYAN}${url}${NC}"
    done
else
    for app in "${OPTIONAL_APPS[@]}"; do
        IFS='|' read -r cask name url <<< "$app"
        install_brew_cask "$cask" "$name"
    done
fi
