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

# Root
ROOT_DIR=".gacli"

# Scripts
FILE_HELPER=".run/helpers/files.zsh"
SCRIPTS=("files.zsh" "parser.zsh" "time.zsh" "brew.zsh" "update.zsh" "modules.zsh")
UNINSTALLER=".auto-install/uninstall.zsh"
# [OÙ ?] → files.zsh → Je peux manipuler l'"espace" !
# [QUAND ?] → time.zsh → Je peux manipuler le "temps" !
# [COMMENT ?] → parser.zsh → Je peux "lire" et "écrire" !
# [A QUEL SUJET ?] → brew.zsh → Je peux "apprendre" !
#   ---
# [DANS QUEL ETAT ?] → update.zsh → Je peux me "soigner" !
# [QUOI FAIRE ?] → modules.zsh → Je peux tout "faire" !

# Dependencies
MODULES=()
CASKS=()
FORMULAE=()

# Buffer for cross-modules communication (kind of "stdinfo")
BUFFER=()

# Formatting
BOLD="\033[1m"
UNDERLINE="\033[4m"

# Colors
BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
CYAN='\033[36m'
ORANGE='\033[38;5;208m'
GREY='\033[90m'
NONE='\033[0m'

# Icons (on / off)
ICON_ON="${GREEN}⊙${NONE}"
ICON_OFF="${RED}○${NONE}"

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

# TODO: add emoji auto enable mode as in install.zsh (btw, reverse "text → emoji" instead of "emoji → text")

# Main function
main() {
    # Check env
    _gacli_check_os || abort "1"
    _gacli_resolve || abort "2"

    # Load core files
    local script
    for script in $SCRIPTS; do
        if ! source "${script}"; then
            echo "[gacli.zsh] Error: Unable to find required file: ${script}"
            abort "3"
        fi
    done

    # Load modules
    # TODO: implement modules_init and modules_load in modules.zsh
    modules_init || abort "4"           # Implemented in modules.zsh
    update_init || abort "5"            # Implemented in update.zsh
    modules_load || abort "6"           # Implemented in modules.zsh

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

# Resolve absolute path to the gacli directory
_gacli_resolve() {

    # Root dir
    if [ -z "${HOME}" ] || [ ! -d "${HOME}" ]; then
        echo "[_gacli_resolve] Error: \$HOME is not set or invalid"
        return 1
    fi
    ROOT_DIR="${HOME}/${ROOT_DIR}" || {
        echo "[_gacli_resolve] Error: Unable to solve root dir path: '${HOME}/${ROOT_DIR}'"
        return 1
    }

    # Core scripts
    FILE_HELPER="${ROOT_DIR}/${FILE_HELPER}" || {
        echo "[_gacli_resolve] Error: Unable to solve required dependencie: '${HOME}/${FILE_HELPER}'"
        return 1
    }
    source "${FILE_HELPER}" || {
        echo "[_gacli_resolve] Error: Unable to load required dependencie: '${FILE_HELPER}'"
        return 1
    }

    # Uninstaller
    UNINSTALLER="${ROOT_DIR}/${UNINSTALLER}" || {
        echo "[_gacli_resolve] Error: Unable to solve required dependencie: '${HOME}/${UNINSTALLER}'"
        return 1
    }
    source "${UNINSTALLER}" || {
        echo "[_gacli_resolve] Error: Unable to load required dependencie: '${UNINSTALLER}'"
        return 1
    }
}

# Dispatch commands
_gacli_dispatch() {
    case "$1" in
        "")
            printStyled debug "case \"\": ${1}"
            style_ascii_logo                # Implemented in gacli/.run/helpers/io.zsh
            printStyled debug "---> after style_ascii_logo"
            print_tools
            printStyled debug "---> after print_tools"
            ;;
        "help")
            printStyled debug "case \"help\": ${1}"
            help
            ;;
        "config")
            printStyled debug "case \"config\": ${1}"
            update_edit_config              # Implemented in gacli/.run/core/update.zsh
            ;;
        "update")
            printStyled debug "case \"update\": ${1}"
            update_manual                   # Implemented in gacli/.run/core/update.zsh
            ;;
        "uninstall")
            printstyled highlight "Uninstalling GACLI... ⏳"
            source "${UNINSTALLER}" && gacli_uninstall && return 0
            printstyled error "[_gacli_dispatch] Uninstall failed"
            return 1
            ;;
        *)
            printStyled debug "case \"*\": ${1}"
            modules_dispatch "$@"           # Implemented in gacli/.run/core/modules.zsh
    esac
    printStyled debug "DISPATCH ended"
    printStyled debug "---------------------"
}

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

# ASCII art logo
style_ascii_logo() {
    print "${ORANGE}  _____          _____ _      _____ ${NONE}"
    print "${ORANGE} / ____|   /\\\\   / ____| |    |_   _|${NONE}"
    print "${ORANGE}| |  __   /  \\\\ | |    | |      | |  ${NONE}"
    print "${ORANGE}| | |_ | / /\\\\ \\\\| |    | |      | |  ${NONE}"
    print "${ORANGE}| |__| |/ ____ \\\\ |____| |____ _| |_ ${NONE}"
    print "${ORANGE} \\\\_____/_/    \\\\_\\\\_____|______|_____|${NONE}"
    print ""
}

# Display formatted message
printStyled() {
    # Variables
    local style=$1
    local raw_message=$2
    local final_message=""
    local color=$NONE

    # Argument check
    if [[ -z "$style" || -z "$raw_message" ]]; then
        echo "❌ [printStyled] Expected: <style> <message>"
        return 1
    fi

    # Formatting
    case "$style" in
        error)
            print "${RED}${BOLD}❌ ${raw_message}${NONE}" >&2
            return
            ;;
        warning)
            print "${YELLOW}${BOLD}⚠️  ${raw_message}${NONE}" >&2
            return
            ;;
        success)
            color=$GREEN
            final_message="✦ ${raw_message}"
            ;;
        info)
            color=$GREY
            final_message="✧ ${raw_message}"
            ;;
        highlight)
            color=$NONE
            final_message="👉 ${raw_message}"
            ;;
        debug)
            color=$YELLOW
            final_message="🔦 ${BOLD}${raw_message}${NONE}"
            ;;
        *)
            color=$NONE
            final_message="${raw_message}"
            ;;
    esac

    # Display
    print "${color}$final_message${NONE}"
}

# Display tools status
print_tools() {
    printStyled debug "[print_tools] Starting..."
    local formulae=()
    local casks=()
    local modules=()
    local commands=()

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

echo ""
echo "-------------------------"
echo "🔦   [GACLI ENDED]"     🎉
echo "-------------------------"
echo ""

