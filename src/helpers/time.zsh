#!/usr/bin/env zsh
###############################
# FICHIER /src/helpers/time.zsh
###############################

# TODO: coreutils no more required thanks to gdate → date fallback ??
TIME_DEPS=("coreutils")

TIME_CMD="gdate"
TIME_CMD_FALLBACK="date"

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# time_get_current => timestamp
time_get_current() {

    local current_ts

    current_ts="$("${TIME_CMD}" +%s)" && echo "${current_ts}" && return

    current_ts="$("${TIME_CMD_FALLBACK}" +%s)" && echo "${current_ts}" && return

    printui error "Failed to get current timestamp"
    return 1
}

# time_add_days <timestamp:date> <int:add> => timestamp
time_add_days() {

    local start_ts="$1"
    local add="$2"

    if [[ -z "${start_ts}" || -z "${add}" ]]; then
        printui error "Expected : <start_ts> <add> (received : ${1} ${2})"
        return 1
    fi

    if ! [[ "${start_ts}" =~ ^[0-9]+$ && "${add}" =~ ^[0-9]+$ ]]; then
        printui error "Both arguments must be positive integers"
        return 1
    fi

    echo $((86400 * $add + $start_ts))
}

# time_to_human <timestamp:date> => YYYY-MM-DD
time_to_human() {

    local ts="$1"

    if [[ -z "$ts" || ! "$ts" =~ ^[0-9]+$ ]]; then
        printui error "Expected a timestamp (received: ${1})"
        return 1
    fi

    if ! "${TIME_CMD}" -u -d "@$ts" "+%Y-%m-%d" && ! "${TIME_CMD_FALLBACK}" -u -d "@$ts" "+%Y-%m-%d"; then
        printui error "Conversion failed"
        return 1
    fi
}

# time_from_human <YYYY-MM-DD:date> => timestamp
time_from_human() {

    local date_str="${1}"

    if [[ -z "${date_str}" || ! "${date_str}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        printui error "Expected format: YYYY-MM-DD (received: ${1})"
        return 1
    fi

    if ! "${TIME_CMD}" -u -d "${date_str}" +%s && ! "${TIME_CMD_FALLBACK}" -u -d "${date_str}" +%s; then
        printui error "Conversion failed"
        return 1
    fi
}
