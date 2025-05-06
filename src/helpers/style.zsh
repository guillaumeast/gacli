#!/usr/bin/env zsh
###############################
# FICHIER /src/helpers/style.zsh
###############################
# I/O formatter

STYLES=("debug" "error" "warning" "success" "highlight" "wait" "info" "passed" "fallback" "failed")
FORMATS=("block" "header" "footer")
POSITIONS=("top" "mid" "bot")
COLORS=( \
    "BLACK_BG" "RED_BG" "GREEN_BG" "YELLOW_BG" "BLUE_BG" \
    "PURPLE_BG" "CYAN_BG" "ORANGE_BG" "GREY_BG" \
    "BOLD" "UNDERLINE" "BLACK" "RED" \
    "GREEN" "YELLOW" "BLUE" "PURPLE" \
    "CYAN" "ORANGE" "GREY" "NONE" \
)

# Background
BLACK_BG="$(printf '\033[40m')"
RED_BG="$(printf '\033[41m')"
GREEN_BG="$(printf '\033[42m')"
YELLOW_BG="$(printf '\033[43m')"
BLUE_BG="$(printf '\033[44m')"
PURPLE_BG="$(printf '\033[45m')"
CYAN_BG="$(printf '\033[46m')"
ORANGE_BG="$(printf '\033[48;5;208m')"
GREY_BG="$(printf '\033[100m')"

# Text
BOLD="$(printf '\033[1m')"
UNDERLINE="$(printf '\033[4m')"
BLACK="$(printf '\033[30m')"
RED="$(printf '\033[31m')"
GREEN="$(printf '\033[32m')"
YELLOW="$(printf '\033[33m')"
BLUE="$(printf '\033[34m')"
PURPLE="$(printf '\033[35m')"
CYAN="$(printf '\033[36m')"
ORANGE="$(printf '\033[38;5;208m')"
GREY="$(printf '\033[90m')"
NONE="$(printf '\033[0m')"
COLOR_FORMULAE="${BLUE}"
COLOR_CASKS="${CYAN}"
COLOR_MODS="${PURPLE}"
COLOR_COMMANDS="${ORANGE}"

# Emojis
EMOJI_DEBUG="🔎"
EMOJI_ERR="🛑"
EMOJI_WARN="⚠️ "
EMOJI_SUCCESS="✅"
EMOJI_HIGHLIGHT="👉"
EMOJI_WAIT="⏳"
EMOJI_INFO="✧"
EMOJI_PASSED="✓"
EMOJI_FALLBACK="⚐"
EMOJI_FAILED="⨯"
ICON_ON="⊙"
ICON_OFF="○"

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# Usage 1 → printui <opt:FORMATS|-|STYLES|-|POSITIONS|-|COLORS> <str:text>
# Usage 2 → printui results <opt:POSITION> <int:passed> <int:fallback> <int:failed>
printui() {

    local text="${2}"

    if (( $# != 2 )) && (( $# != 4 )) && (( $# != 5 )); then
        echo "${YELLOW}${EMOJI_WARN} [printui] Warning: Usage 1 → printui <opt:FORMAT-STYLE-POSITION-COLORS> <text>" >&2
        echo "${YELLOW}${EMOJI_WARN} [printui] Warning: Usage 2 → printui results <opt:position> <int:success> <int:fallback> <int:failed>" >&2
        echo "${RED}${EMOJI_ERR} [printui] Error: Received: '$@'" >&2
        return 1
    fi

    local parts=("${(s:-:)1}")  # Split first arg using '-' as separator
    local format=""
    local style=""
    local position=""
    local border_color=""
    
    for part in "${parts[@]}"; do

        if [[ "${part}" == "results" ]]; then
            shift
            _print_results "$@"
            return $?
        fi

        (( ${FORMATS[(I)$part]} )) && format=$part && continue          # format
        (( ${STYLES[(I)$part]} )) && style=$part && continue            # style    
        (( ${POSITIONS[(I)$part]} )) && position=$part && continue      # position
        (( ${COLORS[(I)$part]} )) && border_color="${border_color}${(P)part}" && continue   # border color
    done

    [[ -z "${border_color}" ]] && border_color=$GREY
    [[ -n "${style}" ]] && text=$(_print_styled "${style}" "${text}")
    [[ -n "${format}" ]] && text=$(_print_formatted "${format}" "${border_color}" "${text}")
    [[ -n "${position}" ]] && text=$(_print_positionned "${position}" "${border_color}" "${text}")

    # stdout vs stderr
    local output_stream=1
    [[ "${style}" == (warning|error|debug) ]] && output_stream=2

    ! loader_is_activ && print -u$output_stream -- "${text}" && return

    loader_pause
    print -u$output_stream -- "${text}"
    loader_start
}

# print_row <str:separator> <@pointer:blocks>
print_row() {

    local separator="$1" && shift
    local blocks=()
    local block width height max_height line char out i

    for block in "$@"; do
        block=("$(eval 'printf "%s\n" "${'"$block"'[@]}"')")
        blocks+=("$block")
    done

    max_height=0
    for block in "${blocks[@]}"; do
        height=$(str_height "${block}")
        (( height > max_height )) && max_height=$height
    done

    out=""
    for (( i=1; i <= max_height; i++ )); do
        for block in "${blocks[@]}"; do
            line=${${(f)block}[$i]}
            height=$(str_height "${block}")
            width=$(str_width "${block}")

            if (( i > height )); then
                out="$(str_repeat $width '' " ")${separator}"
            else
                out="${out}${line}${separator}"
            fi
        done
        out="${out%%${separator}}"
        (( i < max_height )) && out="${out}\n"
    done
    echo $out
}

print_logo() {
    print "${ORANGE}  _____          _____ _      _____ ${NONE}"
    print "${ORANGE} / ____|   /\\\\   / ____| |    |_   _|${NONE}"
    print "${ORANGE}| |  __   /  \\\\ | |    | |      | |  ${NONE}"
    print "${ORANGE}| | |_ | / /\\\\ \\\\| |    | |      | |  ${NONE}"
    print "${ORANGE}| |__| |/ ____ \\\\ |____| |____ _| |_ ${NONE}"
    print "${ORANGE} \\\\_____/_/    \\\\_\\\\_____|______|_____|${NONE}"
    print ""
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

# _print_styled <STYLE> <str:text>
_print_styled() {

    local style="${1}"
    local text="${2}"

    local color_text=$GREY
    local color_emoji=$GREY

    case "${style}" in
        debug)
            echo "${EMOJI_DEBUG} ${GREY}[${funcstack[2]}] → ${YELLOW}${BOLD}${text}${NONE}"
            return ;;
        error)
            echo "${EMOJI_ERR} ${RED}Error: ${BOLD}${text}${NONE}"
            return ;;
        warning)
            echo "${EMOJI_WARN} ${YELLOW}Warning: ${text}${NONE}"
            return ;;
        success)
            color_text=$GREY
            color_emoji=$GREEN
            emoji="${EMOJI_SUCCESS} "
            ;;
        highlight)
            color_text=$NONE
            color_emoji=$NONE
            emoji="${EMOJI_HIGHLIGHT} "
            ;;
        wait)
            color_text=$YELLOW
            color_emoji=$GREY
            emoji="${EMOJI_WAIT} "
            ;;
        info)
            color_text=$GREY
            color_emoji=$GREY
            emoji="${EMOJI_INFO} "
            ;;
        passed)
            color_text=$GREEN
            color_emoji=$GREEN
            emoji="${EMOJI_PASSED} ${NONE}"
            ;;
        fallback)
            color_text=$ORANGE
            color_emoji=$ORANGE
            emoji="${EMOJI_FALLBACK} ${NONE}"
            ;;
        failed)
            color_text=$RED
            color_emoji=$RED
            emoji="${EMOJI_FAILED} ${NONE}"
            ;;
        *)
            echo "${text}"
            ;;
    esac
    echo "${color_emoji}${emoji}${color_text}${text}${NONE}"
}

# TODO: handle multi-line input
# _print_formatted <FORMAT> <COLOR> <str:text>
_print_formatted() {

    local format="${1}"
    local border_color="${2}"
    local text="${3}"

    if [[ -z "${format}" || -z "${border_color}" || -z "${text}" ]]; then
        printui warning "[_print_formatted] Expected: <format> <border_color> <text>; received: '${1}' '${2}' '${3}'"
        return 1
    fi

    # Basic border
    local left_top="┌"
    local left_mid="│"
    local left_bot="└"
    local right_top="┐"
    local right_mid="│"
    local right_bot="┘"
    
    # Header / footer variations
    [[ "${format}" ==  "header" ]] && left_bot="├"
    [[ "${format}" ==  "footer" ]] && left_top="├"

    # Dynamic width
    local border_horizontal=""
    local border_length=$(( $(str_width "${text}") + 2))
    while (( $border_length > 0 )); do
        border_horizontal="${border_horizontal}‒"
        (( border_length-- ))
    done

    local border_top="${border_color}${left_top}${border_horizontal}${right_top}${NONE}"
    local content="${border_color}${left_mid} ${text}${border_color} ${right_mid}${NONE}"
    local border_bot="${border_color}${left_bot}${border_horizontal}${right_bot}${NONE}"

    echo "${border_top}"
    echo "${content}"
    echo "${border_bot}"
}

# _print_positionned <POSITION> <COLOR> <str:text>
_print_positionned() {
    
    local position="${1}"
    local border_color="${2}"
    local text="${3}"

    if [[ -z "${position}" || -z "${border_color}" || -z "${text}" ]]; then
        printui warning "[_print_positionned] Expected: <position> <border_color> <text>; received: '${1}' '${2}' '${3}'"
        return 1
    fi

    local top="${border_color}┌- ${NONE}"
    local mid="${border_color}├→ ${NONE}"
    local bot="${border_color}└→ ${NONE}"
    local empty="   "
    local line="${border_color}│  ${NONE}"

    local prefix_top=""
    local prefix_mid=""
    local prefix_bot=""
    if [[ "$position" == "top" ]]; then
        prefix_top=$empty
        prefix_mid=$top
        prefix_bot=$line
    elif [[ "$position" == "mid" ]]; then
        prefix_top=$line
        prefix_mid=$mid
        prefix_bot=$line
    elif [[ "$position" == "bot" ]]; then
        prefix_top=$line
        prefix_mid=$bot
        prefix_bot=$empty
    fi

    local -a lines
    IFS=$'\n' read -d '' -A lines <<< "$text"
    local height=$(str_height "${text}")

    (( height == 1 )) && echo "${prefix_mid}${text}" && return

    local half=$(( $height / 2 ))
    local i
    for (( i = 1; i <= height; i++ )); do
        if (( i - 1 < half )); then
            lines[i]="${prefix_top}${lines[i]}"
        elif (( i - 1 > half )); then
            lines[i]="${prefix_bot}${lines[i]}"
        else
            lines[i]="${prefix_mid}${lines[i]}"
        fi
    done
    text="$(printf "%s\n" "${lines[@]}")"
    
    echo $text
}

# _print_results <opt:POSITION> <int:passed> <int:fallback> <int:failed>
_print_results() {

    local position=""
    (( $# == 4 )) && position="${1}" && shift
    local passed="${1}"
    local fallback="${2}"
    local failed="${3}"

    if [[ ! "$passed" =~ ^[0-9]+$ || ! "$fallback" =~ ^[0-9]+$ || ! "$failed" =~ ^[0-9]+$ ]]; then
        printui error "[_print_results] Expected: <opt:POSITION> <int:passed> <int:fallback> <int:failed> (received: '$@')"
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
    local color_passed_border="GREY"
    local color_passed_text=$GREY
    local color_fallback_border="GREY"
    local color_fallback_text=$GREY
    local color_failed_border="GREY"
    local color_failed_text=$GREY
    
    # Colors - compute
    local emoji_failed=$EMOJI_FAILED
    (( $passed > 0 )) && color_passed_text=$GREEN
    (( $fallback > 0 )) && color_fallback_text=$ORANGE
    (( $failed > 0 )) && color_failed_text=$YELLOW && emoji_failed=$EMOJI_ERR
    if (( $loserate > 0 )); then
        color_failed_border="RED"
        color_failed_text="${NONE}${RED_BG}"
    elif (( $winrate == 100 )); then
        color_passed_border="GREEN"
        color_passed_text="${NONE}${GREEN_BG}"
    else
        color_fallback_border="ORANGE"
        color_fallback_text="${RED}${ORANGE_BG}"
    fi    

    # Text
    local text_passed="${color_passed_text}${EMOJI_PASSED} ${passed} (${winrate} %)${NONE}"
    local text_fallback="${color_fallback_text}${EMOJI_FALLBACK} ${fallback} (${fallrate} %)${NONE}"
    local text_failed="${color_failed_text}${emoji_failed} ${failed} (${loserate} %)${NONE}"

    # Generate blocks
    local block_passed=("${(@f)$(printui "block-${color_passed_border}" "${text_passed}")}")
    local block_fallback=("${(@f)$(printui "block-${color_fallback_border}" "${text_fallback}")}")
    local block_failed=("${(@f)$(printui "block-${color_failed_border}" "${text_failed}")}")
    local blocks=("block_passed" "block_fallback" "block_failed")

    # Align in a row
    local row=$(print_row " " $blocks)
    printui "${position}" "${row}"
    # TODO: wrap row into header (need to update _print_format before to handle multi_lines input)
    # printui "${position}-header" "${row}"
}

# ────────────────────────────────────────────────────────────────
# TODO: TESTS
# ────────────────────────────────────────────────────────────────

# tmp_test_bg() {

#     # local style=""
#     # local format=""
#     # local position=""
#     # local color=""
#     # for style in $STYLES; do
#     #     for format in $FORMATS; do
#     #         for position in $POSITIONS; do
#     #             printui "${style}-${format}-GREEN-BLUE_BG-${position}" "${style}-${format}-GREEN-BLUE_BG-${position}"
#     #         done
#     #     done
#     # done

#     # printui header-highlight "Testing the test manager... 🤯"
#     # printui passed-mid Passed
#     # printui fallback-mid Fallback
#     # printui passed-mid Passed
#     # printui results bot 0 0 1
#     # printui results top 0 1 0
#     # printui results mid 0 1 1
#     # printui results mid 1 0 0
#     # printui results mid 1 0 1
#     # printui results mid 1 1 0
#     # printui results mid 1 1 1
#     # printui results mid 1 1 2
#     # printui results mid 1 2 1
#     # printui results bot 2 1 1
#     # printui results 0 0 0

#     source /Users/gui/Repos/gacli/gacli/tmp_ga/docker_wip/loader.zsh
#     loader_start "Testing loader..."
#     trap 'loader_stop' EXIT
#     sleep 2
#     return
# }

# tmp_test_bg

