#!/usr/bin/env sh
###############################
# FICHIER /installer/gacli.sh
###############################

# Requires ipkg (Interface for Package Managers)

REPO="guillaumeast/gacli"
BRANCH="dev" # TODO: make it "master" for prod (via ENV variable ?)
URL_ARCHIVE="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"
GACLI_DEPS_LINUX="curl tar"
GACLI_DEPS_COMMON="brew zsh coreutils jq"

DIR_DEST=".gacli"
ENTRY_POINT="${DIR_DEST}/main.zsh"
SYMDIR=".local/bin"
SYMLINK="${SYMDIR}/gacli"
DIR_TMP_GACLI="/tmp/gacli"
FILE_ZSHRC=".zshrc"

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# Used by ipkg to fetch installer dependencies
get_deps() {

    deps=$GACLI_DEPS_COMMON

    [ "$(uname -s)" = "Linux" ] && deps="${deps} ${GACLI_DEPS_LINUX}"

    echo $deps
}

# Called by ipkg after deps install
run() {
    
    if command -v gacli >/dev/null 2>&1; then
        printStyled success "Detected    → ${GREEN}Gacli${NONE}"
        return 0
    fi
    
    _gacli_download || return 1

    loader_start "Installing  → gacli"
    chmod +x "${ENTRY_POINT}" || {
        loader_stop
        printStyled warning "Failed to make ${CYAN}${ENTRY_POINT}${YELLOW} executable"
        return 1
    }
    _create_wrapper || {
        loader_stop
        printStyled warning "Failed to create wrapper"
        return 1
    }
    _update_zshrc || {
        loader_stop
        printStyled warning "Failed to update .zshrc file"
        return 1
    }
    _cleanup || {
        loader_stop
        printStyled warning "Failed to cleanup install files"
        return 1
    }

    loader_stop
    printStyled success "Installed   → ${GREEN}gacli${NONE}"

    echo
    printStyled highlight "Restart your terminal or run ${YELLOW}exec zsh${NONE}"
    echo
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

_gacli_download() {

    loader_start "Downloading → ${CYAN}${URL_ARCHIVE}${NONE}"

    if [ -d "${DIR_DEST}" ]; then

        # TODO: Ask for confirmation

        rm -rf "${DIR_DEST}" || {
            loader_stop
            printStyled error "Unable to delete previous install: ${CYAN}${DIR_DEST}${NONE}"
            return 1
        }
    fi

    mkdir -p "${DIR_TMP_GACLI}" || {
        printStyled error "Unable to create folder: ${CYAN}${DIR_TMP_GACLI}${NONE}"
        return 1
    }

    curl -fsSL "${URL_ARCHIVE}" | tar -xzf - -C "${DIR_TMP_GACLI}" --strip-components=1 || { # TODO: >/dev/null 2>&1 after tests
        loader_stop
        printStyled error "Download failed"
        return 1
    }

    mv "${DIR_TMP_GACLI}/src" "${DIR_DEST}" || {
        loader_stop
        printStyled error "Unable to move files into: ${CYAN}${DIR_DEST}${NONE}"
        return 1
    }

    loader_stop
    printStyled success "Downloaded  → ${CYAN}${URL_ARCHIVE}${NONE}"
}

_create_wrapper() {

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
        printStyled error "Failed to create ${ORANGE}wrapper${NONE}"
        return 1
    }
}

_update_zshrc() {

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
            printStyled error "Failed to update ${FILE_ZSHRC}"
            return 1
        }
    fi
}

_cleanup() {

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
        printStyled fallback "Unable to delete installer"
        return 1
    }
    abs_dir="$(pwd -P)" || {
        printStyled fallback "Unable to delete installer"
        return 1
    }
    installer="${abs_dir}/${base}"

    [ -f "${installer}" ] && rm -f "${installer}"
    [ -d "${DIR_TMP_GACLI}" ] && rm -rf "${DIR_TMP_GACLI}"
}

