###################################################
# FICHIER update.zsh
###################################################
#!/usr/bin/env zsh

# Update homebrew & formulae & casks
update_tools() {
    # Update Homebrew
    brew update 1>/dev/null

    # Install/uninstall formulae & casks referring to the Brewfile
    brew bundle --file="$GACLI_PATH/Brewfile" 1>/dev/null

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
    local config_file="$GACLI_PATH/.config"
    local freq_days=$(grep "^update_frequency" "$config_file" | cut -d= -f2 | xargs)

    echo "date = $TODAY" > "$config_file"
    echo "update_frequency = $freq_days" >> "$config_file"

    # Try to compute next_update date
    local next_update=$(add_days $TODAY $freq_days)
    if [[ -z "$next_update" ]]; then
        printStyled error "[update_config_file] Failed to compute next update date"
        printStyled warning "Auto-update has been disabled"
        echo "next_update = " >> "$GACLI_PATH/.config"
    else
        echo "next_update = $next_update" >> "$config_file"
    fi
}

