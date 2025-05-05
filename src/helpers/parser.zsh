#!/usr/bin/env zsh
###############################
# FICHIER /src/helpers/parser.zsh
###############################

# TODO: add boolean and numeric format support (JSON)

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# PUBLIC - Read a scalar/list value from any file
# file_read <file> <key>
file_read() {
  local file=$1
  local key=$2
  local extension=""

  # Check file integrity
  if [[ ! -f $file ]]; then
    printui error "Unable to find file: ${file}"
    return 1
  fi

  # Check key intergity
  if [[ -z $key ]]; then
    printui error "Incorrect key: '${key}'"
    return 1
  fi

  # Get extension
  if ! extension=$(get_extension $file); then
    printui error "Unable to detect file format: ${file}"
    return 1
  fi

  # Dispatch
  case "$extension" in
    json)
      echo "$(_json_read "${file}" "${key}")" || return 1
      ;;
    brewfile)
      echo "$(_brew_read "${file}" "${key}")" || return 1
      ;;
    *)
      printui error "Format not supported: ${extension}"
      return 1
      ;;
  esac
}

# PUBLIC - Write a scalar value into any file
# file_write <file> <key> <value>
file_write() {
  local file=$1
  local key=$2
  local value=$3
  local extension=""

  # Check file integrity
  if [[ ! -f $file ]]; then
    printui error "Unable to find file: ${file}"
    return 1
  fi

  # Check key intergity
  if [[ -z $key ]]; then
    printui error "Incorrect key: '${key}'"
    return 1
  fi

  # Get extension
  if ! extension=$(get_extension $file); then
    printui error "Unable to detect file format: ${file}"
    return 1
  fi

  # Dispatch
  case "$extension" in
    json)
      _json_write "${file}" "${key}" "${value}" || return 1
      ;;
    brewfile)
      _brew_add "${file}" "${key}" "${value}" || return 1
      ;;
    *)
      printui error "Format not supported: ${extension}"
      return 1
      ;;
  esac
}

# PUBLIC - Reset a list value into any file
file_reset() {
  local file=$1
  local key=$2
  local extension=""

  # Check file integrity
  if [[ ! -f $file ]]; then
    printui error "Unable to find file: ${file}"
    return 1
  fi

  # Check key intergity
  if [[ -z $key ]]; then
    printui error "Incorrect key: '${key}'"
    return 1
  fi

  # Get extension
  if ! extension=$(get_extension $file); then
    printui error "Unable to detect file format: ${file}"
    return 1
  fi

  # Dispatch
  case "$extension" in
    json)
      _json_reset "${file}" "${key}" || return 1
      ;;
    brewfile)
      _brew_reset "${file}" "${key}" || return 1
      ;;
    *)
      printui error "Format not supported: ${extension}"
      return 1
      ;;
  esac
}

# PUBLIC - Add a list of values to a list into any file
file_add() {
  local file=$1
  local key=$2
  shift 2               # Remove the two first args
  local values=("$@")   # Remaining args are the list of values to add
  local extension=""

  # Check file integrity
  if [[ ! -f $file ]]; then
    printui error "Unable to find file: ${file}"
    return 1
  fi

  # Check key intergity
  if [[ -z $key ]]; then
    printui error "Incorrect key: '${key}'"
    return 1
  fi

  # Get extension
  if ! extension=$(get_extension $file); then
    printui error "Unable to detect file format: ${file}"
    return 1
  fi

  # Dispatch
  case "$extension" in
    json)
        for value in "${values[@]}"; do
            _json_add "${file}" "${key}" "${value}" || return 1
        done
        ;;
    brewfile)
        for value in "${values[@]}"; do
            _brew_add "${file}" "${key}" "${value}" || return 1
        done
        ;;
    *)
      printui error "Format not supported: ${extension}"
      return 1
      ;;
  esac
}

# PUBLIC - Remove a list of values from a list into any file
file_rm() {
  local file=$1
  local key=$2
  shift 2               # Remove the two first args
  local values=("$@")   # Remaining args are the list of values to add
  local extension=""

  # Check file integrity
  if [[ ! -f $file ]]; then
    printui error "Unable to find file: ${file}"
    return 1
  fi

  # Check key intergity
  if [[ -z $key ]]; then
    printui error "Incorrect key: '${key}'"
    return 1
  fi

  # Get extension
  if ! extension=$(get_extension $file); then
    printui error "Unable to detect file format: ${file}"
    return 1
  fi

  # Dispatch
  case "$extension" in
    json)
        for value in "${values[@]}"; do
            _json_rm "${file}" "${key}" "${value}" || return 1
        done
        ;;
    brewfile)
        for value in "${values[@]}"; do
            _brew_rm "${file}" "${key}" "${value}" || return 1
        done
        ;;
    *)
      printui error "Format not supported: ${extension}"
      return 1
      ;;
  esac
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

# PUBLIC - Return file extension in lowercase (special case for Brewfile)
# get_extension <file>
get_extension() {
    local file="${1}"
    local file_name="${file##*/}"
    local extension="${file##*.}"

    if [[ $file_name = "Brewfile" ]]; then
        extension="Brewfile"
    fi

    echo "${extension:l}"
}

# ────────────────────────────────────────────────────────────────
# JSON
# ────────────────────────────────────────────────────────────────

# PRIVATE - Read scalar/list value from JSON file
# _json_read <file> <key>
_json_read() {
  local file=$1
  local key=$2
  local output=()

  # Check if the key exists
  if ! jq -e "has(\"$key\")" "$file" >/dev/null; then
    print "${RED}Error: key '${key}' does not exist in ${file}${NONE}" >&2
    return 1
  fi

  # Get the value type
  local type=$(jq -r ".${key} | type" "$file") || {
    print "${RED}Error: unable to fetch key '${key}' type in ${file}${NONE}" >&2
    return 1
  }

  case "$type" in
    "null")
      # Key exists but value is null → return empty string
      echo $output
      ;;
    "string")
      output=("${(Q)$(jq -r ".${key}" "$file")}")
      echo $output
      ;;
    "array")
      output=("${(@f)$(jq -r ".${key}[]" "$file")}")
      printf '%s\n' "${output[@]}"
      ;;
    *)
      print "${RED}Error: unsupported type '${type}' for key '${key}'${NONE}" >&2
      echo $output
      return 1
      ;;
  esac
}

# PRIVATE - Write scalar value into JSON file
# _json_write <file> <key> <value>
_json_write() {
  local file=$1
  local key=$2
  local value=$3

  jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$file" > "${file}.tmp" || return 1
  command mv -f "${file}.tmp" "${file}" || return 1
}

# PRIVATE - Reset list value into JSON file
# _json_reset <file> <key>
_json_reset() {
  local file=$1
  local key=$2

  jq --arg key "$key" '.[$key] = null' "$file" > "${file}.tmp" || return 1
  command mv -f "${file}.tmp" "$file" || return 1
}

# PRIVATE - Add value to a list into JSON file
# _json_add <file> <key> <value>
_json_add() {
  local file=$1
  local key=$2
  local value=$3

  jq --arg key "$key" --arg value "$value" '.[$key] += [$value]' "$file" > "${file}.tmp" || return 1
  command mv -f "${file}.tmp" "$file" || return 1
}

# PRIVATE - Remove value from a list into JSON file
# _json_rm <file> <key> <value>
_json_rm() {
  local file=$1
  local key=$2
  local value=$3

  jq --arg key "$key" --arg value "$value" '.[$key] |= map(select(. != $value))' "$file" > "${file}.tmp" || return 1
  command mv -f "${file}.tmp" "$file" || return 1
}

# ────────────────────────────────────────────────────────────────
# Brewfile
# ────────────────────────────────────────────────────────────────


# PRIVATE - Read values from a Brewfile (formulae or casks)
# _brew_read <file> <key>
_brew_read() {
  local file="${1}"
  local key="${2}"
  local output=()

  case "${key}" in
    formulae)
      output=("${(@f)$(grep '^brew "' "$file" | cut -d'"' -f2 2>/dev/null)}")
      ;;
    casks)
      output=("${(@f)$(grep '^cask "' "$file" | cut -d'"' -f2 2>/dev/null)}")
      ;;
    *)
      printui error "Unknown key for brewfile: '${key}'"
      return 1
      ;;
  esac

  printf '%s\n' "${output[@]}"
}

# PRIVATE - Reset list value into a Brewfile
# _brew_reset <file> <key>
_brew_reset() {
  local file="${1}"
  local key="${2}"
  local tmp_file="$(mktemp)"

  case "${key}" in
      formulae)
          grep -v '^brew "' "${file}" > "${tmp_file}" || {
              printui error "Failed to clean formulae from ${file}"
              rm -f "$tmp_file"
              return 1
          }
          ;;
      casks)
          grep -v '^cask "' "${file}" > "${tmp_file}" || {
              printui error "Failed to clean casks from ${file}"
              rm -f "$tmp_file"
              return 1
          }
          ;;
      *)
          printui error "Unknown key for Brewfile: ${key}"
          rm -f "$tmp_file"
          return 1
          ;;
  esac

  command mv -f "${tmp_file}" "${file}" || {
    printui error "Failed to overwrite ${file}"
    rm -f "$tmp_file"
    return 1
  }
}

# PRIVATE - Add value to a list into a Brewfile (append line if not already present)
# _brew_add <file> <key> <value>
_brew_add() {
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
      printui error "Unknown key for brewfile: '${key}'"
      return 1
      ;;
  esac

  if ! grep -qF "${line}" "${file}"; then
    # Ensure newline at EOF before appending
    [[ $(tail -c1 "${file}") != "" ]] && echo >> "${file}"

    # Append value
    echo "${line}" >> "${file}" || {
      printui error "Failed to append line to ${file}"
      return 1
    }
  fi
}

# PRIVATE - Remove value from a list into a Brewfile
# _brew_rm <file> <key> <value>
_brew_rm() {
  local file=$1
  local key=$2
  local value=$3

  local pattern=""
  case "${key}" in
    formulae)
      pattern="^brew \"${value}\""
      ;;
    casks)
      pattern="^cask \"${value}\""
      ;;
    *)
      printui error "Unknown key for brewfile: '${key}'"
      return 1
      ;;
  esac

  grep -v "${pattern}" "$file" > "${file}.tmp" || {
    printui error "Failed to remove line from ${file}"
    return 1
  }

  command mv -f "${file}.tmp" "${file}" || {
    printui error "Failed to overwrite ${file} after removal"
    return 1
  }
}

