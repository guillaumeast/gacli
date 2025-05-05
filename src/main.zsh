#!/usr/bin/env zsh
###############################
# FICHIER /src/main.zsh
###############################

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
    echo " ---> Error: \$HOME is not set → exiting GACLI <---" >&2
    exit "1"
fi

# Directories
DIR_ROOT="${HOME}/.gacli"   # Add to .zshrc ? (and rename DIR_GACLI ?)
DIR_DATA="${DIR_ROOT}/data"
DIR_CONFIG="${DIR_DATA}/config"
DIR_TOOLS="${DIR_DATA}/tools"
DIR_HELPERS="${DIR_ROOT}/helpers"
DIR_LOGIC="${DIR_ROOT}/logic"
DIR_MODS="${DIR_ROOT}/modules"
DIR_TMP="${DIR_ROOT}/.tmp"
DIRS=("${DIR_ROOT}" "${DIR_DATA}" "${DIR_CONFIG}" "${DIR_TOOLS}" "${DIR_HELPERS}" "${DIR_LOGIC}" "${DIR_MODS}" "${DIR_TMP}")

# Config files
FILE_CONFIG_UPDATE="${DIR_CONFIG}/update.config.json"
FILES_CONFIG=("${FILE_CONFIG_UPDATE}")

# Tools files
FILE_TOOLS_CORE="${DIR_TOOLS}/core.tools.json"
FILE_TOOLS_MODULES="${DIR_TOOLS}/modules.tools.json"
FILE_TOOLS_USER="${DIR_TOOLS}/user.tools.json"
FILES_TOOLS=("${FILE_TOOLS_CORE}" "${FILE_TOOLS_MODULES}" "${FILE_TOOLS_USER}")

# Scripts files
SCRIPTS=( \
    "${DIR_ROOT}/helpers/time.zsh" \
    "${DIR_ROOT}/helpers/parser.zsh" \
    "${DIR_ROOT}/helpers/brew.zsh" \
    "${DIR_ROOT}/logic/update.zsh" \
    "${DIR_ROOT}/logic/modules.zsh" \
    "${DIR_ROOT}/logic/uninstall.zsh" \
)

# Available commands
COMMANDS_CORE=("help=help" "config=update_edit_config" "update=update_manual" "uninstall=gacli_uninstall")
COMMANDS_MODS=()

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
COLOR_FORMULAE="${BLUE}"
COLOR_CASKS="${CYAN}"
COLOR_MODS="${PURPLE}"
COLOR_COMMANDS="${ORANGE}"

# Emojis
EMOJI_SUCCESS="✓"
EMOJI_WARN="⚠️"
EMOJI_ERR="🛑"
EMOJI_INFO="✧"
EMOJI_HIGHLIGHT="👉"
EMOJI_DEBUG="🔎"
EMOJI_WAIT="⏳"
ICON_ON="⊙"
ICON_OFF="○"

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

# Main function
main() {

    # Check gacli install
    if ! command -v gacli > /dev/null 2>&1; then
        printui error "gacli command not found"
        printui highlight "Try to restart your terminal or run: exec zsh"
        return 1
    fi

    # Check env compatibility and files integrity
    _gacli_check_system || abort "1" || return 1
    _gacli_check_files || abort "2" || return 1

    # Load core scripts
    local script
    for script in "${SCRIPTS[@]}"; do
        if ! source "${script}"; then
            printui error "Unable to load required script: ${script}"
            abort "3" || return 1
        fi
    done

    # Load modules and check if update is due (date or new dependencies)
    modules_init || abort "4" || return 1           # Implemented in modules.zsh
    update_init  || abort "5" || return 1           # Implemented in update.zsh
    modules_load || abort "6" || return 1           # Implemented in modules.zsh

    # Dispatch commands
    _gacli_dispatch "$@" || abort "7" || return 1
}

# ────────────────────────────────────────────────────────────────
# CORE LOGIC
# ────────────────────────────────────────────────────────────────

# PRIVATE - Detect the operating system and set the corresponding flags
# TODO: delete (useless to recreate an existing env variable)
_gacli_check_system() {
    if [[ -z "$OSTYPE" ]]; then
        printui error "\$OSTYPE is not set" >&2
        return 1
    fi

    case "$OSTYPE" in
        darwin*) IS_MACOS=true ;;
        linux*)  IS_LINUX=true ;;
        *)
            printui error "Unknown OS type: $OSTYPE" >&2
            return 1
            ;;
    esac
}

# PRIVATE - Check files integrity
_gacli_check_files() {
    local dir file
    local files=("${FILES_CONFIG[@]}" "${FILES_TOOLS[@]}")

    # Check directories integrity
    for dir in "${DIRS[@]}"; do
        mkdir -p "${dir}" || {
            printui error "Unable to resolve dir: ${dir}"
            return 1
        }
    done

    # Check files integrity
    for file in "${files[@]}"; do
        touch "${file}" || {
            printui error "Unable to resolve file: ${file}"
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
            echo ""
            ;;
        *)
            # Dynamic commands (declared via get_commands in modules)
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

            # No command matched
            printui error "Unknown command '$1'" >&2
            modules_print_commands
            return 1
            ;;
    esac
}

# PUBLIC - Display a fatal error message and exit the script
abort() {
    echo ""
    echo "-------------------------------------------------------"
    echo " ---> [GACLI] E${1}: fatal error, exiting GACLI <---" >&2
    echo "-------------------------------------------------------"
    echo ""
    return 1
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
printui() {
    # Variables
    local style=$1
    local raw_message=$2
    local final_message=""
    local color=$NONE

    # Argument check
    if [[ -z "$style" || -z "$raw_message" ]]; then
        echo "❌ [printui] Expected: <style> <message>"
        return 1
    fi

    # Formatting
    case "$style" in
        error)
            echo
            echo "${EMOJI_ERR} [${RED}Error${GREY}: ${funcstack[2]}${GREY}] → ${BOLD}${RED}${raw_message}${NONE}" >&2
            echo
            return
            ;;
        warning)
            print "${EMOJI_WARN} [${ORANGE}Warning${GREY}: ${funcstack[2]}${GREY}] → ${BOLD}${ORANGE}${raw_message}${NONE}" >&2
            return
            ;;
        success)
            color=$GREEN
            final_message="${EMOJI_SUCCESS} ${raw_message}"
            ;;
        info)
            color=$GREY
            final_message="${EMOJI_INFO} ${raw_message}"
            ;;
        highlight)
            color=$NONE
            final_message="${EMOJI_HIGHLIGHT} ${raw_message}"
            ;;
        debug)
            color=$YELLOW
            final_message="${EMOJI_DEBUG} ${GREY}${funcstack[4]}${GREY} → ${GREY}${funcstack[3]}${GREY} → ${YELLOW}${funcstack[2]}${GREY}\n    ${YELLOW}└→ ${BOLD}${raw_message}${NONE}"
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

