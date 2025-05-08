#!/usr/bin/env sh
###############################
# FICHIER /installer/igacli.sh
###############################

# Requires ipkg (Interface for Package Managers)

REPO="guillaumeast/gacli"
BRANCH="dev" # TODO: make it "master" for prod (via ENV variable ?)
URL_ARCHIVE="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"
GACLI_DEPS_LINUX="curl tar"
GACLI_DEPS_COMMON="zsh brew coreutils jq"

DIR_DEST=".gacli"
ENTRY_POINT="${DIR_DEST}/main.zsh"
SYMDIR=".local/bin"
SYMLINK="${SYMDIR}/gacli"
DIR_TMP="/tmp/gacli"
FILE_ZSHRC=".zshrc"

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

main() {
    
    if command -v gacli >/dev/null 2>&1; then
        printStyled success "Detected    → ${GREEN}Gacli${NONE}"
        return 0
    fi

    # TODO: waiting for ipkg auto-install update then replace 'main_install $GACLI_DEPS_LINUX' →  'ipkg install $GACLI_DEPS_LINUX'
    deps=$GACLI_DEPS_COMMON
    [ "$(uname -s)" = "Linux" ] && deps="${deps} ${GACLI_DEPS_LINUX}"

    main_install $deps
    
    _gacli_download || return 1

    chmod +x "${ENTRY_POINT}" || {
        printStyled warning "Failed to make ${CYAN}${ENTRY_POINT}${YELLOW} executable"
        return 1
    }
    printStyled success "Entry point → ${GREEN}Executable${NONE}"

    _create_wrapper || return 1
    
    _update_zshrc   || return 1
    
    _cleanup        || return 1

    printStyled success "Ready       → ${GREEN}Gacli${NONE}"

    echo
    printStyled highlight "Restart your terminal or run ${YELLOW}exec zsh${NONE}"
    echo
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

_gacli_download() {

    loader_start "Downloading → Gacli"

    if [ -d "${DIR_DEST}" ]; then

        # TODO: Ask for confirmation

        rm -rf "${DIR_DEST}" || {
            loader_stop
            printStyled error "Unable to delete previous install: ${CYAN}${DIR_DEST}${NONE}"
            return 1
        }
    fi

    mkdir -p "${DIR_TMP}" || {
        printStyled error "Unable to create folder: ${CYAN}${DIR_TMP}${NONE}"
        return 1
    }

    curl -fsSL "${URL_ARCHIVE}" | tar -xzf - -C "${DIR_TMP}" --strip-components=1 || { # TODO: >/dev/null 2>&1 after tests
        loader_stop
        printStyled error "Download failed"
        return 1
    }

    mv "${DIR_TMP}/src" "${DIR_DEST}" || {
        loader_stop
        printStyled error "Unable to move files into: ${CYAN}${DIR_DEST}${NONE}"
        return 1
    }

    loader_stop
    printStyled success "Downloaded  → ${GREEN}GACLI${NONE}"
}

_create_wrapper() {

    loader_start "Creating    → Wrapper"

    mkdir -p "${SYMDIR}" || {
        loader_stop
        printStyled error "Failed to create ${CYAN}${SYMDIR}${NONE}"
        return 1
    }

    if [ -f "${SYMLINK}" ] || [ -d "${SYMLINK}" ] || [ -L "${SYMLINK}" ]; then
        rm -f "${SYMLINK}"
    fi

    {
        printf '%s\n' '#!/usr/bin/env sh'
        printf '%s\n' "exec \"$(command -v zsh)\" \"${ENTRY_POINT}\" \"\$@\""
    } > "${SYMLINK}" && chmod +x "${SYMLINK}" || {
        loader_stop
        printStyled error "Failed to create ${ORANGE}wrapper${NONE}"
        return 1
    }

    loader_stop
    printStyled success "Created     → ${GREEN}wrapper${GREY} → ${CYAN}${SYMLINK}${GREY} → ${CYAN}${ENTRY_POINT}${NONE}"
}

_update_zshrc() {

    loader_start "Updating    → zsh config file"

    touch "${FILE_ZSHRC}" || {
        printStyled error "Unable to create .zshrc file: ${CYAN}${FILE_ZSHRC}${NONE}"
        return 1
    }

    missing=""
    for line in \
        '# GACLI' \
        "export PATH=\"${SYMDIR}:\$PATH\"" \
        "source ${ENTRY_POINT}"
    do
        if ! grep -Fq "$line" "$FILE_ZSHRC"; then
            missing="${missing}\n${line}"
        fi
    done

    if [ -n "${missing}" ]; then
        printf "${missing}\n" >> "${FILE_ZSHRC}" || {
            loader_stop
            printStyled error "Failed to update ${FILE_ZSHRC}"
            return 1
        }
    fi

    loader_stop
    printStyled success "Updated     → ${GREEN}zsh${GREY} config file"
}

_cleanup() {

    # TODO: create a wrapper for cleanup + exit to ensure tmp files are always deleted after installer succeed or failed

    loader_start "Processing  → cleanup"

    # Resolve installer symlinks
    installer="$0"
    while [ -L "${installer}" ]; do

        dir="$(dirname "${installer}")"
        installer="$(readlink "${installer}")"

        case "${installer}" in
            /*)
                ;;
            *)
                installer="${dir}/${installer}"
                ;;
        esac
    done
    dir="$(dirname "${installer}")"
    base="$(basename "${installer}")"

    # Move to installer directory and get absolute path
    # TODO: do not change activ dir !!
    cd "${dir}" >/dev/null 2>&1 || {
        loader_stop
        printStyled fallback "Unable to delete installer"
        return 1
    }
    abs_dir="$(pwd -P)" || {
        loader_stop
        printStyled fallback "Unable to delete installer"
        return 1
    }
    installer="${abs_dir}/${base}"

    [ -f "${installer}" ] && rm -f "${installer}"
    [ -d "${DIR_TMP}" ] && rm -rf "${DIR_TMP}"

    loader_stop
    printStyled success "Completed   → ${GREEN}cleanup${NONE}"
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

main "$@"

