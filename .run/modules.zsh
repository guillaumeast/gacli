###############################
# FICHIER gacli/modules/module_manager.zsh
###############################

#!/usr/bin/env zsh

# Github repo containing all available modules
MODULES_LIB="https://raw.githubusercontent.com/guillaumeast/gacli-hub/main/modules"

# Resolve path
MODULES_DIR="${GACLI_DIR}/${MODULE_DIR_NAME}"

# Core and optional modules directories
REQUIRED_MODULES=("${MODULES_DIR}/.core/helpers" "${MODULES_DIR}/.core/launcher")
OPTIONAL_MODULES="${MODULES_DIR}/user_modules"

# Modules signature
ENTRY_POINT="main.zsh"
CONFIG_FILE="tools.yaml"

# Modules, commands and dependencies
MODULES=()
FORMULAE=()
CASKS=()
COMMANDS=()

# Tools status (used to install missing dependencies)
NEW_TOOLS=false

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

modules_init() {

    # Fetch and load required modules
    for dir in $REQUIRED_MODULES; do
        _module_dir "${dir}" "fetch" true || return 1
        _module_dir "${dir}" "load" true || return 1
    done

    # Fetch optional modules
    _module_dir "${OPTIONAL_MODULES}" "fetch" false

    # Install required dependencies (implemented in update.zsh)
    if [[ $NEW_TOOLS = true ]]; then
        _module_merge_dependencies || return 1
        update_manual || return 1
    fi

    # Load optional modules
    _module_dir "${OPTIONAL_MODULES}" "load" false
}

# ────────────────────────────────────────────────────────────────
# Functions - PRIVATE
# ────────────────────────────────────────────────────────────────

# Load all modules in a directory (recursive)
_module_dir() {
    local dir="$1"
    local file
    local mode="$2"
    local error_type="Warning"
    local error_code=0
    if [[ $3 = true ]]; then
        error_type="Error"
        error_code=1
    fi

    # Check arguments
    if [[ ! -d "${dir}" ]]; then
        echo "[_module_dir] ${error_type}: modules directory not found at: ${dir}" >&2
        return $error_code
    fi
    if [[ $2 != "fetch" && $2 != "load" ]]; then
        echo "[_module_dir] ${error_type}: Unkonwn mode: ${2} (Expected: \"fetch\" or \"load\")" >&2
        return $error_code
    fi

    # Add modules dirs absolute paths to MODULES
    for module in "${dir}"/*(N); do     # TODO: correct (no recursive here !)
        # Check folder integrity
        if [[ ! -d "${module}" ]]; then
            echo "[_module_dir] ${error_type}: module not found at: ${dir}" >&2
            return $error_code
        fi

        # Fetch or load
        if [[ $mode = "fetch" ]]; then
            _module_fetch "${module}" || return "$error_code"
        elif [[ $mode = "load" ]]; then
            _module_load "${module}" || return "$error_code"
        fi

        # Add to MODULES
        MODULES+=("${module}")      # TODO: correct (should add module's folder absolute path into MODULES)
    done
}

# [RECURSIVE] Download module (if needed) and merge dependencies
_module_fetch() {
    local module="${1}"
    local entry_point="${module}/${ENTRY_POINT}"
    local dependencies="${module}/${CONFIG_FILE}"
    local module_name="${module:t}"
    local module_url="${MODULES_LIB}/${module_name}"
    
    # Check signature
    if [[ ! -f "${entry_point}" || ! -f "${dependencies}" ]]; then
        printStyled error "Module signature not recognized: ${module}"
        return 1
    fi

    # Parse nested modules
    nested_modules="$(config_get_modules "${dependencies}")" # TODO: update config.zsh (parse nested modules names from $dependencies yaml file)

    # Fetch nested modules (recusrive)
    for nested_module in $nested_modules; do
        _module_fetch "${nested_module}"
    done

    # Check if module is already installed
    if [[ ! "${MODULES[*]}" =~ "${module}" && -d "${module}" ]]; then
        MODULES+=("${module}")
        return 0
    fi

    # Download module
    if ! git clone "${module_url}" "${module}" > /dev/null 2>&1; then
        printStyled error "[GACLI] Error: Failed to download module: ${module_name}"
        return 1
    fi

    # Save module absolute path
    MODULES+=("${module_path}")
}

# Check if a module's tools.yaml has changed since last install
_module_check_dependencies() {
    local module="$1"
    local tools="${module}/${CONFIG_FILE}"
    local module_name="${module:t}"
    local tmp_tools="tmp/modules/${module_name}-tools.yaml"

    # If tmp version doesn't exist, consider it as new
    if [[ ! -f "$tmp_tools" ]]; then
        NEW_TOOLS=true
        return
    fi

    # Compare current and tmp version
    if ! diff -q "$tools" "$tmp_tools" > /dev/null; then
        NEW_TOOLS=true
    fi
}

# Source module main script and load module exposed commands
_module_load() {
    local file="${1}/${ENTRY_POINT}"
    local required

    # Check arguments
    if [[ ! -f "$file" ]]; then
        printStyled error "[_module_load] Module entry point not found: ${file}"
        return 1
    fi
    if [[ "$2" = "required" ]]; then
        required=true
    fi

    # Source code
    if ! source "${file}"; then
        printStyled error "[_module_load] Failed to load module: ${1}"
        return 1
    fi

    # Import exposed commands
    if ! _module_get_commands "${file}"; then
        printStyled error "[_module_load] Failed to import module commands: ${1}"
        return 1
    fi
}

# Import command mappings exposed by a module
_module_get_commands() {
    local file="$1"

    # Check argument
    if [[ -z "$file" ]]; then
        printStyled error "[_module_get_commands] Expected : <file> (received : $1)"
        return 1
    fi

    # Check if file exposes commands (optional)
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

    # Unset get_commands to avoid conflicts with next files
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

# ────────────────────────────────────────────────────────────────
# INIT
# ────────────────────────────────────────────────────────────────

modules_init || return 1

