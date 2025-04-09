###############################
# FICHIER update.zsh
###############################

#!/usr/bin/env zsh

# Update if next_update >= TODAY (needs coreutils installed)
gacli_auto_update() {
    # Dependency check
    if ! command -v gdate >/dev/null 2>&1; then
        printStyled warning "[gacli_auto_update] Missing dependency: coreutils → skipping"
        printStyled highlight "You can execute manual update by running `gacli update`"
        return 1
    fi

    # Variables
    local next_update=$(grep "^next_update =" "${CONFIG_FILE}" | cut -d= -f2 | xargs)
    if [[ -z "$next_update" ]]; then
        printStyled warning "[gacli_auto_update] No next_update date found in config → skipping"
        printStyled highlight "You can execute manual update by running `gacli update`"
        return 1
    fi

    # Parse TODAY date
    local today_ts next_ts
    if ! today_ts=$(gdate -d "${TODAY}" +%s 2>/dev/null); then
        printStyled warning "[gacli_auto_update] Failed to parse TODAY ($TODAY) → skipping"
        printStyled highlight "You can execute manual update by running `gacli update`"
        return 1
    fi

    # Parse next_update date
    if ! next_ts=$(gdate -d "${next_update}" +%s 2>/dev/null); then
        printStyled warning "[gacli_auto_update] Failed to parse next_update ($next_update) → skipping"
        printStyled highlight "You can execute manual update by running `gacli update`"
        return 1
    fi

    # Logic
    if (( today_ts >= next_ts )); then
        gacli_update || return 1
    fi
}

# Update homebrew & formulae & casks
gacli_update() {
    # Update Homebrew, formulae and casks (Implemented in `gacli/modules/.core/brew.zsh`)
    brew_update || return 1

    # Update config file
    config_update || return 1

    # Display result
    printStyled success "Updated 🚀"
    print ""
}

# Update config file
config_update() {
    # Extract frequency
    local freq_days
    freq_days=$(grep "^update_frequency" "${CONFIG_FILE}" | cut -d= -f2 | xargs)
    if [[ -z "${freq_days}" ]]; then
        printStyled error "[config_update] Failed to extract update_frequency from config"
        printStyled warning "Auto-update disabled"
        return 1
    fi

    # Write base config
    {
        echo "date = ${TODAY}"
        echo "update_frequency = ${freq_days}"
    } > "${CONFIG_FILE}" || {
        printStyled error "[config_update] Failed to write config"
        printStyled warning "Auto-update disabled"
        return 1
    }

    # Compute next_update
    local next_update
    next_update=$(add_days "${TODAY}" "${freq_days}") || {
        printStyled error "[config_update] Failed to compute next update date"
        printStyled warning "Auto-update disabled"
        echo "next_update = " >> "${CONFIG_FILE}"
        return 1
    }

    echo "next_update = ${next_update}" >> "${CONFIG_FILE}" || {
        printStyled error "[config_update] Failed to write next_update to config"
        printStyled warning "Auto-update disabled"
        return 1
    }
}

