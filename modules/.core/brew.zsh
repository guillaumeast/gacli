###############################
# FICHIER brew.zsh
###############################

#!/usr/bin/env zsh

# Variables
BREWFILE_REL_PATH="Brewfile"
BREWFILE=""
FORMULAE=()
CASKS=()

# Install Homebrew if needed and check if Brewfile exists
brew_init() {
    # Resolve Brewfile path
    brew_resolve || return 1

    # Install Homebrew if needed
    if ! command -v brew >/dev/null 2>&1; then
        brew_install || return 1
        brew_update || return 1
    fi

    # Load Brewfile content
    load_brewfile || return 1
}

# Resolve paths
brew_resolve() {
    # Resolve Brewfile path
    BREWFILE="${GACLI_PATH}/${BREWFILE_REL_PATH}"

    # Check if Brewfile exists
    if [[ ! -f "$BREWFILE" ]]; then
        printStyled error "Brewfile not found at: ${BREWFILE}"
        return 1
    fi
}

# Install Homebrew
brew_install() {
    printStyled info "Installing ${ORANGE}Homebrew${GREY}... ⏳"

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

    if ! eval "$("$brew_exec_path" shellenv)"; then
        printStyled error "[brew_install] Failed to set Homebrew environment"
        return 1
    fi

    if ! hash -r; then
        printStyled warning "[brew_install] Failed to refresh shell hash table"
    fi
}

# Update Homebrew, formulae and casks
brew_update() {
    # Loading mesage
    print ""
    printStyled "info" "Updating... (this may take a few minutes) ⏳"

    # Update Homebrew
    if ! brew update  > /dev/null 2>&1; then
        printStyled warning "[brew_update] Failed to update Homebrew"
    fi

    # Install/uninstall formulae & casks referring to the Brewfile
    if ! brew bundle --file="${BREWFILE}" 1>/dev/null; then
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

# Load formulae and casks lists from Brewfile
load_brewfile() {
    # Load formulae
    if ! FORMULAE=($(grep '^brew "' "$BREWFILE" | cut -d'"' -f2 2>/dev/null)); then
        printStyled warning "[load_brewfile] Failed to extract formulae from Brewfile"
        FORMULAE=()
    fi

    # Load casks
    if ! CASKS=($(grep '^cask "' "$BREWFILE" | cut -d'"' -f2 2>/dev/null)); then
        printStyled warning "[load_brewfile] Failed to extract casks from Brewfile"
        CASKS=()
    fi
}

# Print formulae status
print_formulae() {
    local output_formulae=""

    # Compute
    for formula in $FORMULAE; do
        if [[ "$formula" = "coreutils" ]]; then
            if command -v gdate >/dev/null 2>&1; then
                output_formulae+="${ICON_ON}"
            else
                output_formulae+="${ICON_OFF}"
            fi
        else
            if command -v $formula >/dev/null 2>&1; then
                output_formulae+="${ICON_ON}"
            else
                output_formulae+="${ICON_OFF}"
            fi
        fi
        output_formulae+=" ${ORANGE}$formula${NONE} ${GREY}|${NONE} "
    done

    # Display (removing trailing " | ")
    print "${output_formulae% ${GREY}|${NONE} }"
}

# Print casks status
print_casks() {
    local output_casks=""

    # Compute
    for cask in $CASKS; do
        # "my-cask-name" → "My Cask Name.app"
        local app_name="$(echo "$cask" | sed -E 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1').app"

        # Check .app folders first for speed, fallback to brew if missing
        if [[ -d "/Applications/$app_name" || -d "$HOME/Applications/$app_name" ]]; then
            output_casks+="${ICON_ON}"
        elif brew list --cask "$cask" >/dev/null 2>&1; then
            output_casks+="${ICON_ON}"
        else
            output_casks+="${ICON_OFF}"
        fi
        output_casks+=" ${CYAN}$cask${NONE} ${GREY}|${NONE} "
    done

    # Display (removing trailing " | ")
    print "${output_casks% ${GREY}|${NONE} }"
}

# Init
brew_init || return 1

