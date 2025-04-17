#!/usr/bin/env sh
###############################
# FICHIER /.auto-install/install.sh
###############################

# Options
FORCE_MODE="false"

# OS variables
IS_MACOS=false
IS_LINUX=false

# GACLI urls
REPO="https://github.com/guillaumeast/gacli"
# ARCHIVE="${REPO}/archive/refs/heads/main.tar.gz"
ARCHIVE="${REPO}/archive/refs/heads/dev.tar.gz"

# GACLI paths
DIR=".gacli"
ENTRY_POINT=".run/gacli.zsh"
ZSHRC=".zshrc"

# SYMLINK
SYM_DIR=".local/bin"
SYMLINK="gacli"

# Tools
CLIENTS="curl wget git"
HTTP_CLIENT=""

# Colors
RED="$(printf '\033[31m')"
GREEN="$(printf '\033[32m')"
YELLOW='\033[33m'
ORANGE="$(printf '\033[38;5;208m')"
GREY="$(printf '\033[90m')"
NONE="$(printf '\033[0m')"
BOLD="$(printf '\033[1m')"

# Emojis (swicthed to emojis if system supports unicode)
EMOJI_SUCCESS="[OK]"
EMOJI_WARN="[!]"
EMOJI_ERR="[X]"
EMOJI_INFO="[i]"
EMOJI_HIGHLIGHT="=>"
EMOJI_DEBUG="[???]"
EMOJI_WAIT="..."

# ────────────────────────────────────────────────────────────────
# PSEUDO-CODE
# ────────────────────────────────────────────────────────────────

# main()
# |→ check_env                  → Checks env:
# |     |→ ✅ check_env                 → Detect environment: OS, package manager and default shell
# |     |→ ✅ init_style                → Enable emojis if system can handle it + welcome message
# |     |→ ✅ parse_args                → Inits global variables referring to given args
# |     |→ ✅ resolve_paths             → Resolve relative paths to absolute paths
# |→ setup_env                  → Setup required tools:
# |     |→ ✅ install_brew              → Try to install Homebrew (for downloading further dependencies)
# |     |→ ✅ install_zsh               → Install zsh via package manager or add to Brewfile if available as a formula/cask
# |→ download_gacli             → Download GACLI files from Github:
# |     |→ ✅ download_gacli            → Download GACLI files from Github
# |     |→ ✅ install_deps              → Install GACLI dependencies from "${DIR}/.auto-install/Brewfile"
# |→ install_gacli              → Execute GACLI installation steps:
# |     |→ ✅ make_executable           → Ensure GACLI entry point is executable
# |     |→ ✅ create_wrapper            → Generate a small shell script to launch GACLI reliably across shells
# |     |→ ✅ update_zshrc              → Append GACLI to PATH and source its entry point in ~/.zshrc
# |→ ✅ auto_launch             → Launch GACLI

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

main() {
    
    # Check env
    check_env || exit 01            # Detect environment: OS, package manager and default shell
    init_style                      # Enable emojis if system can handle it + welcome message
    parse_args "$@" || exit 02      # Inits global variables referring to given args
    resolve_paths || exit 03        # Resolve relative paths to absolute paths

    # Install dependencies
    echo ""
    printStyled info "Installing dependencies... ${EMOJI_WAIT}"
    install_brew || exit 04         # Needed to install gacli dependencies
    install_zsh || exit 05          # Needed to run GACLI

    # Download GACLI
    echo ""
    printStyled info "Downloading GACLI into \"${DIR}\"... ${EMOJI_WAIT}"
    download_gacli || exit 06       # Clone GACLI repo
    install_deps || exit 07         # Install gacli dependencies

    # Install GACLI
    echo ""
    printStyled info "Installing GACLI... ${EMOJI_WAIT}" 
    make_executable || exit 08      # Make GACLI entry point executable
    create_wrapper || exit 09       # Create a wrapper to enable gacli commands (avoid symlink's shell env corruption)
    update_zshrc || exit 10         # Add GACLI to path and auto-source it

    # Launch GACLI
    auto_launch || exit 11          # Launch GACLI after install (only if shell is zsh)
}

# ────────────────────────────────────────────────────────────────
# CHECK ENV
# ────────────────────────────────────────────────────────────────

# Detect environment: OS, package manager and default shell
check_env() {

    # Detect OS
    if [ -z "$OSTYPE" ]; then
        printStyled error "[check_env] Error: OSTYPE is not set"
        return 1
    fi
    case "$OSTYPE" in
        darwin*)
            IS_MACOS=true
            IS_LINUX=false
            ;;
        linux*)
            IS_LINUX=true
            IS_MACOS=false
            ;;
        *)
            printStyled error "[check_env] Error: Unsupported OS: $OSTYPE"
            return 1
            ;;
    esac
    printStyled success "OS detected: $OSTYPE"

    # Detect package manager
    if command -v brew >/dev/null 2>&1; then
        PACKAGE_MANAGER="brew"
        printStyled success "Package manager: Homebrew"
    elif command -v apt >/dev/null 2>&1; then
        PACKAGE_MANAGER="apt"
        printStyled success "Package manager: apt"
    elif command -v dnf >/dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
        printStyled success "Package manager: dnf"
    elif command -v pacman >/dev/null 2>&1; then
        PACKAGE_MANAGER="pacman"
        printStyled success "Package manager: pacman"
    else
        PACKAGE_MANAGER=""
        printStyled warning "[check_env] Warning: No supported package manager found"
    fi

    # 4) Detect default shell
    SHELL_PATH=${SHELL:-$(command -v sh)}
    SHELL_NAME=$(basename "$SHELL_PATH")
    printStyled success "Default shell: ${SHELL_NAME} (${SHELL_PATH})"

    # Detect http client
    for client in $CLIENTS; do
        if command -v "${client}" > /dev/null 2>&1; then
            HTTP_CLIENT="${client}"
            printStyled success "${client} detected"
        fi
    done

    # No http client found
    if [ -z "${HTTP_CLIENT}" ]; then
        printStyled error "[check_env] Unable to find curl, wget or git for downloading"
        return 1
    fi
}

# Display ASCII art logo
init_style() {
    printf "%s\n" "${ORANGE}  _____          _____ _      _____ ${NONE}"
    printf "%s\n" "${ORANGE} / ____|   /\\\\   / ____| |    |_   _|${NONE}"
    printf "%s\n" "${ORANGE}| |  __   /  \\\\ | |    | |      | |  ${NONE}"
    printf "%s\n" "${ORANGE}| | |_ | / /\\\\ \\\\| |    | |      | |  ${NONE}"
    printf "%s\n" "${ORANGE}| |__| |/ ____ \\\\ |____| |____ _| |_ ${NONE}"
    printf "%s\n" "${ORANGE} \\\\_____/_/    \\\\_\\\\_____|______|_____|${NONE}"
    printf "%s\n" ""

    # Check if locale supports unicode
    if locale charmap | grep -iq "utf"; then
        EMOJI_SUCCESS="✦"
        EMOJI_WARN="⚠️"
        EMOJI_ERR="❌"
        EMOJI_INFO="✧"
        EMOJI_HIGHLIGHT="👉"
        EMOJI_DEBUG="🔎"
        EMOJI_WAIT="⏳"
        printStyled success "Emojis enabled"
    else
        printStyled info "[enable_emojis] Unicode unsupported, emojis disabled for compatibility"
    fi
}

# Display formatted message
printStyled() {
    # Variables
    style=$1
    raw_message=$2
    final_message=""
    color=$NONE

    # Argument check
    if [ -z "$style" ] || [ -z "$raw_message" ]; then
        printStyled error "Veuillez fournir un ${YELLOW}style${RED} et un ${YELLOW}message${RED} pour afficher du texte"
        return 1
    fi

    # Formatting
    case "$style" in
        error)
            printf "%s\n" "${RED}${BOLD}${EMOJI_ERR} ${raw_message}${NONE}" >&2
            return
            ;;
        warning)
            printf "%s\n" "${YELLOW}${BOLD}${EMOJI_WARN}  ${raw_message}${NONE}" >&2
            return
            ;;
        success)
            color=$GREEN
            final_message="${EMOJI_SUCCESS} ${raw_message}"
            ;;
        info)
            color=$GREY
            final_message="${EMOJI_INFO} ${raw_message}"
            ;;
        highlight)
            color=$NONE
            final_message="${EMOJI_DEBUG} ${raw_message}"
            ;;        
        debug)
            color=$YELLOW
            final_message="🔦 ${BOLD}${raw_message}${NONE}"
            ;;
        *)
            color=$NONE
            final_message="${raw_message}"
            ;;
    esac

    # Display
    printf "%s\n" "${color}$final_message${NONE}"
}

# Parse arguments
parse_args() {
    for arg in "$@"; do
        case "$arg" in
            --force)
                # Enable force mode
                FORCE_MODE="true"
                ;;
            *)
                printStyled error "[GACLI] Error: Unknown option [${arg}]"
                return 1
                ;;
        esac
    done

    # Display success
    printStyled success "Arguments parsed"
}

# Resolve paths
resolve_paths() {

    # Check if $HOME is set
    if [ -z "${HOME}" ] || [ ! -d "${HOME}" ]; then
        printStyled error "[GACLI] Error: \$HOME is not set or invalid"
        return 1
    fi

    # Resolve paths
    DIR="${HOME}/${DIR}"
    ENTRY_POINT="${DIR}/${ENTRY_POINT}"
    ZSHRC="${HOME}/${ZSHRC}"
    SYM_DIR="${HOME}/${SYM_DIR}"
    SYMLINK="${SYM_DIR}/${SYMLINK}"

    # Check .zshrc path
    while [ -z "${ZSHRC}" ] || [ ! -f "${ZSHRC}" ]; do
        printStyled warning ".zshrc not found at ${ZSHRC}"
        printStyled highlight "Please provide the correct path to your .zshrc file:"
        printf "> "
        read ZSHRC
    done

    # Display success
    printStyled success "Paths resolved"
}

# ────────────────────────────────────────────────────────────────
# SETUP ENV
# ────────────────────────────────────────────────────────────────

# Install Homebrew if missing
install_brew() {
    # Check if brew is already installed
    if command -v brew >/dev/null 2>&1; then
        printStyled success "Homebrew detected"
        return 0
    fi

    # Only macOS or Linux are supported
    if [ "$IS_MACOS" != true ] && [ "$IS_LINUX" != true ]; then
        printStyled error "[install_brew] Unsupported OS: $OSTYPE"
        return 1
    fi

    # Choose download tool: curl or wget
    if command -v curl >/dev/null 2>&1; then
        downloader="curl -fsSL"
    elif command -v wget >/dev/null 2>&1; then
        downloader="wget -qO-"
    else
        printStyled error "[install_brew] curl or wget required to download Homebrew."
        return 1
    fi

    install_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

    # Download and run the Homebrew installer
    if [ "$IS_LINUX" = true ]; then
        printStyled info "Installing Homebrew non-interactively..."
        if ! { NONINTERACTIVE=1 $downloader "$install_url" | /bin/bash; }; then
            printStyled error "[install_brew] Homebrew installation failed"
            return 1
        fi
    else
        printStyled info "Installing Homebrew..."
        if ! { $downloader "$install_url" | /bin/bash; }; then
            printStyled error "[install_brew] Homebrew installation failed"
            return 1
        fi
    fi

    # Initialize Homebrew in the current shell environment
    if command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"; then
        # Refresh the shell command lookup hash
        hash -r 2>/dev/null || true
        printStyled success "Homebrew installed and initialized"
        return 0
    fi

    printStyled error "[install_brew] Failed to configure Homebrew environment"
    return 1
}

# Install zsh if missing
install_zsh() {
    # Check if zsh is already installed
    if command -v zsh >/dev/null 2>&1; then
        printStyled success "zsh detected"
        return 0
    fi

    # Determine installation command based on detected package manager
    case "$PACKAGE_MANAGER" in
        brew)
            install_cmd="brew install zsh"
            ;;
        apt)
            install_cmd="sudo apt-get update && sudo apt-get install -y zsh"
            ;;
        dnf)
            install_cmd="sudo dnf install -y zsh"
            ;;
        pacman)
            install_cmd="sudo pacman -Sy --noconfirm zsh"
            ;;
        *)
            printStyled error "[install_zsh] No supported package manager found"
            return 1
            ;;
    esac

    # Install zsh
    printStyled info "Installing zsh..."
    if ! eval "$install_cmd"; then
        printStyled error "[install_zsh] zsh installation failed"
        return 1
    fi

    # Success
    printStyled success "zsh installed"
    return 0
}

# ────────────────────────────────────────────────────────────────
# DOWNLOAD
# ────────────────────────────────────────────────────────────────

# Download GACLI (curl → wget → git fallback)
download_gacli() {
    # If the target directory already exists…
    if [ -d "${DIR}" ]; then
        if [ "${FORCE_MODE}" = "true" ]; then
            printStyled info "Removing existing GACLI directory at ${DIR}..."
            rm -rf "${DIR}" \
                || { printStyled error "[GACLI] Error: Failed to remove ${DIR}"; return 1; }
        else
            printStyled error "[GACLI] Error: ${DIR} already exists. Use --force to overwrite."
            return 1
        fi
    fi

    case "${HTTP_CLIENT}" in
        curl)
            printStyled info "Downloading and extracting GACLI archive with curl..."
            # Create target directory
            mkdir -p "${DIR}" \
                || { printStyled error "[GACLI] Error: Failed to create directory ${DIR}"; return 1; }
            # Stream the tarball from GitHub and extract, stripping top‑level folder
            if ! curl -fSL "${ARCHIVE}" | tar -xzf - -C "${DIR}" --strip-components=1; then
                printStyled error "[GACLI] Error: Failed to download or extract archive with curl"
                return 1
            fi
            ;;
        wget)
            printStyled info "Downloading and extracting GACLI archive with wget..."
            # Create target directory
            mkdir -p "${DIR}" \
                || { printStyled error "[GACLI] Error: Failed to create directory ${DIR}"; return 1; }
            # Stream the tarball from GitHub and extract, stripping top‑level folder
            if ! wget -qO - "${ARCHIVE}" | tar -xzf - -C "${DIR}" --strip-components=1; then
                printStyled error "[GACLI] Error: Failed to download or extract archive with wget"
                return 1
            fi
            ;;
        git)
            # Fallback to git clone: extract branch name from ARCHIVE (e.g. "dev.tar.gz" → "dev")
            branch="${ARCHIVE##*/}"
            branch="${branch%.tar.gz}"
            printStyled info "Cloning branch ${branch} from ${REPO} with git..."
            if ! git clone --depth 1 --branch "${branch}" "${REPO}" "${DIR}"; then
                printStyled error "[GACLI] Error: Failed to clone repository"
                return 1
            fi
            ;;
        *)
            printStyled error "[GACLI] Error: Unsupported HTTP client: ${HTTP_CLIENT}"
            return 1
            ;;
    esac

    printStyled success "GACLI installed into ${DIR}"
}

# ────────────────────────────────────────────────────────────────
# INSTALL
# ────────────────────────────────────────────────────────────────

# Brew bundle from gacli/.auto-install/Brewfile
install_deps() {
    # Path to the Brewfile shipped with GACLI
    brewfile="${DIR}/.auto-install/Brewfile"

    # Only proceed if Homebrew is available and the Brewfile exists
    if command -v brew >/dev/null 2>&1 && [ -f "${brewfile}" ]; then
        printStyled info "Installing dependencies from Brewfile..."
        # Run brew bundle in the current environment
        if ! brew bundle --file="${brewfile}"; then
            printStyled error "[install_deps] Failed to install dependencies from Brewfile"
            return 1
        fi
        printStyled success "Dependencies installed"
        return 0
    fi

    # Fallback: no Brewfile or no brew => skip
    printStyled warning "[install_deps] Brewfile not found or Homebrew unavailable, skipping dependencies"
    return 0
}

# Make main script executable
make_executable() {
    # Check if ENTRY_POINT is executable
    if ! chmod +x "${ENTRY_POINT}"; then
        printStyled error "[make_executable] Failed to make ${ENTRY_POINT} executable"
        return 1
    fi
    printStyled success "GACLI has been made executable"
    return 0
}

# Create executable wrapper script for GACLI (instead of symlink for cross-shell compatibility)
create_wrapper() {
    # Create bin folder if needed
    sym_dir="$(dirname "${SYMLINK}")"
    if ! mkdir -p "${sym_dir}"; then
        printStyled error "[create_wrapper] Failed to create ${sym_dir}"
        return 1
    fi

    # Remove previous symlink or file if exists
    if [ -e "${SYMLINK}" ] || [ -L "${SYMLINK}" ]; then
        rm -f "${SYMLINK}" || {
            printStyled warning "[create_wrapper] Failed to delete existing file at ${SYMLINK}"
        }
    fi

    # Create executable wrapper
    if ! {
        echo '#!/bin/sh' > "${SYMLINK}" &&
        echo "exec zsh \"${ENTRY_POINT}\" \"\$@\"" >> "${SYMLINK}" &&
        chmod +x "${SYMLINK}"
    }; then
        printStyled error "[create_wrapper] Failed to create wrapper script at ${SYMLINK}"
        return 1
    fi

    printStyled success "Wrapper created: ${SYMLINK} → ${ENTRY_POINT}"
    return 0
}

# Update ~/.zshrc to include GACLI in PATH and source gacli.zsh
update_zshrc() {
    # Don’t re-add if already present
    if grep -q '# GACLI' "${ZSHRC}"; then
        printStyled success ".zshrc already configured"
        return 0
    fi

    # Append GACLI block
    {
        echo ""
        echo "# GACLI"
        echo "export PATH=\"${SYM_DIR}:\$PATH\""
        echo "source \"${ENTRY_POINT}\""
    } >> "${ZSHRC}" || {
        printStyled error "[update_zshrc] Failed to update ${ZSHRC}"
        return 1
    }

    printStyled success ".zshrc updated"
    return 0
}

# Launch GACLI after install (only if shell is zsh)
auto_launch() {
    echo ""
    printStyled success "GACLI installed! 🚀"
    echo ""

    # Only re‑exec into zsh if we’re already in zsh
    if [ -n "${ZSH_VERSION}" ]; then
        printStyled info "Reloading shell environment... ${EMOJI_WAIT}"
        echo ""
        exec zsh
    else
        printStyled warning "Open a new terminal window or run: exec zsh"
        echo ""
    fi
    return 0
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

main "$@"

