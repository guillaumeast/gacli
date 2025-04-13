###############################
# FICHIER module_manager.zsh
###############################

#!/usr/bin/env zsh

# setopt extended_glob (TODO: no more needed ?)

# Resolve path
MODULES_DIR="${GACLI_DIR}/${MODULE_DIR_NAME}"

# Core and optional modules directories
HELPERS="${MODULES_DIR}/.core/helpers"
LAUNCHER="${MODULES_DIR}/.core/launcher"
USER_MODULES="${MODULES_DIR}/user_modules"

# Module signature
ENTRY_POINT_FILE_NAME="main.zsh"
DEPENDENCIES_FILE_NAME="Brewfile"
MODULES_FILE_NAME="modules.json"

# Custom modules and commands
MODULES=()
COMMANDS=()

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

modules_init() {

    # Load core modules (cross-platform compatibility)
    _modules_load_dir "${HELPERS}" true || return 1

    # Load launcher modules (GACLI config and update management)
    _modules_load_dir "${LAUNCHER}" true || return 1

    # Load user modules
    _modules_load_dir "${USER_MODULES}" false || return 1
}

# ────────────────────────────────────────────────────────────────
# WIP
# ────────────────────────────────────────────────────────────────

# Load all modules in a directory (recursive)
_modules_load_dir() {
    local dir="$1"
    local required="$2"
    local file

    # Check arguments
    if [[ ! -d "${dir}" ]]; then
        if [[ $required = true ]]; then
            echo "[_modules_load_dir] Error: modules directory not found at: ${dir}" >&2
            return 1
        else
            echo "[_modules_load_dir] Warning: modules directory not found at: ${dir}" >&2
            return 0
        fi
    fi
    if [[ $required != true && $required != false ]]; then
        echo "[_modules_load_dir] Error: Expected true or false (received: ${2})"
        return 1
    fi

    # Load each module
    for file in "${dir}"/**/*.zsh(N); do
        # Download nested modules and merge tools
        _module_fetch "${file}" "$required" || return 1
        _module_init "${file}" "$required" || return 1
    done
}

# ────────────────────────────────────────────────────────────────
# Functions - PRIVATE
# ────────────────────────────────────────────────────────────────

# Vérifier que chaque module est chargé après que toutes ses dépendances l'aient été ? (osef tant qu'on source pas le fichier ? )
# 1. Load helpers
# 2. Load launcher
# 3. Load user_modules

_modules_load_custom() {
#      |
#      |-> For each module in $USER_MODULES             # No recursive
#      |        |-> module_fetch "$module"              # Recursively fetch nested modules
#      |
#      |-> brew_bundle                                  # Implemented in brew.zsh
#      |        |-> Download/update dependencies        # Using ${TMP_DIR}/Brewfile
#      |
#      |-> For each module in $USER_MODULES             # Arrey of absolute paths
#      |        |-> module_init "$module"               # Sources main/zsh and gets module commands
}

_module_fetch() { # <module>    # TODO: Ne pas partir de $USER_MODULES mais de "${GACLI_PATH}/${MODULES_FILE_NAME}" ! (no modules in $USER_MODULES after install !)
#      |
#      |-> Check if <module>/main.zsh exists (required, even if its content is empty)
#      |
#      |-> Check if <module>/Brewfile exists (required, even if its content is empty)
#      |        |-> brew_add_brewfile "<module>/Brewfile" (implemented in brew.zsh)
#      |                |-> Append <module>/Brewfile content to ${TMP_DIR}/Brewfile
#      |
#      |-> Check if <module>/modules.json exists (required, even if its content is empty)
#      |        |-> For each <module> in modules.json
#      |                |-> Extract <module_name>, <module_url> and <module_enabled>
#      |                |-> If <module_enabled> = false => return 0
#      |                |-> If "${USER_MODULES}/<module_name>" doesn't exists => _module_add <module_url>
#      |                |-> module_fetch "${USER_MODULES}/<module_name>"    # Recursive
#      |
#      |-> If main.zsh, Brewfile and modules.json exist => Add <module> absolute path to USER_MODULES array (deduplicated !)
}

# Source module main script and load module exposed commands
_module_init() {
    local file="${1}/${ENTRY_POINT_FILE_NAME}"
    local required
    if [[ "$2" = "required" ]]; then
        required=true
    fi

    # Check file integrity
    if [[ ! -f "$file" ]]; then
        printStyled error "[_module_init] Module entry point not found: ${file}"
        return 1
    fi

    # Try to source module code and commands
    if source "${file}"; then
        _module_get_commands "${file}" || return 1
    else
        printStyled error "[_module_init] Failed to load module: ${file}"
        return 1
    fi
}

# Import command mappings from a unique module
_module_get_commands() {
    local file="$1"

    # Check argument
    if [[ -z "$file" ]]; then
        printStyled error "[_module_get_commands] Expected : <file> (received : $1)"
        return 1
    fi

    # Check if module exposes commands (optional)
    if ! typeset -f get_commands >/dev/null; then
        return 0
    fi

    # Load raw command list
    local raw_output
    if ! raw_output="$(get_commands)"; then
        printStyled error "[_module_get_commands] get_commands failed in ${file}"
        return 1
    fi

    # Load each command
    local cmd
    for cmd in ${(f)raw_output}; do
        if [[ "$cmd" != *=* ]]; then
            printStyled warning "[_module_get_commands] Invalid command format: '$cmd' in ${file}"
            printStyled highlight "Expected : 'command=function'"
            continue
        fi
        COMMANDS+=("$cmd")
    done

    # Unset get_commands to avoid conflicts with next modules
    unfunction get_commands
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

