###############################
# FICHIER /.run/core/update.zsh
###############################

#!/usr/bin/env zsh

# Variables
INITIALIZED=""
AUTO_UPDATE=""
FREQ_DAYS=""
LAST_UPDATE=""
NEXT_UPDATE=""

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

update_init() {

    # Get data
    _update_get_config || return 1

    # Initialize config
    if [[ "$INITIALIZED" == "false" ]]; then
        update_edit_config || return 1
    fi

    # Update if needed
    update_auto

    # Display next update date
    if [[ $AUTO_UPDATE = true ]]; then
        printStyled info "Next update on: $(time_to_human "${NEXT_UPDATE}")"
    else
        printStyled info "Auto updates disabled"
    fi
}

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

# Edit auto-update config
update_edit_config() {

    # Ask for auto-update frequency
    _update_ask_freq || return 1 # TODO: create generic `ask` function inside `io.zsh` and rename `io.zsh` -> `io.zsh`

    # Setup auto-update
    LAST_UPDATE="$(time_get_current)" || {
        printStyled error "[update_edit_config] Failed to initialize LAST_UPDATE"
        return 1
    }
    if [[ $FREQ_DAYS = 0 || -z $FREQ_DAYS ]]; then
        AUTO_UPDATE="false"
        NEXT_UPDATE=""
    else
        if ! NEXT_UPDATE="$(time_add_days "${LAST_UPDATE}" "${FREQ_DAYS}")"; then
            printStyled warning "[update_manual] Failed to compute next update date"
            printStyled warning "Auto-update disabled"
            AUTO_UPDATE=false
            NEXT_UPDATE=""
        else
            AUTO_UPDATE="true"
        fi
    fi

    # Perform initial update
    update_manual || return 1

    # Save
    INITIALIZED="true"
    _update_set_config || return 1
}

# Auto-update GACLI if needed (based on config.json and coreutils)
update_auto() {
    local today

    # Check if auto update is enabled
    if [[ "${AUTO_UPDATE}" == "false" ]]; then
        printStyled info "[gacli_auto_update] Auto-update is disabled → skipping"
        return 0
    fi

    # Check if next_update is defined
    if [[ -z "$NEXT_UPDATE" ]] || ! [[ "$NEXT_UPDATE" =~ ^[0-9]+$ ]]; then
        printStyled warning "[update_auto] Invalid NEXT_UPDATE timestamp"
        printStyled warning "Auto-update disabled"
        AUTO_UPDATE="false" && _update_set_config
        NEXT_UPDATE=""
        return 1
    fi

    # Get current timestamp
    if ! today="$(time_get_current)"; then
        printStyled warning "[gacli_auto_update] Unable to get current timestamp"
        printStyled warning "Auto-update disabled"
        AUTO_UPDATE="false" && _update_set_config
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
    LAST_UPDATE="$(time_get_current)"
    if [[ $AUTO_UPDATE = true ]]; then
        if ! NEXT_UPDATE="$(time_add_days "${LAST_UPDATE}" "${FREQ_DAYS}")"; then
            printStyled warning "[update_manual] Failed to compute next update date"
            printStyled warning "Auto-update disabled"
            AUTO_UPDATE=false
            NEXT_UPDATE=""
        fi
    fi

    # Save
    _update_set_config

    # Display result
    printStyled success "Updated 🚀"
    print ""
}

# ────────────────────────────────────────────────────────────────
# Functions - PRIVATE
# ────────────────────────────────────────────────────────────────

_update_get_config() {
    local section="update_settings"

    parser_read "$CONFIG" "${section}.initialized" || return 1
    INITIALIZED="${BUFFER[1]}" || return 1

    parser_read "$CONFIG" "${section}.auto_update" || return 1
    AUTO_UPDATE="${BUFFER[1]}" || return 1

    parser_read "$CONFIG" "${section}.last_update" || return 1
    LAST_UPDATE="${BUFFER[1]}" || return 1

    parser_read "$CONFIG" "${section}.freq_days" || return 1
    FREQ_DAYS="${BUFFER[1]}" || return 1

    parser_read "$CONFIG" "${section}.next_update" || return 1
    NEXT_UPDATE="${BUFFER[1]}" || return 1
}

_update_set_config() {
    local section="update_settings"

    parser_write "$CONFIG" "${section}.initialized" "${INITIALIZED}" || return 1
    parser_write "$CONFIG" "${section}.auto_update" "${AUTO_UPDATE}" || return 1
    parser_write "$CONFIG" "${section}.last_update" "${LAST_UPDATE}" || return 1
    parser_write "$CONFIG" "${section}.freq_days" "${FREQ_DAYS}" || return 1
    parser_write "$CONFIG" "${section}.next_update" "${NEXT_UPDATE}" || return 1
}

# Ask user for auto-update frequency (type safe)
_update_ask_freq() {
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
# WIP: DEBUG
# ────────────────────────────────────────────────────────────────

printStyled debug "=====> 5. update.zsh loaded"

