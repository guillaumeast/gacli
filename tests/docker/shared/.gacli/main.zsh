#!/usr/bin/env zsh
###############################
# FICHIER /src/main.zsh
###############################

# TODO: Load style.zsh then lazy load others helpers depending on command which must be executed

if [[ $1 == "" ]]; then
    print "\033[90m✧ Don't panic... 🐥\033[0m"
fi

# Env
setopt extended_glob
if [ -z "${HOME}" ] || [ ! -d "${HOME}" ]; then

    echo ""
    echo "\033[31m-------------------------------------------------------\033[0m"
    echo "\033[31m→ [GACLI] Fatal error: \$HOME is not set\033[0m" >&2
    echo "\033[31m-------------------------------------------------------\033[0m"
    echo ""
    return 1
fi
DIR_GACLI="${HOME}/.gacli"

# Directories
DIR_DATA="${DIR_GACLI}/data"
DIR_CONFIG="${DIR_DATA}/config"
DIR_TOOLS="${DIR_DATA}/tools"
DIR_HELPERS="${DIR_GACLI}/helpers"
DIR_LOGIC="${DIR_GACLI}/logic"
DIR_MODS="${DIR_GACLI}/modules"

# TODO: "/tmp" instead (⚠️ check all files → there must be some `rm -rf "${DIR_TEMP}"` !!)
DIR_TMP="${DIR_GACLI}/.tmp"

# TODO: waste of time ?
DIRS=("${DIR_GACLI}" "${DIR_DATA}" "${DIR_CONFIG}" "${DIR_TOOLS}" "${DIR_HELPERS}" "${DIR_LOGIC}" "${DIR_MODS}" "${DIR_TMP}")

# Config files
FILE_CONFIG_UPDATE="${DIR_CONFIG}/update.config.json"
FILES_CONFIG=("${FILE_CONFIG_UPDATE}")

# Tools files
FILE_TOOLS_CORE="${DIR_TOOLS}/core.tools.json"
FILE_TOOLS_MODULES="${DIR_TOOLS}/modules.tools.json"
FILE_TOOLS_USER="${DIR_TOOLS}/user.tools.json"
FILES_TOOLS=("${FILE_TOOLS_CORE}" "${FILE_TOOLS_MODULES}" "${FILE_TOOLS_USER}")

# Scripts files
# TODO: load all DIR_HELPERS files recursively instead
SCRIPTS=( \
    "${DIR_GACLI}/helpers/time.zsh" \
    "${DIR_GACLI}/helpers/parser.zsh" \
    "${DIR_GACLI}/helpers/brew.zsh" \
    "${DIR_GACLI}/logic/update.zsh" \
    "${DIR_GACLI}/logic/modules.zsh" \
    "${DIR_GACLI}/logic/uninstall.zsh" \
)

# Available commands
COMMANDS_CORE=("help=help" "config=update_edit_config" "update=update_manual" "uninstall=gacli_uninstall")
COMMANDS_MODS=()

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

# Main function
main() {

    if ! command -v gacli > /dev/null 2>&1; then
        printui warning "gacli command not found"
        printui highlight "Check your PATH then restart your terminal or run: exec zsh"
        return 1
    fi

    # TODO: waste of time ?
    _gacli_check_files || return 1

    local script
    # TODO: load all DIR_HELPERS files recursively instead
    for script in "${SCRIPTS[@]}"; do
        if ! source "${script}"; then
            print_fatal_error "Unable to load required script: ${script}"
            return 2
        fi
    done

    # Auto-check if update is required (date) when script is sourced ?
    update_init  || abort "5" || return 4           # Implemented in update.zsh

    ############################################
    # WIP → Start

    # TODO: waste of time → do it only when a module is added/removed/updated/called
    # TODO: store module commands ine some persistant place
    # TODO: later → lazy load depending on called command (only load required modules to make startup as fast as possible)
    modules_init || abort "4" || return 3           # Implemented in modules.zsh
    modules_load || abort "6" || return 5           # Implemented in modules.zsh

    _gacli_dispatch "$@" || abort "7" || return 6
    # WIP → End
    ############################################
}

# ────────────────────────────────────────────────────────────────
# CORE LOGIC
# ────────────────────────────────────────────────────────────────

# TODO: waste of time ?
_gacli_check_files() {

    local dir=""
    local file=""
    local files=("${FILES_CONFIG[@]}" "${FILES_TOOLS[@]}")

    for dir in "${DIRS[@]}"; do
        mkdir -p "${dir}" || {
            print_fatal_error "Unable to resolve dir: ${dir}"
            return 1
        }
    done

    for file in "${files[@]}"; do
        touch "${file}" || {
            print_fatal_error "Unable to resolve file: ${file}"
            return 1
        }
    done
}

_gacli_dispatch() {
    case "$1" in
        "")
            # TODO: optimize
            print_logo
            print_formulae
            print_casks
            print_modules
            print_core_commands
            print_mods_commands
            echo ""
            ;;
        *)
            # TODO: refer to a static command definition updated when modules are added/updated/removed)
            local commands=("${COMMANDS_CORE[@]}" "${COMMANDS_MODS[@]}")
            for cmd in "${commands[@]}"; do
                local command_name="${cmd%%=*}"
                local function_name="${cmd#*=}"

                if [[ "$1" == "$command_name" ]]; then
                    # Call matched function with remaining args
                    "${function_name}" "${@:2}"
                    return "$?"
                fi
            done

            printui error "Unknown command '$1'" >&2
            modules_print_commands
            return 1
            ;;
    esac
}

# Print errors even if style.zsh is not sourced
print_fatal_error() {

    echo ""
    echo "\033[31m-------------------------------------------------------\033[0m"
    echo "\033[31m→ [GACLI] Fatal error: ${1}\033[0m" >&2
    echo "\033[31m-------------------------------------------------------\033[0m"
    echo ""
}

# ────────────────────────────────────────────────────────────────
# OUTPUTS (TODO → style.zsh)
# ────────────────────────────────────────────────────────────────

# PUBLIC - Diplay tips
help() {
    print ""
    print "${GREY}→ Formulaes → https://formulae.brew.sh/formula ${NONE}"
    print_formulae

    print ""
    print "${GREY}→ Casks → https://formulae.brew.sh/cask/ ${NONE}"
    print_casks

    print ""
    print "${GREY}→ Modules → https://github.com/guillaumeast/gacli ${NONE}"
    print_modules

    print ""
    print "${GREY}→ Core commands${NONE}"
    print_core_commands

    print ""
    print "${GREY}→ Modules commands${NONE}"
    print_mods_commands
    print ""
}

# PUBLIC - Print installed status for all formulae defined in tools descriptors
print_formulae() {
    local tmp_brewfile="${DIR_TMP}/Brewfile"
    local formula
    local output

    # Get merged casks
    update_merge_into "${tmp_brewfile}" || {
        rm -f "${tmp_brewfile}"
        return 1
    }
    
    formulae+=("${(@f)$(file_read "${tmp_brewfile}" formulae)}") || {
        rm -f "${tmp_brewfile}"
        return 1
    }

    # Compute
    for formula in "${formulae[@]}"; do
        formula="${formula#"${formula%%[![:space:]]*}"}"  # Trim leading spaces
        formula="${formula%"${formula##*[![:space:]]}"}"  # Trim trailing spaces
        [[ -z $formula || "$formula" == "" ]] && continue
        local icon="${RED}${ICON_OFF}${NONE}"
        local color=$RED
        brew_is_f_active "${formula}" && {
            icon="${GREEN}${ICON_ON}${NONE}"
            color=$COLOR_FORMULAE
        }
        output+="${icon} ${color}$formula ${GREY}|${NONE} "
    done

    # Display (removing trailing " | ")
    [[ -n "${output}" ]] && print "${output% ${GREY}|${NONE} }"

    # Delete temporary Brewfile
    rm -f "${tmp_brewfile}"
}

# PUBLIC - Print installed status for all casks defined in tools descriptors
print_casks() {
    local tmp_brewfile="${DIR_TMP}/Brewfile"
    local casks=()
    local cask=""
    local output=""

    # Get merged casks
    update_merge_into "${tmp_brewfile}" || {
        rm -f "${tmp_brewfile}"
        return 1
    }
    casks=("${(@f)$(file_read "${tmp_brewfile}" casks)}") || {
        rm -f "${tmp_brewfile}"
        return 1
    }

    # Compute
    for cask in "${casks[@]}"; do
        cask="${cask#"${cask%%[![:space:]]*}"}"  # Trim leading spaces
        cask="${cask%"${cask##*[![:space:]]}"}"  # Trim trailing spaces
        [[ -z $cask || "$cask" == "" ]] && continue
        local icon="${RED}${ICON_OFF}${NONE}"
        local color=$RED
        brew_is_c_active "${cask}" && {
            icon="${GREEN}${ICON_ON}${NONE}"
            color=$COLOR_CASKS
        }
        output+="${icon} ${color}$cask ${GREY}|${NONE} "
    done

    # Display (removing trailing " | ")
    [[ -n "${output}" ]] && print "${output% ${GREY}|${NONE} }"

    # Delete temporary Brewfile
    rm -f "${tmp_brewfile}"
}

# PUBLIC - Print installed status for all installed modules
print_modules() {
    local output=""
    local icon

    for module in "${MODULES_INSTALLED[@]}"; do
        module="${module#"${module%%[![:space:]]*}"}"  # Trim leading spaces
        module="${module%"${module##*[![:space:]]}"}"  # Trim trailing spaces
        [[ -z $module || "$module" == "" ]] && continue
        local icon="${RED}${ICON_OFF}${NONE}"
        local color=$RED
        [[ " $MODULES_ACTIV " == *" $module "* ]] && {
            icon="${GREEN}${ICON_ON}${NONE}"
            color=$COLOR_MODS
        }
        output+="${icon} ${color}$module ${GREY}|${NONE} "
    done
    
    # Display (removing trailing " | ")
    [[ -n "${output}" ]] && print "${output% ${GREY}|${NONE} }"
}

# PUBLIC - Print available built-in GACLI core commands
print_core_commands() {
    local output

    for cmd in "${COMMANDS_CORE[@]}"; do
        local command_name="${cmd%%=*}"
        output+="${GREEN}${ICON_ON} ${COLOR_COMMANDS}${command_name} ${GREY}|${NONE} "
    done
    print "${output% ${GREY}|${NONE} }"
}

# PUBLIC - Print available commands provided by loaded modules
print_mods_commands() {
    local output

    for cmd in "${COMMANDS_MODS[@]}"; do
        local command_name="${cmd%%=*}"
        output+="${GREEN}${ICON_ON} ${COLOR_COMMANDS}${command_name} ${GREY}|${NONE} "
    done
    [[ -n "${output}" ]] && print "${output% ${GREY}|${NONE} }"
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

# Call main with all command args
main "$@"

