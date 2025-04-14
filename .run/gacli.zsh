###############################
# FICHIER gacli.zsh
###############################

#!/usr/bin/env zsh

# Easter egg display
if [[ $1 == "" ]]; then
    print "\033[90m✧ Don't panic... 🐥\033[0m"
fi

# Env
setopt extended_glob
IS_MACOS=false
IS_LINUX=false

# Root path
GACLI_DIR_REL=".gacli"
GACLI_DIR=""

# Helpers
HELPERS_DIR_REL=".run/helpers"
HELPERS_FILES_REL=("io.zsh" "brew.zsh" "parser.zsh" "time.zsh")
HELPERS=()

# Core files
CORE_DIR_REL=".run/helpers"
CORE_FILES_REL=("config.zsh" "update.zsh" "uninstall.zsh")
CORE_FILES=()

# Modules manager
MODULES_MANAGER_REL=".run/modules.zsh"
MODULES_MANAGER=""

# Temporary directory
TMP_DIR_REL=".tmp"
TMP_DIR=""

# Buffer for cross-modules communication (kind of "stdinfo")
BUFFER=()

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

# Main function
main() {
    # Check env
    _gacli_check_os || abort "1"
    _gacli_resolve || abort "2"

    # Load helpers
    for helper in $HELPERS; do
        if ! source "${helper}"; then
            echo "[gacli.zsh] Unable to find required helper: ${helper}"
            abort "3"
        fi
    done

    # Check core dependencies
    # TODO: check instead of make a blind update (maybe it's not needed !)
    # TODO: create `_gacli_check_dependencies` function
    brew_bundle "/.run/core/Brewfile"

    # Load core files
    for core_file in $CORE_FILES; do
        if ! source "${core_file}"; then
            echo "[gacli.zsh] Unable to find required file: ${core_file}"
            abort "4"
        fi
    done
    config_init || abort "5"
    update_init || abort "6"

    # Load modules
    source "${MODULE_MANAGER}" || abort "7"
    modules_load || abort "8"

    # Dispatch commands
    _gacli_dispatch "$@" || abort "9"
}

# ────────────────────────────────────────────────────────────────
# Functions - PRIVATE
# ────────────────────────────────────────────────────────────────

# Detect the operating system and set the corresponding flags
_gacli_check_os() {
    if [[ -z "$OSTYPE" ]]; then
        echo "[_gacli_check_os] Error: \$OSTYPE is not set" >&2
        return 1
    fi

    case "$OSTYPE" in
        darwin*) IS_MACOS=true ;;
        linux*)  IS_LINUX=true ;;
        *)
            echo "[_gacli_check_os] Error: Unknown OS type: $OSTYPE" >&2
            return 1
            ;;
    esac
}

# Resolve and store the absolute path to the gacli directory
_gacli_resolve() {

    # Root dir
    if [ -z "${HOME}" ] || [ ! -d "${HOME}" ]; then
        echo "[_gacli_resolve] Error: \$HOME is not set or invalid"
        return 1
    fi
    GACLI_DIR="${HOME}/${GACLI_DIR_REL}"

    # Helpers
    local helper
    for helper in $HELPERS_FILES_REL; do
        HELPERS+=("${GACLI_DIR}/${HELPERS_DIR_REL}/${helper}")
    done

    # Core files
    local file
    for file in $CORE_FILES_REL; do
        CORE_FILES+=("${GACLI_DIR}/${CORE_DIR_REL}/${file}")
    done

    # Module manager
    MODULES_MANAGER="${GACLI_DIR}/${MODULES_MANAGER_REL}"

    # Tmp directory
    TMP_DIR="${GACLI_DIR}/${TMP_DIR_REL}"
    mkdir -p "${TMP_DIR}" || {
        echo "[_gacli_resolve] Error: Failed to create tmp dir: ${TMP_DIR}"
        return 1
    }
}

# Dispatch commands
_gacli_dispatch() {
    case "$1" in
        "")
            style_ascii_logo                # Implemented in gacli/modules/.core/io.zsh
            print_tools
            ;;
        "help")
            help
            ;;
        "config")
            update_config                   # Implemented in gacli/modules/.core/.launcher/update.zsh
            ;;
        "update")
            update_manual                   # Implemented in gacli/modules/.core/.launcher/update.zsh
            ;;
        "uninstall")
            gacli_uninstall                 # Implemented in gacli/modules/.core/.launcher/uninstall.zsh
            ;;
        *)
            modules_dispatch "$@"           # Implemented in gacli/modules/.core/module_manager.zsh
    esac
}

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

# Display tools status
print_tools() {
    # Display Hombrew packages
    print_formulae                      # Implemented in gacli/modules/.core/brew.zsh
    print_casks                         # Implemented in gacli/modules/.core/brew.zsh

    # Display available commands
    modules_print_commands              # Implemented in gacli/modules/module_manager.zsh
    print ""
}

# Diplay tips
help() {
    print ""
    printStyled highlight "Formulaes: (more info: https://formulae.brew.sh/formula)"
    print_formulae                      # Implemented in gacli/modules/.core/brew.zsh
    print ""
    printStyled highlight "Casks: (more info: https://formulae.brew.sh/cask/)"
    print_casks                         # Implemented in gacli/modules/.core/brew.zsh
    print ""
    printStyled highlight "Gacli core commands: (more info: https://github.com/guillaumeast/gacli)"
    print "${ICON_ON} ${RED}gacli update ${GREY}| ${ICON_ON} ${RED}gacli uninstall${NONE}"
    print ""
    printStyled highlight "Gacli modules commands: (more info: https://github.com/guillaumeast/gacli)"
    modules_print_commands                      # Implemented in gacli/modules/module_manager.zsh
    print ""
}

# Display a fatal error message and exit the script
abort() {
    echo "[GACLI] E${1}: fatal error, exiting GACLI" >&2
    exit "${1}"
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

# Call main with all command args
main "$@"

