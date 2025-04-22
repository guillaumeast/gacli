#!/usr/bin/env zsh
###############################
# FICHIER /.helpers/parser.zsh
###############################

# [File parser for tools/config]
   #   - Reads/writes YAML, JSON and Brewfile formats
   #   - Handles formulae, casks and modules values
   #   - Resets values from descriptors
   #   - Detects file type and applies correct tool

   # Depends on:
   #   - yq                 → YAML parsing
   #   - jq                 → JSON parsing
   #   - gacli.zsh          → for styled error output

   # Used by:
   #   - brew.zsh           → reads/writes Brewfile
   #   - update.zsh         → manages config and dependencies
   #   - modules.zsh        → parses tools.yaml in each module

   # Note: Exposes unified `parser_read`, `parser_write`, `parser_reset` interface
#

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# Universal reader: parser_read <file> <key>
parser_read() {
    local file="${1}"
    local key="${2}"

    # Reset buffer value
    BUFFER=()

    # Check arguments
    if [[ -z "${file}" || -z "${key}" ]]; then
        printStyled error "Expected: <file> <key> (received: \"${file}\" \"${key}\")"
        return 1
    fi
    if [[ ! -f "${file}" ]]; then
        printStyled error "Unable to find file: ${file}"
        return 1
    fi

    # Resolve extension
    local extension="$(_get_extension "${file}")" || return 1

    # Use corresponding processor
    case "${extension}" in
        yml|yaml)
            _read_yq "${file}" "${key}" && return 0
            ;;
        json)
            BUFFER=("${(@f)$(jq -r ".${key}" "${file}" 2>/dev/null)}") && return 0
            ;;
        brewfile)
            _read_brew "${file}" "${key}" && return 0
            ;;
        *)
            printStyled error "Unsupported file format: .${extension}"
            return 1
            ;;
    esac

    printStyled error "Failed to read key '${key}' in ${file}"
}

# Universal writer: parser_write <file> <key> <value>
parser_write() {
    local file="${1}"
    local key="${2}"
    local value="${3}"

    # Check arguments
    if [[ -z "${file}" || -z "${key}" ]]; then
        printStyled error "Expected: <file> <key> <value> (received: \"${1}\" \"${2}\" \"${3}\")"
        return 1
    fi
    if [[ ! -f "${file}" ]]; then
        printStyled error "Unable to find file: ${file}"
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
                printStyled error "Failed to write key '${key}' in ${file}"
                return 1
            fi
            mv "${file}.tmp" "${file}" && return 0
            ;;
        brewfile)
            _write_brew "${file}" "${key}" "${value}" && return 0
            ;;
        *)
            printStyled error "Unsupported file format: .${extension}"; return 1
            ;;
    esac

    printStyled error "Failed to write key '${key}' = ${value} in ${file}"
}

# Universal reset: parser_reset <file> <key>
parser_reset() {
    local file="${1}"
    local key="${2}"

    # Check arguments
    if [[ -z "${file}" || -z "${key}" ]]; then
        printStyled error "Expected: <file> <key> (received: \"${1}\" \"${2}\")"
        return 1
    fi
    if [[ ! -f "${file}" ]]; then
        printStyled error "File not found: ${file}"
        return 1
    fi

    # Resolve extension
    local extension="$(_get_extension "${file}")" || return 1

    # Dispatch per type
    case "${extension}" in
        yml|yaml)
            yq e "del(.${key})" -i "${file}" 2>/dev/null || {
                printStyled error "Failed to reset key '${key}' in ${file}"
                return 1
            }
            ;;
        json)
            jq "del(.${key})" "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}" || {
                printStyled error "Failed to reset key '${key}' in ${file}"
                return 1
            }
            ;;
        brewfile)
            _reset_brew "${file}" "${key}" || {
                printStyled error "Failed to reset key '${key}' in ${file}"
                return 1
            }
            ;;
        *)
            printStyled error "Unsupported file format: .${extension}"
            return 1
            ;;
    esac
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

# Return file extension in lowercase (special case for Brewfile)
_get_extension() {
    local file="${1}"
    local file_name="${file##*/}"
    local extension="${file##*.}"

    if [[ $file_name = "Brewfile" ]]; then
        extension="Brewfile"
    fi

    echo "${extension:l}"
}

# Read values from a Brewfile (formulae or casks)
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
            printStyled error "Unknown key for brewfile: '${key}'"
            return 1
            ;;
    esac
}

# Write value to a Brewfile (append line if not already present)
_write_brew() {
    local file="${1}"
    local key="${2}"
    local value="${3}"
    local line=""

    case "${key}" in
        formulae)
            line="brew \"${value}\""
            ;;
        casks)
            line="cask \"${value}\""
            ;;
        *)
            printStyled error "Unknown key for brewfile: '${key}'"
            return 1
            ;;
    esac

    if ! grep -qF "${line}" "${file}"; then
        echo "${line}" >> "${file}" || {
            printStyled error "Failed to append line to ${file}"
            return 1
        }
    fi
}

# Reset values from a Brewfile (remove matching lines)
_reset_brew() {
    local file="${1}"
    local key="${2}"
    local tmp_file="$(mktemp)"

    case "${key}" in
        formulae)
            grep -v '^brew "' "${file}" > "${tmp_file}" || {
                printStyled error "Failed to clean formulae from ${file}"
                rm -f "$tmp_file"
                return 1
            }
            ;;
        casks)
            grep -v '^cask "' "${file}" > "${tmp_file}" || {
                printStyled error "Failed to clean casks from ${file}"
                rm -f "$tmp_file"
                return 1
            }
            ;;
        *)
            printStyled error "Unknown key for Brewfile: ${key}"
            rm -f "$tmp_file"
            return 1
            ;;
    esac

    mv "${tmp_file}" "${file}" || {
        printStyled error "Failed to overwrite ${file}"
        rm -f "$tmp_file"
        return 1
    }
}

_read_yq() {
  local file=$1 key=$2

  # Check if key is a sequence
  if yq eval ".${key} | tag" "$file" 2>/dev/null | grep -q '!!seq'; then
    node_is_sequence=true
  else
    node_is_sequence=false
  fi

  if [[ $node_is_sequence == true ]]; then
    # Sequence → read each element
    while IFS= read -r element; do
      [[ -n $element ]] && BUFFER+=("$element")
    done < <(yq eval -r ".${key}[]" "$file" 2>/dev/null)
  else
    # Scalar → read value
    local val
    val=$(yq eval -r ".${key} // \"\"" "$file" 2>/dev/null)
    BUFFER=("$val")
  fi
}

