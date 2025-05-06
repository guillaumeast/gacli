#!/usr/bin/env zsh

FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
DELAY=0.1
DEFAULT_MESSAGE="Loading..."
MESSAGE=""
PAUSED="false"
SPINNER_PID=""

# ⚠️ Don't forget in calling function → trap 'loader_stop' EXIT
loader_start() {

    local message="${1:-$DEFAULT_MESSAGE}"

    [[ "${PAUSED}" == "false" ]] && MESSAGE="${message}"

    # Kill previous loader process if exists
    PAUSED="false"
    loader_stop

    # Create process
    {
        while true; do
            for frame in "${FRAMES[@]}"; do
                printf "\r\033[K%s %s" "${frame}" "${MESSAGE}"
                sleep $DELAY
            done
        done
    } &

    # Save process ID
    SPINNER_PID=$!
}

loader_pause() {
    
    PAUSED="true"
    loader_stop
}

loader_stop() {

    if [[ -n "$SPINNER_PID" ]] && kill -0 "$SPINNER_PID" 2>/dev/null; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
        SPINNER_PID=""
        printf "\r\033[K"
    fi
}

loader_is_activ() {

    [[ -n "$SPINNER_PID" ]] || return 1
}

