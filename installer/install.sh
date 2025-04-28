#!/usr/bin/env sh
###############################
# FICHIER /installer/install.sh
###############################

# Move this file to your shared folder (volume) then run:
# docker run --rm -v "<local_folder_path>:<virtual_folder_path>" -it <image> sh -c ". <virtual_folder_path>/install.sh"

# Options
FORCE_MODE="false"

# Setup variables
ARCH=""
IS_MACOS=false
IS_LINUX=false
SHELL_PATH=""
SHELL_NAME=""

# Urls
URL_REPO="https://github.com/guillaumeast/gacli"
URL_ARCHIVE="${URL_REPO}/archive/refs/heads/dev.tar.gz"

# Paths
DIR_GACLI=".gacli"
FILE_ENTRY_POINT="${DIR_GACLI}/main.zsh"
FILE_ZSHRC=".zshrc"

# Temporary files
DIR_TMP=".gacli_tmp"
DIR_TMP_SRC="${DIR_TMP}/src"
BREWFILE_TMP="${DIR_TMP}/installer/Brewfile"

# WRAPPER
SYM_DIR=".local/bin"
SYMLINK="${SYM_DIR}/gacli"

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
EMOJI_WARN="⚠️"
EMOJI_ERR="🛑"
EMOJI_INFO="✧"
EMOJI_TBD="⚐"
EMOJI_HIGHLIGHT="→"
EMOJI_DEBUG="🔎"
EMOJI_WAIT="✧ ⏳"

# ────────────────────────────────────────────────────────────────
# PSEUDO-CODE
# ────────────────────────────────────────────────────────────────

# install.sh
    # |→ ✅ init_style                → Enable emojis if system can handle it + welcome message
    # |→ ✅ init_style                → Standardize output formatting
    # |
    # |→ ✅ parse_args                → Inits global variables referring to given args
    # |→ ✅ resolve_paths             → Resolve relative paths to absolute paths
    # |→ ✅ check_env                 → Detect environment: OS, default shell and privilege
    # |
    # |→ ✅ install_brew_deps         → Install Homebrew dependencies with current package manager
    # |→ ✅ install_brew              → Install Homebrew
    # |→ ✅ install_zsh               → Ensure ZSH is the default shell
    # |
    # |→ ✅ download_gacli            → Download GACLI files from Github
    # |→ ✅ install_gacli_deps        → Install GACLI dependencies from BREWFILE_TMP
    # |→ ✅ make_executable           → Ensure GACLI entry point is executable
    # |→ ✅ create_wrapper            → Generate a small shell script to launch GACLI reliably across shells
    # |→ ✅ update_zshrc              → Append GACLI to PATH and source its entry point in ~/.zshrc
    # |
    # |→ ✅ auto_launch               → Launch GACLI
#

# TODO: make zsh default shell
# TODO: add more package managers (apt-get, ziper...)

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

# Entry point that sequences environment checks, download, install and shell reload
main() {

    init_style
    printStyled highlight "Initializing..."
    parse_args "$@" || return 1
    resolve_paths   || return 2

    echo ""
    printStyled highlight "Checking environment..."
    check_env       || return 3

    echo ""
    printStyled highlight "Installing package manager: Homebrew..."
    install_brew    || return 4

    echo ""
    printStyled highlight "Installing GACLI ${GREY}→${CYAN} ${DIR_GACLI}${GREY}...${NONE}"
    download_gacli  || return 5
    install_gacli_deps    || return 6
    make_executable || return 7
    create_wrapper  || return 8
    update_zshrc    || return 9
    cleanup         || return 10

    auto_launch     || return 11
}

# ────────────────────────────────────────────────────────────────
# OUTPUT FORMATTING
# ────────────────────────────────────────────────────────────────

# Prints ASCII banner and activates emoji styling when UTF‑8 is supported
init_style() {
    printf "%s\n" "${ORANGE}  _____          _____ _      _____ ${NONE}"
    printf "%s\n" "${ORANGE} / ____|   /\\   / ____| |    |_   _|${NONE}"
    printf "%s\n" "${ORANGE}| |  __   /  \\ | |    | |      | |  ${NONE}"
    printf "%s\n" "${ORANGE}| | |_ | / /\\ \\| |    | |      | |  ${NONE}"
    printf "%s\n" "${ORANGE}| |__| |/ ____ \\ |____| |____ _| |_ ${NONE}"
    printf "%s\n" "${ORANGE} \\_____/_/    \\_\\_____|______|_____|${NONE}"
    printf "%s\n" ""
}

# Centralised formatter to colour‑code and emoji log messages by severity
printStyled() {
    style=$1
    msg=$2
    color_text=$GREY
    color_emoji=$GREY
    case "${style}" in
        error)
            printf "%s\n" "${EMOJI_ERR} ${RED}${BOLD}${msg}${NONE}" >&2
            return ;;
        warning)
            printf "%s\n" "${EMOJI_WARN}  ${YELLOW}${BOLD}${msg}${NONE}" >&2
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
        info_tbd)
            color_text=$GREY
            color_emoji=$ORANGE
            emoji=$EMOJI_TBD
            ;;
        highlight)
            color_text=$NONE
            color_emoji=$NONE
            emoji=$EMOJI_HIGHLIGHT
            ;;
        *)
            emoji=""
            ;;
    esac
    printf "%s\n" "${color_emoji}${emoji} ${color_text}${msg}${NONE}"
}

# ────────────────────────────────────────────────────────────────
# CHECK ENV
# ────────────────────────────────────────────────────────────────

# Parses CLI options (currently only --force) and sets corresponding flags
parse_args() {
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
    printStyled success "Arguments: ${GREEN}parsed${NONE}"
}

# Expands user‑relative paths, ensures .zshrc exists, and defines wrapper installers
resolve_paths() {

    # Ensure $HOME is set
    [ -n "${HOME}" ] || { printStyled error "\$HOME not set"; return 1; }

    # Main paths
    DIR_GACLI="${HOME}/${DIR_GACLI}"
    FILE_ENTRY_POINT="${HOME}/${FILE_ENTRY_POINT}"
    FILE_ZSHRC="${HOME}/${FILE_ZSHRC}"

    # Symlink paths
    SYM_DIR="${HOME}/${SYM_DIR}"
    SYMLINK="${HOME}/${SYMLINK}"

    # Temporary paths
    DIR_TMP="${HOME}/${DIR_TMP}"
    DIR_TMP_SRC="${HOME}/${DIR_TMP_SRC}"
    BREWFILE_TMP="${HOME}/${BREWFILE_TMP}"

    # Reset temporary files
    [ -d "${DIR_TMP}" ] && rm -rf "${DIR_TMP}"
    mkdir -p "${DIR_TMP}"

    # Log
    printStyled success "Paths: ${GREEN}resolved${NONE}"
}

# Detects OS, default shell and privilege
check_env() {

    # Detect arch
    ARCH="$(uname -m)"
    printStyled success "Arch: ${GREEN}${ARCH}${NONE}"

    # Detect OS via uname
    ud=$(uname -s)
    case "${ud}" in
        Darwin) IS_MACOS=true ;;
        Linux)  IS_LINUX=true ;;
        *)      printStyled error "Unsupported OS: ${ud}"; return 1 ;;
    esac
    printStyled success "OS: ${GREEN}${ud}${NONE}"

    # Detect distribution
    if [ "${IS_LINUX}" = true ]; then
    
        # Read /etc/os-release to get the distro pretty-name (fallback to ID)
        if [ -r /etc/os-release ]; then
            . /etc/os-release
            distro="${NAME:-${ID}}"
        else
            distro="unknown"
        fi
        
        # Alpine is unsupported (musl instead of glibc)
        if echo "${distro}" | grep -qi alpine; then
            printStyled info "Distribution: ${RED}${distro}${NONE}"
            printStyled error "Distribution not supported → please use a ${ORANGE}glibc-based${RED} distribution"
            return 1
        fi

        # Success
        printStyled success "Distribution: ${GREEN}${distro}${NONE}"
    fi

    # Detect default shell
    SHELL_PATH=${SHELL:-$(command -v sh)}
    SHELL_NAME=$(basename "$SHELL_PATH")
    style=""
    color=""
    if [ ${SHELL_NAME} = "zsh" ]; then
        style="success"
        color="${GREEN}"
    elif [ -n "${SHELL_NAME}" ]; then
        style="info_tbd"
        color="${ORANGE}"
    else
        style="info"
        color="${RED}"
        SHELL_NAME="unknwon"
    fi
    printStyled "${style}" "Default shell: ${color}${SHELL_NAME}${GREY} → ${CYAN}${SHELL_PATH}${NONE}"

    # — Privilege escalation setup —
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            SUDO="sudo "
            printStyled success "Privilege: ${GREEN}sudo enabled${NONE}"
        else
            SUDO=""
            printStyled info_tbd "Privilege: ${ORANGE}No sudo detected${GREY} → non-root installs may fail${NONE}"
        fi
    else
        SUDO=""
        printStyled success "Privilege: ${GREEN}root${NONE}"
    fi
}

# ────────────────────────────────────────────────────────────────
# SETUP ENV
# ────────────────────────────────────────────────────────────────

# Installs Homebrew when absent, selecting curl or wget as downloader
install_brew() {
    
    # Check if Installed
    if command -v brew >/dev/null 2>&1; then
        printStyled success "Detected: ${GREEN}Homebrew${NONE}"
        return 0
    fi

    # Install Homebrew dependencies
    install_brew_deps || return 1

    # Install
    printStyled wait "Downloading Homebrew..."
    yes '' | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null 2>&1
    printStyled success "Downloaded: ${GREEN}Homebrew${NONE}"
    
    # Setup Linux env
    if [ "$IS_LINUX" = true ]; then
        files="/root/.profile /root/.kshrc /root/.bashrc /root/.zshrc /root/.dashrc /root/.tcshrc /root/.cshrc"
        brew_path=""
        brew_shellenv=""

        # Resolve brew path
        location_1="/home/linuxbrew/.linuxbrew/bin/brew"
        location_2="/home/linuxbrew/.linuxbrew/Homebrew/bin/brew"
        if command -v brew; then
            brew_path="$(command -v brew)"
        elif [ -x "${location_1}" ]; then
            brew_path=$location_1
        elif [ -x "${location_2}" ]; then
            brew_path=$location_2
        else
            printStyled error "Unable to locate ${ORANGE}Homebrew${RED} binary"
            return 1
        fi

        # Resolve brew shellenv output
        brew_shellenv="$("${brew_path}" shellenv)" || {
            printStyled error "Unable to fetch ${ORANGE}brew shellenv${NONE}"
            return 1
        }

        # Add Homebrew to all source files
        touch "/root/.zshrc"
        for file in $files; do
            [ ! -f "${file}" ] && continue
            echo "" >> "${file}"
            echo "eval \"${brew_shellenv}\"" >> "${file}"
        done

        # Add Homebrew to current session
        eval "${brew_shellenv}"

        # Install gcc if missing
        if ! command -v gcc >/dev/null 2>&1; then
            brew install gcc >/dev/null 2>&1 || {
                printStyled error "Unable to install ${ORANGE}gcc${NONE}"
                return 1
            }
        fi
        printStyled success "Configured: ${GREEN}Linuxbrew${NONE}"
    fi

    # Check install
    if ! command -v brew >/dev/null 2>&1; then
        printStyled error "Unable to install ${ORANGE}Homebrew${NONE}"
        return 1
    fi
    
    # Success
    printStyled success "Installed: ${GREEN}Homebrew${NONE}"
}

# Installs Homebrew dependencies
install_brew_deps() {

    # TODO: macOS default package manager ?
    
    # Depending on current package manager
    default_deps="file git curl bash zsh coreutils jq"
    if command -v brew >/dev/null 2>&1; then
        package_manager="brew"
        step_1="brew install coreutils"
        step_2="brew install jq"
    elif command -v apt >/dev/null 2>&1; then
        package_manager="apt"
        step_1="${SUDO}apt-get update -y"
        step_2="${SUDO}apt-get install -y build-essential procps ${default_deps}"
        cmd="${step_1} && ${step_2}"
    elif command -v dnf >/dev/null 2>&1; then
        if dnf --version 2>/dev/null | grep -q "5\."; then
            package_manager="dnf v5"
            step_1="${SUDO}dnf install -y @development-tools"
        else
            package_manager="dnf v4"
            step_1="${SUDO}dnf group install -y \"Development Tools\""
        fi
        step_2="${SUDO}dnf install -y procps-ng ${default_deps} gawk"
        cmd="${step_1} && ${step_2}"
    elif command -v zypper >/dev/null 2>&1; then
        package_manager="zypper"
        step_1="${SUDO}zypper refresh"
        step_2="${SUDO}zypper install -y -t pattern devel_basis && ${SUDO}zypper install -y procps ${default_deps} gzip ruby"
        cmd="${step_1} && ${step_2}"
    elif command -v apk >/dev/null 2>&1; then
        package_manager="apk"
        step_1="${SUDO}apk update"
        step_2="${SUDO}apk add --no-cache build-base procps ${default_deps}"
        cmd="${step_1} && ${step_2}"
    elif command -v pacman >/dev/null 2>&1; then
        package_manager="pacman"
        cmd="${SUDO}pacman -Sy --noconfirm base-devel procps-ng ${default_deps}"
    elif command -v yum >/dev/null 2>&1; then
        printStyled error "Unsupported package manager: ${ORANGE}yum${RED} (git ≥ 2.7.0 not available)"
        return 1
    else
        printStyled error "No supported package manager found"
        return 1
    fi


    printStyled info_tbd "Current package manager: ${ORANGE}${package_manager}${NONE}"
    printStyled wait "Installing Homebrew dependencies → ${ORANGE}${EMOJI_WARN}  This may take a while, please wait...${NONE}"
    eval "${cmd}" >/dev/null 2>&1 || {
        printStyled error "Unable to install Homebrew dependencies"
        return 1
    }

    # Success
    printStyled success "Installed: ${GREEN}Homebrew dependencies${NONE}"
}

# ────────────────────────────────────────────────────────────────
# INSTALL GACLI
# ────────────────────────────────────────────────────────────────

# Retrieves GACLI source (curl, wget or git) into the installer directory, honouring --force
download_gacli() {

    # Log
    printStyled wait "Downloading GACLI..."

    # Delete previous install if --force, else abort
    if [ -d "${DIR_GACLI}" ]; then
        if [ "${FORCE_MODE}" = "true" ]; then
            rm -rf "${DIR_GACLI}"
        else
            printStyled error "Gacli already installed. Use --force to overwrite"
            return 1
        fi
    fi

    # Download all repo in tmp folder
    curl -fsSL "${URL_ARCHIVE}" | tar -xzf - -C "${DIR_TMP}" --strip-components=1 >/dev/null 2>&1 || {
        printStyled error "Download failed"
        return 1
    }

    # Copy source files
    mv "${DIR_TMP_SRC}" "${DIR_GACLI}" || {
        printStyled error "Unable to move files into: ${DIR_GACLI}"
        return 1
    }

    printStyled success "Downloaded: ${GREEN}GACLI${NONE}"
}

# Runs brew bundle on the downloaded BREWFILE_TMP to install required formulae and casks
install_gacli_deps() {

    # Log
    printStyled wait "Installing GACLI dependencies..."

    # Check Brewfile integrity
    [ -f "${BREWFILE_TMP}" ] || {
        printStyled error "Unable to find dependencies descriptor at: ${CYAN}${BREWFILE_TMP}${NONE}"
        return 1
    }

    # Check Homebrew install
    command -v brew >/dev/null 2>&1 || {
        printStyled error "Unable to find ${ORANGE}Homebrew${NONE}"
        return 1     
    }

    # Install dependencies
    brew bundle --file="${BREWFILE_TMP}" || { # >/dev/null 2>&1
        printStyled error "Failed to install dependencies with ${ORANGE}Homebrew${NONE}"
        return 1
    }

    # Log
    printStyled success "Installed: ${GREEN}GACLI dependencies${NONE}"
}

# Adds execute permission to the downloaded GACLI entry‑point script
make_executable() {
    chmod +x "${FILE_ENTRY_POINT}" || {
        printStyled warning "Failed to make ${CYAN}${FILE_ENTRY_POINT}${YELLOW} executable"
        return 1
    }
    printStyled success "Entry point: ${GREEN}executable${NONE}"
}

# Generates a wrapper in $HOME/.local/bin that relays args to the entry point via zsh
create_wrapper() {

    # Create symlink dir if missing
    mkdir -p "${SYM_DIR}" || {
        printStyled warning "Failed to create ${CYAN}${SYM_DIR}${NONE}"; return 1
    }

    # Delete symlink if already exists
    if [ -f "${SYMLINK}" ] || [ -d "${SYMLINK}" ] || [ -L "${SYMLINK}" ]; then
        rm -f "${SYMLINK}"
    fi

    # Create symlink
    {
        printf '%s\n' '#!/usr/bin/env sh'
        printf '%s\n' "exec \"$(command -v zsh)\" \"${FILE_ENTRY_POINT}\" \"\$@\""
    } > "${SYMLINK}" && chmod +x "${SYMLINK}" || {
        printStyled warning "Failed to create ${ORANGE}wrapper${NONE}"; return 1
    }

    # Success
    printStyled success "Wrapper: ${GREEN}created${GREY} → ${CYAN}${SYMLINK}${GREY} → ${CYAN}${FILE_ENTRY_POINT}${NONE}"
}

# Appends PATH export and source command to the user’s .zshrc when missing
update_zshrc() {

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
        printf 'export PATH="%s:$PATH"\n' "${SYM_DIR}"
        printf 'source "%s"\n' "${FILE_ENTRY_POINT}"
    } >> "${FILE_ZSHRC}" || {
        printStyled warning "Failed update ${FILE_ZSHRC}"; return 1
    }
    printStyled success "Zsh: ${GREEN}configured${NONE}"
}

# Deletes installer and temporary files
cleanup() {

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
    cd "${dir}" >/dev/null 2>&1 || return 1
    abs_dir="$(pwd -P)" || return 1
    installer="${abs_dir}/${base}"

    # Delete installer
    [ -f "${installer}" ] && rm -f "${installer}"

    # Delete temporary files
    [ -d "${DIR_TMP}" ] && rm -rf "${DIR_TMP}"

    # Log
    printStyled success "Cleanup: ${GREEN}completed${NONE}"
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

# Displays success message and either execs a new zsh or prompts the user to reopen a shell
# TODO: add --no-launch option to avoid auto_launch for test purposes
auto_launch() {
    echo ""
    printStyled success "${GREEN}GACLI successfully installed${NONE} 🚀"
    echo ""
    if command -v zsh >/dev/null 2>&1; then
        printStyled info "Reloading shell..."
        exec zsh
    else
        printStyled error "Missing dependencie: ${ORANGE}zsh${NONE}"
        echo ""
        return 1
    fi
}


main "$@"

