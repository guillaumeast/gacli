###############################
# FICHIER /.run/core/update.zsh
###############################

#!/usr/bin/env zsh

TODAY=""

# Config
CONFIG="${ROOT_DIR}/.data/config/update.config.yaml"
INITIALIZED=""
AUTO_UPDATE=""
FREQ_DAYS=""
LAST_UPDATE=""
NEXT_UPDATE=""

# Dependencies
CORE_TOOLS="${ROOT_DIR}/.data/tools/core.tools.yaml"
MODULES_TOOLS="${ROOT_DIR}/.data/tools/modules.tools.yaml"
USER_TOOLS="${ROOT_DIR}/tools.yaml"
DESCRIPTORS=("${CORE_TOOLS}" "${MODULES_TOOLS}" "${USER_TOOLS}")

# Check paths (using check_path from gacli.zsh)
_update_resolve() {
    
    local files=("${CONFIG}" "${DESCRIPTORS[@]}")
    check_path file "${files[@]}" || {
        printstyled error "[update] Unable to find required file: ${file}"
        return 1
    }
}; _update_resolve

# ────────────────────────────────────────────────────────────────
# AUTO-UPDATE
# ────────────────────────────────────────────────────────────────

# PUBLIC - Initialize config process and trigger auto-update if needed
update_init() {
    local tmp_brewfile=$(mktemp)

    # Get config values
    _update_get_config || {
        printstyled error "[update] Unable to load config"
        rm -f "${tmp_brewfile}"
        return 1
    }

    # Merge dependencies
    _update_merge_into "${tmp_brewfile}" || {
        printstyled error "[update] Unable to merge dependencies"
        rm -f "${tmp_brewfile}"
        return 1
    }

    # Run update if needed
    if [[ $(_update_is_reached) || $(_update_is_required "${tmp_brewfile}") ]]; then
        _update_run "${tmp_brewfile}"
    fi

    # Delete temporary Brewfile
    rm -f "${tmp_brewfile}"

    # Display next update status (date or "disabled")
    _update_display_next
}

# PRIVATE - Check if the scheduled auto-update date is reached
_update_is_reached() {

    # Check if auto update is enabled
    [[ "${AUTO_UPDATE}" = "false" ]] && return 1

    # Check if next_update is defined
    if [[ -z "$NEXT_UPDATE" || ! "$NEXT_UPDATE" =~ ^[0-9]+$ ]]; then
        printStyled warning "[update] Unable to parse next update date → Auto-update disabled"
        AUTO_UPDATE="false" && NEXT_UPDATE=""
        _update_set_config
        return 1
    fi

    # Check if next_update is reached
    if (( TODAY < NEXT_UPDATE )); then
        return 1
    fi
}

# PRIVATE - Check if any required dependency is missing in the system
_update_is_required() {
    local brewfile="${1}"
    local dependencie

    # Check if formulae are missing
    parser_read "${brewfile}" formulae
    for dependencie in "${BUFFER[@]}"; do
        brew_is_f_active "${dependencie}" || return 0
    done

    # Check if formulae are missing
    parser_read "${brewfile}" casks
    for dependencie in "${BUFFER[@]}"; do
        brew_is_c_active "${dependencie}" || return 0
    done

    return 1
}

# ────────────────────────────────────────────────────────────────
# MANUAL UPDATE
# ────────────────────────────────────────────────────────────────

# PRIVATE - Run manual update by merging and applying all dependencies
_update_manual() {
    local tmp_brewfile=$(mktemp)

    # Merge all dependencies
    _update_merge_into "${tmp_brewfile}" || {
        printstyled error "[update] Unable to merge dependencies"
        rm -f "${tmp_brewfile}"
        return 1
    }

    _update_run "${tmp_brewfile}" || {
        printstyled error "[update] Update failed"
        rm -f "${tmp_brewfile}"
        return 1
    }
}

# PUBLIC - Generate temporary merged Brewfile with all dependencies (core + modules + user)
update_merge_into() {
    local output_brewfile="${1}"

    # Download missing modules and merge modules dependencies
    modules_init || {
        printstyled error "[update] Unable to init modules"
        return 1
    }

    for descriptor in $DESCRIPTORS; do
        parser_read "${descriptor}" formulae || return 1
        parser_write "${output_brewfile}" formulae "${BUFFER[@]}" || return 1
        parser_read "${descriptor}" casks || return 1
        parser_write "${output_brewfile}" casks "${BUFFER[@]}" || return 1
    done
}

# PRIVATE - Execute the update process and save new status in config file
_update_run() {
    local brewfile="${1}"
    # Update Homebrew, formulae and casks (Implemented in `gacli/modules/.core/brew.zsh`)
    brew_update "${brewfile}" || return 1

    # Update variables
    LAST_UPDATE="${TODAY}"
    if [[ $AUTO_UPDATE = true ]]; then
        if ! NEXT_UPDATE="$(time_add_days "${LAST_UPDATE}" "${FREQ_DAYS}")"; then
            printStyled warning "[_update_manual] Failed to compute next update date"
            printStyled warning "Auto-update disabled"
            AUTO_UPDATE=false
            NEXT_UPDATE=""
        fi
    fi

    # Save
    _update_set_config

    # Update 

    # Display result
    printStyled success "Updated 🚀"
    _update_display_next
}

# ────────────────────────────────────────────────────────────────
# CONFIG MANAGEMENT
# ────────────────────────────────────────────────────────────────

# PRIVATE - Load auto-update config from config file or trigger config file initialization
_update_get_config() {

    # Read values from config file
    parser_read "${CONFIG}" "initialized" || return 1
    INITIALIZED="${BUFFER[1]}" || return 1

    parser_read "${CONFIG}" "auto_update" || return 1
    AUTO_UPDATE="${BUFFER[1]}" || return 1

    parser_read "${CONFIG}" "last_update" || return 1
    LAST_UPDATE="${BUFFER[1]}" || return 1

    parser_read "${CONFIG}" "freq_days" || return 1
    FREQ_DAYS="${BUFFER[1]}" || return 1

    parser_read "${CONFIG}" "next_update" || return 1
    NEXT_UPDATE="${BUFFER[1]}" || return 1

    # Init config at first launch
    [[ $INITIALIZED = "false" ]] && update_edit_config || return 1

    # Get current date if auto-update is enabled
    [[ $AUTO_UPDATE = "true" ]] && TODAY="$(time_get_current)" || return 1
}

# PUBLIC - Configure auto-update settings based on user input
update_edit_config() {

    # Ask for auto-update frequency
    _update_ask_freq || return 1

    # Setup auto-update
    if [[ $FREQ_DAYS = 0 || -z $FREQ_DAYS ]]; then
        AUTO_UPDATE="false"
        NEXT_UPDATE=""
    else
        if ! NEXT_UPDATE="$(time_add_days "${TODAY}" "${FREQ_DAYS}")"; then
            printStyled warning "[update_edit_config] Failed to compute next update date"
            printStyled warning "Auto-update disabled"
            AUTO_UPDATE=false
            NEXT_UPDATE=""
        else
            AUTO_UPDATE="true"
        fi
    fi

    # Save
    INITIALIZED="true"
    _update_set_config || return 1
}

# PRIVATE - Save current update config values to config file
_update_set_config() {

    parser_write "${CONFIG}" "initialized" "${INITIALIZED}" || return 1
    parser_write "${CONFIG}" "auto_update" "${AUTO_UPDATE}" || return 1
    parser_write "${CONFIG}" "last_update" "${LAST_UPDATE}" || return 1
    parser_write "${CONFIG}" "freq_days" "${FREQ_DAYS}" || return 1
    parser_write "${CONFIG}" "next_update" "${NEXT_UPDATE}" || return 1
}

# ────────────────────────────────────────────────────────────────
# I/O
# ────────────────────────────────────────────────────────────────

# PRIVATE - Ask user for auto-update frequency (type safe)
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

        # Check format
        if [[ "$FREQ_DAYS" =~ ^[0-9]+$ ]]; then
            break
        else
            printStyled "error" "⛔ Invalid input. Please enter a number\n"
        fi
    done
}

# PRIVATE - Display the next scheduled auto-update date or status
_update_display_next() {
    # Display next update date
    if [[ $AUTO_UPDATE = true ]]; then
        printStyled info "Next update on: $(time_to_human "${NEXT_UPDATE}")"
    else
        printStyled info "Auto updates disabled"
    fi
}

