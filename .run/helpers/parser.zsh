###############################
# FICHIER /.run/helpers/parser.zsh
###############################

#!/usr/bin/env zsh

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

# Universal reader: parser_read <file> <key>
read() {
    local file="${1}"
    local key="${2}"

    # Reset buffer value
    BUFFER=()

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

# Universal reset: parser_reset <file> <key>
reset() {
    local file="${1}"
    local key="${2}"

    # Check arguments
    if [[ -z "${file}" || -z "${key}" ]]; then
        printStyled error "[reset] Expected: <file> <key> (received: \"${1}\" \"${2}\")"
        return 1
    fi
    if [[ ! -f "${file}" ]]; then
        printStyled error "[reset] File not found: ${file}"
        return 1
    fi

    # Resolve extension
    local extension="$(_get_extension "${file}")" || return 1

    # Dispatch per type
    case "${extension}" in
        yml|yaml)
            yq e "del(.${key})" -i "${file}" 2>/dev/null || {
                printStyled error "[reset] Failed to reset key '${key}' in ${file}"
                return 1
            }
            ;;
        json)
            jq "del(.${key})" "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}" || {
                printStyled error "[reset] Failed to reset key '${key}' in ${file}"
                return 1
            }
            ;;
        brewfile)
            _reset_brew "${file}" "${key}"
            ;;
        *)
            printStyled error "[reset] Unsupported file format: .${extension}"
            return 1
            ;;
    esac
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

    case "${key}" in
        formulae)
            BUFFER=($(grep '^brew "' "$file" | cut -d'"' -f2 2>/dev/null)) && return 0
            ;;
        casks)
            BUFFER=($(grep '^cask "' "$file" | cut -d'"' -f2 2>/dev/null)) && return 0
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

_reset_brew() {
    local file="${1}"
    local key="${2}"
    local tmp_file="$(mktemp)"

    case "${key}" in
        formulae)
            grep -v '^brew "' "${file}" > "${tmp_file}" || {
                printStyled error "[reset] Failed to clean formulae from ${file}"
                rm -f "$tmp_file"
                return 1
            }
            ;;
        casks)
            grep -v '^cask "' "${file}" > "${tmp_file}" || {
                printStyled error "[reset] Failed to clean casks from ${file}"
                rm -f "$tmp_file"
                return 1
            }
            ;;
        *)
            printStyled error "[reset] Unknown key for Brewfile: ${key}"
            rm -f "$tmp_file"
            return 1
            ;;
    esac

    mv "${tmp_file}" "${file}" || {
        printStyled error "[reset] Failed to overwrite ${file}"
        rm -f "$tmp_file"
        return 1
    }
}

# ────────────────────────────────────────────────────────────────
# WIP: DEBUG
# ────────────────────────────────────────────────────────────────

printStyled debug "---> 3. parser.zsh loaded"

