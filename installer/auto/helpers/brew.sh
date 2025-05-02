#!/usr/bin/env zsh
###############################
# FICHIER /<TODO: path>/brew.zsh (move to src/helpers or installer/ ?)
###############################

# Full POSIX sh script to abstract Homebrew handling

BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
FILES_RC="${HOME}/.profile ${HOME}/.kshrc ${HOME}/.bashrc ${HOME}/.zshrc ${HOME}/.dashrc ${HOME}/.tcshrc ${HOME}/.cshrc"

BREW_DEPS_APT="bash git curl file gcc make binutils gawk gzip ruby nghttp2 brotli ca-certificates perl procps libsasl2-2"
BREW_DEPS_OTHERS="bash git curl file gcc make binutils gawk gzip ruby nghttp2 brotli ca-certificates perl procps-ng cyrus-sasl"

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# Installs Homebrew when absent
brew_install() {
    
    # Check if already installed
    if command -v brew >/dev/null 2>&1; then
        printStyled success "Detected: ${GREEN}Homebrew${NONE}"
        return 0
    fi

    # Install Homebrew dependencies
    pkg_install $BREW_DEPS_COMMON || {
        printStyled warning "Unable to update dependencies → ${ORANGE}install may fail${NONE}"
        return 1
    }

    # Build install command
    bash_path="$(command -v bash || printf %s '/bin/bash')"
    install_cmd="yes '' | ${bash_path} -c \"\$(curl -fsSL ${BREW_INSTALL_URL})\"" # TODO WIP: >/dev/null 2>&1

    # Try default install + NO_API fallback
    printStyled wait "Installing Homebrew..."
    if ! eval "${install_cmd}"; then
        # Fallback → NO_API
        printStyled warning "Install failed → Fallback on API-less method..."
        printStyled warning "${ORANGE}This may take a few minutes - time for a coffee?${NONE} ☕️"
        export HOMEBREW_NO_INSTALL_FROM_API=1
        eval "${install_cmd}" || {
            printStyled error "Unable to install ${ORANGE}Homebrew${NONE}"
            return 1
        }
    fi
    printStyled success "Installed: ${GREEN}Homebrew${NONE}"
    
    # Configure env
    _brew_config || return 1
    printStyled success "Configured: ${GREEN}Linuxbrew${NONE}"

    # Check install
    if command -v brew >/dev/null 2>&1; then
        printStyled success "Ready: ${GREEN}Homebrew${NONE}"
        return 0
    else
        printStyled error "Unable to install ${ORANGE}Homebrew${NONE}"
        return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

_brew_config() {

    # Configure Linux env only
    [ "$(uname -s)" != "Linux" ] && return 0

    # Resolve
    brew_path="$(_brew_get_path)" || return 1
    brew_shellenv="$("${brew_path}" shellenv)" || {
        printStyled error "Unable to fetch ${ORANGE}brew shellenv${NONE}"
        return 1
    }

    # Add Homebrew to current session
    eval "${brew_shellenv}"

    # Add Homebrew to all source files
    for file in $FILES_RC; do
        [ ! -f "${file}" ] && continue
        echo "" >> "${file}"
        echo "eval \"${brew_shellenv}\"" >> "${file}"
    done

    # Install gcc if missing
    if ! command -v gcc >/dev/null 2>&1; then
        brew install gcc >/dev/null 2>&1 || {
            printStyled error "Unable to install ${ORANGE}gcc${NONE}"
            return 1
        }
    fi
}

_brew_get_path() {

    # Default locations
    location_1="/home/linuxbrew/.linuxbrew/bin/brew"
    location_2="/home/linuxbrew/.linuxbrew/Homebrew/bin/brew"

    # Fetch Homebrew path
    command -v brew && echo "$(command -v brew)" && return 0
    [ -x "${location_1}" ] && echo "$location_1" && return 0
    [ -x "${location_2}" ] && echo "$location_2" && return 0

    # Unfetched
    printStyled error "Unable to locate ${ORANGE}Homebrew${RED} binary"
    return 1
}

