#!/usr/bin/env zsh
###############################
# FICHIER /src/logic/modules.zsh
###############################

# TODO: If cycle conflict → Ask user to choose ([1] file_1 → file_2 || [2] file_2 → file_1 || [3] Only file_1 || [4] Only file_2 || [5] Cancel both)
#   |-> Reorganise MODULES global var content to be same oredered as resolved conflicts (and remove canceled modules)

# Github repo containing all available modules
MODULES_LIB="https://raw.githubusercontent.com/guillaumeast/gacli-hub/refs/heads/master/modules"

# Modules signature
ENTRY_POINT="main.zsh"
CONFIG_FILE="tools.json"

# Active modules and commands
MODULES_INSTALLED=()
MODULES_ACTIV=()

# ────────────────────────────────────────────────────────────────
# DOWNLOAD FILES
# ────────────────────────────────────────────────────────────────

# PUBLIC - Download and merge all modules
modules_init() {
    local modules_raw=()
    local modules_to_check=()
    local merged_formulae=()
    local merged_casks=()

    # Reset merged file
    file_reset "${FILE_TOOLS_MODULES}" formulae || return 1
    file_reset "${FILE_TOOLS_MODULES}" casks || return 1

    # Get modules list from $DIR_MODS
    setopt local_options nullglob # Avoid errors when DIR_MODS is empty
    local folders=("${DIR_MODS}"/*(/))
    if [[ ${#folders[@]} -gt 0 ]]; then
        local module_path
        for module_path in "${folders[@]}"; do
            modules_to_check+=("${module_path##*/}")
        done
    fi

    # Get modules list from $FILE_TOOLS_USER
    modules_raw+=("${(@f)$(file_read "${FILE_TOOLS_USER}" modules)}") || return 1

    if [[ ${#modules_raw[@]} -gt 0 ]]; then
        for module in "${modules_raw[@]}"; do
            [[ -z "$module" ]] && continue
            modules_to_check+=("${module}")
        done
    fi

    # Modules are optional
    [[ ${#modules_to_check[@]} = 0 ]] && return 0

    # Download modules
    for module in "${modules_to_check[@]}"; do
        # Download module and nested modules
        _module_download "${module}" || continue

        # Merge dependencies
        merged_formulae+=("${(@f)$(file_read "${DIR_MODS}/${module}/${CONFIG_FILE}" formulae)}") || continue
        merged_casks+=("${(@f)$(file_read "${DIR_MODS}/${module}/${CONFIG_FILE}" casks)}") || continue
    done

    # Save merged dependencies
    file_add "${FILE_TOOLS_MODULES}" formulae "${merged_formulae[@]}" || {
        printStyled error "Unable to merge modules dependencies"
        return 1
    }
    file_add "${FILE_TOOLS_MODULES}" casks "${merged_casks[@]}"|| {
        printStyled error "Unable to merge modules dependencies"
        return 1
    }
}

# PRIVATE - Download and extract a module (recursively)
_module_download() {
    local module="${1}"
    local config=""
    local nested_modules=()

    # Download module if needed
    if ! _module_is_downloaded "${module}"; then
        local descriptor_url="${MODULES_LIB}/${module}.json"
        local tmp_descriptor="${TMP_DIR}/${module}.json"
        local module_url=""

        # Download descriptor file (abstract curl / get handling into a /.helpers/http.zsh file)
        curl "${descriptor_url}" > "${tmp_descriptor}" || {
            printStyled error "Unable to download descriptor"
            printStyled error "→ url: ${descriptor_url}"
            rm -f "$tmp_descriptor"
            return 1
        }

        # Get archive url
        module_url=$(file_read "${tmp_descriptor}" module_url) || {
            printStyled error "Unable to parse descriptor"
            rm -f "${tmp_descriptor}"
            return 1
        }
        rm -f "${tmp_descriptor}"

        # Download module archive
        local tmp_archive="$(mktemp)"
        if ! curl -sL "${module_url}" --output "${tmp_archive}"; then
            printStyled error "Unable to download module archive"
            printStyled error "→ url: ${module_url}"
            rm -f "$tmp_archive"
            return 1
        fi

        # Create target directory
        mkdir -p "${DIR_MODS}/${module}" || {
            printStyled error "Failed to create module directory: ${DIR_MODS}/${module}"
            rm -f "$tmp_archive"
            return 1
        }

        # Extract archive to module directory
        if ! tar --strip-components=1 -xzf "$tmp_archive" -C "${DIR_MODS}/${module}"; then
            printStyled error "Failed to extract archive: ${tmp_archive}"
            rm -f "$tmp_archive"
            return 1
        fi

        # Cleanup
        rm -f "$tmp_archive"

        # Check integrity
        _module_is_downloaded "${module}" || {
            printStyled error "Unable to recognize module: ${module}"
            return 1
        }
    fi

    # Download nested modules (recursive)
    config="${DIR_MODS}/${module}/${CONFIG_FILE}"
    nested_modules+=("${(@f)$(file_read "${config}" modules)}")
    for nested_module in "${nested_modules[@]}"; do
        [[ -z "${nested_module}" || "${nested_module}" == "" ]] && continue
        _module_download "${nested_module}" || {
            printStyled error "Unable to download nested module: ${nested_module}"
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
    local module_path="${DIR_MODS}/${module}"
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
    
    local module=""
    local entry_point=""
    for module in "${MODULES_INSTALLED[@]}"; do
        entry_point="${DIR_MODS}/${module}/${ENTRY_POINT}"
        [[ ! -f "${entry_point}" ]] && continue
        source "${entry_point}" || {
            printStyled warning "Unable to load module: ${module}"
            continue
        }
        _module_get_commands "${entry_point}" || {
            printStyled warning "Unable to fetch module commands: ${module}"
            continue
        }
        MODULES_ACTIV+=("${module}")
    done
}

# PRIVATE - Extract dynamic commands from a module via get_commands
_module_get_commands() {
    local file="$1"

    # Argument check
    if [[ -z "$file" ]]; then
        printStyled error "Expected : <file> (received : $1)"
        return 1
    fi

    # get_commands is optional
    if ! typeset -f get_commands >/dev/null; then
        return 0
    fi

    # Capture and validate output
    local raw_output
    raw_output=("${(@f)$(get_commands | tr -d '\r')}")
    if (( $? != 0 )); then
        printStyled error "get_commands failed in ${file}"
        return 1
    fi

    for cmd in "${raw_output[@]}"; do
        [[ $cmd == *=* ]] || {
            printStyled warning "Invalid command format: '$cmd' in ${file}"
            continue
        }
        COMMANDS_MODS+=("$cmd")
    done

    unfunction get_commands
}


