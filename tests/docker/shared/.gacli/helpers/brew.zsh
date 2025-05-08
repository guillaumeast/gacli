#!/usr/bin/env zsh
###############################
# FICHIER /src/helpers/brew.zsh
###############################

BREW_DEPS=("brew" "sed" "awk")

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# brew_bundle <path:Brewfile>
brew_bundle() {
    
    local brewfile="${1}"

    print ""
    printui "wait" "Updating..."

    if ! brew update  > /dev/null 2>&1; then
        printui warning "Failed to update Homebrew"
    fi

    if ! brew bundle --file="${brewfile}" >/dev/null; then
        printui error "Failed to run bundle Homebrew"
        return 1
    fi

    if ! brew upgrade 1>/dev/null; then
        printui error "Failed to upgrade Homebrew packages"
        return 1
    fi

    if ! brew cleanup 1>/dev/null; then
        printui warning "Failed to cleanup Homebrew packages"
    fi
}

# brew_is_f_active <str:formula>
brew_is_f_active() {

    local formula="${1}"

    [[ "$formula" = "coreutils" ]] && formula="gdate"

    command -v $formula >/dev/null 2>&1 || return 1
}

# brew_is_c_active <str:cask>
brew_is_c_active() {

    local cask="${1}"

    # "my-cask-name" → "My Cask Name.app"
    local app_name="$(echo "$cask" | sed -E 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1').app"

    # Check .app folders first for speed, fallback to brew if missing
    [[ -d "/Applications/$app_name" || -d "$HOME/Applications/$app_name" ]] && return 0
    brew list --cask "$cask" >/dev/null 2>&1 || return 1
}

