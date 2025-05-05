#!/usr/bin/env zsh
###############################
# FICHIER /<TODO: path>/style.zsh (move to src/helpers or installer/ ?)
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
BLACK_BG='\033[40m'
RED_BG='\033[41m'
GREEN_BG='\033[42m'
YELLOW_BG='\033[43m'
BLUE_BG='\033[44m'
PURPLE_BG='\033[45m'
CYAN_BG='\033[46m'
ORANGE_BG='\033[48;5;208m'
GREY_BG='\033[100m'

# Text
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
# PRIVATE
# ────────────────────────────────────────────────────────────────

# _print_styled <style> <text>
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

# _print_formatted <format> <color> <text>
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

# _print_positionned <position> <color> <text>
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
        color_fallback_text="${NONE}${ORANGE_BG}"
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
    local row=$(_print_row " " $blocks)
    # local width=$(str_width $row)
    # echo "width → ${width}"
    # TODO: wrap row into header (need to update _print_format before to handle multi_lines input)
    printui mid "${GREY}------------------------------------------------${NONE}"
    printui "${position}" "${row}"
}

# _print_row <str:separator> <@pointer:blocks>
_print_row() {

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

# Usage 1 → printui <FORMATS|-|STYLES|-|POSITIONS|-|COLORS> <text>
# Usage 2 → printui results <position> <success_count> <fallback_count> <failed_count>
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
        _print_styled warning "[printui] Unknown arg → '${part}'"       # unknown
    done

    [[ -z "${border_color}" ]] && border_color=$GREY
    [[ -n "${style}" ]] && text=$(_print_styled "${style}" "${text}")

    if [[ "${style}" == "warning" || "${style}" == "error" || "${style}" == "debug" ]]; then
        echo "${text}" >&2
        return
    fi

    [[ -n "${format}" ]] && text=$(_print_formatted "${format}" "${border_color}" "${text}")
    [[ -n "${position}" ]] && text=$(_print_positionned "${position}" "${border_color}" "${text}")

    echo "${text}"
}

# ────────────────────────────────────────────────────────────────
# TODO: move into some helper file
# ────────────────────────────────────────────────────────────────

# str_repeat <int:count> <str:separator> <text>
str_repeat() {

    local count=$1
    local separator="${2}"
    local text="${3}"
    local out=""

    if ! (( count > 0 )); then
        printui error "Expected: <int:count> <str:separator> <text>; received '$@'"
        return 1
    fi

    local i
    for (( i=1; i < count; i++ )); do
        out="${out}${text}${separator}"
    done
    out="${out}${text}"

    echo "${out}"
}

str_height() {

    local string="${1}"
    local line_count=0

    [[ -z "$string" ]] && echo 0 && return

    line_count=$(printf "%s\n" "$string" | wc -l | tr -d ' ')

    echo $line_count
}

# TODO: si string contient plusieurs lignes => Renvoyer la width de la plus grande ligne
str_width() {

  local string="$1"
  local length=0
  # TODO: split string into `local lines=()`

  if [[ -z "$string" ]]; then
    printui error "Expected: <string>; received: '$1'"
    return 1
  fi

  # Remove ANSI escape sequences
  local clean=$(echo "$string" | sed -E $'s/\x1B\\[[0-9;]*[mK]//g')

  # Extract grapheme clusters: base char + modifiers (VS16, ZWJ, etc.)
  local -a graphemes
  local grapheme=""
  local i char next

  for (( i = 1; i <= ${#clean}; i++ )); do
    char="${clean[i]}"
    next="${clean[i+1]}"

    grapheme+="$char"

    # If next char is VS16 or ZWJ, keep building the cluster
    if [[ "$next" == $'\uFE0F' || "$next" == $'\u200D' ]]; then
      continue
    fi

    # End of grapheme cluster
    graphemes+=("$grapheme")
    grapheme=""
  done

  # Compute display width
  for graph in "${graphemes[@]}"; do
    local char_len=$(char_width "$graph")
    (( length += char_len ))
    $debug && printf "%-10s → %s\n" "$graph" "$char_len"
  done

  echo $length
}

char_width() {

    local char="$1"

    # Ignore non-visible emoji modifiers
    [[ "$char" == $'\uFE0F' || "$char" == $'\u200D' ]] && echo 0 && return
    [[ -z "${char}" ]] && echo 0 && return
    [[ "${char}" == " " ]] && echo 1 && return

    # Double length emojis
    local -a wide_chars=(
        "✅" "⚠" "${EMOJI_WARN}" "❌" "🛑" "🛑" "⛔" "🚫" "📛" "👉" "🔎" "⏳" \
        "💡" "🔥" "💥" "🌟" "🌈" "🎯" "🎉" "🎁" "🎲" "🎮" \
        "🚀" "🧠" "👀" "👓" "🦾" "🧪" "🧩" "📦" "📁" "📂" \
        "😄" "😁" "😆" "😅" "😂" "🤣" "🙂" "🙃" "😎" "😐" "🤯" \
        "🙈" "🙉" "🙊" "🐵" "🐶" "🐱" "🦊" "🐻" "🐼" \
        "🔴" "🟠" "🟡" "🟢" "🔵" "🟣" "⚫" "⚪" "🟤" \
        "➕" "➖" "➗" "❓" "❗" \
    )

    (( ${wide_chars[(I)$char]} )) && echo 2 && return
    
    echo 1
}

is_int() {

    case "$1" in
        ''|*[!0-9-]*|*-*-*)
            ;; # Ignore non numeric parts
        *)
            return 0 ;;
    esac

    return 1
}

# ────────────────────────────────────────────────────────────────
# TESTS
# ────────────────────────────────────────────────────────────────

tmp_test_bg() {

    # local style=""
    # local format=""
    # local position=""
    # local color=""
    # for style in $STYLES; do
    #     for format in $FORMATS; do
    #         for position in $POSITIONS; do
    #             printui "${style}-${format}-GREEN-BLUE_BG-${position}" "${style}-${format}-GREEN-BLUE_BG-${position}"
    #         done
    #     done
    # done

    printui header-highlight "Testing the test manager... 🤯"
    printui passed-mid Passed
    printui results mid 0 0 1
    printui results mid 0 1 0
    printui results mid 0 1 1
    printui results mid 1 0 0
    printui results mid 1 0 1
    printui results mid 1 1 0
    printui results mid 1 1 1
    printui results mid 1 1 2
    printui results mid 1 2 1
    printui results bot 2 1 1
    printui results 0 0 0
}

tmp_test_bg

