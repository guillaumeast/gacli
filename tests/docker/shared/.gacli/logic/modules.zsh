#!/usr/bin/env zsh
###############################
# FICHIER /src/logic/modules.zsh
###############################

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

    # Reset merged file
    file_reset "${FILE_TOOLS_MODULES}" formulae || return 1
    file_reset "${FILE_TOOLS_MODULES}" casks || return 1
    file_reset "${FILE_TOOLS_MODULES}" modules || return 1

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

    # Download modules and merge dependencies (recursively)
    for module in "${modules_to_check[@]}"; do
        _module_download "${module}" || continue
    done
}

# PRIVATE - Download a module and merge dependencies (recursively)
_module_download() {
    local module="${1}"
    local config=""
    local list=()

    # Download module if needed
    if ! _module_is_downloaded "${module}"; then
        local descriptor_url="${MODULES_LIB}/${module}.json"
        local tmp_descriptor="${DIR_TMP}/${module}.json"
        local module_url=""

        # Download descriptor file (abstract curl / get handling into a /.helpers/http.zsh file)
        curl "${descriptor_url}" > "${tmp_descriptor}" || {
            printui error "Unable to download descriptor of: ${module}"
            printui error "→ url: ${descriptor_url}"
            printui error "Check module descriptor at: ${descriptor_url}"
            rm -f "$tmp_descriptor"
            return 1
        }

        # Check descriptor integrity
        [[ -f "${tmp_descriptor}" ]] || {
            printui error "Unable to download descriptor of: ${module}"
            printui error "→ url: ${descriptor_url}"
            printui error "Check module descriptor at: ${descriptor_url}"
            rm -f "$tmp_descriptor"
            return 1
        }

        # Get archive url
        module_url=$(file_read "${tmp_descriptor}" module_url) || {
            printui error "Unable to parse descriptor of: ${module}"
            rm -f "${tmp_descriptor}"
            return 1
        }
        rm -f "${tmp_descriptor}"

        # Check url integrity
        [[ -n "${module_url}" ]] || {
            printui error "Unable to extract url of: ${module}"
            printui error "→ Check module descriptor at: ${descriptor_url}"
            rm -f "$tmp_descriptor"
            return 1
        }

        # Download module archive
        local tmp_archive="$(mktemp)"
        if ! curl -sL "${module_url}" --output "${tmp_archive}"; then
            printui error "Unable to download module archive"
            printui error "→ url: ${module_url}"
            rm -f "$tmp_archive"
            return 1
        fi

        # Create target directory
        mkdir -p "${DIR_MODS}/${module}" || {
            printui error "Failed to create module directory: ${DIR_MODS}/${module}"
            rm -f "$tmp_archive"
            return 1
        }

        # Extract archive to module directory
        if ! tar --strip-components=1 -xzf "$tmp_archive" -C "${DIR_MODS}/${module}"; then
            printui error "Failed to extract archive: ${tmp_archive}"
            rm -f "$tmp_archive"
            return 1
        fi

        # Cleanup
        rm -f "$tmp_archive"

        # Check integrity
        _module_is_downloaded "${module}" || {
            printui error "Unable to recognize module: ${module}"
            return 1
        }
    fi

    # Download nested modules (recursive)
    config="${DIR_MODS}/${module}/${CONFIG_FILE}"
    list=("${(@f)$(file_read "${config}" modules)}")
    for nested_module in "${list[@]}"; do
        [[ -z "${nested_module}" ]] && continue
        if ! _module_is_downloaded "${nested_module}"; then
            _module_download "${nested_module}" || {
                printui error "Unable to download nested module: ${nested_module}"
                return 1
            }
        fi
    done

    # Add to installed modules variable
    MODULES_INSTALLED+=("${module}")

    # Merge dependencies
    list=("${(@f)$(file_read "${DIR_MODS}/${module}/${CONFIG_FILE}" formulae)}")
    file_add "${FILE_TOOLS_MODULES}" formulae "${list[@]}" || {
        printui error "Unable to merge modules dependencies"
        return 1
    }
    list=("${(@f)$(file_read "${DIR_MODS}/${module}/${CONFIG_FILE}" casks)}")
    file_add "${FILE_TOOLS_MODULES}" casks "${list[@]}"|| {
        printui error "Unable to merge modules dependencies"
        return 1
    }
    list=("${(@f)$(file_read "${DIR_MODS}/${module}/${CONFIG_FILE}" modules)}")
    file_add "${FILE_TOOLS_MODULES}" modules "${list[@]}"|| {
        printui error "Unable to merge modules dependencies"
        return 1
    }
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
            printui warning "Unable to load module: ${module}"
            continue
        }
        _module_get_commands "${entry_point}" || {
            printui warning "Unable to fetch module commands: ${module}"
            continue
        }
        MODULES_ACTIV+=("${module}")
    done
}

# PRIVATE - Extract dynamic commands list from a module via get_commands
_module_get_commands() {
    local file="$1"
    local commands=()

    # Argument check
    if [[ ! -f "$file" ]]; then
        printui error "Incorrect file : ${1}"
        return 1
    fi

    # Clear hash table (before)
    if typeset -f get_commands >/dev/null; then
        unfunction get_commands
    fi

    # Source module file (TODO: do it in a subshell to avoid double sourcing issues ?)
    source "${file}"
    if (( $? != 0 )); then
        printui error "Failed to load file : ${1}"
        return 1
    fi

    # Check if get_commands is implemented
    if ! typeset -f get_commands >/dev/null; then
        return 1
    fi

    # Capture and validate output
    commands=("${(@f)$(get_commands)}")
    if (( $? != 0 )); then
        unfunction get_commands
        return 1
    else
        unfunction get_commands
    fi

    # Return commands
    local cmd=""
    for cmd in "${commands[@]}"; do
        [[ -n "$cmd" && $cmd == *=* ]] || continue
        COMMANDS_MODS+=("${cmd}")
    done
}

