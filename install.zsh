###################################################
# FICHIER install.zsh
###################################################
#!/usr/bin/env zsh

# Global installer
install_gacli() {
    # Config
    ask_frequency
    create_config_file

    # Install
    install_brew
    update_tools
    update_zshrc
}

# Ask user for auto-update frequency (type safe)
ask_frequency() {
    # Welcome Message
    print "👋 ${CYAN}Welcome to ${BOLD}${ORANGE}GACLI${NONE}${CYAN}, the CLI that makes your dev life easier!${NONE}"
    print ""
    print "${CYAN}Let’s start by choosing the update frequency,${NONE}"
    print "${CYAN}then I’ll take care of installing all the tools you need${NONE} 💻✨"
    print ""

    # Question
    while true; do
        print -n "👉 ${BOLD}How many days between each auto-update? ${NONE}"
        read -r FREQ_DAYS

        # Check format
        if [[ "$FREQ_DAYS" =~ ^[0-9]+$ ]] && [[ $FREQ_DAYS -gt 0 ]]; then
            break
        else
            printStyled "error" "⛔ Invalid input. Please enter a positive number"
        fi
    done

    # Loading mesage
    print ""
    printStyled "info" "Installing all tools... (this may take a few minutes) ⏳"
}

# Homebrew installer
install_brew() {
    # Homebrew install
    if ! command -v brew >/dev/null 2>&1; then
        printStyled info "Installing ${ORANGE}Homebrew${GREY}..."

        if $IS_MACOS; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        elif $IS_LINUX; then
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            printStyled error "[install_brew] Unsupported OS: $OSTYPE"
            return 1
        fi

        # Add Homebrew to PATH for current session (cross-platform)
        local brew_exec_path="$(command -v brew)"
        eval "$("$brew_exec_path" shellenv)"

        # Refresh command hash table
        hash -r
    fi
}

# Create config file
create_config_file() {
    echo "date = $TODAY" > "$GACLI_PATH/.config"
    echo "update_frequency = $FREQ_DAYS" >> "$GACLI_PATH/.config"
    
    # Try to compute date (coreutils needed)
    local next_update=$(add_days $TODAY $FREQ_DAYS)
    if [[ -z "$next_update" ]]; then
        printStyled error "[create_config_file] Failed to compute next update date"
        printStyled warning "Auto-update has been disabled"
        echo "next_update = " >> "$GACLI_PATH/.config"
    else
        echo "next_update = $next_update" >> "$GACLI_PATH/.config"
    fi
}

# Update zshrc (source + path)
update_zshrc() {
    local zshrc_path="$HOME/.zshrc"

    # Ask user for .zshrc if not found
    while [[ ! -f "$zshrc_path" ]]; do
        printStyled "warning" "[install_gacli] .zshrc not found at $zshrc_path"
        print -n "👉 ${BOLD}Where is your .zshrc located (full path)? ${NONE}"
        read -r zshrc_path
    done

    # Add GACLI to PATH (if not already present)
    if ! grep -q "export PATH=.*$GACLI_PATH" "$zshrc_path"; then
        echo "\n# GACLI\nexport PATH=\"\$PATH:$GACLI_PATH\"" >> "$zshrc_path"
    fi

    # Source main.zsh (if not already present)
    if ! grep -q "source \"$GACLI_PATH/main.zsh\"" "$zshrc_path"; then
        echo "source \"$GACLI_PATH/main.zsh\"" >> "$zshrc_path"
    fi
}

