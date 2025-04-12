###############################
# FICHIER io.zsh
###############################

#!/usr/bin/env zsh

# Custom ls colors
    # (scripts) yellow 33
    # (code files) light green 92
    # (executables other than code/scripts) green 32
    # (files) cyan 36
    # (directories) blue 34
    # (archives) magenta 35
    # (symbolic links) grey 90
export LS_COLORS="di=34:fi=36:ln=90:ex=32:\
*.sh=33:*.bsh=33:*.bash=33:*.zsh=33:*.ps1=33:\
*.java=92:*.js=92:*.ts=92:*.jsx=92:*.tsx=92:*.c=92:*.cpp=92:*.h=92:*.hpp=92:*.cxx=92:\
*.py=92:*.rb=92:*.rs=92:*.go=92:*.php=92:*.swift=92:*.kt=92:*.dart=92:*.lua=92:*.pl=92:*.r=92:*.sql=92:\
*.html=92:*.css=92:*.scss=92:*.sass=92:*.json=92:*.xml=92:*.yaml=92:*.yml=92:\
*.tar=35:*.tgz=35:*.gz=35:*.zip=35"

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

# Formatted output
printStyled() {
    # Variables
    local style=$1
    local raw_message=$2
    local final_message=""
    local color=$NONE

    # Argument check
    if [[ -z "$style" || -z "$raw_message" ]]; then
        printStyled error "Veuillez fournir un ${YELLOW}style${RED} et un ${YELLOW}message${RED} pour afficher du texte"
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
            final_message="🔦 ===> ${BOLD}${raw_message}${NONE}"
            ;;
        *)
            color=$NONE
            final_message="${raw_message}"
            ;;
    esac

    # Display
    print "${color}$final_message${NONE}"
}

# Use gls for custom LS_COLORS compatibility (triggered by init_modules in module_manager.zsh)
use_gls() {
    if command -v gls >/dev/null 2>&1; then
        alias ls="gls --color=auto"
    else
        echo "[GACLI] Missing depedencie: gls (from coreutils)"
        echo "→ custom colors may not work"
        return 1
    fi
}

