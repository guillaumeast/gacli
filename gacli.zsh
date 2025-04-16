###############################
# FICHIER /.run/gacli.zsh
###############################
#!/usr/bin/env zsh

# FILE DESCRIPTION:
    # GACLI main entry point
    #   - Entry script called by user via `gacli` wrapper
    #   - Detects OS, resolves paths, loads core scripts and modules
    #   - Dispatches CLI commands and displays global status/help

    # Depends on:
    #   - update.zsh        → for auto-update procedure
    #   - modules.zsh       → for modules management
    #   - brew.zsh          → for getting formulae and caks status
    #   - uninstall.zsh     → for gacli uninstall procedure

    # Used by:
    #   - gacli wrapper     → executes this file directly
    #   - install.zsh       → makes this file executable and sources it in `.zshrc`

    # Note: Relies on `BUFFER`, `FORMULAE`, `CASKS`, and other globals for runtime state.
    #       Also embeds IO helpers like `printStyled` and `style_ascii_logo` directly.
#

# Easter egg display
if [[ $1 == "" ]]; then
    print "\033[90m✧ Don't panic... 🐥\033[0m"
fi

# Env
setopt extended_glob
IS_MACOS=false
IS_LINUX=false

# Check $HOME is set
if [ -z "${HOME}" ] || [ ! -d "${HOME}" ]; then
    echo " ---> [GACLI] E1: fatal error, exiting GACLI <---" >&2
    exit "1"
fi

# Directories
ROOT_DIR="${HOME}/.gacli"
HELPERS_DIR="${ROOT_DIR}/.helpers"
CORE_DIR="${ROOT_DIR}/.run"
MODULES_DIR="${ROOT_DIR}/modules"
DIRS=("${ROOT_DIR}" "${HELPERS_DIR}" "${CORE_DIR}" "${MODULES_DIR}")

# Config files
UPDATE_CONFIG="${ROOT_DIR}/.data/config/update.config.yaml"
CORE_TOOLS="${ROOT_DIR}/.data/tools/core.tools.yaml"
MODULES_TOOLS="${ROOT_DIR}/.data/tools/modules.tools.yaml"
USER_TOOLS="${ROOT_DIR}/tools.yaml"
FILES=("${CONFIG}" "${CORE_TOOLS}" "${MODULES_TOOLS}" "${USER_TOOLS}")

# Scripts files
SCRIPTS=( \
    "${ROOT_DIR}/.helpers/time.zsh" \
    "${ROOT_DIR}/.helpers/parser.zsh" \
    "${ROOT_DIR}/.helpers/brew.zsh" \
    "${ROOT_DIR}/.run/modules.zsh" \
    "${ROOT_DIR}/.run/update.zsh" \
    "${ROOT_DIR}.auto-install/uninstall.zsh" \
)

# Buffer for cross-modules communication (kind of "stdinfo")
BUFFER=()

# Formatting
BOLD="\033[1m"
UNDERLINE="\033[4m"
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

# Main function
main() {
    # Check env compatibility and files integrity
    _gacli_check_system || abort "1"
    _gacli_check_files || abort "2"

    # Load core scripts
    local script
    for script in $SCRIPTS; do
        if ! source "${script}"; then
            printstyled error "[gacli.zsh] Unable to load required script: ${script}"
            abort "3"
        fi
    done

    # Load modules and check if update is due (date or new dependencies)
    modules_init || abort "4"           # Implemented in modules.zsh
    update_check || abort "5"           # Implemented in update.zsh
    modules_load || abort "6"           # Implemented in modules.zsh

    # Dispatch commands
    _gacli_dispatch "$@" || abort "7"
}

# ────────────────────────────────────────────────────────────────
# CORE LOGIC
# ────────────────────────────────────────────────────────────────

# PRIVATE - Detect the operating system and set the corresponding flags
_gacli_check_system() {
    if [[ -z "$OSTYPE" ]]; then
        printstyled error "[_gacli_check_system] \$OSTYPE is not set" >&2
        return 1
    fi

    case "$OSTYPE" in
        darwin*) IS_MACOS=true ;;
        linux*)  IS_LINUX=true ;;
        *)
            printstyled error "[_gacli_check_system] Unknown OS type: $OSTYPE" >&2
            return 1
            ;;
    esac

    # TODO: add emoji auto enable mode as in install.zsh (btw, reverse "text → emoji" instead of "emoji → text")
}

# PRIVATE - Resolve absolute paths, check files integrity and source scripts
_gacli_check_files() {

    # Check directories integrity
    local dir
    for dir in $DIRS; do
        mkdir -p "${MODULES_DIR}" || {
            printstyled error "[_gacli_check_files] Unable to resolve dir: ${dir}"
            return 1
        }
    done

    # Check config files integrity
    local file
    for file in $FILES; do
        [[ -f "${file}" ]] || {
            printstyled error "[_gacli_check_files] Unable to resolve file: ${dir}"
            return 1
        }
    done
}

# PRIVATE - Dispatch commands
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
            printstyled highlight "Uninstalling GACLI... ⏳"
            source "${UNINSTALLER}" && gacli_uninstall && return 0
            printstyled error "[_gacli_dispatch] Uninstall failed"
            return 1
            ;;
        *)
            modules_dispatch "$@"           # Implemented in gacli/.run/core/modules.zsh
    esac
}

# PUBLIC - Display a fatal error message and exit the script
abort() {
    echo ""
    echo "-------------------------------------------------------"
    echo " ---> [GACLI] E${1}: fatal error, exiting GACLI <---" >&2
    echo "-------------------------------------------------------"
    echo ""
    exit "${1}"
}

# ────────────────────────────────────────────────────────────────
# OUTPUTS
# ────────────────────────────────────────────────────────────────

# PUBLIC - ASCII art logo
style_ascii_logo() {
    print "${ORANGE}  _____          _____ _      _____ ${NONE}"
    print "${ORANGE} / ____|   /\\\\   / ____| |    |_   _|${NONE}"
    print "${ORANGE}| |  __   /  \\\\ | |    | |      | |  ${NONE}"
    print "${ORANGE}| | |_ | / /\\\\ \\\\| |    | |      | |  ${NONE}"
    print "${ORANGE}| |__| |/ ____ \\\\ |____| |____ _| |_ ${NONE}"
    print "${ORANGE} \\\\_____/_/    \\\\_\\\\_____|______|_____|${NONE}"
    print ""
}

# PUBLIC - Display formatted message
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
            echo "${RED}${BOLD}❌ ${raw_message}${NONE}" >&2
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

# PUBLIC - Display tools status
print_tools() {
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

# PUBLIC - Diplay tips
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

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

# Call main with all command args
main "$@"

# ────────────────────────────────────────────────────────────────
# TODO
# ────────────────────────────────────────────────────────────────

# From brew.zsh

# Print formulae status (TODO: refacto in gacli.zsh)
print_formulae() {
    local output=""

    # Compute
    for formula in $FORMULAE; do
        local icon="${ICON_OFF}"
        brew_is_f_active "${formula}" && icon="${ICON_ON}"
        output+="${icon} ${ORANGE}$formula${NONE} ${GREY}|${NONE} "
    done

    # Display (removing trailing " | ")
    print "${output% ${GREY}|${NONE} }"
}

# Print casks status (TODO: refato in gacli.zsh)
print_casks() {
    local output=""

    # Compute
    for cask in $CASKS; do
        local icon="${ICON_OFF}"
        brew_is_c_active "${cask}" && icon="${ICON_ON}"
        output+="${icon} ${CYAN}$cask${NONE} ${GREY}|${NONE} "
    done

    # Display (removing trailing " | ")
    print "${output% ${GREY}|${NONE} }"
}

# From modules.zsh

modules_dispatch() {
    # Dynamic commands (declared via get_commands in modules)
    for cmd in "${COMMANDS[@]}"; do
        local command_name="${cmd%%=*}"
        local function_name="${cmd#*=}"

        if [[ "$1" == "$command_name" ]]; then
            # Call matched function with remaining args
            "${function_name}" "${@:2}"
            return
        fi
    done

    # No command matched
    printStyled error "[GACLI] Error: unknown command '$1'" >&2
    modules_print_commands
    return 1
}

modules_print_commands() {
    local output_commands=""

    # Compute
    for cmd in "${COMMANDS[@]}"; do
        local command_name="${cmd%%=*}"
        output_commands+="${ICON_ON} ${GREEN}${command_name}${NONE} ${GREY}|${NONE} "
    done

    # Display (removing trailing " | ")
    print "${output_commands% ${GREY}|${NONE} }"
}
