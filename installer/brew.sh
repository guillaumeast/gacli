#!/usr/bin/env sh
###############################
# FICHIER /installer/brew.sh
###############################

# Requires ipkg (Interface for Package Managers)

BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
FILES_RC="${HOME}/.profile ${HOME}/.kshrc ${HOME}/.bashrc ${HOME}/.zshrc ${HOME}/.dashrc ${HOME}/.tcshrc ${HOME}/.cshrc"
BREW_DEPS="bash git curl file gcc make binutils gawk gzip ca-certificates perl brotli ruby procps cyrus-sasl nghttp2"

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# Used by ipkg to fetch installer dependencies
get_deps() {

    [ "$(uname -s)" = "Linux" ] && echo $BREW_DEPS
}

# Called by ipkg after deps install
run() {
    
    if command -v brew >/dev/null 2>&1; then
        printStyled success "Detected    → ${GREEN}brew${NONE}"
        return 0
    fi

    [ "$(uname -s)" = "Linux" ] && update-ca-certificates --fresh >/dev/null 2>&1

    _brew_install_with_fallback || return 1
    
    _brew_config || return 1

    if ! command -v brew >/dev/null 2>&1; then
        printStyled error "Unable to install ${ORANGE}brew${NONE}"
        return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

_brew_install_with_fallback() {

    bash_path="$(command -v bash || printf %s '/bin/bash')"
    install_cmd="yes '' | ${bash_path} -c \"\$(curl -fsSL ${BREW_INSTALL_URL})\" >/dev/null 2>&1"


    loader_start "Installing  → brew"
    if ! eval "${install_cmd}"; then

        printStyled warning "Failed      → Fallback on API-less method..."
        printStyled warning "🥱 ${ORANGE}This may take a few minutes - time for a coffee?${NONE} ☕️"

        if ! eval "HOMEBREW_NO_INSTALL_FROM_API=1 ${install_cmd}"; then
            loader_stop
            printStyled error "Unable to install ${ORANGE}brew${NONE}"
            return 1
        fi
    fi

    printStyled success "Installed   → ${GREEN}brew${NONE}"
}

_brew_config() {

    [ "$(uname -s)" != "Linux" ] && return 0

    brew_path="$(_brew_get_path)" || return 1
    brew_shellenv="$("${brew_path}" shellenv)" || {
        printStyled error "Unable to fetch ${ORANGE}brew shellenv${NONE}"
        return 1
    }

    # Add brew to current session
    eval "${brew_shellenv}"

    # Add brew to all source files
    for file in $FILES_RC; do
        [ ! -f "${file}" ] && continue
        echo "" >> "${file}"
        echo "eval \"${brew_shellenv}\"" >> "${file}"
    done

    # Install gcc if missing (recommended)
    if ! command -v gcc >/dev/null 2>&1; then
        brew install gcc >/dev/null 2>&1 || {
            printStyled error "Unable to install ${ORANGE}gcc${NONE}"
            return 1
        }
    fi

    printStyled success "Configured  → ${GREEN}Linux env${NONE}"
}

_brew_get_path() {

    location_1="/home/linuxbrew/.linuxbrew/bin/brew"
    location_2="/home/linuxbrew/.linuxbrew/Homebrew/bin/brew"

    command -v brew && echo "$(command -v brew)" && return 0
    [ -x "${location_1}" ] && echo "$location_1" && return 0
    [ -x "${location_2}" ] && echo "$location_2" && return 0

    printStyled error "Unable to locate ${ORANGE}brew${RED} binary"
    return 1
}

