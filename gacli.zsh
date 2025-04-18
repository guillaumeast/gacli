#!/usr/bin/env zsh
###############################
# FICHIER /.run/gacli.zsh
###############################

# [GACLI CLI entry point]
   #   - Loads core scripts and modules
   #   - Checks system compatibility and file integrity
   #   - Enables auto-update mechanism
   #   - Dispatches commands from CLI

   # Depends on:
   #   - update.zsh         → handles auto-update and dependency merge
   #   - modules.zsh        → loads external modules and tools
   #   - brew.zsh           → checks Homebrew tools status
   #   - uninstall.zsh      → provides uninstall logic

   # Used by:
   #   - install.zsh        → sets executable and sources it in shell
   #   - wrapper (gacli)    → executes this script directly

   # Note: Holds the `main` dispatcher and core system setup logic
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

# Scripts files
SCRIPTS=( \
    "${ROOT_DIR}/.helpers/time.zsh" \
    "${ROOT_DIR}/.helpers/parser.zsh" \
    "${ROOT_DIR}/.helpers/brew.zsh" \
    "${ROOT_DIR}/.run/modules.zsh" \
    "${ROOT_DIR}/.run/update.zsh" \
    "${ROOT_DIR}.auto-install/uninstall.zsh" \
)

# Available commands
COMMANDS_CORE=("help=help" "config=update_edit_config" "update=update_manual" "uninstall=gacli_uninstall")
COMMANDS_MODS=()

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

# Emojis
EMOJI_SUCCESS="✦"
EMOJI_WARN="⚠️"
EMOJI_ERR="❌"
EMOJI_INFO="✧"
EMOJI_HIGHLIGHT="👉"
EMOJI_DEBUG="🔎"
EMOJI_WAIT="⏳"
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
    update_check || abort "4"           # Implemented in update.zsh
    modules_load || abort "5"           # Implemented in modules.zsh

    # Dispatch commands
    _gacli_dispatch "$@" || abort "6"
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
            style_ascii_logo
            print_formulae
            print_casks
            print_modules
            print_core_commands
            print_mods_commands
            print ""
            ;;
        *)
            # Dynamic commands (declared via get_commands in modules)
            for cmd in "${COMMANDS_MODS[@]}"; do
                local command_name="${cmd%%=*}"
                local function_name="${cmd#*=}"

                if [[ "$1" == "$command_name" ]]; then
                    # Call matched function with remaining args
                    "${function_name}" "${@:2}"
                    return "$?"
                fi
            done

            # No command matched
            printStyled error "[GACLI] Error: unknown command '$1'" >&2
            modules_print_commands
            return 1
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

# PUBLIC - Diplay tips
help() {
    print ""
    printStyled highlight "Formulaes: (more info: https://formulae.brew.sh/formula)"
    print_formulae

    print ""
    printStyled highlight "Casks: (more info: https://formulae.brew.sh/cask/)"
    print_casks

    print ""
    printStyled highlight "Modules: (more info: https://github.com/guillaumeast/gacli)"
    print_modules

    print ""
    printStyled highlight "Core commands: (more info: https://github.com/guillaumeast/gacli)"
    print_core_commands

    print ""
    printStyled highlight "Modules commands: (more info: https://github.com/guillaumeast/gacli)"
    print_mods_commands
    print ""
}

# PUBLIC - Print installed status for all formulae defined in tools descriptors
print_formulae() {
    local tmp_brewfile=$(mktemp)
    local icon, formula, output

    # Get merged casks
    update_merge_into "${tmp_brewfile}" || {
        rm -f "${tmp_brewfile}"
        return 1
    }
    parser_read "${tmp_brewfile}" formulae || {
        rm -f "${tmp_brewfile}"
        return 1
    }

    # Compute
    for formula in "${BUFFER[@]}"; do
        icon="${ICON_OFF}"
        brew_is_f_active "${formula}" && icon="${ICON_ON}"
        output+="${icon} ${ORANGE}$formula${GREY}|${NONE} "
    done

    # Display (removing trailing " | ")
    print "${output% ${GREY}|${NONE} }"

    # Delete temporary Brewfile
    rm -f "${tmp_brewfile}"
}

# PUBLIC - Print installed status for all casks defined in tools descriptors
print_casks() {
    local tmp_brewfile=$(mktemp)
    local icon, cask, output

    # Get merged casks
    update_merge_into "${tmp_brewfile}" || {
        rm -f "${tmp_brewfile}"
        return 1
    }
    parser_read "${tmp_brewfile}" casks || {
        rm -f "${tmp_brewfile}"
        return 1
    }

    # Compute
    for cask in "${BUFFER[@]}"; do
        icon="${ICON_OFF}"
        brew_is_c_active "${cask}" && icon="${ICON_ON}"
        output+="${icon} ${CYAN}$cask${GREY}|${NONE} "
    done

    # Display (removing trailing " | ")
    print "${output% ${GREY}|${NONE} }"

    # Delete temporary Brewfile
    rm -f "${tmp_brewfile}"
}

# PUBLIC - Print installed status for all installed modules
print_modules() {
    local output=""
    local icon

    for module in $MODULES_INSTALLED; do
        icon="${ICON_OFF}"
        [[ " $MODULES_ACTIV " == *" $module "* ]] && icon="${ICON_ON}"
        output+="${icon} ${GREEN}${module}${NONE} ${GREY}|${NONE} "
    done
    print "${output% ${GREY}|${NONE} }"
}

# PUBLIC - Print available built-in GACLI core commands
print_core_commands() {
    local output

    for cmd in $COMMANDS_CORE; do
        local command_name="${cmd%%=*}"
        output+="${ICON_ON} ${RED}${command_name} ${GREY}|${NONE} "
    done
    print "${output% ${GREY}|${NONE} }"
}

# PUBLIC - Print available commands provided by loaded modules
print_mods_commands() {
    local output

    for cmd in $COMMANDS_MODS; do
        local command_name="${cmd%%=*}"
        output+="${ICON_ON} ${GREEN}${command_name} ${GREY}|${NONE} "
    done
    print "${output% ${GREY}|${NONE} }"
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

# Call main with all command args
main "$@"

