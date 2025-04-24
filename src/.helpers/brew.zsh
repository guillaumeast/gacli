#!/usr/bin/env zsh
###############################
# FICHIER /.helpers/brew.zsh
###############################

# [Homebrew tools manager]
   #   - Checks if formulae and casks are active
   #   - Runs brew bundle if needed
   #   - Installs and configures Homebrew

   # Depends on:
   #   - parser.zsh         → reads Brewfile content
   #   - gacli.zsh          → for styled outputs

   # Used by:
   #   - update.zsh         → updates dependencies from merged Brewfile
   #   - modules.zsh        → installs tools required by modules

   # Note: Triggers update only if missing tools are detected
#

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# Run Homebrew bundle if at least one formula or cask from given Brewfile is not yet active
brew_bundle() {
    local brewfile="${1}"

    _brew_is_update_due "${1}" || return 0

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

# Check if given formula is active
brew_is_f_active() {
    local formula="${1}"
    [[ "$formula" = "coreutils" ]] && formula="gdate"

    if command -v $formula >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Check if given cask is active
brew_is_c_active() {
    local cask="${1}"

    # "my-cask-name" → "My Cask Name.app"
    local app_name="$(echo "$cask" | sed -E 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1').app"

    # Check .app folders first for speed, fallback to brew if missing
    if [[ -d "/Applications/$app_name" || -d "$HOME/Applications/$app_name" ]]; then
        return 0
    elif brew list --cask "$cask" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

# Install Homebrew
_brew_install() {

    # Check if Homebrew is already installed
    if command -v brew >/dev/null 2>&1; then
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

# Check if at least one formula or cask from given Brewfile is not active
_brew_is_update_due() {
    local brewfile="${1}"
    local formulae=()
    local casks=()

    # Arg check
    [[ -f "${brewfile}" ]] || {
        printStyled error "Expected: <brewfile> (received: ${brewfile})"
        return 1
    }

    # Get formulae from $brewfile
    formulae+=("${(@f)$(file_read "${brewfile}" "formulae")}") || {
        printStyled error "Unable to read Brewfile: ${brewfile}"
        return 1
    }

    # Check each formula status
    for formula in "${formulae[@]}"; do
        brew_is_f_active "${formula}" || return 0
    done

    # Get casks from $brewfile
    casks+=("${(@f)$(file_read "${brewfile}" "casks")}") || {
        printStyled error "Unable to read Brewfile: ${brewfile}"
        return 1
    }

    # Check each cask status
    for cask in "${casks[@]}"; do
        brew_is_c_active "${cask}" || return 0
    done
}

