#!/usr/bin/env zsh
###############################
# FICHIER /.run/core/modules.zsh
###############################

# TODO: If cycle conflict → Ask user to choose ([1] file_1 → file_2 || [2] file_2 → file_1 || [3] Only file_1 || [4] Only file_2 || [5] Cancel both)
#   |-> Reorganise MODULES global var content to be same oredered as resolved conflicts (and remove canceled modules)

# [Modules manager and loader]
   #   - Downloads modules recursively
   #   - Merges modules dependencies
   #   - Loads and activates modules
   #   - Registers dynamic CLI commands

   # Depends on:
   #   - parser.zsh         → reads and writes tools descriptors
   #   - brew.zsh           → installs missing Homebrew dependencies

   # Used by:
   #   - gacli.zsh          → loads modules at startup
   #   - update.zsh         → triggers modules refresh before updates

   # Note: Handles module download conflicts and nested modules
#

# Github repo containing all available modules
MODULES_LIB="https://raw.githubusercontent.com/guillaumeast/gacli-hub/refs/heads/master/modules"

# Modules signature
ENTRY_POINT="main.zsh"
CONFIG_FILE="tools.yaml"

# Active modules and commands
MODULES_INSTALLED=()
MODULES_ACTIV=()

# ────────────────────────────────────────────────────────────────
# DOWNLOAD FILES
# ────────────────────────────────────────────────────────────────

# PUBLIC - Download and merge all modules
modules_init() {
    local modules_to_check=()
    local merged_formulae=()
    local merged_casks=()

    # Reset merged file
    parser_reset "${MODULES_TOOLS}" formulae || return 1
    parser_reset "${MODULES_TOOLS}" casks || return 1

    # Get modules list from $MODULES_DIR
    setopt local_options nullglob # Avoid errors when MODULES_DIR is empty
    local folders=("${MODULES_DIR}"/*(/))
    if [[ ${#folders[@]} -gt 0 ]]; then
        local module_path
        for module_path in "${folders[@]}"; do
            modules_to_check+=("${module_path##*/}")
        done
    fi

    # Get modules list from $USER_TOOLS
    parser_read "${USER_TOOLS}" modules || return 1
    if [[ ${#BUFFER[@]} -gt 0 ]]; then
    for module in "${BUFFER[@]}"; do
        modules_to_check+=("${module}")
    done

    # Modules are optional
    [[ ${#modules_to_check[@]} = 0 ]] && return 0

    # Download modules
    for module in $modules_to_check; do
        # Download module and nested modules
        _module_download "${module}" || continue

        # Merge formulae dependencies
        parser_read "${MODULES_DIR}/${module}/${CONFIG_FILE}" formulae || continue
        merged_formulae+=("${BUFFER[@]}")

        # Merge casks dependencies
        parser_read "${MODULES_DIR}/${module}/${CONFIG_FILE}" casks || continue
        merged_casks+=("${BUFFER[@]}")
    fi

    # Save merged dependencies
    parser_write "${MODULES_TOOLS}" formulae "${merged_formulae[@]}" || {
        printstyled error "[modules] Unable to merge modules dependencies"
        return 1
    }
    parser_write "${MODULES_TOOLS}" casks "${merged_casks[@]}"|| {
        printstyled error "[modules] Unable to merge modules dependencies"
        return 1
    }
}

# PRIVATE - Download and extract a module (recursively)
_module_download() {
    local module="${1}"

    # Download module if needed
    if ! _module_is_downloaded "${module}"; then
        local descriptor_url="${MODULES_LIB}/${module}.yaml"
        local tmp_descriptor="$(mktemp)"
        tmp_descriptor="${TMP_DIR}/${module}.yaml"

        # Download descriptor file (abstract curl / get handling into a /.helpers/http.zsh file)
        curl "${descriptor_url}" > "${descriptor_path}" || {
            printstyled error "[_module_download] Unable to download descriptor"
            printstyled error "→ url: ${descriptor_url}"
            rm -f "$tmp_descriptor"
            return 1
        }

        # Get archive url
        parser_read "${descriptor_path}" module_url || {
            printstyled error "[_module_download] Unable to parse descriptor"
            rm -f "$tmp_descriptor"
            return 1
        }
        local module_url="${BUFFER[1]}"
        rm -f "$tmp_descriptor"

        # Download module archive
        local tmp_archive="$(mktemp)"
        if ! curl -sL "${module_url}" --output "${tmp_archive}"; then
            printstyled error "[_module_download] Unable to download module archive"
            printstyled error "→ url: ${module_url}"
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

        # Check integrity
        _module_is_downloaded "${module}" || {
            printstyled error "[_module_download] Unable to recognize module: ${module}"
            return 1
        }
    fi

    # Download nested modules (recursive)
    local config="${MODULES_DIR}/${module}/${CONFIG_FILE}"
    parser_read "${config}" modules
    for nested_module in "${BUFFER[@]}"; do
        _module_download "${nested_module}" || {
            printstyled error "[_module_download] Unable to download nested modules for module: ${module}"
            return 1
        }
    done

    # Add to installed modules variable
    MODULES_INSTALLED+=("${module}")
}

# PRIVATE - Check if a module is correctly installed
_module_is_downloaded() {

    # Resolve paths
    local module="${1}"
    local module_path="${MODULES_DIR}/${module}"
    local entry_point="${module_path}/${ENTRY_POINT}"
    local config_file="${module_path}/${CONFIG_FILE}"

    # Check signatures
    [[ -d "${module_path}" ]] || return 1
    [[ -f "${entry_point}" ]] || return 1
    [[ -f "${config_file}" ]] || return 1
}

# ────────────────────────────────────────────────────────────────
# SOURCE CODE
# ────────────────────────────────────────────────────────────────

# PUBLIC - Source installed modules and activate their commands
modules_load() {
    local MODULES_ACTIV=()

    # Reset modules value into $INSTALLED_TOOLS file
    parser_reset "${INSTALLED_TOOLS}" modules

    # Source installed modules
    local module
    for module in "${MODULES_INSTALLED[@]}"; do
        source "${module}" && _module_get_commands "${module}" && MODULES_ACTIV+=("${module}")
    done

    # Set modules value into $INSTALLED_TOOLS file
    parser_write "${INSTALLED_TOOLS}" modules "${MODULES_ACTIV[@]}"
}

# PRIVATE - Extract dynamic commands from a module via get_commands
_module_get_commands() {
    local file="$1"

    # Argument check
    if [[ -z "$file" ]]; then
        printStyled error "[_module_get_commands] Expected : <file> (received : $1)"
        return 1
    fi

    # get_commands is optional
    if ! typeset -f get_commands >/dev/null; then
        return 0
    fi

    # Capture and validate output
    local raw_output
    if ! raw_output="$(get_commands)"; then
        printStyled error "[_module_get_commands] get_commands failed in ${file}"
        return 1
    fi

    local cmd
    for cmd in ${(f)raw_output}; do
        if [[ "$cmd" != *=* ]]; then
            printStyled warning "[_module_get_commands] Invalid command format: '$cmd' in ${file}"
            printStyled highlight "Expected : 'command=function'"
            continue
        fi
        COMMANDS_MODS+=("$cmd")
    done

    unfunction get_commands
}

