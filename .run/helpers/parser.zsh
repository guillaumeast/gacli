###############################
# FICHIER parser.zsh
###############################

#!/usr/bin/env zsh

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

# Universal reader: parser_read <file> <key>
read() {
    local file="${1}"
    local key="${2}"

    # Check arguments
    if [[ -z "${file}" || -z "${key}" ]]; then
        printStyled error "[read] Expected: <file> <key> (received: \"${file}\" \"${key}\")"
        return 1
    fi
    if [[ ! -f "${file}" ]]; then
        printStyled error "[read] Unable to find file: ${file}"
        return 1
    fi

    # Resolve extension
    local extension="$(_get_extension "${file}")" || return 1

    # Use corresponding processor
    case "${extension}" in
        yml|yaml)
            BUFFER=("${(@f)$(yq e ".${key}" "${file}" 2>/dev/null)}") && return 0
            ;;
        json)
            BUFFER=("${(@f)$(jq -r ".${key}" "${file}" 2>/dev/null)}") && return 0
            ;;
        brewfile)
            _read_brew "${file}" "${key}" && return 0
            ;;
        *)
            printStyled error "[read] Unsupported file format: .${extension}"
            return 1
            ;;
    esac

    printStyled error "[read] Failed to read key '${key}' in ${file}"
}

# Universal writer: parser_write <file> <key> <value>
write() {
    local file="${1}"
    local key="${2}"
    local value="${3}"

    # Check arguments
    if [[ -z "${file}" || -z "${key}" ]]; then
        printStyled error "[write] Expected: <file> <key> <value> (received: \"${1}\" \"${2}\" \"${3}\")"
        return 1
    fi
    if [[ ! -f "${file}" ]]; then
        printStyled error "[write] Unable to find file: ${file}"
        return 1
    fi

    # Resolve extension
    local extension="$(_get_extension "${file}")" || return 1

    # Call the correct function depending on file format
    case "${extension}" in
        yml|yaml)
            yq e ".${key} = \"${value}\"" -i "${file}" 2>/dev/null && return 0
            ;;
        json)
            if ! jq ".${key} = \"${value}\"" "${file}" > "${file}.tmp" 2>/dev/null; then
                printStyled error "[write] Failed to write key '${key}' in ${file}"
                return 1
            fi
            mv "${file}.tmp" "${file}" && return 0
            ;;
        brewfile)
            _write_brew "${file}" "${key}" "${value}" && return 0
            ;;
        *)
            printStyled error "[write] Unsupported file format: .${extension}"; return 1
            ;;
    esac

    printStyled error "[write] Failed to write key '${key}' = ${value} in ${file}"
}

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

_get_extension() {
    local file="${1}"
    local file_name="${file##*/}"
    local extension="${file##*.}"

    if [[ $file_name = "Brewfile" ]]; then
        extension="Brewfile"
    fi

    echo "${extension:l}"
}

_read_brew() {
    local file="${1}"
    local key="${2}"
    local value="${3}"

    case "${key}" in
        formulae)
            BUFFER=($(grep '^brew "' "$BREWFILE" | cut -d'"' -f2 2>/dev/null)) && return 0
            ;;
        casks)
            BUFFER=($(grep '^cask "' "$BREWFILE" | cut -d'"' -f2 2>/dev/null)) && return 0
            ;;
        *)
            printStyled error "[read] Unknown key for brewfile: ${key}"
            return 1
            ;;
    esac
}

_write_brew() {
    local file="${1}"
    local key="${2}"
    local value="${3}"
    local line=""

    case "${key}" in
        formula)
            line="brew \"${value}\""
            ;;
        cask)
            line="cask \"${value}\""
            ;;
        *)
            printStyled error "[write] Unknown key for brewfile: ${key}"
            return 1
            ;;
    esac

    if ! grep -qF "${line}" "${file}"; then
        echo "${line}" >> "${file}" || {
            printStyled error "[write] Failed to append line to ${file}"
            return 1
        }
    fi
}

