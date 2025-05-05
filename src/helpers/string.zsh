#!/usr/bin/env zsh
###############################
# FICHIER /src/helpers/string.zsh
###############################
# String format helper

STR_DEPS=("wc" "tr" "sed")

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# str_repeat <int:count> <str:separator> <str:text>
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

# str_is_int <str:string>
str_is_int() {

    case "$1" in
        ''|*[!0-9-]*|*-*-*)
            ;; # Ignore non numeric parts
        *)
            return 0 ;;
    esac

    return 1
}

# str_height <str:string>
str_height() {

    local string="${1}"
    local line_count=0

    [[ -z "$string" ]] && echo 0 && return

    line_count=$(printf "%s\n" "$string" | wc -l | tr -d ' ')

    echo $line_count
}

# str_width <str:string>
str_width() {

    local block="${1}"
    local max_width=0
    local width=0
    local line=""

    while IFS= read -r line; do
        width=$(str_line_width "${line}")
        (( width > max_width )) && max_width=$width
    done <<< "${block}"

    echo $max_width
}

# str_line_width <str:line>
str_line_width() {

    local string="$1"
    local length=0

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
        local char_len=$(str_char_width "$graph")
        (( length += char_len ))
    done

    echo $length
}

# str_char_width <str:char>
str_char_width() {

    local char="$1"

    # Ignore non-visible emoji modifiers
    [[ "$char" == $'\uFE0F' || "$char" == $'\u200D' ]] && echo 0 && return
    [[ -z "${char}" ]] && echo 0 && return
    [[ "${char}" == " " ]] && echo 1 && return

    # Double length emojis
    local -a wide_chars=(
        "✅" "⚠" "${EMOJI_WARN}" "❌" "🛑" "🛑" "⛔" "🚫" "📛" "👉" "🔎" "⏳" \
        "💡" "🔥" "💥" "🌟" "🌈" "🎯" "🎉" "🎁" "🎲" "🎮" \
        "🚀" "🧠" "👓" "🦾" "🧪" "🧩" "📦" "📁" "📂" \
        "😄" "😁" "😆" "😅" "😂" "🤣" "🙂" "🙃" "😎" "😐" "🤯" \
        "🙈" "🙉" "🙊" "🐵" "🐶" "🐱" "🦊" "🐻" "🐼" \
        "🔴" "🟠" "🟡" "🟢" "🔵" "🟣" "⚫" "⚪" "🟤" \
        "➕" "➖" "➗" "❓" "❗" \
    )

    (( ${wide_chars[(I)$char]} )) && echo 2 && return
    
    echo 1
}

