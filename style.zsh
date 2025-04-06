#!/usr/bin/env zsh

# Couleurs LS personnalisées
    # (scripts) jaune 33
    # (codes) vert clair 92
    # (exécutables autres que codes et scripts) vert 32
    # (fichiers) cyan 36
    # (dossiers) bleu 34
    # (archives) magenta 35
    # (liens symboliques) gris 90

export LS_COLORS="di=34:fi=36:ln=90:ex=32:\
*.sh=33:*.bsh=33:*.bash=33:*.zsh=33:*.ps1=33:\
*.java=92:*.js=92:*.ts=92:*.jsx=92:*.tsx=92:*.c=92:*.cpp=92:*.h=92:*.hpp=92:*.cxx=92:\
*.py=92:*.rb=92:*.rs=92:*.go=92:*.php=92:*.swift=92:*.kt=92:*.dart=92:*.lua=92:*.pl=92:*.r=92:*.sql=92:\
*.html=92:*.css=92:*.scss=92:*.sass=92:*.json=92:*.xml=92:*.yaml=92:*.yml=92:\
*.tar=35:*.tgz=35:*.gz=35:*.zip=35"

# Formattage (TODO : Mettre en majuscules)
BOLD="\e[1m"
UNDERLINE="\e[4m"

# Couleurs (TODO : Mettre en majuscules)
BLACK='\e[30m'
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
PURPLE='\e[35m'
CYAN='\e[36m'
ORANGE='\e[38;5;208m'
GREY='\e[90m'
NONE='\e[0m'

# Icons (on / off)
ICON_ON="${GREEN}⊙${NONE}"
ICON_OFF="${RED}○${NONE}"

# TODO : Ajouter "style" aux datas / Typeset {"StyleName": "color"}
# ===> Plus facilement modifier la couleur des messages sans changer les couleurs dans le message fourni par la fonction appelante

# -----------------------------------------------
# Function: printStyled(style: string, text: string) => print formattedString
# Description: Affiche le texte formatté en fonction du style fourni
# -----------------------------------------------
printStyled() {

    # Variables
    local style=$1
    local rawMessage=$2
    local finalMessage=""
    local color=$NONE

    # Vérification des arguments
    if [ -z "$style" -o -z "$rawMessage" ]; then
        printStyled error "Veuillez fournir un ${yellow}style${red} et un ${yellow}message${red} pour afficher du texte"
        return 1
    fi

    # Mise en forme
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
        # Affichage
        print "${color}$finalMessage${NONE}"
    fi

}
