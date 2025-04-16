###############################
# FICHIER /.run/core/modules.zsh
###############################

# 1. Download files (recursive)
# 2. Merge dependencies in /.config/modules_Brewfile
# 2. Source files (init)
#   |-> If cycle conflict → Ask user to choose ([1] file_1 → file_2 || [2] file_2 → file_1 || [3] Only file_1 || [4] Only file_2 || [5] Cancel both)
#   |-> Reorganise MODULES global var content to be same oredered as resolved conflicts (and remove canceled modules)
# 3. Call get_commands() on each module (ord)
# 4. Call main()

#!/usr/bin/env zsh

# Github repo containing all available modules
MODULES_LIB="https://raw.githubusercontent.com/guillaumeast/gacli-hub/refs/heads/master/modules"

# Modules signature
ENTRY_POINT="main.zsh"
CONFIG_FILE="tools.yaml"

# Modules, commands and dependencies
FORMULAE=()
CASKS=()
MODULES=()
COMMANDS=()
BREW_UPDATE_IS_DUE="false"

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

modules_init() {
    
    # Load installed tools lists
    _modules_get_installed

    # Check new modules
    _modules_check_new

    # Install new modules
    if [[ ${#MODULES_TO_INSTALL[@]} -gt 0 ]]; then
        for module in $MODULES_TO_INSTALL; do
            _module_install "${module}"
        done
    fi

    _modules_merge_dependencies

    # Update dependencies if needed
    if [[ "$BREW_UPDATE_IS_DUE" = "true" ]]; then
        brew_update
    fi
    
    # Reset INSTALLED_TOOLS values
    parser_reset "${INSTALLED_TOOLS}" modules
    

    # Source module and get commands
    if [[ ${#MODULES[@]} -gt 0 ]]; then
        for module in $MODULES; do
            local entry_point="${MODULES_DIR}/${module}/${ENTRY_POINT}"
            if ! source "${entry_point}"; then
                printStyled warning "[modules_init] Unable to load module: ${module}"
            else
                _module_get_commands "${entry_point}"
            fi
        done
    fi

    # Save current state
    echo ""
    echo "---------------------------------------------"
    echo "---------------------------------------------"
    printStyled debug "[modules_init] BEFORE FORMULAE: ${FORMULAE[@]}"
    printStyled debug "[modules_init] BEFORE CASKS: ${CASKS[@]}"
    echo "---------------------------------------------"
    parser_reset "${INSTALLED_TOOLS}" formulae
    parser_reset "${INSTALLED_TOOLS}" casks
    echo "---------------------------------------------"
    printStyled debug "[modules_init] RESETED FORMULAE: ${FORMULAE[@]}"
    printStyled debug "[modules_init] RESETED CASKS: ${CASKS[@]}"
    echo "---------------------------------------------"
    for formula in "${FORMULAE[@]}"; do
        printStyled debug "[modules_init] Adding f: ${formula}..."
        parser_write "${INSTALLED_TOOLS}" formulae "${formula}"
        printStyled debug "[modules_init] -> Added"
        printStyled debug "[modules_init] ---> FORMULAE: ${FORMULAE[@]}"
    done
    echo "---------------------------------------------"
    for cask in "${CASKS[@]}"; do
        printStyled debug "[modules_init] Adding c: ${cask}..."
        parser_write "${INSTALLED_TOOLS}" casks "${cask}"
        printStyled debug "[modules_init] -> Added"
        printStyled debug "[modules_init] ---> CASKS: ${CASKS[@]}"
    done
    echo "---------------------------------------------"
    printStyled debug "[modules_init] AFTER FORMULAE: ${FORMULAE[@]}"
    printStyled debug "[modules_init] AFTER CASKS: ${CASKS[@]}"
    echo "---------------------------------------------"
    echo "---------------------------------------------"
    echo ""
}

# ────────────────────────────────────────────────────────────────
# Functions - PRIVATE
# ────────────────────────────────────────────────────────────────

_modules_get_installed() {

    # Formulae
    parser_read "${INSTALLED_TOOLS}" formulae || return 1
    FORMULAE=("${BUFFER[@]}")

    # Casks
    parser_read "${INSTALLED_TOOLS}" casks || return 1
    CASKS=("${BUFFER[@]}")

    # Modules
    parser_read "${INSTALLED_TOOLS}" modules || return 1
    MODULES=("${BUFFER[@]}")
}

_modules_check_new() {
    MODULES_TO_INSTALL=()

    # Check new modules in $MODULES_DIR
    setopt local_options nullglob           # Nullglob to avoid errors when MODULES_DIR is empty
    local modules=("${MODULES_DIR}"/*(/))
    if [[ ${#modules[@]} -gt 0 ]]; then
        for module_path in "${modules[@]}"; do
            local module_name="${module_path##*/}"
            _module_is_installed "${module_name}" || MODULES_TO_INSTALL+=("${module_name}")
        done
    fi

    # Check new modules in $USER_TOOLS
    parser_read "${USER_TOOLS}" modules || return 1
    for module in "${BUFFER[@]}"; do
        _module_is_installed "${module}" || MODULES_TO_INSTALL+=("${module}")
    done
}

_module_install() {
    local module="${1}"

    # Check if module is already installed
    if _module_is_installed "${module}"; then
        MODULES+=("${module}")
        return 0
    fi

    # Download module files
    _module_download "${module}" || return 1

    # Install nested modules (recursive)
    parser_read "${MODULES_DIR}/${module}/${CONFIG_FILE}" modules || return 1
    local nested_module
    for nested_module in "${BUFFER[@]}"; do
        if ! [[ " ${MODULES[*]} " == *" ${nested_module} "* ]]; then
            _module_install "${nested_module}"
        fi
    done

    # Add formulae and casks dependencies
    _module_add_dependencies "${module}" || return 1

    # Add this module to MODULES
    MODULES+=("${module}")
}

_module_is_installed() {
    local module="${1}"
    local module_path="${MODULES_DIR}/${module}"
    [[ -d "${module_path}" ]] || return 1
    [[ -f "${module_path}/${ENTRY_POINT}" ]] || return 1
    [[ -f "${module_path}/${CONFIG_FILE}" ]] || return 1
}

_module_download() {
    local module="${1}"
    local descriptor_url="${MODULES_LIB}/${module}.yaml"
    local descriptor_path="${TMP_DIR}/${module}.yaml"

    # Download descriptor
    curl "${descriptor_url}" > "${descriptor_path}" || return 1

    # Get archive url
    parser_read "${descriptor_path}" module_url || return 1
    local module_url="${BUFFER[1]}"

    # Download archive
    local tmp_archive="$(mktemp)"
    if ! curl -sL "${module_url}" --output "${tmp_archive}"; then
        printStyled error "[_module_download] Failed to download module archive: ${module_url}"
        rm -f "$tmp_archive"
        return 1
    fi

    # Create target directory
    mkdir -p "${MODULES_DIR}/${module}" || {
        printStyled error "[_module_download] Failed to create module directory: ${MODULES_DIR}/${module}"
        rm -f "$tmp_archive"
        return 1
    }

    # Extract archive to module directory
    if ! tar -xzf "$tmp_archive" -C "${MODULES_DIR}/${module}"; then
        printStyled error "[_module_download] Failed to extract archive: ${tmp_archive}"
        rm -f "$tmp_archive"
        return 1
    fi

    # Cleanup
    rm -f "$tmp_archive"

}

_module_add_dependencies() {
    local module="${1}"

    # Check formulae
    parser_read "${MODULES_DIR}/${module}/${CONFIG_FILE}" formulae || return 1
    local formula
    for formula in "${BUFFER[@]}"; do
        if ! [[ " ${FORMULAE[*]} " == *" ${formula} "* ]]; then
            FORMULAE+=("${formula}")
            BREW_UPDATE_IS_DUE=true
        fi
    done

    # Check casks
    parser_read "${MODULES_DIR}/${module}/${CONFIG_FILE}" casks || return 1
    local cask
    for cask in "${BUFFER[@]}"; do
        if ! [[ " ${CASKS[*]} " == *" ${cask} "* ]]; then
            CASKS+=("${cask}")
            BREW_UPDATE_IS_DUE=true
        fi
    done
}

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
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

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

