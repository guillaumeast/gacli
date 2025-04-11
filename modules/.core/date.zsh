###############################
# FICHIER date.zsh
###############################

#!/usr/bin/env zsh
# (requires coreutils)

# Variables
TODAY=""

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

# Set TODAY value
date_init() {
    if ! TODAY="$(date "+%Y-%m-%d")"; then
        printStyled error "[date_init] Failed to get current date"
        return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

# Add a number of days to a date
add_days() {
    # Variables
    local start_date="$1"
    local add="$2"

    # Argument 1 check
    if [[ -z "$start_date" || -z "$add" ]]; then
        printStyled error "[add_days] Expected : <start_date> <add> (received : $1 $2)"
        return 1
    fi

    # Argument 2 check
    if ! [[ "$add" =~ ^[0-9]+$ ]]; then
        printStyled error "[add_days] <add> must be a positive number (received : $add)"
        return 1
    fi

    # Dependency check
    if ! command -v gdate >/dev/null 2>&1; then
        printStyled error "[add_days] Missing dependency: gdate (from coreutils)"
        return 1
    fi

    # Logic
    if ! gdate -d "$start_date +$add days" "+%Y-%m-%d"; then
        printStyled error "[add_days] Failed to compute date from '$start_date'"
        return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

date_init || return 1

