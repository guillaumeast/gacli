#!/usr/bin/env zsh
###############################
# FICHIER /src/logic/update.zsh
###############################

TODAY=""

# Config
INITIALIZED=""
AUTO_UPDATE=""
FREQ_DAYS=""
LAST_UPDATE=""
NEXT_UPDATE=""

# ────────────────────────────────────────────────────────────────
# AUTO-UPDATE
# ────────────────────────────────────────────────────────────────

# PUBLIC - Initialize config process and trigger auto-update if needed
update_init() {
    local tmp_brewfile="${DIR_TMP}/Brewfile"

    # Get config values
    _update_get_config || {
        printStyled error "Unable to load config"
        return 1
    }

    # Merge dependencies
    update_merge_into "${tmp_brewfile}" || {
        printStyled error "Unable to merge dependencies"
        rm -f "${tmp_brewfile}"
        return 1
    }

    # Run update if needed
    if [[ $(_update_is_reached) || $(_update_is_required "${tmp_brewfile}") ]]; then
        _update_run "${tmp_brewfile}" || printStyled warning "Unable to run update"
    fi

    # Delete temporary Brewfile
    rm -f "${tmp_brewfile}"
}

# PRIVATE - Check if the scheduled auto-update date is reached
_update_is_reached() {

    # Check if auto update is enabled
    [[ "${AUTO_UPDATE}" = "false" ]] && return 1

    # Check if next_update is defined
    if [[ -z "$NEXT_UPDATE" || ! "$NEXT_UPDATE" =~ ^[0-9]+$ ]]; then
        printStyled warning "Unable to parse next update date: '${NEXT_UPDATE}' \n    └→ Auto-update disabled"
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
    local dependencies=()
    local dependencie=""

    # Check if formulae are missing
    dependencies=("${(@f)$(file_read "${brewfile}" formulae)}")
    for dependencie in "${dependencies[@]}"; do
        brew_is_f_active "${dependencie}" || return 0
    done

    # Check if casks are missing
    dependencies=("${(@f)$(file_read "${brewfile}" casks)}")
    for dependencie in "${dependencies[@]}"; do
        brew_is_c_active "${dependencie}" || return 0
    done

    return 1
}

# ────────────────────────────────────────────────────────────────
# MANUAL UPDATE
# ────────────────────────────────────────────────────────────────

# PRIVATE - Run manual update by merging and applying all dependencies
_update_manual() {
    local tmp_brewfile="${DIR_TMP}/Brewfile"

    # Merge all dependencies
    update_merge_into "${tmp_brewfile}" || {
        printStyled error "Unable to merge dependencies"
        rm -f "${tmp_brewfile}"
        return 1
    }

    _update_run "${tmp_brewfile}" || {
        printStyled error "Update failed"
        rm -f "${tmp_brewfile}"
        return 1
    }
}

# PUBLIC - Generate temporary merged Brewfile with all dependencies (core + modules + user)
update_merge_into() {

    # Variables
    local output_brewfile="$1"
    local descriptor=""
    local formulae=()
    local casks=()

    # Check arguments
    if [[ -z "${output_brewfile}" ]]; then
        printStyled error "Expected : <output_brewfile> (received : ${1})"
        return 1
    fi

    # Reset merged file
    echo "" > "${output_brewfile}" || {
        printStyled error "Unable to create merged Brewfile: ${output_brewfile}"
        return 1
    }

    # Merge content
    for descriptor in "${FILES_TOOLS[@]}"; do
        [[ ! -f "${descriptor}" ]] && continue
        formulae=("${(@f)$(file_read "${descriptor}" formulae)}")
        casks=("${(@f)$(file_read "${descriptor}" casks)}")

        # Intro
        {
            echo ""
            echo "############################################"
            echo "# Dependencies from ${descriptor}:"
            echo ""
        } >> "${output_brewfile}" || printStyled warning "Unable to write into: ${output_brewfile}"

        # Content
        file_add "${output_brewfile}" formulae "${formulae[@]}"
        file_add "${output_brewfile}" casks "${casks[@]}"

        # Final line
        echo "" >> "${output_brewfile}"
    done
}


# PRIVATE - Execute the update process and save new status in config file
_update_run() {
    local brewfile="${1}"
    # Update Homebrew, formulae and casks (Implemented in `gacli/modules/.core/brew.zsh`)
    brew_bundle "${brewfile}" || return 1

    # Update variables
    LAST_UPDATE="${TODAY}"
    if [[ $AUTO_UPDATE = true ]]; then
        if ! NEXT_UPDATE="$(time_add_days "${LAST_UPDATE}" "${FREQ_DAYS}")"; then
            printStyled warning "Failed to compute next update date"
            printStyled warning "Auto-update disabled"
            AUTO_UPDATE=false
            NEXT_UPDATE=""
        fi
    fi

    # Save
    _update_set_config

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
    INITIALIZED="$(file_read "${FILE_CONFIG_UPDATE}" "initialized")" || return 1
    AUTO_UPDATE="$(file_read "${FILE_CONFIG_UPDATE}" "auto_update")" || return 1
    LAST_UPDATE="$(file_read "${FILE_CONFIG_UPDATE}" "last_update")" || return 1
    FREQ_DAYS="$(file_read "${FILE_CONFIG_UPDATE}" "freq_days")" || return 1
    NEXT_UPDATE="$(file_read "${FILE_CONFIG_UPDATE}" "next_update")" || return 1

    # Get current date
    TODAY="$(time_get_current)" || return 1

    # Init config at first launch
    if [[ $INITIALIZED != "true" ]]; then
        update_edit_config || return 1
        return 0
    fi
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
            printStyled warning "Failed to compute next update date"
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
    _update_display_next
    echo ""
}

# PRIVATE - Save current update config values to config file
_update_set_config() {

    file_write "${FILE_CONFIG_UPDATE}" "initialized" "${INITIALIZED}" || return 1
    file_write "${FILE_CONFIG_UPDATE}" "auto_update" "${AUTO_UPDATE}" || return 1
    file_write "${FILE_CONFIG_UPDATE}" "last_update" "${LAST_UPDATE}" || return 1
    file_write "${FILE_CONFIG_UPDATE}" "freq_days" "${FREQ_DAYS}" || return 1
    file_write "${FILE_CONFIG_UPDATE}" "next_update" "${NEXT_UPDATE}" || return 1
}

# ────────────────────────────────────────────────────────────────
# I/O
# ────────────────────────────────────────────────────────────────

# PRIVATE - Ask user for auto-update frequency (type safe)
_update_ask_freq() {

    while true; do
        echo ""
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

