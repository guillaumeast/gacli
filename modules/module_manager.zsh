###############################
# FICHIER module_manager.zsh
###############################

#!/usr/bin/env zsh

# Resolve path
MODULES_PATH=""
if ! MODULES_PATH="$(cd "$(dirname "${(%):-%x}")" && pwd)"; then
    echo "[resolve_path] Error: unable to resolve MODULES_PATH" >&2
    return 1
fi

# Modules and commands
ORDERED_CORE_MODULES=( \
    "style.zsh" \   # Needed for all other modules (implements formatting input / output functions)
    "brew.zsh" \    # Needed for next modules depedencies
    "date.zsh" \    # Needed for date computing (needs coreutils from brew)
)
CORE_DIR_NAME=".core"
LAUNCHER_DIR_NAME=".launcher"
USER_DIR_NAME="user_modules"
COMMANDS=()

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

init_modules() {
    # Load required modules
    modules_load_required || return 1

    # Load user modules
    modules_load_user || return 1 
}

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

# Load required modules
modules_load_required() {

    # Load core modules
    local file
    for file in $ORDERED_CORE_MODULES; do
        _module_load "${MODULES_PATH}/${CORE_DIR_NAME}/${file}" || return 1
    done
    
    # Ensure cross-platform compatibility (TODO: better put the alias in .zshrc to avoid corrupted shell env ?)
    use_gls                 # Implemented in style.zsh (needs coreutils auto-installed by brew.zsh)

    # Load launcher modules
    _modules_load_dir "${MODULES_PATH}/${LAUNCHER_DIR_NAME}" || return 1
}

# Load optional modules
modules_load_user() {
    _modules_load_dir "${MODULES_PATH}/${USER_DIR_NAME}" || return 1    
}

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
        output_commands+="${ICON_ON} ${GREEN}gacli ${command_name}${NONE} ${GREY}|${NONE} "
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
    local file

    # Check if modules directory exists
    if [[ ! -d "${dir}" ]]; then
        echo "[_modules_load_dir] Error: modules directory not found at: ${optional_dir}" >&2
        return 1
    fi

    for file in "${dir}"/**/*.zsh(N); do
        _module_load "${file}"
    done
}

# Load a unique module
_module_load() {
    local file="$1"

    # Check file integrity
    [[ -f "$file" ]] || continue

    # Try to source module code and commands
    if source "${file}"; then
        _module_load_commands "${file}"
    else
        printStyled warning "[_module_load] Failed to load optional module: ${file}"
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

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

init_modules || return 1

