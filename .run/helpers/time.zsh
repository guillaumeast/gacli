###############################
# FICHIER /.run/helpers/time.zsh
###############################

#!/usr/bin/env zsh

# (requires coreutils)
# Dates are manipulated in UNIX timestamp format

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

# Returns current timestamp
time_get_current() {
    local current_ts
    if ! current_ts="$(gdate +%s)"; then
        printStyled error "[time_get_current] Failed to get current timestamp"
        return 1
    fi
    echo "${current_ts}"
}

# Add a number of days to a timestamp and return result as timestamp
time_add_days() {

    # Variables
    local start_ts="$1"
    local add="$2"

    # Arguments checks
    if [[ -z "${start_ts}" || -z "${add}" ]]; then
        printStyled error "[time_add_days] Expected : <start_ts> <add> (received : ${1} ${2})"
        return 1
    fi
    if ! [[ "${start_ts}" =~ ^[0-9]+$ && "${add}" =~ ^[0-9]+$ ]]; then
        printStyled error "[time_add_days] Both arguments must be positive integers"
        return 1
    fi

    # Dependency check
    if ! command -v gdate >/dev/null 2>&1; then
        printStyled error "[time_add_days] Missing dependency: gdate (from coreutils)"
        return 1
    fi

    # Compute
    echo $((86400 * $add + $start_ts))
}

# Convert UNIX timestamp to YYYY-MM-DD
time_to_human() {
    local ts="$1"
    if [[ -z "$ts" || ! "$ts" =~ ^[0-9]+$ ]]; then
        printStyled error "[time_to_human] Expected a timestamp (received: ${1})"
        return 1
    fi

    if ! gdate -d "@$ts" "+%Y-%m-%d"; then
        printStyled error "[time_to_human] Conversion failed"
        return 1
    fi
}

# Convert YYYY-MM-DD to UNIX timestamp
time_from_human() {
    local date_str="${1}"

    # Check format
    if [[ -z "${date_str}" || ! "${date_str}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        printStyled error "[time_from_human] Expected format: YYYY-MM-DD (received: ${1})"
        return 1
    fi

    # Dependency check
    if ! command -v gdate >/dev/null 2>&1; then
        printStyled error "[time_from_human] Missing dependency: gdate (from coreutils)"
        return 1
    fi

    # Convert
    if ! gdate -d "${date_str}" +%s; then
        printStyled error "[time_from_human] Conversion failed"
        return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# WIP: DEBUG
# ────────────────────────────────────────────────────────────────

printStyled debug "----> 4. time.zsh loaded"

