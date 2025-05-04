#!/usr/bin/env zsh
###############################
# FICHIER /<TODO: path>/style.zsh (move to src/helpers or installer/ ?)
###############################

# I/O formatter

# Background formatting
BLACK_BG='\033[40m'
RED_BG='\033[41m'
GREEN_BG='\033[42m'
YELLOW_BG='\033[43m'
BLUE_BG='\033[44m'
PURPLE_BG='\033[45m'
CYAN_BG='\033[46m'
ORANGE_BG='\033[48;5;208m'
GREY_BG='\033[100m'

# Text formatting
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
EMOJI_DEBUG="🔎"
EMOJI_ERR="🛑"
EMOJI_WARN="⚠️"
EMOJI_SUCCESS="✅"
EMOJI_WAIT="⏳"
EMOJI_INFO="✧"
EMOJI_HIGHLIGHT="👉"
EMOJI_PASSED="✓"
EMOJI_FALLBACK="⚐"
EMOJI_FAILED="⨯"
ICON_ON="⊙"
ICON_OFF="○"

# ────────────────────────────────────────────────────────────────
# Standard I/O
# ────────────────────────────────────────────────────────────────

# Format output
printStyled() {
    style="${1}"
    msg="${2}"
    color_text=$GREY
    color_emoji=$GREY
    case "${style}" in
        debug)
            echo "${EMOJI_DEBUG} ${GREY}${funcstack[2]} → ${YELLOW}${BOLD}${msg}${NONE}" >&2
            return ;;
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
        highlight)
            color_text=$NONE
            color_emoji=$NONE
            emoji=$EMOJI_HIGHLIGHT
            ;;
        passed)
            color_text=$GREY
            color_emoji=$GREEN
            emoji=$EMOJI_PASSED
            msg="Passed   → ${GREEN}${msg}${NONE}"
            ;;
        fallback)
            color_text=$ORANGE
            color_emoji=$ORANGE
            emoji=$EMOJI_FALLBACK
            msg="Fallback → ${ORANGE}${msg}${NONE}"
            ;;
        failed)
            color_text=$RED
            color_emoji=$RED
            emoji=$EMOJI_FAILED
            msg="Failed   → ${msg}"
            ;;
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

# ────────────────────────────────────────────────────────────────
# Format test results
# ────────────────────────────────────────────────────────────────

# TODO: printui → dispatch to printStyled|print_results|print_block...
# TODO: printui <text> <style> <type> <opt:position> <opt:border_color> <opt:extra_space>
# TODO: printui <header|line|block|footer|results> <done> <top|mid|bot>
# TODO: all scripts → Replace "printStyled" by "printui"
print_results() {

    local passed="${1}"
    local fallback="${2}"
    local failed="${3}"

    if [[ ! "$1" =~ ^[0-9]+$ || ! "$2" =~ ^[0-9]+$ || ! "$3" =~ ^[0-9]+$ ]]; then
        printStyled error "[print_results] Expected: <passed:int> <fallback:int> <failed:int> (received: '$1' '$2' '$3')"
        return 1
    fi

    # Total
    local total=$(( $passed + $fallback + $failed ))
    if (( total == 0 )); then
        printui block "${GREY}" "🤷 No result to display" 1
        return 1
    fi

    # Ratios
    local winrate=$(( $passed * 100 / $total ))
    local fallrate=$(( $fallback * 100 / $total ))
    local loserate=$(( $failed * 100 / $total ))

    # Colors - default
    local color_passed_border=$GREY
    local color_passed_text=$GREY
    local color_fallback_border=$GREY
    local color_fallback_text=$GREY
    local color_failed_border=$GREY
    local color_failed_text=$GREY
    
    # Colors - compute
    local emoji_failed="⨯"
    local failed_extra_length=0
    (( $passed > 0 )) && color_passed_text=$GREEN
    (( $fallback > 0 )) && color_fallback_text=$ORANGE
    (( $failed > 0 )) && color_failed_text=$YELLOW && emoji_failed=$EMOJI_ERR && failed_extra_length=1
    if (( $loserate > 0 )); then
        color_failed_border=$RED
        color_failed_text="${NONE}${RED_BG}"
    elif (( $winrate == 100 )); then
        color_passed_border=$GREEN
        color_passed_text="${BLACK}${GREEN_BG}"
    else
        color_fallback_border=$ORANGE
        color_fallback_text="${BLACK}${ORANGE_BG}"
    fi    

    # Text
    local text_passed="${color_passed_text}${EMOJI_SUCCESS} ${passed} (${winrate} %)${NONE}"
    local text_fallback="${color_fallback_text}${EMOJI_FALLBACK} ${fallback} (${fallrate} %)${NONE}"
    local text_failed="${color_failed_text}${emoji_failed} ${failed} (${loserate} %)${NONE}"

    # Generate items
    local block_passed=("${(@f)$(printui block_line_bot "$color_passed_border" "${text_passed}")}")
    local block_fallback=("${(@f)$(printui block "$color_fallback_border" "${text_fallback}")}")
    local block_failed=("${(@f)$(printui block "$color_failed_border" "${text_failed}" ${failed_extra_length})}")

    # Display items in a row
    echo "${block_passed[1]}${block_fallback[1]}${block_failed[1]}"
    echo "${block_passed[2]}${block_fallback[2]}${block_failed[2]}"
    echo "${block_passed[3]}${block_fallback[3]}${block_failed[3]}"
}

printui() {

    local text="${1}"                       # required → message to display
    local style="${2}"                      # required → cf printStyled styles
    local type="${3:-"line"}"               # optional → line|block|header|footer|results
    local position="${4}"                   # optional → top|mid|bot
    local border_color="${5:-"${GREY}"}"    # optional
    local extra_space="${6:-0}"             # optional

    if [[ -z "$text" || -z "$style" || -z "$type" || -z "$position" || -z "$border_color" || -z "$extra_space" ]]; then
        printStyled error "Expected: <text> <style> <opt:type> <opt:position> <opt:border_color> <opt:extra_space>"
        printStyled debug "Received: '$1' '$2' '$3' '$4' '$5'"
        return 1
    fi

    # TODO: WIP → exemple → printui header-top-highlight-1 "📊 Formatted results"
    # TODO: if 2 args → autoparse first arg into optional args: <style> <type> <position> <border_color> <extra_space>
    # TODO: if style is defined → call print_styled + get extra_space for auto-concatened emojis (auto-detect ??)
    # TODO: if type is defined → call print_typed <border_color> <extra_space>
    # TODO: if position is defined → call print_positionned

    # TODO: check extra_space format

    [[ "${type}" ==  "line_empty" ]] && echo "│" && return 0
    [[ "${type}" ==  "line_top" ]] && echo "┌- ${text}" && return 0
    [[ "${type}" ==  "line_mid" ]] && echo "├→ ${text}" && return 0
    [[ "${type}" ==  "line_bot" ]] && echo "└→ ${text}" && return 0

    local prefix_top=""
    local prefix_mid=""
    local prefix_bot=""
    if [[ "${type}" ==  "block_line_top" ]]; then
        prefix_top="  "
        prefix_mid="┌-"
        prefix_bot="│ "
    elif [[ "${type}" ==  "block_line_mid" ]]; then
        prefix_top="│ "
        prefix_mid="├→"
        prefix_bot="│ "
    elif [[ "${type}" ==  "block_line_bot" ]]; then
        prefix_top="│ "
        prefix_mid="└→"
        prefix_bot="  "
    fi

    local border_left_top="┌"
    [[ "${type}" ==  "footer" ]] && border_left_top="├"
    local border_left_bot="└"
    [[ "${type}" ==  "header" ]] && border_left_bot="├"

    local border_horizontal=""
    local border_length=$(( $(str_length "${text}") + $extra_space + 2))
    while (( $border_length > 0 )); do
        border_horizontal="${border_horizontal}-"
        (( border_length-- ))
    done

    local border_top="${prefix_top}${border_color}${border_left_top}${border_horizontal}┐${NONE}"
    local content="${prefix_mid}${border_color}│ ${text}${border_color} │${NONE}"
    local border_bot="${prefix_bot}${border_color}${border_left_bot}${border_horizontal}┘${NONE}"
    echo "${border_top}"
    echo "${content}"
    echo "${border_bot}"
}

# ────────────────────────────────────────────────────────────────
# TODO: move into some helper file
# ────────────────────────────────────────────────────────────────

str_length() {

    local string="${1}"

    if [[ -z "$string" ]]; then
        printStyled error "Expected: <string>; received: '$1'"
        return 1
    fi

    # Remove ANSI sequences (colors...)
    local clean=$(echo "$string" | sed -r 's/\x1B\[[0-9;]*[mK]//g')

    echo ${#clean}
}

# ────────────────────────────────────────────────────────────────
# TESTS
# ────────────────────────────────────────────────────────────────

tmp_test_bg() {

    echo
    printui block "${NONE}" "block"
    echo
    printui header "${NONE}" "header"
    printui line_mid "${NONE}" "line_mid"
    printui block_line_mid "${NONE}" "block_line_mid"
    printui footer "${NONE}" "footer"
    echo
    printui block_line_top "${NONE}" "block_line_top"
    printui block_line_mid "${NONE}" "block_line_mid"
    printui block_line_bot "${NONE}" "block_line_bot"
    echo
    printui line_top "${NONE}" "line_top"
    printui line_mid "${NONE}" "line_mid"
    printui line_bot "${NONE}" "line_bot"
    echo
    printui header "${NONE}" "$(printStyled highlight "Testing the test manager... 🤯")" 2
    printui line_mid "${NONE}" "$(printStyled success "Passed")"
    print_results 0 0 1
    echo
    # print_results 0 1 0
    # print_results 0 1 1
    # print_results 1 0 0
    # print_results 1 0 1
    # print_results 1 1 0
    # print_results 1 1 1
    # print_results 1 1 2
    # print_results 1 2 1
    # print_results 2 1 1
    # print_results 0 0 0
}

tmp_test_bg

