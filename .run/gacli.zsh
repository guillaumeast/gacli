###############################
# FICHIER /.run/gacli.zsh
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
GACLI_DIR=".gacli"

# Config files
CONFIG_DIR=".run/config"
CONFIG=".run/config/config.yaml"
CORE_BREWFILE=".run/config/Brewfile"
USER_TOOLS="tools.yaml"

# Helpers
HELPERS_DIR=".run/helpers"
HELPERS_FILES_REL=("io.zsh" "brew.zsh" "parser.zsh" "time.zsh")
HELPERS=()

# Core files
CORE_DIR=".run/core"
CORE_FILES_REL=("update.zsh" "uninstall.zsh" "modules.zsh")
CORE_FILES=()

# Temporary files
TMP_DIR=".tmp"
INSTALLED_TOOLS=".tmp/installed_tools.yaml"
MERGED_BREWFILE=".tmp/Brewfile"

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

    # Install core dependencies
    brew_update "${CORE_BREWFILE}" || abort "4"

    # Load core files
    for core_file in $CORE_FILES; do
        if ! source "${core_file}"; then
            echo "[gacli.zsh] Unable to find required file: ${core_file}"
            abort "5"
        fi
    done
    update_init || abort "7"

    # Load user modules
    modules_init || abort "8"

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
    GACLI_DIR="${HOME}/${GACLI_DIR}"

    # Directories paths
    CONFIG_DIR="${GACLI_DIR}/${CONFIG_DIR}"
    HELPERS_DIR="${GACLI_DIR}/${HELPERS_DIR}"
    CORE_DIR="${GACLI_DIR}/${CORE_DIR}"
    TMP_DIR="${GACLI_DIR}/${TMP_DIR}"
    mkdir -p "${TMP_DIR}" || {
        echo "[_gacli_resolve] Error: Failed to create tmp dir: ${TMP_DIR}"
        return 1
    }

    # Config files
    CONFIG="${GACLI_DIR}/${CONFIG_REL}"
    CORE_BREWFILE="${GACLI_DIR}/${CORE_BREWFILE_REL}"

    # Helpers
    local helper
    for helper in $HELPERS_FILES_REL; do
        HELPERS+=("${HELPERS_DIR}/${helper}")
    done

    # Core files
    local file
    for file in $CORE_FILES_REL; do
        CORE_FILES+=("${CORE_DIR}/${file}")
    done

    # Tmp files
    INSTALLED_TOOLS="${TMP_DIR}/${INSTALLED_TOOLS_REL}"
    MERGED_BREWFILE="${TMP_DIR}/${MERGED_BREWFILE_REL}"
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
    local formulae=()
    local casks=()
    local modules=()
    local commands=()

    # Get data
    formulae="$(read "${INSTALLED_TOOLS}" formulae)"
    casks="$(read "${INSTALLED_TOOLS}" casks)"
    modules="$(read "${INSTALLED_TOOLS}" modules)"
    commands="$(modules_get_commands)"

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

# ────────────────────────────────────────────────────────────────
# WIP: DEBUG
# ────────────────────────────────────────────────────────────────

print ""
printStyled debug "[GACLI ENDED]"
print ""

