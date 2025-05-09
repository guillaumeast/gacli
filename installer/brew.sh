#!/usr/bin/env sh
###############################
# FICHIER /installer/brew.sh
###############################

# Requires ipkg (Interface for Package Managers)

URL_OFFICIAL_BREW_INSTALLER="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
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

    _brew_update_ca_certificates
    _brew_install_with_fallback || return 1
    _brew_config_path
    _brew_install_gcc

    if ! command -v brew >/dev/null 2>&1; then
        printStyled error "${ORANGE}brew${YELLOW} → Install failed"
        return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

_brew_update_ca_certificates() {

    [ "$(uname -s)" != "Linux" ] && return 0

    loader_start "Updating    → ca-certificates"

    if ! update-ca-certificates --fresh >/dev/null 2>&1; then
        loader_stop
        printStyled warning "${ORANGE}ca-certificates${YELLOW} → Update failed"
        return 1
    fi

    loader_stop
    printStyled success "Updated     → ${GREEN}ca-certificates${NONE}"
}

_brew_install_with_fallback() {

    tmp_installer="${DIR_TMP_IPKG}/homebrew_official_installer.sh"
    http_download "${URL_OFFICIAL_BREW_INSTALLER}" "${tmp_installer}" || return 1

    loader_start "Installing  → brew"

    bash_path="$(command -v bash || printf %s '/bin/bash')"
    install_cmd="yes '' | ${bash_path} ${tmp_installer} >/dev/null 2>&1"
    fallback_cmd="HOMEBREW_NO_INSTALL_FROM_API=1 ${install_cmd}"
    
    if ! eval "${install_cmd}"; then

        printStyled warning "Failed      → Fallback on API-less method..."
        printStyled warning "🥱 ${ORANGE}This may take a few minutes - time for a coffee?${NONE} ☕️"

        if ! eval "${fallback_cmd}"; then
            loader_stop
            printStyled error "${ORANGE}brew${NONE} → Install failed"
            return 1
        fi
    fi

    loader_stop
    printStyled success "Installed   → ${GREEN}brew${NONE}"
}

_brew_config_path() {

    [ "$(uname -s)" != "Linux" ] && return 0

    loader_start "Configuring → PATH"

    brew_path="$(_brew_get_path)" || {
        loader_stop
        printStyled error "${ORANGE}brew${YELLOW} → path resolution failed"
        return 1
    }
    brew_shellenv="$("${brew_path}" shellenv)" || {
        loader_stop
        printStyled error "${ORANGE}brew${YELLOW} → shellenv resolution failed"
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

    loader_stop
    printStyled success "Configured  → ${GREEN}PATH${NONE}"
}

_brew_get_path() {

    location_1="/home/linuxbrew/.linuxbrew/bin/brew"
    location_2="/home/linuxbrew/.linuxbrew/Homebrew/bin/brew"

    command -v brew && echo "$(command -v brew)" && return 0
    [ -x "${location_1}" ] && echo "$location_1" && return 0
    [ -x "${location_2}" ] && echo "$location_2" && return 0

    return 1
}

_brew_install_gcc() {

    if [ "$(uname -s)" != "Linux" ] || command -v gcc >/dev/null 2>&1 ; then
        return 0
    fi

    loader_start "Installing  → gcc"

    brew install gcc >/dev/null 2>&1 || {
        loader_stop
        printStyled warning "${ORANGE}gcc${YELLOW} install failed"
        return 1
    }

    loader_stop
    printStyled success "Installed   → ${GREEN}gcc${NONE}"
}

