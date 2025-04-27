#!/usr/bin/env zsh
###############################
# FICHIER /src/helpers/brew.zsh
###############################

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# PUBLIC - Run Homebrew update, bundle, upgrade and cleanup
brew_bundle() {
    local brewfile="${1}"

    # Install Homebrew if missing
    _brew_install || {
        printStyled error "Missing required dependencie: Homebrew"
        return 1
    }

    # Loading mesage
    print ""
    printStyled "info" "Updating... (this may take a few minutes) ⏳"

    # Update Homebrew
    if ! brew update  > /dev/null 2>&1; then
        printStyled warning "Failed to update Homebrew"
    fi

    # Install/uninstall formulae & casks referring to the Brewfile
    if ! brew bundle --file="${brewfile}" 1>/dev/null; then
        printStyled error "Failed to run bundle Homebrew"
        return 1
    fi

    # Upgrade
    if ! brew upgrade 1>/dev/null; then
        printStyled error "Failed to upgrade Homebrew packages"
        return 1
    fi

    # Cleanup
    if ! brew cleanup 1>/dev/null; then
        printStyled warning "Failed to cleanup Homebrew packages"
    fi
}

# PUBLIC - Check if given formula is active
brew_is_f_active() {

    # Install Homebrew if missing
    _brew_install || {
        printStyled error "Missing required dependencie: Homebrew"
        return 1
    }

    local formula="${1}"
    [[ "$formula" = "coreutils" ]] && formula="gdate"

    command -v $formula >/dev/null 2>&1 || return 1
}

# PUBLIC - Check if given cask is active
brew_is_c_active() {
    local cask="${1}"

    # Install Homebrew if missing
    _brew_install || {
        printStyled error "Missing required dependencie: Homebrew"
        return 1
    }

    # "my-cask-name" → "My Cask Name.app"
    local app_name="$(echo "$cask" | sed -E 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1').app"

    # Check .app folders first for speed, fallback to brew if missing
    [[ -d "/Applications/$app_name" || -d "$HOME/Applications/$app_name" ]] && return 0
    brew list --cask "$cask" >/dev/null 2>&1 || return 1
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

# PRIVATE - Install Homebrew
_brew_install() {

    # Check if Homebrew is already installed
    if command -v brew > /dev/null 2>&1; then
        return 0
    fi
    printStyled info "Installing ${ORANGE}Homebrew${GREY}... ⏳"

    # Resolve install command
    local install_cmd="/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    if $IS_MACOS || $IS_LINUX; then
        if $IS_LINUX; then
            install_cmd="NONINTERACTIVE=1 ${install_cmd}"
        fi
    else
        printStyled error "Unsupported OS: ${OSTYPE}"
        return 1
    fi

    # Execute install command
    if ! eval "$install_cmd"; then
        printStyled error "Homebrew installation failed"
        return 1
    fi

    # Add Homebrew to PATH
    local brew_exec_path
    if ! brew_exec_path="$(command -v brew)"; then
        printStyled error "Failed to detect brew after installation"
        return 1
    fi

    # Check if install is successful
    if ! eval "$("$brew_exec_path" shellenv)"; then
        printStyled error "Failed to set Homebrew environment"
        return 1
    fi

    # Refresh command hash table
    if ! hash -r; then
        printStyled warning "Failed to refresh shell hash table"
    fi
}

