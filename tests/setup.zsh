#!/usr/bin/env zsh
###############################
# FICHIER /tests/setup.zunit
###############################

DIR_CURRENT="$(dirname "${(%):-%N}")"
DIR_ROOT="${DIR_CURRENT}/.."
DIR_SRC="${DIR_ROOT}/src"
DIR_TESTS="${DIR_ROOT}/tests"

# ────────────────────────────────────────────────────────────────
# I/O formatting (from main.zsh)
# ────────────────────────────────────────────────────────────────

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
EMOJI_SUCCESS="✦"
EMOJI_WARN="⚠️"
EMOJI_ERR="❌"
EMOJI_INFO="✧"
EMOJI_HIGHLIGHT="👉"
EMOJI_DEBUG="🔎"
EMOJI_WAIT="⏳"
ICON_ON="⊙"
ICON_OFF="○"

printStyled() {
    # Variables
    local style=$1
    local raw_message=$2
    local final_message=""
    local color=$NONE

    # Argument check
    if [[ -z "$style" || -z "$raw_message" ]]; then
        echo "❌ [printStyled] Expected: <style> <message>"
        return 1
    fi

    # Formatting
    case "$style" in
        error)
            echo "${RED}${BOLD}${EMOJI_ERR} ${GREY}${funcstack[4]}${GREY} → ${GREY}${funcstack[3]}${GREY} → ${RED}${funcstack[2]}${GREY}\n    ${RED}└→ ${raw_message}${NONE}" >&2
            return
            ;;
        warning)
            print "${YELLOW}${BOLD}${EMOJI_WARN}  ${GREY}${funcstack[4]}${GREY} → ${GREY}${funcstack[3]}${GREY} → ${ORANGE}${funcstack[2]}${GREY}\n    ${ORANGE}└→ ${raw_message}${NONE}" >&2
            return
            ;;
        success)
            color=$GREEN
            final_message="${EMOJI_SUCCESS} ${raw_message}"
            ;;
        info)
            color=$GREY
            final_message="${EMOJI_INFO} ${raw_message}"
            ;;
        highlight)
            color=$NONE
            final_message="${EMOJI_HIGHLIGHT} ${raw_message}"
            ;;
        debug)
            color=$YELLOW
            final_message="${EMOJI_DEBUG} ${GREY}${funcstack[4]}${GREY} → ${GREY}${funcstack[3]}${GREY} → ${YELLOW}${funcstack[2]}${GREY}\n    ${YELLOW}└→ ${BOLD}${raw_message}${NONE}"
            ;;
        *)
            color=$NONE
            final_message="${raw_message}"
            ;;
    esac

    # Display
    print "${color}$final_message${NONE}"
}

