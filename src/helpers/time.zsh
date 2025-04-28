#!/usr/bin/env zsh
###############################
# FICHIER /src/helpers/time.zsh
###############################

TIME_CMD=""

# ────────────────────────────────────────────────────────────────
# INIT
# ────────────────────────────────────────────────────────────────

# Set TIME_CMD depending on platform (gdate or date)
time_init() {

    if command -v gdate; then
        TIME_CMD="gdate"
    elif command -v date; then
        TIME_CMD="date"
    else
        printStyled error "Unable to find ${ORANGE}gdate${NONE} or ${ORANGE}date${NONE}"
    fi
}

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# Returns current timestamp
time_get_current() {

    # Variables
    local current_ts

    # Fetch current date
    if ! current_ts="$("${TIME_CMD}" +%s)"; then
        printStyled error "Failed to get current timestamp"
        return 1
    fi

    # Return value
    echo "${current_ts}"
}

# Add a number of days to a timestamp and return result as timestamp
time_add_days() {

    # Variables
    local start_ts="$1"
    local add="$2"

    # Arguments checks
    if [[ -z "${start_ts}" || -z "${add}" ]]; then
        printStyled error "Expected : <start_ts> <add> (received : ${1} ${2})"
        return 1
    fi
    if ! [[ "${start_ts}" =~ ^[0-9]+$ && "${add}" =~ ^[0-9]+$ ]]; then
        printStyled error "Both arguments must be positive integers"
        return 1
    fi

    # Compute
    echo $((86400 * $add + $start_ts))
}

# Convert UNIX timestamp to YYYY-MM-DD
time_to_human() {

    # Variables
    local ts="$1"

    # Arguments checks
    if [[ -z "$ts" || ! "$ts" =~ ^[0-9]+$ ]]; then
        printStyled error "Expected a timestamp (received: ${1})"
        return 1
    fi

    # Convert
    if ! "${TIME_CMD}" -u -d "@$ts" "+%Y-%m-%d"; then
        printStyled error "Conversion failed"
        return 1
    fi
}

# Convert YYYY-MM-DD to UNIX timestamp
time_from_human() {

    # Variables
    local date_str="${1}"

    # Arguments checks
    if [[ -z "${date_str}" || ! "${date_str}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        printStyled error "Expected format: YYYY-MM-DD (received: ${1})"
        return 1
    fi

    # Convert
    if ! "${TIME_CMD}" -u -d "${date_str}" +%s; then
        printStyled error "Conversion failed"
        return 1
    fi
}

