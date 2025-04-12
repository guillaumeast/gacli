###############################
# FICHIER config.zsh
###############################

#!/usr/bin/env zsh

# Path
CONFIG_FILE="${TMP_DIR}/config.json"

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

# Load config file and assign values to global variables
config_init() {
    # Create config file if it doesn't exist
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        if ! echo '{}' > "${CONFIG_FILE}"; then
            printStyled error "[_config_create] Error: Unable to init config file (${CONFIG_FILE})"
            return 1
        fi
        set_config "gacli_path" "${GACLI_DIR}" || return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC (Getter and setter)
# ────────────────────────────────────────────────────────────────

# Get a value from config.json by key
get_config() {

    # Variables
    local key="${1}"

    # Check if key is provided
    if [[ -z "${key}" ]]; then
        printStyled error "[get_config] Expected : <key> (received : ${1})"
        return 1
    fi

    # Check if jq is installed
    if ! command -v jq >/dev/null 2>&1; then
        printStyled error "[get_config] Missing dependency: jq"
        return 1
    fi

    # Extract value using jq
    jq -r --arg key "${key}" '.[$key]' "${CONFIG_FILE}"
}

# Set a value in config.json by key
set_config() {

    # Variables
    local key="${1}"
    local value="${2}"

    # Check if both key and value are provided
    if [[ -z "${key}" || -z "${value}" ]]; then
        printStyled error "[set_config] Expected : <key> <value> (received : ${1} ${2})"
        return 1
    fi

    # Check if jq is installed
    if ! command -v jq >/dev/null 2>&1; then
        printStyled error "[set_config] Missing dependency: jq"
        return 1
    fi

    # Update value using jq (convert number if possible)
    tmp="$(mktemp)"
    jq --arg key "${key}" --arg value "$value" '.[$key] = ($value | fromjson? // $value)' "${CONFIG_FILE}" > "${tmp}"
    mv "${tmp}" "${CONFIG_FILE}"
}

