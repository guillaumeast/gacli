###############################
# FICHIER gacli.zsh
###############################

#!/usr/bin/env zsh

# Easter egg display
if [[ $1 == "" ]]; then
    print "\033[90m🐥 Don't panic...\033[0m"
fi

# Env
IS_MACOS=false
IS_LINUX=false

# Root path
GACLI_PATH=""

# Module manager
MODULE_MANAGER_REL_PATH="modules/module_manager.zsh"
MODULE_MANAGER=""

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

# Main function
main() {
    # Init
    _check_os || abort "1"
    _gacli_resolve || abort "2"

    # Load required modules
    source "${MODULE_MANAGER}" || abort "3"

    # Update
    gacli_auto_update                   # Implemented in gacli/modules/.core/.launcher/update.zsh
    load_modules                        # Implemented in gacli/modules/.core/module_manager.zsh
    
    # Display
    print_formulae              # Implemented in `gacli/modules/.core/brew.zsh`
    print_casks                 # Implemented in `gacli/modules/.core/brew.zsh`

    # Dispatch commands
    _gacli_dispatch "$@" || return 1
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
    if ! GACLI_PATH="$(cd "$(dirname "${(%):-%x}")" && pwd)"; then
        echo "[_gacli_resolve] Error: unable to resolve root path" >&2
        return 1
    fi

    # Module manager
    MODULE_MANAGER="${GACLI_PATH}/${MODULE_MANAGER_REL_PATH}"
    if [[ ! -f "${MODULE_MANAGER}" ]]; then
        echo "[_gacli_resolve] Error: unable to find module manager" >&2
        return 1
    fi

    # Config file
    CONFIG_FILE="${GACLI_PATH}/${CONFIG_FILE_REL_PATH}"
}

_parse_config() {
    # TODO: implement in gacli/modules/.launcher/config.zsh
    # TODO: Check if config file exists
    # TODO: Parse config + error handling
}

# Dispatch commands
_gacli_dispatch() {
    case "$1" in
        "")
            display_ascii_logo              # Implemented in gacli/modules/.core/style.zsh
            print_tools
            ;;
        "help")
            help
            ;;
        "update")
            gacli_update                    # Implemented in gacli/modules/.core/.launcher/update.zsh
            ;;
        "uninstall")
            gacli_uninstall                 # Implemented in gacli/modules/.core/.launcher/uninstall.zsh
            ;;
        *)
            modules_dispatch "$@"  # Implemented in gacli/modules/.core/module_manager.zsh
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
    print_commands                      # Implemented in gacli/modules/module_manager.zsh
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
    print_commands                      # Implemented in gacli/modules/module_manager.zsh
    print ""
}

# Display a fatal error message and exit the script
abort() {
    echo "[GACLI] E${1}: fatal error, exiting GACLI" >&2
    echo "[GACLI] Tip: If error persist, try deleting the config file to reinstall GACLI" >&2
    echo "[GACLI] Tip: If error still persist, download latest version at: https://github.com/guillaumeast/gacli" >&2
    exit 1
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

# Call main with all command args
main "$@"

