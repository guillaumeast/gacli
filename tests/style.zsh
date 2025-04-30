#!/usr/bin/env zsh
###############################
# FICHIER /<TODO: path>/style.zsh (move to src/helpers ?)
###############################

# Style variables and formatted i/o functions
# ────────────────────────────────────────────────────────────────
# FORMATTING
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
            echo "${EMOJI_WARN}  ${YELLOW}Warning: ${BOLD}${msg}${NONE}" >&2
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

