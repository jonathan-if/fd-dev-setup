#!/bin/bash
# jonathan_00_shell.sh - Jonathan's shell configuration

ZSHRC="$HOME/.zshrc"
ALIASES_FILE="$HOME/.zsh_aliases"
CUSTOM_CODE_FILE="$HOME/.zsh_custom_code"

# Prompt for SHELL_ME_VAR (branch name prefix) just-in-time
echo ""
log_step "Configuring shell environment"
echo ""
echo -e "  ${GREY}Your branch name prefix is used for git branches like: yourname/horizon-1234${NC}"
SHELL_ME_VAR=$(prompt_and_save "SHELL_ME_VAR" "Your branch name prefix (e.g., jcrider)")

# Use DEV_DIR from environment if set, otherwise prompt
if [[ -n "$DEV_DIR" ]]; then
    # Extract just the folder name from the path
    DEV_FOLDER=$(basename "$DEV_DIR")
else
    # Ask for dev folder path
    echo ""
    echo -e "  ${GREY}Your development folder (relative to home directory)${NC}"
    DEV_FOLDER=$(prompt_and_save_optional "DEV_FOLDER" "Development folder name" "fd")
fi

# Create aliases file
if [[ -f "$ALIASES_FILE" ]]; then
    log_installed "Aliases file" "exists at $ALIASES_FILE"
    track_skipped "Aliases file"
else
    log_step "Creating aliases file..."

    cat > "$ALIASES_FILE" << EOF
# Custom Aliases

# DEVELOPMENT ROOT
DEV_ROOT="\$HOME/${DEV_FOLDER}"

# ZSH FILES
alias aliasl="cat ~/.zsh_aliases"
alias zshrc="code ~/.zshrc"
alias zshrca="code ~/.zsh_aliases"
alias zshrcc="code ~/.zsh_custom_code"

# NAVIGATION AND TERMINAL
alias dev="cd \$DEV_ROOT"
alias ll="ls -la"
alias refresh="source ~/.zshrc"
alias tree="lsd --tree -I \"node_modules\""

# QUICK EDITS
alias ohmyzsh="code ~/.oh-my-zsh"
alias gitconfig="code ~/.gitconfig"

# UTILITIES
alias myip='echo \$(curl -s ipinfo.io/ip)'

# REPOS
alias fe="cd \$DEV_ROOT/fd-web && code ."
alias be="cd \$DEV_ROOT/fd-backend && code ."
alias afe="cd \$DEV_ROOT/fd-admin-web && code ."

# BE
alias be-localdb="npm run dev:consumer"
alias be-proxydb="USING_LOCAL_CLOUD_SQL_PROXY=true npm run dev:consumer"
alias be-refresh="docker-compose stop && docker-compose rm -f -v && docker-compose up -d && sleep 2 && npm run dbMigrateToLatest"
alias be-csp="npm run startCloudSqlProxy"
alias be-anp="npm run startCloudSqlAccountNumbersDbProxy"
alias be-proxies="be-csp & be-anp"
alias be-proxies-stop="npm run stopCloudSqlProxy && npm run stopCloudSqlAccountNumbersDbProxy"

# FE
alias fe-localbe="VITE_LOCAL_BACKEND=true npm run dev:consumer"
alias fe-cloudbe="npm run dev:consumer"

# GIT
alias todo='git log main..HEAD --no-merges --author="\$(git config user.name)" --name-only --format="" | sort -u | xargs git --no-pager grep -n "TODO" 2>/dev/null | cut -d: -f1,2'
alias todov='git log main..HEAD --no-merges --author="\$(git config user.name)" --name-only --format="" | sort -u | xargs git --no-pager grep -n "TODO" 2>/dev/null | sed "s/^\([^:]*:[^:]*\):[[:space:]]*/\1\n/"'
EOF

    log_success "Aliases file created at $ALIASES_FILE"
    track_installed "Aliases file"
fi

# Create custom code file
if [[ -f "$CUSTOM_CODE_FILE" ]]; then
    log_installed "Custom code file" "exists at $CUSTOM_CODE_FILE"
    track_skipped "Custom code file"
else
    log_step "Creating custom code file..."

    cat > "$CUSTOM_CODE_FILE" << EOF
# CUSTOM CODE AND FUNCTIONS

#### COLORS
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GREY='\033[0;37m'
YELLOW='\033[1;33m'

# Go up N directories
up() {
  local levels=\${1:-1}

  if ! [[ "\$levels" =~ ^[0-9]+\$ ]]; then
      echo "Error: Please provide a positive number"
      return 1
  fi

  cd \$(printf "%0.0s../" \$(seq 1 \$levels)) || {
      echo "Failed to go up \$levels directories"
      return 1
  }
}

# Checkout a new branch for a horizon ticket
chb() {
  local ME='${SHELL_ME_VAR}'
  local ticket_number=\$1

  if ! [[ "\$ticket_number" =~ ^[0-9]+\$ ]]; then
      echo "Error: Please provide a ticket number"
      return 1
  fi

  if [[ "\$ME" == "yourname" ]]; then
      echo "\${YELLOW}Update SHELL_ME_VAR in .env and re-run setup\${NC}"
      echo "\${RED}Branch creation cancelled\${NC}"
      return 1
  fi

  local branch_name="\$ME/horizon-\$ticket_number"

  echo "Creating branch \${CYAN}\$branch_name\${NC}, is this correct? \${YELLOW}(y/n)\${NC}"
  read -sk 1 "answer"

  if [[ "\$answer" == "y" ]]; then
      git checkout -b "\$branch_name"
      echo "Branch \${CYAN}\$branch_name \${NC}created"
  else
      echo "\${RED}Branch creation cancelled\${NC}"
  fi
}

# Checkout existing branch for a horizon ticket
ch() {
  local ME='${SHELL_ME_VAR}'
  local ticket_number=\$1

  if ! [[ "\$ticket_number" =~ ^[0-9]+\$ ]]; then
      echo "\${RED}Error:\${NC} Please provide a ticket number"
      return 1
  fi

  if [[ "\$ME" == "yourname" ]]; then
      echo "\${YELLOW}Update SHELL_ME_VAR in .env and re-run setup\${NC}"
      echo "\${RED}Branch checkout cancelled\${NC}"
      return 1
  fi

  local branch_name="\$ME/horizon-\$ticket_number"
  git checkout "\$branch_name"
}

# Open Jira project board or ticket by number
jira() {
  local DEFAULT='HORIZON'
  if [[ -n "\$1" ]]; then
      if [[ "\$1" =~ ^[0-9]+\$ ]]; then
          DEFAULT="\$DEFAULT-\$1"
      elif [[ "\$1" == *-* ]]; then
          DEFAULT="\$1"
      fi
  fi
  open "https://first-dollar.atlassian.net/browse/\$DEFAULT"
}
EOF

    log_success "Custom code file created at $CUSTOM_CODE_FILE"
    track_installed "Custom code file"
fi

# Add sourcing to .zshrc if not already present
if grep -q "zsh_aliases" "$ZSHRC" 2>/dev/null && grep -q "zsh_custom_code" "$ZSHRC" 2>/dev/null; then
    log_installed "Shell imports" "exist in .zshrc"
else
    log_step "Adding imports to .zshrc..."

    cat >> "$ZSHRC" << 'EOF'

# IMPORTS (added by fd-dev-setup jonathan profile)
if [ -f $HOME/.zsh_aliases ]; then
    source $HOME/.zsh_aliases
fi
if [ -f $HOME/.zsh_custom_code ]; then
    source $HOME/.zsh_custom_code
fi
EOF

    log_success "Shell imports added to .zshrc"
fi
