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
FILE_ZSHRC="${HOME}/.zshrc"

FILES_RC="${HOME}/.profile ${HOME}/.kshrc ${HOME}/.bashrc ${HOME}/.zshrc ${HOME}/.dashrc ${HOME}/.tcshrc ${HOME}/.cshrc"

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
    
    _gacli_install          || return 1
    _gacli_create_wrapper   || return 1
    _gacli_update_path     || return 1

    loader_stop
    echo
    printStyled highlight "Restart your terminal or run ${YELLOW}exec zsh${NONE}"
    echo
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

_gacli_install() {

    if [ -d "${DIR_DEST}" ]; then

        # TODO: Ask for confirmation

        rm -rf "${DIR_DEST}" || {
            loader_stop
            printStyled error "Unable to delete previous install: ${CYAN}${DIR_DEST}${NONE}"
            return 1
        }
    fi

    tmp_archive="${DIR_TMP_IPKG}/gacli_archive.tar.gz"
    tmp_extracted="${DIR_TMP_IPKG}/gacli"
    http_download "${URL_ARCHIVE}" "${tmp_archive}"

    loader_start "Extracting  → ${tmp_extracted}"

    mkdir -p "${tmp_extracted}" || {
        loader_stop
        printStyled error "Failed to create ${CYAN}${tmp_extracted}${NONE}"
        return 1
    }

    tar -xzf "${tmp_archive}" -C "${tmp_extracted}" --strip-components=1  >/dev/null 2>&1 || {
        loader_stop
        printStyled error "Extraction failed"
        return 1
    }

    loader_start "Moving to   → ${DIR_DEST}"

    mv "${tmp_extracted}/src" "${DIR_DEST}" || {
        loader_stop
        printStyled error "Unable to move files into: ${CYAN}${DIR_DEST}${NONE}"
        return 1
    }

    loader_stop
    printStyled success "Installed   → ${GREEN}gacli${NONE}"
}

_gacli_create_wrapper() {

    loader_start "Creating    → wrapper"

    chmod +x "${ENTRY_POINT}" || {
        loader_stop
        printStyled warning "Failed to make executable → ${CYAN}${ENTRY_POINT}${YELLOW}"
        return 1
    }

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
    printStyled success "Created     → ${GREEN}wrapper${NONE}"
}

_gacli_update_path() {

    loader_start "Configuring → PATH"

    touch "${FILE_ZSHRC}" || {
        loader_stop
        printStyled error "Unable to create .zshrc file: ${CYAN}${FILE_ZSHRC}${NONE}"
        return 1
    }

    for file in $FILES_RC; do

        missing=""
        for line in \
            '# GACLI' \
            "export PATH=\"${SYMDIR}:\$PATH\"" \
            "source ${ENTRY_POINT}"
        do
            if ! grep -Fq "$line" "$file"; then
                missing="${missing}\n${line}"
            fi
        done

        if [ -n "${missing}" ]; then
            printf "${missing}\n" >> "${file}" || {
                loader_stop
                printStyled error "Failed to update ${file}"
                return 1
            }
        fi
    done

    loader_stop
    printStyled success "Configured  → ${GREEN}PATH${NONE}"
}

