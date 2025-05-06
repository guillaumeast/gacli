#!/usr/bin/env sh
###############################
# FICHIER /installer/http/install.sh
###############################

# ────────────────────────────────────────────────────────────────
# TODO
# ────────────────────────────────────────────────────────────────

# TODO: make zsh default shell
# TODO: add loader
# TODO: add wget one-liner install cmd into README
# TODO: add git one-liner install cmd into README

BRANCH="dev" # TODO: make it "master" for prod (via ENV variable ?)
GACLI_DEPS="zsh coreutils jq" # TODO: use Brewfile instead !

# ────────────────────────────────────────────────────────────────
# VARIABLES
# ────────────────────────────────────────────────────────────────

# Options
FORCE_MODE="false"

# HTTP client
HTTP_CLIENTS="curl wget git"
HTTP_CLIENT=""

# URLs
REPO="guillaumeast/gacli"
URL_ARCHIVE="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"
URL_MANUAL_INSTALLER="https://github.com/${REPO}/blob/${BRANCH}/installer/manual/install.sh"
URL_HELPERS_DIR="https://raw.githubusercontent.com/${REPO}/refs/heads/${BRANCH}/installer/http/helpers"
URL_HELPERS_FILES="${URL_HELPERS_DIR}/pkg.sh ${URL_HELPERS_DIR}/brew.sh"

# PATHs
DIR_DEST=".gacli"
ENTRY_POINT="${DIR_DEST}/main.zsh"
SYMDIR=".local/bin"
SYMLINK="${SYMDIR}/gacli"
DIR_TMP="/tmp/gacli"
FILE_ZSHRC=".zshrc"
FILES_RC=".profile .kshrc .bashrc .zshrc .dashrc .tcshrc .cshrc"

# ────────────────────────────────────────────────────────────────
# I/O FORMATTING
# ────────────────────────────────────────────────────────────────

# Colors
RED="$(printf '\033[31m')"
GREEN="$(printf '\033[32m')"
YELLOW="$(printf '\033[33m')"
CYAN="$(printf '\033[36m')"
ORANGE="$(printf '\033[38;5;208m')"
GREY="$(printf '\033[90m')"
NONE="$(printf '\033[0m')"
BOLD="$(printf '\033[1m')"

# Emojis
EMOJI_SUCCESS="✓"
EMOJI_WARN="⚠️ "
EMOJI_ERR="🛑"
EMOJI_INFO="✧"
EMOJI_TBD="⚐"
EMOJI_HIGHLIGHT="→"
EMOJI_DEBUG="🔎"
EMOJI_WAIT="✧ ⏳"

# Centralised formatter to colour‑code and emoji log messages by severity
printStyled() {
    style=$1
    msg=$2
    color_text=$GREY
    color_emoji=$GREY
    case "${style}" in
        error)
            echo
            printf "%s\n" "${EMOJI_ERR} ${RED}Error: ${BOLD}${msg}${NONE}" >&2
            echo
            return ;;
        warning)
            printf "%s\n" "${EMOJI_WARN} ${YELLOW}Warning: ${BOLD}${msg}${NONE}" >&2
            return ;;
        success)
            color_text=$GREY
            color_emoji=$GREEN
            emoji=$EMOJI_SUCCESS
            ;;
        wait)
            color_text=$GREY
            color_emoji=$GREY
            emoji=$EMOJI_WAIT
            ;;
        info)
            color_text=$GREY
            color_emoji=$GREY
            emoji=$EMOJI_INFO
            ;;
        fallback)
            color_text=$GREY
            color_emoji=$ORANGE
            emoji=$EMOJI_TBD
            ;;
        highlight)
            color_text=$NONE
            color_emoji=$NONE
            emoji=$EMOJI_HIGHLIGHT
            ;;
        debug)
            printf "%s\n" "${EMOJI_DEBUG} ${YELLOW}Debug: ${msg}${NONE}" >&2
            return ;;
        *)
            emoji=""
            ;;
    esac
    printf "%s\n" "${color_emoji}${emoji} ${color_text}${msg}${NONE}"
}

# Prints ASCII banner and activates emoji styling when UTF‑8 is supported
display_logo() {
    printf "%s\n" "${ORANGE}  _____          _____ _      _____ ${NONE}"
    printf "%s\n" "${ORANGE} / ____|   /\\   / ____| |    |_   _|${NONE}"
    printf "%s\n" "${ORANGE}| |  __   /  \\ | |    | |      | |  ${NONE}"
    printf "%s\n" "${ORANGE}| | |_ | / /\\ \\| |    | |      | |  ${NONE}"
    printf "%s\n" "${ORANGE}| |__| |/ ____ \\ |____| |____ _| |_ ${NONE}"
    printf "%s\n" "${ORANGE} \\_____/_/    \\_\\_____|______|_____|${NONE}"
    printf "%s\n" ""
    printStyled highlight "Checking environment..."
}

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

main() {

    echo
    init_script "$@"        || exit 10
    check_env               || exit 20

    echo
    printStyled highlight "Preparing install..."
    resolve_paths           || exit 30
    init_tmp_folder         || exit 31

    echo
    printStyled highlight "Updating installer..."
    fetch_helpers           || {
        echo
        printStyled highlight "Download autonomous offline installer at: ${URL_MANUAL_INSTALLER}"
        echo
        exit 40
    }

    echo
    printStyled highlight "Checking package manager..."
    check_brew              || exit 50

    ####################
    # WIP

    # Install dependencies with pkg.sh (Homebrew + Gacli !) → curl git bash zsh coreutils(macOS only ?) jq
    # Install Homebrew with brew.sh
    # Download GACLI archive
    # Uncompress GACLI archive
    # ...

    # WIP
    ####################


    ####################
    # OLD

    # # Install GACLI
    # echo
    # printStyled highlight "Installing GACLI ${GREY}→${CYAN} ${DIR_DEST}${GREY}...${NONE}"
    # gacli_download      || exit 41
    # gacli_install_deps  || exit 42
    # gacli_config        || exit 43

    # # Success
    # echo
    # printStyled success "${GREEN}GACLI successfully installed${NONE} 🚀"
    # echo
    # printStyled success "👉 ${GREEN}restart your shell${GREY} or run ${GREEN}exec zsh${NONE}"
    # echo

    # OLD
    ####################
}

# ────────────────────────────────────────────────────────────────
# INIT SCRIPT
# ────────────────────────────────────────────────────────────────

init_script() {

    _posix_guard        || return 1
    _parse_args "$@"    || return 1
    _force_sudo "$@"    || return 1
}

_posix_guard() {

    shell_name="$(ps -p $$ -o comm= 2>/dev/null)"

    case "${shell_name}" in
        zsh)
            # Force local POSIX mode (Zsh is not POSIX by default)
            emulate -L sh || return 1
        ;;
        fish)
            # Abort if sourced (Fish is not POSIX-compatible)
            echo "❌ This script is POSIX. Run with: sh install.sh" >&2
            return 1
        ;;
    esac
}

_parse_args() {
    
    for arg in "$@"; do
        case "${arg}" in
            --force)
                FORCE_MODE="true"
                ;;
            *)
                printStyled error "Expected : --force (received : ${arg})"
                return 1
                ;;
        esac
    done
}

_force_sudo() {

    # Root → fine
    if [ "$(id -u)" -eq 0 ]; then
        display_logo
        printStyled success "Privilege: ${GREEN}root${NONE}"
        return 0
    fi

    # Sudo → Retry in sudo mode
    if command -v sudo >/dev/null 2>&1; then
        printStyled warning "Enabling sudo mode..."
        echo
        echo "🔐 ${YELLOW}Password may be required${NONE}"
        # TODO: fix pipe support ! (fails on archlinux when `... | sh`)
        exec sudo -E sh "$0" "$@"
    fi

    # No sudo → Warn install may fail
    display_logo
    printStyled fallback "Privilege: ${ORANGE}non-root user${NONE}"
    printStyled fallback "Not detected : ${ORANGE}sudo${NONE}"
    printStyled warning "Non-root install may fail"
}

# ────────────────────────────────────────────────────────────────
# CHECK ENV
# ────────────────────────────────────────────────────────────────

check_env() {

    _check_arch         || return 1
    _check_os           || return 1
    _check_shell        || return 1
    _check_http_client  || return 1
}

_check_arch() {

    arch="$(uname -m)"
    if [ -n "$arch" ]; then
        printStyled success "Arch: ${GREEN}${arch}${NONE}"
    else
        printStyled fallback "Arch: ${ORANGE}unknown${NONE}"
    fi
}

_check_os() {

    # Check OS
    os=$(uname -s)
    if [ "${os}" != "Darwin" ] && [ "${os}" != "Linux" ]; then
        printStyled error "Unsupported OS: ${RED}${os}${NONE}"
        return 1
    fi
    printStyled success "OS: ${GREEN}${os}${NONE}"

    # Linux → Check distribution
    if [ "${os}" = "Linux" ]; then

        # Read /etc/os-release to get the distro pretty-name (fallback to ID)
        if [ -r /etc/os-release ]; then
            . /etc/os-release
            distro="${NAME:-${ID}}"
        else
            distro="unknown"
        fi
        
        # Alpine is unsupported (musl instead of glibc) → TODO: make it dynamic
        if echo "${distro}" | grep -qi alpine; then
            printStyled info "Distribution: ${RED}${distro}${NONE}"
            printStyled error "Distribution not supported → please use a ${ORANGE}glibc-based${RED} distribution"
            return 1
        fi

        printStyled success "Distribution: ${GREEN}${distro}${NONE}"
    fi
}

_check_shell() {
    
    # Detect default shell
    shell_path=${SHELL:-$(command -v sh)}
    shell_name=$(basename "$shell_path")

    # Zsh → success
    if [ ${shell_name} = "zsh" ]; then
        printStyled success "Default shell: ${GREEN}${shell_name}${GREY} → ${CYAN}${shell_path}${NONE}"
        return 0
    fi

    # Other → tbd
    if [ -n "${shell_name}" ]; then
        printStyled fallback "Default shell: ${ORANGE}${shell_name}${GREY} → ${CYAN}${shell_path}${NONE}"
        return 0
    fi

    # Unknown → warn
    printStyled fallback "Default shell: ${RED}unknown${GREY} → path: '${CYAN}${shell_path}${NONE}'"
}

_check_http_client() {

    for client in $HTTP_CLIENTS; do

        ! command -v "$client" >/dev/null 2>&1 && continue

        HTTP_CLIENT="$client"

        color=$ORANGE
        style="fallback"
        if [ "${HTTP_CLIENT}" = "curl" ]; then
            color=$GREEN
            style="success"
        fi

        printStyled "${style}" "HTTP client: ${color}${HTTP_CLIENT}${GREY}"
        return 0
    done

    printStyled error "No ${ORANGE}HTTP client${RED} found"
    echo
    printStyled highlight "Download autonomous offline installer at: ${CYAN}${URL_MANUAL_INSTALLER}${NONE}"
    echo
    return 1
}

# ────────────────────────────────────────────────────────────────
# PREPARE INSTALL
# ────────────────────────────────────────────────────────────────

resolve_paths() {

    [ -n "${HOME}" ] || {
        printStyled error "\$HOME not set"
        return 1
    }

    # Destination
    DIR_DEST="${HOME}/${DIR_DEST}"
    ENTRY_POINT="${HOME}/${ENTRY_POINT}"
    SYMDIR="${HOME}/${SYMDIR}"
    SYMLINK="${HOME}/${SYMLINK}"

    # Shell config files
    FILE_ZSHRC="${HOME}/${FILE_ZSHRC}"
    raw=$RC_FILES && RC_FILES=""
    for file in $raw; do
        RC_FILES+="${HOME}/${file}"
    done

    printStyled success "Paths: ${GREEN}resolved${NONE}"
}

init_tmp_folder() {

    if [ -d "${DIR_TMP}" ]; then
        rm -rf "${DIR_TMP}" || {
            printStyled error "Unable to delete old temporary files: ${CYAN}${DIR_TMP}${NONE}"
            return 1
        }
    fi

    DIR_TMP=$(mktemp -d "${DIR_TMP}".XXXXXX) || {
        printStyled error "Unable to create temporary folder: ${CYAN}${DIR_TMP}${NONE}"
        return 1
    }

    trap 'rm -rf "$DIR_TMP"' EXIT
    printStyled success "Ready: ${GREEN}temporary folder${NONE}"
}

# ────────────────────────────────────────────────────────────────
# HELPERS
# ────────────────────────────────────────────────────────────────

fetch_helpers() {
    
    dir_tmp_helpers="${DIR_TMP}/helpers"

    mkdir -p "${dir_tmp_helpers}" || {
        printStyled error "Unable to create temporary folder: ${dir_tmp_helpers}"
        return 1
    }

    _download_files "${dir_tmp_helpers}" $URL_HELPERS_FILES || return 1
    printStyled success "Downloaded: ${GREEN}helpers${NONE}"

    for url in $URL_HELPERS_FILES; do
        filename=$(basename "${url}")
        . "${dir_tmp_helpers}/${filename}" || return 1
        printStyled success "Loaded: ${GREEN}${filename}${NONE}"
    done
}

_download_files() {

    destination_dir="${1}"
    if [ ! -d "${destination_dir}" ]; then
        printStyled error "Unable to find dir: ${destination_dir}"
        return 1
    fi

    shift
    urls="$@"
    if [ -z "${urls}" ]; then
        printStyled error "Expected <destination_dir> <urls>; received: '${destination_dir}' '${2}'"
        return 1
    fi

    if [ "${HTTP_CLIENT}" = "git" ]; then

        printStyled wait "Downloading: helpers..."

        tmp_repo="${DIR_TMP}/gitclone"
        git clone --depth=1 --branch="${BRANCH}" "https://github.com/${REPO}.git" "${tmp_repo}" >/dev/null 2>&1 || return 1
    fi

    for url in $urls; do

        filename=$(basename "$url")
        dest="${destination_dir}/${filename}"

        if [ -f "${dest}" ]; then
            printStyled error "Destination file already exists: ${CYAN}${dest}${NONE}"
            return 1
        fi

        [ "${HTTP_CLIENT}" = "curl" ] && curl -fsSL "${url}" > "${dest}" && continue
        [ "${HTTP_CLIENT}" = "wget" ] && wget -qO- "${url}" > "${dest}" && continue

        if [ "${HTTP_CLIENT}" = "git" ]; then
            file_path_in_repo="$(printf '%s' "${url}" | sed -E "s|https://raw.githubusercontent.com/${REPO}/refs/heads/${BRANCH}/||")"
            cp "${tmp_repo}/${file_path_in_repo}" "${dest}" && continue
        fi
        
        printStyled error "Unable to download file"
        printStyled fallback "→ with: ${ORANGE}${HTTP_CLIENT}${NONE}"
        printStyled fallback "→ from: ${CYAN}${url}${NONE}"
        printStyled fallback "→ to:   ${CYAN}${dest}${NONE}"
        return 1
    done
}

# ────────────────────────────────────────────────────────────────
# HOMEBREW
# ────────────────────────────────────────────────────────────────

check_brew() {

    package_manager=$(pkg_get_current) || return 1
    if [ "${package_manager}" = "brew" ]; then
        printStyled success "Detected: ${GREEN}${package_manager}${GREY}"
        return 0
    fi
    printStyled fallback "Package manager: ${ORANGE}${package_manager}${GREY}"

    echo
    printStyled highlight "Installing Homebrew..."
    brew_install || return 1

    # TODO: WIP
    echo "🚧 WIP - Available SOON™️"
    echo
}

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

