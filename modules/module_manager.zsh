###############################
# FICHIER module_manager.zsh
###############################

#!/usr/bin/env zsh

# Resolve path
MODULES_DIR="${GACLI_PATH}/${MODULE_DIR_NAME}"

# Modules and commands
CORE_DIR="${MODULES_DIR}/.core"
LAUNCHER_DIR="${MODULES_DIR}/.launcher"
USER_DIR="${MODULES_DIR}/user_modules"
COMMANDS=()

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

modules_init() {

    # Load core modules (cross-platform compatibility)
    _modules_load_dir "${CORE_DIR}" true || return 1

    # Load launcher modules (GACLI config and update management)
    _modules_load_dir "${LAUNCHER_DIR}" true || return 1

    # Load user modules
    _modules_load_dir "${USER_DIR}" false || return 1
}

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

# Dispatch command to corresponding module
modules_dispatch() {
    # Dynamic commands (declared via get_commands in modules)
    for cmd in "${COMMANDS[@]}"; do
        local command_name="${cmd%%=*}"
        local function_name="${cmd#*=}"

        if [[ "$1" == "$command_name" ]]; then
            # Call matched function with remaining args
            "${function_name}" "${@:2}"
            return
        fi
    done

    # No command matched
    printStyled error "[GACLI] Error: unknown command '$1'" >&2
    modules_print_commands
    return 1
}

# Print available commands
modules_print_commands() {
    local output_commands=""

    # Compute
    for cmd in "${COMMANDS[@]}"; do
        local command_name="${cmd%%=*}"
        output_commands+="${ICON_ON} ${GREEN}${command_name}${NONE} ${GREY}|${NONE} "
    done

    # Display (removing trailing " | ")
    print "${output_commands% ${GREY}|${NONE} }"
}

# ────────────────────────────────────────────────────────────────
# Functions - PRIVATE
# ────────────────────────────────────────────────────────────────

# Load all modules in a directory (recursive)
_modules_load_dir() {
    local dir="$1"
    local required="$2"
    local file

    # Check arguments
    if [[ $required != true && $required != false ]]; then
        echo "[_modules_load_dir] Error: Expected true or false (received: ${2})"
        return 1
    fi

    # Check if modules directory exists
    if [[ ! -d "${dir}" ]]; then
        if [[ $required = true ]]; then
            echo "[_modules_load_dir] Error: modules directory not found at: ${dir}" >&2
            return 1
        else
            echo "[_modules_load_dir] Warning: modules directory not found at: ${dir}" >&2
            return 0
        fi
    fi

    # Load each module
    for file in "${dir}"/**/*.zsh(N); do
        _module_load_file "${file}" "$required" || return 1
    done
}

# Load a unique module
_module_load_file() {
    local file="$1"
    local required
    if [[ "$2" = "required" ]]; then
        required=true
    fi

    # Check file integrity
    if [[ ! -f "$file" ]]; then
        if [[ $required = true ]]; then
            printStyled error "[_module_load_file] Required module not found: ${file}"
            return 1
        else
            printStyled warning "[_module_load_file] Optional module not found: ${file}"
            return 0
        fi
    fi

    # Try to source module code and commands
    if source "${file}"; then
        _module_load_commands "${file}"
    else
        if [[ $required = true ]]; then
            printStyled error "[_module_load_file] Failed to load required module: ${file}"
            return 1
        else
            printStyled warning "[_module_load_file] Failed to load optional module: ${file}"
        fi
    fi
}

# Import command mappings from a unique module
_module_load_commands() {
    local file="$1"

    # Argument check
    if [[ -z "$file" ]]; then
        printStyled error "[_module_load_commands] Expected : <file> (received : $1)"
        return 1
    fi

    # get_commands is optional
    if ! typeset -f get_commands >/dev/null; then
        return 0
    fi

    # Capture and validate output
    local raw_output
    if ! raw_output="$(get_commands)"; then
        printStyled error "[_module_load_commands] get_commands failed in ${file}"
        return 1
    fi

    local cmd
    for cmd in ${(f)raw_output}; do
        if [[ "$cmd" != *=* ]]; then
            printStyled warning "[_module_load_commands] Invalid command format: '$cmd' in ${file}"
            printStyled highlight "Expected : 'command=function'"
            continue
        fi
        COMMANDS+=("$cmd")
    done

    unfunction get_commands
}

