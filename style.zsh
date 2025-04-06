#!/usr/bin/env zsh

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

# Custom LS_COLORS
if command -v gls >/dev/null 2>&1; then
    # Use GNU ls if available (for LS_COLORS compatibility)
    alias ls="gls --color=auto"

    # Custom colors
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
fi

# Formatted output
printStyled() {

    # Variables
    local style=$1
    local rawMessage=$2
    local finalMessage=""
    local color=$NONE

    # Argument check
    if [ -z "$style" -o -z "$rawMessage" ]; then
        printStyled error "Veuillez fournir un ${yellow}style${red} et un ${yellow}message${red} pour afficher du texte"
        return 1
    fi

    # Formatting
    if [ "$style" = "error" ]; then
        color=$RED
        rawMessage="❌ ${rawMessage:-"❌ Oups, quelque chose s'est mal passe... 😶‍🌫️"}"
        finalMessage="${RED}$rawMessage${color}"
        print "${color}${BOLD}$finalMessage${NONE}" >&2
    else
        if [ "$style" = "success" ]; then
            color=$GREEN
            rawMessage="✦ ${rawMessage:-"✦ Bravo, tout s'est bien passe ! 🎉"}"
            finalMessage="$rawMessage"
        elif [ "$style" = "warning" ]; then
            color=$YELLOW
            rawMessage="⚠️  ${rawMessage:-"⚠️  Attention, quelque chose s'est mal passe... 👀"}"
            finalMessage="${bold}$rawMessage"
        elif [ "$style" = "info" ]; then
            color=$GREY
            rawMessage="✧ ${rawMessage:-"✧ Voilà où on est est 🫡"}"
            finalMessage="${rawMessage}"
        elif [ "$style" = "highlight" ]; then
            color=$NONE
            rawMessage="👉 ${rawMessage:-"👉 Jette un oeil à ça..."}"
            finalMessage="$rawMessage"
        elif [ "$style" = "debug" ]; then
            color=$YELLOW
            rawMessage="🔦 ===> ${BOLD}${rawMessage:-"🔦 ===> Alors, ça marche ? 🤷‍♂️"}${NONE}"
            finalMessage="$rawMessage"
        fi

        # Display
        print "${color}$finalMessage${NONE}"
    fi

}
