###############################
# FICHIER /.run/helpers/brew.zsh
###############################

#!/usr/bin/env zsh

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

# Update Homebrew, formulae and casks
brew_update() {
    local brewfile="${1}"

    # Check arguments
    if [[ ! -f "${brewfile}" ]]; then
        printStyled error "[brew_update] Unable to find Brewfile: ${brewfile}"
        return 1
    fi

    # Check Homebrew install
    _brew_install || return 1

    # Check dependencies have changed
    local update_is_due
    update_is_due="$(_brew_is_update_due "${brewfile}")" || return 1

    # Update
    [[ "$update_is_due" == true ]] && _brew_bundle "${brewfile}"
}

# ────────────────────────────────────────────────────────────────
# Functions - PRIVATE
# ────────────────────────────────────────────────────────────────

# Install Homebrew
_brew_install() {

    # Check if Homebrew is already installed
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi
    printStyled info "Installing ${ORANGE}Homebrew${GREY}... ⏳"

    # Resolve install command
    local install_cmd
    if $IS_MACOS || $IS_LINUX; then
        if $IS_LINUX; then
            install_cmd="NONINTERACTIVE=1 "
        fi
        install_cmd="/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    else
        printStyled error "[brew_install] Unsupported OS: ${OSTYPE}"
        return 1
    fi

    # Execute install command
    if ! eval "$install_cmd"; then
        printStyled error "[brew_install] Homebrew installation failed"
        return 1
    fi

    # Add Homebrew to PATH
    local brew_exec_path
    if ! brew_exec_path="$(command -v brew)"; then
        printStyled error "[brew_install] Failed to detect brew after installation"
        return 1
    fi

    # Check if install is successful
    if ! eval "$("$brew_exec_path" shellenv)"; then
        printStyled error "[brew_install] Failed to set Homebrew environment"
        return 1
    fi

    # Refresh command hash table
    if ! hash -r; then
        printStyled warning "[brew_install] Failed to refresh shell hash table"
    fi
}

_brew_bundle() {
    local brewfile="${1}"

    # Loading mesage
    print ""
    printStyled "info" "Updating... (this may take a few minutes) ⏳"

    # Update Homebrew
    if ! brew update  > /dev/null 2>&1; then
        printStyled warning "[brew_update] Failed to update Homebrew"
    fi

    # Install/uninstall formulae & casks referring to the Brewfile
    if ! brew bundle --file="${brewfile}" 1>/dev/null; then
        printStyled error "[brew_update] Failed to run bundle Homebrew"
        return 1
    fi

    # Upgrade
    if ! brew upgrade 1>/dev/null; then
        printStyled error "[brew_update] Failed to upgrade Homebrew packages"
        return 1
    fi

    # Cleanup
    if ! brew cleanup 1>/dev/null; then
        printStyled warning "[brew_update] Failed to cleanup Homebrew packages"
    fi
}

# Checks if update is due
_brew_is_update_due() {
    local brewfile="${1}"
    local update_is_due=false

    # Check if formulae need update
    read "${INSTALLED_FILE}" formulae || return 1
    local installed_f=("${BUFFER[@]}")
    read "${brewfile}" formulae || return 1
    local required_f=("${BUFFER[@]}")
    for formula in $required_f; do
        if ! [[ " ${installed_f[*]} " == *" ${formula} "* ]]; then
            update_is_due=true
        fi
    done

    # Check casks need update
    read "${INSTALLED_FILE}" casks || return 1
    local installed_c=("${BUFFER[@]}")
    read "${brewfile}" casks || return 1
    local required_c=("${BUFFER[@]}")
    for cask in $required_c; do
        if ! [[ " ${installed_c[*]} " == *" ${cask} "* ]]; then
            update_is_due=true
        fi
    done

    echo $update_is_due
}

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC
# ────────────────────────────────────────────────────────────────

brew_is_f_installed() {
    local formula="${1}"
    [[ "$formula" = "coreutils" ]] && formula="gdate"

    if command -v $formula >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

brew_is_c_installed() {
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

# Print formulae status
print_formulae() {
    local output=""

    # Compute
    read "${INSTALLED_FILE}" formulae || return 1
    local installed=("${BUFFER[@]}")

    for formula in $installed; do
        local icon="${ICON_OFF}"
        _brew_is_f_installed "${formula}" && icon="${ICON_ON}"
        output+="${icon} ${ORANGE}$formula${NONE} ${GREY}|${NONE} "
    done

    # Display (removing trailing " | ")
    print "${output% ${GREY}|${NONE} }"
}

# Print casks status
print_casks() {
    local output=""

    # Compute
    read "${INSTALLED_FILE}" casks || return 1
    local installed=("${BUFFER[@]}")

    # Compute
    for cask in $installed; do
        local icon="${ICON_OFF}"
        brew_is_c_installed "${cask}" && icon="${ICON_ON}"
        output+="${icon} ${CYAN}$cask${NONE} ${GREY}|${NONE} "
    done

    # Display (removing trailing " | ")
    print "${output% ${GREY}|${NONE} }"
}

# ────────────────────────────────────────────────────────────────
# WIP: DEBUG
# ────────────────────────────────────────────────────────────────

printStyled debug "--> 2. brew.zsh loaded"

