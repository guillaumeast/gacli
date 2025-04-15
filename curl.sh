###############################
# FICHIER /<TODO>/curl.sh
###############################

#!/usr/bin/sh

# Try to download files from **ANY** Linux/macOS vanilla system

# Target archive.tar.gz
TARGET="https://github.com/guillaumeast/gacli/archive/refs/heads/dev.tar.gz"

# Array of commands to test
# Format: "<check_command>|<install_command>|<download_command>"    # Why we should use this tool
# <check_command> is used to check if this tool is installed
# <install_command> is used to download this tool files
# <download_command> is used to download any other files via this tool
COMMANDS=( \
    "<TODO>|apt-get install curl|<TODO>"            # curl (basic on macOS)
    "wget --version|<TODO>|"                        # wget (basic on Ubuntu)
    "<TODO>|<TODO>|<TODO>"                          # git (basic on both)
    # TODO: A lot more options !
)

# ────────────────────────────────────────────────────────────────
# TODO
# ────────────────────────────────────────────────────────────────

test_curl() {

    # TODO: Check if already installed
    # TODO: try to install
    # TODO: if installed => try to download TARGET
}

test_wget() {

    # TODO: Check if already installed
    # TODO: try to install
    # TODO: if installed => try to download TARGET
}

test_git() {

    # TODO: Check if already installed
    # TODO: try to install
    # TODO: if installed => try to download TARGET
}

# ────────────────────────────────────────────────────────────────
# GPT
# ────────────────────────────────────────────────────────────────

# Télécharge l’archive ZIP de la branche main du dépôt
curl -L -o repo.zip https://github.com/<utilisateur>/<repo>/archive/main.zip  
# (Ou utiliser wget à la place de curl)

# Télécharge l’archive ZIP de la branche main du dépôt
curl -L -o repo.zip https://github.com/<utilisateur>/<repo>/archive/main.zip  
# (Ou utiliser wget à la place de curl)

git clone https://github.com/<utilisateur>/<repo>.git

# ────────────────────────────────────────────────────────────────
# IF NEEDED
# ────────────────────────────────────────────────────────────────

# aria2 (gestionnaire de téléchargement avancé)
# rsync (synchronisation distante)
# Navigateurs en ligne de commande (lynx, w3m, links)
