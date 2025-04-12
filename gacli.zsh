###############################
# FICHIER gacli.zsh
###############################

#!/usr/bin/env zsh

# Easter egg display
if [[ $1 == "" ]]; then
    print "\033[90m✧ Don't panic... 🐥\033[0m"
fi

# Env
IS_MACOS=false
IS_LINUX=false

# Root path
GACLI_DIR=""

# Module manager path
MODULE_DIR_NAME="modules"
MODULE_MANAGER_REL="${MODULE_DIR_NAME}/module_manager.zsh"
MODULE_MANAGER=""

# Temporary files directory path
TMP_DIR_REL="modules/.tmp"
TMP_DIR=""

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

# Main function
main() {
    # Check env and source code
    _check_os || abort "1"
    _gacli_resolve || abort "2"
    source "${MODULE_MANAGER}" || abort "3"

    # Init
    modules_init || abort "4"   # Implemented in gacli/modules/module_manager.zsh
    brew_init || abort "5"      # Implemented in gacli/modules/.launcher/brew.zsh
    use_gls                     # Implemented in gacli/modules/.core/io.zsh
    config_init || abort "6"    # Implemented in gacli/modules/.launcher/config.zsh
    update_init || abort "7"    # Implemented in gacli/modules/.launcher/update.zsh

    # Dispatch commands
    _gacli_dispatch "$@" || abort "8"
}

# ────────────────────────────────────────────────────────────────
# Functions - PRIVATE
# ────────────────────────────────────────────────────────────────

# Detect the operating system and set the corresponding flags
_check_os() {
    if [[ -z "$OSTYPE" ]]; then
        echo "[_check_os] Error: \$OSTYPE is not set" >&2
        return 1
    fi

    case "$OSTYPE" in
        darwin*) IS_MACOS=true ;;
        linux*)  IS_LINUX=true ;;
        *)
            echo "[_check_os] Error: Unknown OS type: $OSTYPE" >&2
            return 1
            ;;
    esac
}

# Resolve and store the absolute path to the gacli directory
_gacli_resolve() {
    # Root path
    script_path="${(%):-%x}"
    GACLI_DIR="$(cd "$(dirname "$script_path")" && pwd)"

    # Module manager
    MODULE_MANAGER="${GACLI_DIR}/${MODULE_MANAGER_REL}"
    if [[ ! -f "${MODULE_MANAGER}" ]]; then
        echo "[_gacli_resolve] Error: Failed to find module manager at: ${MODULE_MANAGER}" >&2
        return 1
    fi

    # Tmp directory
    TMP_DIR="${GACLI_DIR}/${TMP_DIR_REL}"
    mkdir -p "${TMP_DIR}" || {
        echo "[_gacli_resolve] Error: Failed to create tmp dir: ${TMP_DIR}"
        return 1
    }

    # Config file
    CONFIG_FILE="${GACLI_DIR}/${CONFIG_FILE_REL_PATH}"
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

