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
USER_TOOLS="tools.yaml"
CONFIG_DIR=".run/config"
CONFIG="config.yaml"
CORE_BREWFILE="Brewfile"

# Helpers
HELPERS_DIR=".run/helpers"
HELPERS_FILES=("io.zsh" "brew.zsh" "parser.zsh" "time.zsh")
HELPERS=()

# Core files
CORE_DIR=".run/core"
CORE_FILES=("update.zsh" "uninstall.zsh" "modules.zsh")
CORE=()

# Temporary files
TMP_DIR=".tmp"
INSTALLED_TOOLS="installed_tools.yaml"
MERGED_BREWFILE="Brewfile"

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
    for core_file in $CORE; do
        if ! source "${core_file}"; then
            echo "[gacli.zsh] Unable to find required file: ${core_file}"
            abort "5"
        fi
    done
    update_init || abort "6"

    # Load user modules
    modules_init || abort "7"

    # Dispatch commands
    _gacli_dispatch "$@" || abort "8"
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
    echo "🔦  => GACLI_DIR = \"${GACLI_DIR}\""

    # Directories paths
    CONFIG_DIR="${GACLI_DIR}/${CONFIG_DIR}"
    echo "🔦  => CONFIG_DIR = \"${CONFIG_DIR}\""
    HELPERS_DIR="${GACLI_DIR}/${HELPERS_DIR}"
    echo "🔦  => HELPERS_DIR = \"${HELPERS_DIR}\""
    CORE_DIR="${GACLI_DIR}/${CORE_DIR}"
    echo "🔦  => CORE_DIR = \"${CORE_DIR}\""
    TMP_DIR="${GACLI_DIR}/${TMP_DIR}"
    echo "🔦  => TMP_DIR = \"${TMP_DIR}\""
    mkdir -p "${TMP_DIR}" || {
        echo "[_gacli_resolve] Error: Failed to create tmp dir: ${TMP_DIR}"
        return 1
    }

    # Config files
    USER_TOOLS="${GACLI_DIR}/${USER_TOOLS}"
    echo "🔦  => USER_TOOLS = \"${USER_TOOLS}\""
    CONFIG="${CONFIG_DIR}/${CONFIG}"
    echo "🔦  => CONFIG = \"${CONFIG}\""
    CORE_BREWFILE="${CONFIG_DIR}/${CORE_BREWFILE}"
    echo "🔦  => CORE_BREWFILE = \"${CORE_BREWFILE}\""

    # Helpers
    local helper
    for helper in $HELPERS_FILES; do
        local helper_path="${HELPERS_DIR}/${helper}"
        HELPERS+=("${helper_path}")
        echo "🔦  ======> helper = \"${helper_path}\""
    done

    # Core files
    local file
    for file in $CORE_FILES; do
        local file_path="${CORE_DIR}/${file}"
        CORE+=("${file_path}")
        echo "🔦  ===========> core file = \"${file_path}\""
    done

    # Tmp files
    INSTALLED_TOOLS="${TMP_DIR}/${INSTALLED_TOOLS}"
    echo "🔦  => INSTALLED_TOOLS = \"${INSTALLED_TOOLS}\""
    MERGED_BREWFILE="${TMP_DIR}/${MERGED_BREWFILE}"
    echo "🔦  => MERGED_BREWFILE = \"${MERGED_BREWFILE}\""
}

# Dispatch commands
_gacli_dispatch() {
    case "$1" in
        "")
            style_ascii_logo                # Implemented in gacli/.run/helpers/io.zsh
            print_tools
            ;;
        "help")
            help
            ;;
        "config")
            update_edit_config              # Implemented in gacli/.run/core/update.zsh
            ;;
        "update")
            update_manual                   # Implemented in gacli/.run/core/update.zsh
            ;;
        "uninstall")
            gacli_uninstall                 # Implemented in gacli/.run/core/uninstall.zsh
            ;;
        *)
            modules_dispatch "$@"           # Implemented in gacli/.run/core/modules.zsh
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
    print_formulae                      # Implemented in .run/helpers/brew.zsh
    print_casks                         # Implemented in .run/helpers/brew.zsh

    # Display available commands
    modules_print_commands              # Implemented in gacli/.run/core/modules.zsh
    print ""
}

# Diplay tips
help() {
    print ""
    printStyled highlight "Formulaes: (more info: https://formulae.brew.sh/formula)"
    print_formulae                      # Implemented in gacli/.run/helpers/brew.zsh
    print ""
    printStyled highlight "Casks: (more info: https://formulae.brew.sh/cask/)"
    print_casks                         # Implemented in gacli/.run/helpers/brew.zsh
    print ""
    printStyled highlight "Gacli core commands: (more info: https://github.com/guillaumeast/gacli)"
    print "${ICON_ON} ${RED}gacli update ${GREY}| ${ICON_ON} ${RED}gacli uninstall${NONE}"
    print ""
    printStyled highlight "Gacli modules commands: (more info: https://github.com/guillaumeast/gacli)"
    modules_print_commands              # Implemented in gacli/.run/core/modules.zsh
    print ""
}

# Display a fatal error message and exit the script
abort() {
    echo ""
    echo "-------------------------------------------------------"
    echo " ---> [GACLI] E${1}: fatal error, exiting GACLI XXX <---" >&2
    echo "-------------------------------------------------------"
    echo ""
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
echo "🔦 [GACLI ENDED]"
print ""

