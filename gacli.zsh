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

# Config file
CONFIG_FILE_REL_PATH="config"
CONFIG_FILE=""

# Main function
main() {
    # Init
    check_os || abort "1"
    resolve_paths || abort "2"

    # Load required modules
    source "${MODULE_MANAGER}" || abort "3"

    # Install or auto update
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        gacli_install || abort "4"          # Implemented in gacli/modules/.core/.launcher/install.zsh
    else
        gacli_auto_update                   # Implemented in gacli/modules/.core/.launcher/update.zsh
        load_modules                        # Implemented in gacli/modules/.core/module_manager.zsh
        dispatch_commands "$@" || return 1
    fi
}

# Detect the operating system and set the corresponding flags
check_os() {
    if [[ -z "$OSTYPE" ]]; then
        echo "[check_os] Error: \$OSTYPE is not set" >&2
        return 1
    fi

    case "$OSTYPE" in
        darwin*) IS_MACOS=true ;;
        linux*)  IS_LINUX=true ;;
        *)
            echo "[check_os] Error: Unknown OS type: $OSTYPE" >&2
            return 1
            ;;
    esac
}

# Resolve and store the absolute path to the gacli directory
resolve_paths() {
    # Root path
    if ! GACLI_PATH="$(cd "$(dirname "${(%):-%x}")" && pwd)"; then
        echo "[resolve_paths] Error: unable to resolve root path" >&2
        return 1
    fi

    # Module manager
    MODULE_MANAGER="${GACLI_PATH}/${MODULE_MANAGER_REL_PATH}"
    if [[ ! -f "${MODULE_MANAGER}" ]]; then
        echo "[resolve_paths] Error: unable to find module manager" >&2
        return 1
    fi

    # Config file
    CONFIG_FILE="${GACLI_PATH}/${CONFIG_FILE_REL_PATH}"
}

# Dispatch commands
dispatch_commands() {
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
            dispatch_modules_commands "$@"  # Implemented in gacli/modules/.core/module_manager.zsh
    esac
}

# Print all tools status
print_tools() {
    # Display Hombrew packages
    print_formulae                      # Implemented in gacli/modules/.core/brew.zsh
    print_casks                         # Implemented in gacli/modules/.core/brew.zsh

    # Display available commands
    print_commands                      # Implemented in gacli/modules/module_manager.zsh
    print ""
}

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

# Call main with all command args
main "$@"

