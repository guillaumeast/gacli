###############################
# FICHIER config.zsh
###############################

#!/usr/bin/env zsh

# Path
CONFIG_FILE_REL_PATH="config"
CONFIG_FILE=""

# Variables
AUTO_UPDATE=""
FREQ_DAYS=""
NEXT_UPDATE=""

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

config_init() {

    # Resolve paths
    _config_resolve || return 1

    # Load / create config
    if ! config_load; then
        config_create || return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# Functions - PRIVATE
# ────────────────────────────────────────────────────────────────

# Resolve paths
_config_resolve() {
    # Resolve Brewfile path
    CONFIG_FILE="${GACLI_PATH}/${CONFIG_FILE_REL_PATH}"

    # Check if file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        printStyled error "Config file not found at: ${CONFIG_FILE}"
        return 1
    fi
}

# Ask user for auto-update frequency (type safe)
_ask_frequency() {
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

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC (LOGIC)
# ────────────────────────────────────────────────────────────────

# Create config file (TODO: utiliser format json ou yaml pour faciliter la manipulation des datas ?)
config_create() {

    # Ensure TODAY is set
    if [[ -z "${TODAY}" ]]; then
        printStyled error "[init_config] TODAY is not set"
        return 1
    fi

    # Ask for auto-update frequency
    _ask_frequency || return 1

    # Write base config
    {
        echo "last_update = ${TODAY}"
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
        printStyled warning "Auto-update has been disabled"
        return 1
    }
}

# Update config file (wizard)
config_update() {
    # TODO
}

# Save current config variables into the config file
config_save() {
    # TODO
}

# Parse config file
config_load() {
    # TODO
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

config_init || return 1

