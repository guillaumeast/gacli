###############################
# FICHIER /.run/core/modules.zsh
###############################

#!/usr/bin/env zsh

# Github repo containing all available modules
MODULES_LIB="https://raw.githubusercontent.com/guillaumeast/gacli-hub/refs/heads/master/modules"

# Modules path
MODULES_DIR="${GACLI_DIR}/modules"

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
    for module in $MODULES_TO_INSTALL; do
        _module_install "${module}"
    done

    # Update dependencies if needed
    if [[ "$BREW_UPDATE_IS_DUE" = "true" ]]; then
        brew_update
    fi
    
    # Reset INSTALLED_TOOLS values
    parser_reset "${INSTALLED_TOOLS}" modules
    

    # Source module and get commands
    for module in $MODULES; do
        if ! source "${MODULES_DIR}/${module}/${ENTRY_POINT}"; then
            printStyled warning "[modules_init] Unable to load module: ${module}"
        else
            COMMANDS+=("$(get_commands)") || {
                printStyled warning "[modules_init] Unable to get module commands: ${module}"
            }
            parser_write "${INSTALLED_TOOLS}" modules "${module}" || {
                printStyled warning "[modules_init] Unable to add module: ${module} → ${INSTALLED_TOOLS}"
            }
            unfunction get_commands
        fi
    done

    # Save current state
    for formula in $FORMULAE; do
        parser_write "${INSTALLED_TOOLS}" formula "${formula}"
    done
    for cask in $CASKS; do
        parser_write "${INSTALLED_TOOLS}" cask "${cask}"
    done
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
    for module_path in "${MODULES_DIR}"/*(/); do
        local module="${module_path##*/}"
        _module_is_installed "${module}" || MODULES_TO_INSTALL+=("${module}")
    done

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

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

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
# WIP: DEBUG
# ────────────────────────────────────────────────────────────────

printStyled debug "=======> 7. modules.zsh loaded"

