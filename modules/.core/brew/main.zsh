###############################
# FICHIER gacli/modules/.core/brew/main.zsh
###############################

#!/usr/bin/env zsh

# Variables
BREWFILE="${TMP_DIR}/Brewfile"
FORMULAE=()
CASKS=()

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

# Install Homebrew if needed and check if Brewfile exists
brew_init() {
    # Install Homebrew if needed
    if ! command -v brew >/dev/null 2>&1; then
        brew_install || return 1
        brew_update || return 1
    fi

    # Concat and load Brewfiles content
    brew_load || return 1
}

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC (life cycle management)
# ────────────────────────────────────────────────────────────────

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

brew_load() {
    _brew_concat || return 1
    _brew_load_file || return 1
}

# Update Homebrew, formulae and casks
brew_update() {
    # Loading mesage
    print ""
    printStyled "info" "Updating... (this may take a few minutes) ⏳"

    # Concat Brewfiles
    brew_load || return 1

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

# ────────────────────────────────────────────────────────────────
# Functions - PRIVATE (Brewfiles management)
# ────────────────────────────────────────────────────────────────

# Create a temporary Brewfile by concatenating all Brewfiles (root + .core + user_modules)
_brew_concat() {

    # Create/reset the final concatenated Brewfile
    : > "${BREWFILE}" || {
        printStyled error "[_brew_concat] Failed to initialize ${BREWFILE}"
        return 1
    }

    # Find all Brewfiles in the repo, excluding tmp dir
    local brewfiles
    brewfiles=("${(@f)$(find "${GACLI_DIR}" -type f -name "Brewfile" ! -path "${TMP_DIR}/*" 2>/dev/null)}")

    # Append each Brewfile content into the final $BREWFILE
    local file
    for file in "${brewfiles[@]}"; do
        if [[ -f "$file" ]]; then
            echo "#############################################" >> "${BREWFILE}"
            echo "# From: ${file}" >> "${BREWFILE}"
            echo "#############################################" >> "${BREWFILE}"
            cat "$file" >> "${BREWFILE}"
            echo "" >> "${BREWFILE}"
        fi
    done
}

# Load formulae and casks lists from Brewfiles (in all directories)
_brew_load_file() {

    # Load formulae
    if ! FORMULAE=($(grep '^brew "' "$BREWFILE" | cut -d'"' -f2 2>/dev/null)); then
        printStyled error "[_brew_load_file] Failed to extract formulae from Brewfile"
        FORMULAE=()
        return 1
    fi

    # Load casks
    if ! CASKS=($(grep '^cask "' "$BREWFILE" | cut -d'"' -f2 2>/dev/null)); then
        printStyled error "[_brew_load_file] Failed to extract casks from Brewfile"
        CASKS=()
        return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# Functions - PUBLIC (I/O)
# ────────────────────────────────────────────────────────────────

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

# ────────────────────────────────────────────────────────────────
# INIT
# ────────────────────────────────────────────────────────────────

brew_init || return 1

