# ────────────────────────────────────────────────────────────────
# GACLI - INSTALL
# ────────────────────────────────────────────────────────────────

# Retrieves GACLI source (curl, wget or git) into the installer directory, honouring --force
gacli_download() {

    printStyled wait "Downloading GACLI..."

    if [ -d "${DIR_DEST}" ]; then

        if [ "${FORCE_MODE}" != "true" ]; then
            printStyled error "Gacli already installed. Use --force to overwrite"
            return 1
        fi

        rm -rf "${DIR_DEST}" || {
            printStyled error "Unable to delete previous install: ${CYAN}${DIR_DEST}${NONE}"
            return 1
        }
    fi

    curl -fsSL "${URL_ARCHIVE}" | tar -xzf - -C "${DIR_TMP}" --strip-components=1 >/dev/null 2>&1 || {
        printStyled error "Download failed"
        return 1
    }

    mv "${DIR_TMP_SRC}" "${DIR_DEST}" || {
        printStyled error "Unable to move files into: ${DIR_DEST}"
        return 1
    }

    printStyled success "Downloaded: ${GREEN}GACLI${NONE}"
}

# Runs brew bundle on the downloaded FILE_TMP_BREWFILE to install required formulae and casks
gacli_install_deps() {

    printStyled wait "Installing GACLI dependencies..."

    # Check Brewfile integrity
    [ -f "${FILE_TMP_BREWFILE}" ] || {
        printStyled error "Unable to find dependencies descriptor at: ${CYAN}${FILE_TMP_BREWFILE}${NONE}"
        return 1
    }

    # Check Homebrew install
    command -v brew >/dev/null 2>&1 || {
        printStyled error "Unable to find ${ORANGE}Homebrew${NONE}"
        return 1     
    }

    ###############################
    # WIP

    # ==> Pouring coreutils--9.7.arm64_linux.bottle.tar.gz
    #     Error: Could not rename binutils keg! Check/fix its permissions:
    #     sudo chown -R root /home/linuxbrew/.linuxbrew/Cellar/binutils/2.44

    # -> Permission is not the real issue
    # -> Real issue: /home/linuxbrew/.linuxbrew/Cellar/binutils/2.44 does not exist

    # ---> Try to find why binutils is not in linuxbrew ?

    # WIP
    ###############################

    # Install dependencies
    brew bundle --file="${FILE_TMP_BREWFILE}" || { # TODO WIP: >/dev/null 2>&1
        printStyled error "Failed to install dependencies with ${ORANGE}Homebrew${NONE}"
        return 1
    }
    
    printStyled success "Installed: ${GREEN}GACLI dependencies${NONE}"
}

# ────────────────────────────────────────────────────────────────
# GACLI - CONFIG
# ────────────────────────────────────────────────────────────────

gacli_config() {

    # Adds execute permission to the downloaded GACLI entry‑point script
    chmod +x "${ENTRY_POINT}" || {
        printStyled warning "Failed to make ${CYAN}${ENTRY_POINT}${YELLOW} executable"
        return 1
    }
    printStyled success "Made executable: ${GREEN}Entry point${NONE}"

    _create_wrapper || return 1
    _update_zshrc || return 1
    _cleanup || return 1
}

# Generates a wrapper in $HOME/.local/bin that relays args to the entry point via zsh
_create_wrapper() {

    # Create symlink dir if missing
    mkdir -p "${SYMDIR}" || {
        printStyled warning "Failed to create ${CYAN}${SYMDIR}${NONE}"; return 1
    }

    # Delete symlink if already exists
    if [ -f "${SYMLINK}" ] || [ -d "${SYMLINK}" ] || [ -L "${SYMLINK}" ]; then
        rm -f "${SYMLINK}"
    fi

    # Create symlink
    {
        printf '%s\n' '#!/usr/bin/env sh'
        printf '%s\n' "exec \"$(command -v zsh)\" \"${ENTRY_POINT}\" \"\$@\""
    } > "${SYMLINK}" && chmod +x "${SYMLINK}" || {
        printStyled warning "Failed to create ${ORANGE}wrapper${NONE}"; return 1
    }

    # Success
    printStyled success "Created: ${GREEN}wrapper${GREY} → ${CYAN}${SYMLINK}${GREY} → ${CYAN}${ENTRY_POINT}${NONE}"
}

# Appends PATH export and source command to the user’s .zshrc when missing
_update_zshrc() {

    touch "${FILE_ZSHRC}" || {
        printStyled error "Unable to create .zshrc file: ${CYAN}${FILE_ZSHRC}${NONE}"
        return 1
    }

    if grep -q '# GACLI' "${FILE_ZSHRC}"; then
        printStyled success "Zsh : ${GREEN}configured${NONE}"
        return 0
    fi
    {
        printf '\n\n# GACLI\n'
        printf 'export PATH="%s:$PATH"\n' "${SYMDIR}"
        printf 'source "%s"\n' "${ENTRY_POINT}"
    } >> "${FILE_ZSHRC}" || {
        printStyled warning "Failed update ${FILE_ZSHRC}"; return 1
    }
    printStyled success "Configured: ${GREEN}zsh${NONE}"
}

# Deletes installer and temporary files
_cleanup() {

    # TODO: create a wrapper for cleanup + exit to ensure tmp files are always deleted after installer succeed or failed

    # Resolve installer symlinks
    installer="$0"
    while [ -L "${installer}" ]; do
        dir="$(dirname "${installer}")"
        installer="$(readlink "${installer}")"
        case "${installer}" in
        /*) ;;
        *) installer="${dir}/${installer}" ;;
        esac
    done
    dir="$(dirname "${installer}")"
    base="$(basename "${installer}")"

    # Move to installer directory and get absolute path
    # TODO: do not change activ dir !!
    cd "${dir}" >/dev/null 2>&1 || return 1
    abs_dir="$(pwd -P)" || return 1
    installer="${abs_dir}/${base}"

    # Delete installer
    [ -f "${installer}" ] && rm -f "${installer}"

    # Delete temporary files
    [ -d "${DIR_TMP}" ] && rm -rf "${DIR_TMP}"

    printStyled success "Cleanup: ${GREEN}completed${NONE}"
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

main "$@"

