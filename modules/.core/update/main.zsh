###############################
# FICHIER gacli/modules/.core/update/main.zsh
###############################

#!/usr/bin/env zsh

# Variables
LAST_UPDATE_KEY="update_last"
LAST_UPDATE=""

FREQ_DAYS_KEY="update_frequency"
FREQ_DAYS=""

NEXT_UPDATE_KEY="update_next"
NEXT_UPDATE=""

AUTO_UPDATE_KEY="update_auto"
AUTO_UPDATE=""

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

update_init() {

    # Initialize config if needed
    local test="$(get_config "${AUTO_UPDATE_KEY}")"
    if [[ $test = "null" ]]; then
        # Enable auto updates (default)
        AUTO_UPDATE=true
        set_config "${AUTO_UPDATE_KEY}" "${AUTO_UPDATE}"

        # Set last update to now (default)
        LAST_UPDATE="$(get_current_ts)" || return 1
        set_config "${LAST_UPDATE_KEY}" "${LAST_UPDATE}" || return 1

        # 
        update_config || return 1
    else
        # Load values from config
        LAST_UPDATE="$(get_config "${LAST_UPDATE_KEY}")" || return 1
        FREQ_DAYS="$(get_config "${FREQ_DAYS_KEY}")" || return 1
        NEXT_UPDATE="$(get_config "${NEXT_UPDATE_KEY}")" || return 1
        AUTO_UPDATE="$(get_config "${AUTO_UPDATE_KEY}")" || return 1
    fi

    # Display next update date
    if [[ $AUTO_UPDATE = true ]]; then
        printStyled info "Next update on: $(date_to_human "${NEXT_UPDATE}")"
    else
        printStyled info "Auto updates disabled"
    fi
}

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

# Edit auto-update config
update_config() {

    # Ask for auto-update frequency
    _ask_frequency || return 1 # TODO: create generic `ask` function inside `io.zsh` and rename `io.zsh` -> `io.zsh`
    set_config "${FREQ_DAYS_KEY}" "${FREQ_DAYS}" || return 1

    if [[ $FREQ_DAYS = 0 || -z $FREQ_DAYS ]]; then
        AUTO_UPDATE=false
        NEXT_UPDATE=""
    else
        AUTO_UPDATE=true
        NEXT_UPDATE="$(date_add "${LAST_UPDATE}" "${FREQ_DAYS}")" || return 1
    fi

    # Compute NEXT_UPDATE
    set_config "${AUTO_UPDATE_KEY}" "${AUTO_UPDATE}" || return 1
    set_config "${NEXT_UPDATE_KEY}" "${NEXT_UPDATE}" || return 1
}

# Auto-update GACLI if needed (based on config.json and coreutils)
update_auto() {
    local today

    # Check if auto update is enabled
    if [[ "${AUTO_UPDATE}" = false ]]; then
        printStyled info "[gacli_auto_update] Auto-update is disabled → skipping"
        return 0
    fi

    # Check if next_update is defined
    if [[ -z "$NEXT_UPDATE" ]]; then
        printStyled warning "[gacli_auto_update] No next update date found"
        printStyled warning "Auto-update disabled"
        AUTO_UPDATE=false
        set_config "${AUTO_UPDATE_KEY}" "${AUTO_UPDATE}"
        return 1
    fi

    # Get current timestamp
    if ! today="$(get_current_ts)"; then
        printStyled warning "Auto-update disabled"
        AUTO_UPDATE=false
        set_config "${AUTO_UPDATE_KEY}" "${AUTO_UPDATE}"
        return 1
    fi

    # If update is due
    if (( today >= NEXT_UPDATE )); then
        update_manual || return 1
    fi
}

# Update homebrew & formulae & casks
update_manual() {
    # Update Homebrew, formulae and casks (Implemented in `gacli/modules/.core/brew.zsh`)
    brew_update || return 1

    # Update variables
    LAST_UPDATE="$(get_current_ts)"
    if [[ $AUTO_UPDATE = true ]]; then
        if ! NEXT_UPDATE="$(date_add "${LAST_UPDATE}" "${FREQ_DAYS}")"; then
            printStyled warning "[update_manual] Failed to compute next update date"
            printStyled warning "Auto-update disabled"
            AUTO_UPDATE=false
            NEXT_UPDATE=""
        fi
    fi

    # Update config file
    set_config "${LAST_UPDATE_KEY}" "${LAST_UPDATE}"
    set_config "${NEXT_UPDATE_KEY}" "${NEXT_UPDATE}"
    set_config "${AUTO_UPDATE_KEY}" "${AUTO_UPDATE}"

    # Display result
    printStyled success "Updated 🚀"
    print ""
}

# ────────────────────────────────────────────────────────────────
# Functions - PRIVATE
# ────────────────────────────────────────────────────────────────

# Ask user for auto-update frequency (type safe)
_ask_frequency() {
    # Welcome Message
    print ""
    print "👋 ${CYAN}Welcome to ${BOLD}${ORANGE}GACLI${NONE}${CYAN}, the CLI that makes your dev life easier!${NONE}"
    print ""
    print "${CYAN}Let’s start by choosing the ${BOLD}${ORANGE}update frequency${NONE}${CYAN},${NONE}"
    print "${CYAN}then I’ll take care of installing all the tools you need${NONE} 💻✨"
    print ""

    # Question
    while true; do
        print -n "👉 ${BOLD}How many days between each auto-update? (OFF = 0) ${NONE}"
        read -r FREQ_DAYS
        print ""

        # Check format
        if [[ "$FREQ_DAYS" =~ ^[0-9]+$ ]]; then
            break
        else
            printStyled "error" "⛔ Invalid input. Please enter a number\n"
        fi
    done
}

# ────────────────────────────────────────────────────────────────
# INIT
# ────────────────────────────────────────────────────────────────

io_init || return 1

