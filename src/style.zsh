#!/usr/bin/env zsh
###############################
# FICHIER /<TODO: path>/style.zsh (move to src/helpers or installer/ ?)
###############################

# I/O formatter

# Formatting
BOLD="\033[1m"
UNDERLINE="\033[4m"
BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
CYAN='\033[36m'
ORANGE='\033[38;5;208m'
GREY='\033[90m'
NONE='\033[0m'
COLOR_FORMULAE="${BLUE}"
COLOR_CASKS="${CYAN}"
COLOR_MODS="${PURPLE}"
COLOR_COMMANDS="${ORANGE}"

# Emojis
EMOJI_SUCCESS="✓"
EMOJI_WARN="⚠️"
EMOJI_ERR="🛑"
EMOJI_INFO="✧"
EMOJI_TBD="⚐"
EMOJI_HIGHLIGHT="👉"
EMOJI_DEBUG="🔎"
EMOJI_WAIT="⏳"
ICON_ON="⊙"
ICON_OFF="○"

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# Format output
printStyled() {
    style=$1
    msg=$2
    color_text=$GREY
    color_emoji=$GREY
    case "${style}" in
        error)
            echo
            echo "${EMOJI_ERR} ${RED}Error: ${BOLD}${msg}${NONE}" >&2
            echo
            return ;;
        warning)
            echo "${EMOJI_WARN}  ${YELLOW}Warning: ${msg}${NONE}" >&2
            return ;;
        success)
            color_text=$GREY
            color_emoji=$GREEN
            emoji=$EMOJI_SUCCESS
            ;;
        wait)
            color_text=$GREY
            color_emoji=$GREY
            emoji=$EMOJI_WAIT
            ;;
        info)
            color_text=$GREY
            color_emoji=$GREY
            emoji=$EMOJI_INFO
            ;;
        info_tbd)
            color_text=$GREY
            color_emoji=$ORANGE
            emoji=$EMOJI_TBD
            ;;
        highlight)
            color_text=$NONE
            color_emoji=$NONE
            emoji=$EMOJI_HIGHLIGHT
            ;;
        debug)
            echo "${EMOJI_DEBUG} ${GREY}${funcstack[2]} → ${YELLOW}${BOLD}${msg}${NONE}" >&2
            return ;;
        *)
            emoji=""
            ;;
    esac
    echo "${color_emoji}${emoji} ${color_text}${msg}${NONE}"
}

# Display section header
printheader() {

    echo
    echo "----------------------------"
    printStyled highlight "${1}"
    echo "${GREY}----------------------------${NONE}"
}

# Display section header
printfooter() {

    echo "${GREY}----------------------------${NONE}"
    echo "${1}"
    echo "----------------------------"
    echo
}

printresults() {

    # Variables
    local passed=0
    local failed=0
    local total=0
    local winrate=0
    local loserate=0

    # Check args
    if [[ ! "$1" =~ ^[0-9]+$ || ! "$2" =~ ^[0-9]+$ ]]; then
        printStyled error "[printresults] Expected: <passed:int> <failed:int> (received: $1 $2)"
        return 1
    fi

    # Compute
    passed=$1
    failed=$2
    total=$(( $passed + $failed ))
    winrate=$(( $passed * 100 / $total ))
    loserate=$(( $failed * 100 / $total ))

    # Display results
    if (( failed == 0 )); then
        printfooter "$(printStyled success "${GREEN}Passed → ${passed}${GREY} (100 %)${NONE}")"
    elif (( passed == 0 )); then
        printfooter "$(printStyled error "${RED}Failed → ${failed}${GREY} (100 %)${NONE}" 2>&1)"
    else
        local line1="$(printStyled success "${GREEN}Passed → ${passed}${GREY} (${winrate} %)${NONE}")"
        local line2="$(printStyled info_tbd "${ORANGE}Failed → ${failed}${GREY} (${loserate} %)${NONE}")"
        printfooter "${line1}\n${line2}"
    fi
}

