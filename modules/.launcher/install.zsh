###############################
# FICHIER install.zsh
###############################

#!/usr/bin/env zsh

# Global installer
gacli_install() {
    # Display logo
    display_ascii_logo          # Implemented in `gacli/modules/.core/style.zsh`

    # Config
    ask_frequency || return 1
    init_config || return 1
    update_zshrc || return 1

    # Display
    print_formulae              # Implemented in `gacli/modules/.core/brew.zsh`
    print_casks                 # Implemented in `gacli/modules/.core/brew.zsh`

    # Command availability warning
    print ""
    printStyled warning "Restart your terminal or run 'source ~/.zshrc' to unlock gacli commands"
    print ""
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
        print ""

        # Check format
        if [[ "$FREQ_DAYS" =~ ^[0-9]+$ ]] && [[ $FREQ_DAYS -gt 0 ]]; then
            break
        else
            printStyled "error" "⛔ Invalid input. Please enter a positive number"
        fi
    done
}

# Create config file
init_config() {
    # Ensure TODAY is set
    if [[ -z "${TODAY}" ]]; then
        printStyled error "[init_config] TODAY is not set"
        return 1
    fi

    # Ensure FREQ_DAYS is set
    if [[ -z "${FREQ_DAYS}" ]]; then
        printStyled error "[init_config] FREQ_DAYS is not set"
        return 1
    fi

    # Write base config
    {
        echo "date = ${TODAY}"
        echo "update_frequency = ${FREQ_DAYS}"
    } > "${CONFIG_FILE}" || {
        printStyled error "[init_config] Failed to write config file"
        return 1
    }

    # Compute next update
    local next_update
    next_update=$(add_days "${TODAY}" "${FREQ_DAYS}") || {
        printStyled error "[init_config] Failed to compute next update date"
        printStyled warning "Auto-update has been disabled"
        echo "next_update = " >> "${CONFIG_FILE}"
        return 1
    }
    echo "next_update = ${next_update}" >> "${CONFIG_FILE}" || {
        printStyled error "[init_config] Failed to write next_update to config"
        return 1
    }
}

# Update zshrc
update_zshrc() {
    local zshrc_path="$HOME/.zshrc"

    # Ask user for .zshrc if not found
    while [[ ! -f "$zshrc_path" ]]; do
        printStyled "warning" "[install_gacli] .zshrc not found at $zshrc_path"
        print -n "👉 ${BOLD}Where is your .zshrc located (full path)? ${NONE}"
        read -r zshrc_path
    done

    {
        echo ""
        echo ""
        echo "# GACLI"

        # Source gacli.zsh (if not already present)
        if ! grep -q "source \"${GACLI_PATH}/gacli.zsh\"" "$zshrc_path"; then
            echo "source \"${GACLI_PATH}/gacli.zsh\""
        fi

        # Add alias to run GACLI as command
        if ! grep -q 'alias gacli=' "$zshrc_path"; then
            echo "alias gacli=\"zsh ${GACLI_PATH}/gacli.zsh\""
        fi
    } >> "$zshrc_path" || {
        printStyled warning "[update_zshrc] Failed to write to $zshrc_path"
        return 1
    }
}

