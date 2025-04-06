#!/usr/bin/env zsh
print "\033[90m✌️  Don't panic...\033[0m"

# OS
IS_MACOS=false
IS_LINUX=false

case "$OSTYPE" in
  darwin*) IS_MACOS=true ;;
  linux*)  IS_LINUX=true ;;
esac

# MODULES
SCRIPTS_PATH="$(cd "$(dirname "${(%):-%x}")" && pwd)"
source "$SCRIPTS_PATH/style.zsh"
source "$SCRIPTS_PATH/tools.zsh"

# DATE
TODAY="$(date "+%Y-%m-%d")"

# TOOLS LIST (from Brewfile)
if [[ ! -f "$SCRIPTS_PATH/Brewfile" ]]; then
    printStyled "error" "⛔ Brewfile not found in $SCRIPTS_PATH"
else
    FORMULAE=($(grep '^brew "' "$SCRIPTS_PATH/Brewfile" | cut -d'"' -f2))
    CASKS=($(grep '^cask "' "$SCRIPTS_PATH/Brewfile" | cut -d'"' -f2))
fi

# MAIN
main() {
    # ASCII art
    print "${ORANGE}  _____          _____ _      _____ ${NONE}"
    print "${ORANGE} / ____|   /\\\\   / ____| |    |_   _|${NONE}"
    print "${ORANGE}| |  __   /  \\\\ | |    | |      | |  ${NONE}"
    print "${ORANGE}| | |_ | / /\\\\ \\\\| |    | |      | |  ${NONE}"
    print "${ORANGE}| |__| |/ ____ \\\\ |____| |____ _| |_ ${NONE}"
    print "${ORANGE} \\\\_____/_/    \\\\_\\\\_____|______|_____|${NONE}"
    print ""
                                    
    # Install or update
    if [[ -f "$SCRIPTS_PATH/.config" ]]; then
        # Update if needed
        local next_update=$(grep "^next_update =" "$SCRIPTS_PATH/.config" | cut -d= -f2 | xargs)
        if [[ -z $next_update || "$TODAY" == "$next_update" || "$TODAY" > "$next_update" ]]; then
            update_tools
        fi

        # Log tools status
        print_tools
    else
        # Install GACLI
        install_gacli    
        
        # Log tools status
        print_tools
    fi
}

########################
#   INSTALL
########################

# Create config file
create_config_file() {
    # Compute next update date (MacOS + Linux fallback)
    local freq_days=$1
    local next_update=$(add_days $TODAY $freq_days)

    # Create config file
    echo "date = $TODAY" > "$SCRIPTS_PATH/.config"
    echo "update_frequency = $freq_days" >> "$SCRIPTS_PATH/.config"
    echo "next_update = $next_update" >> "$SCRIPTS_PATH/.config"
}

# Install GACLI
install_gacli() {
    # Onboard
    print "👋 ${CYAN}Welcome to ${BOLD}${ORANGE}GACLI${NONE}${CYAN}, the CLI that makes your dev life easier!${NONE}"
    print ""
    print "${CYAN}Let’s start by choosing the update frequency,${NONE}"
    print "${CYAN}then I’ll take care of installing all the tools you need${NONE} 💻✨"
    print ""

    # Ask user for update frequency
    while true; do
        # Ask
        print -n "👉 ${BOLD}How many days between each auto-update? ${NONE}"
        read -r freq_days

        # Check format
        if [[ "$freq_days" =~ '^[0-9]+$' ]] && [[ $freq_days -gt 0 ]]; then
            break
        else
            printStyled "error" "⛔ Invalid input. Please enter a positive number"
        fi
    done

    # Create config file
    create_config_file $freq_days

    # Install tools
    print ""
    printStyled "info" "Installing all tools (this may take a few minutes) ⏳"
    install_brew
    install_coreutils
    update_tools
}

# Install Homebrew
install_brew() {
    # Homebrew install
    if ! command -v brew >/dev/null 2>&1; then
        printStyled info "Installing ${ORANGE}Homebrew${GREY}..."

        if $IS_MACOS; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        elif $IS_LINUX; then
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            printStyled error "install_brew" "Unsupported OS: $OSTYPE"
            return 1
        fi

        # Add Homebrew to PATH for current session (cross-platform)
        local brew_path="$(command -v brew | sed 's|/bin/brew||')"
        eval "$("$brew_path/bin/brew" shellenv)"

        # Refresh command hash table
        hash -r
    fi
}

# Install coreutils (for cross-platform compatibility)
install_coreutils() {
    if ! command -v gdate >/dev/null 2>&1; then
        printStyled info "Installing ${ORANGE}coreutils${GREY} (for cross-platform compatibility)..."
        brew install coreutils
    fi
}

########################
#   UPDATE
########################

# Update homebrew & formulae & casks
update_tools() {
    print ""
    printStyled "info" "Updating GACLI tools..."

    # Update Homebrew
    brew update 1>/dev/null

    # Install/uninstall formulae & casks referring to the Brewfile
    brew bundle --file="$SCRIPTS_PATH/Brewfile"

    # Update formulae & casks
    brew upgrade 1>/dev/null

    # Cleanup
    brew cleanup 1>/dev/null

    # Update .config file
    update_config_file

    printStyled "success" "Ready to go 🚀"
    print ""
}

# Update config file
update_config_file() {
    local config_file="$SCRIPTS_PATH/.config"
    local freq_days=$(grep "^update_frequency" "$config_file" | cut -d= -f2 | xargs)
    local next_update=$(add_days $TODAY $freq_days)

    echo "date = $TODAY" > "$config_file"
    echo "update_frequency = $freq_days" >> "$config_file"
    echo "next_update = $next_update" >> "$config_file"
}


########################
#   PRINT
########################

# Print tools status
print_tools() {
    local output_formulae=""
    local output_casks=""

    # formulae
    for formula in $FORMULAE; do
        if [[ "$formula" = "coreutils" ]]; then
            if command -v gdate >/dev/null 2>&1; then
                output_formulae+="${ICON_ON}"
            else
                output_formulae+="${ICON_OFF}"
            fi
        else
            if command -v $formula >/dev/null 2>&1; then
                output_formulae+="${ICON_ON}"
            else
                output_formulae+="${ICON_OFF}"
            fi
        fi
        output_formulae+=" ${ORANGE}$formula${NONE} ${GREY}|${NONE} "
    done

    # Casks
    for cask in $CASKS; do
        # "my-cask-name" → "My Cask Name.app"
        local app_name="$(echo "$cask" | sed -E 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1').app"

        # Check .app folders first for speed, fallback to brew if missing
        if [[ -d "/Applications/$app_name" || -d "$HOME/Applications/$app_name" ]]; then
            output_casks+="${ICON_ON}"
        elif brew list --cask "$cask" >/dev/null 2>&1; then
            output_casks+="${ICON_ON}"
        else
            output_casks+="${ICON_OFF}"
        fi
        output_casks+=" ${CYAN}$cask${NONE} ${GREY}|${NONE} "
    done

    # Print both lines (removing trailing " | ")
    print "${output_formulae% ${GREY}|${NONE} }"
    print "${output_casks% ${GREY}|${NONE} }"
    print ""
}

########################
#   RUN
########################

# Run
main