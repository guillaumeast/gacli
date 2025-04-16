###############################
# FICHIER /.install/install.zsh
###############################

#!/usr/bin/env zsh

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
# TODOs
# ────────────────────────────────────────────────────────────────

# TODO: converti in full macOS/Linux POSIX compatible ".sh" script
# TODO: update code to be be as described above :

# ────────────────────────────────────────────────────────────────
# PSEUDO-CODE
# ────────────────────────────────────────────────────────────────

# main()
# |→ check_env                  → Checks env
# |     |→ check_os                 → Checks if OS is supported
# |     |→ enable_emojis            → Checks if emojis are supported
# |     |→ parse_args               → Inits global variables referring to given args
# |     |→ resolve_paths            → Resolves absolute paths
# |→ display_start              → Displays welcome message
# |     |→ display_ascii_logo       → Displays ascii art style logo
# |     |→ prinstyled               → Displays waiting message
# |→ setup_env                  → Setup required tools
# |     |→ check_curl               → Firt try: curl (macOS)
# |     |→ check_wget               → Fallback: wget (Linux)
# |     |→ check_zsh                → Try to install zsh for running GACLI (TODO: store in config file if it's a formulae / cask)
# |     |→ check_brew               → Try to install Homebrew (for downloading further dependencies)
# |→ prinstyled                 → Displays waiting message
# |→ download_gacli             → Download GACLI files from Github
# |     |→ download_gacli           → Download GACLI files from Github
# |     |→ brew_bundle                → Install GACLI dependencies from "${DIR}/.data/dependencies/core.Brewfile" (temporary rename it "Brewfile" if needed)
# |→ prinstyled                 → Displays success message
# |→ auto_launch                → Launch GACLI

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

main() {
    
    # Check env compatibility
    check_os || exit 01             # Linux and macOS are supported (Windows is NOT supported)
    enable_emojis                   # Enable emojis if system can handle it
    
    # Init
    display_ascii_logo
    printStyled info "Initializing... ${EMOJI_WAIT}"
    parse_args "$@" || exit 02      # Parse args and set command relative variables
    resolve_paths || exit 03        # Resolve relative paths to absolute paths
    check_zsh || exit 04            # Needed to run GACLI

    # Install dependencies
    echo ""
    printStyled info "Installing dependencies... ${EMOJI_WAIT}"
    curl_install || wget_install || git_install || exit 05
    brew_install || exit 07         # Needed to install coreutils
    coreutils_install || exit 08    # Needed for cross-platform compatibility

    # Configure GACLI
    echo ""
    printStyled info "Installing GACLI into \"${DIR}\"... ${EMOJI_WAIT}"
    gacli_download || exit 09       # Clone GACLI repo
    make_executable || exit 10      # Make GACLI entry point executable
    create_wrapper || exit 11       # Create a wrapper to enable gacli commands (avoid symlink's shell env corruption)
    update_zshrc || exit 12         # Add GACLI to path and auto-source it

    # Done
    auto_launch                     # Launch GACLI after install (only if shell is zsh)
}

# ────────────────────────────────────────────────────────────────
# Functions - INIT
# ────────────────────────────────────────────────────────────────

# Detect the operating system and set the corresponding flags
check_os() {

    # Check if $OSTYPE is set
    if [[ -z "$OSTYPE" ]]; then
        echo "[check_os] Error: \$OSTYPE is not set" >&2
        return 1
    fi

    # Check if current OS is supported
    case "$OSTYPE" in
        darwin*) IS_MACOS=true ;;
        linux*)  IS_LINUX=true ;;
        *)
            echo "[check_os] Error: Unknown OS type: ${OSTYPE}" >&2
            return 1
            ;;
    esac
    
    # Display success
    printStyled success "OS supported: ${OSTYPE}"
}

# TODO
enable_emojis() {
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

# Check if zsh is installed
check_zsh() {

    # Check
    if ! command -v zsh >/dev/null 2>&1; then
        printStyled error "[GACLI] Error: zsh is not installed"
        echo ""
        printStyled highlight "Please install zsh manually before continuing"
        printStyled info "macOS : already available, enable it via System Preferences > Shell"
        printStyled info "Linux : sudo apt install zsh   # or your distro equivalent"
        echo ""
        return 1
    fi

    # Display success
    printStyled success "Zsh detected"
}

# ────────────────────────────────────────────────────────────────
# Functions - DEPENDENCIES
# ────────────────────────────────────────────────────────────────

# Install curl
curl_install() {
    printStyled debug "-------------------"
    printStyled debug "[CURL] Checking..."

    # Check
    if ! command -v curl >/dev/null 2>&1; then
        printStyled debug "[CURL] ---> Not installed"

        printStyled highlight "Installing curl (your password may be asked)... ${EMOJI_WAIT}"

        # Try auto-install
        printStyled debug "[CURL] Trying to install..."
        if [ "$IS_MACOS" = true ]; then
            printStyled debug "[CURL] Running 'brew install curl'..."
            if brew install curl; then
                printStyled success "Curl installed"
                return 0
            fi
            printStyled debug "[CURL] ---> Failed"
        elif [ "$IS_LINUX" = true ]; then
            if command -v apt >/dev/null 2>&1; then
                printStyled debug "[CURL] Running 'sudo apt install curl'..."
                if sudo apt install curl; then
                    printStyled success "Curl installed"
                    return 0
                fi
                printStyled debug "[CURL] ---> Failed"
            elif command -v dnf >/dev/null 2>&1; then
                printStyled debug "[CURL] Running 'sudo dnf install curl'..."
                if sudo dnf install curl; then
                    printStyled success "Curl installed"
                    return 0
                fi
                printStyled debug "[CURL] ---> Failed"
            elif command -v pacman >/dev/null 2>&1; then
                printStyled debug "[CURL] Running 'sudo pacman -S curl'..."
                if sudo pacman -S curl; then
                    printStyled success "Curl installed"
                    return 0
                fi
                printStyled debug "[CURL] ---> Failed"
            fi
        fi

        # Manual fallback
        printStyled error "[GACLI] Error: curl is not installed"
        echo ""
        printStyled highlight "Please install curl manually before continuing"
        printStyled info "macOS : brew install curl"
        printStyled info "Linux : Use your package manager"
        echo ""
        return 1
    fi

    # Display success
    printStyled success "Curl detected"
}

# Install wget
wget_install() {
    printStyled debug "-------------------"
    printStyled debug "[WGET] Checking..."

    # Check
    if ! command -v wget >/dev/null 2>&1; then
        printStyled debug "[WGET] ---> Not installed"

        printStyled highlight "Installing wget (your password may be asked)... ${EMOJI_WAIT}"

        # Try auto-install
        printStyled debug "[WGET] Trying to install..."
        if [ "$IS_MACOS" = true ]; then
            printStyled debug "[WGET] Running 'brew install wget'..."
            if brew install wget; then
                printStyled success "wget installed"
                return 0
            fi
            printStyled debug "[WGET] ---> Failed"
        elif [ "$IS_LINUX" = true ]; then
            if command -v apt >/dev/null 2>&1; then
                printStyled debug "[WGET] Running 'sudo apt install wget'..."
                if sudo apt install wget; then
                    printStyled success "wget installed"
                    return 0
                fi
                printStyled debug "[WGET] ---> Failed"
            elif command -v dnf >/dev/null 2>&1; then
                printStyled debug "[WGET] Running 'sudo dnf install wget'..."
                if sudo dnf install wget; then
                    printStyled success "wget installed"
                    return 0
                fi
                printStyled debug "[WGET] ---> Failed"
            elif command -v pacman >/dev/null 2>&1; then
                printStyled debug "[CURL] Running 'sudo pacman -S wget'..."
                if sudo pacman -S wget; then
                    printStyled success "wget installed"
                    return 0
                fi
                printStyled debug "[WGET] ---> Failed"
            fi
        fi

        # Manual fallback
        printStyled warning "[GACLI] Unable to install wget"
        return 1
    fi

    # Display success
    printStyled success "wget detected"
}

# Install git
git_install() {

    # Check
    if ! command -v git >/dev/null 2>&1; then

        printStyled highlight "Installing git (your password may be asked)... ${EMOJI_WAIT}"

        # Try auto-install
        if [ "$IS_MACOS" = true ]; then
            if xcode-select --install; then
                printStyled success "Git installed"
                return 0
            fi
        elif [ "$IS_LINUX" = true ]; then 
            if command -v apt >/dev/null 2>&1; then
                if sudo apt install git; then
                    printStyled success "Git installed"
                    return 0
                fi
            elif command -v dnf >/dev/null 2>&1; then
                if sudo dnf install git; then
                    printStyled success "Git installed"
                    return 0
                fi
            elif command -v pacman >/dev/null 2>&1; then
                if sudo pacman -S git; then
                    printStyled success "Git installed"
                    return 0
                fi
            fi
        fi

        # Manual fallback
        printStyled error "[GACLI] Error: git is not installed"
        echo ""
        printStyled highlight "Please install git manually before continuing"
        printStyled info "macOS : xcode-select --install"
        printStyled info "Linux : Use your package manager"
        echo ""
        return 1
    fi

    # Display success
    printStyled success "Git detected"
}

# Install Homebrew
brew_install() {

    # Check if Homebrew is already installed
    if command -v brew >/dev/null 2>&1; then
        printStyled success "Homebrew detected"
        return 0
    fi

    # Compute Homebrew install command
    local install_cmd="/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    if $IS_MACOS || $IS_LINUX; then
        if $IS_LINUX; then
            install_cmd="NONINTERACTIVE=1 ${install_cmd}"
        fi
    else
        echo "${EMOJI_ERR} [brew_install] Unsupported OS: ${OSTYPE}"
        return 1
    fi

    # Install Homebrew
    if ! eval "$install_cmd"; then
        echo "${EMOJI_ERR} [brew_install] Homebrew installation failed"
        return 1
    fi

    # Add Homebrew to PATH
    local brew_exec_path
    if ! brew_exec_path="$(command -v brew)"; then
        echo "${EMOJI_ERR} [brew_install] Failed to detect brew after installation"
        return 1
    fi

    if ! eval "$("$brew_exec_path" shellenv)"; then
        echo "${EMOJI_ERR} [brew_install] Failed to set Homebrew environment"
        return 1
    fi

    # Refresh hashmap command table
    if ! hash -r; then
        echo "${EMOJI_ERR} [brew_install] Failed to refresh shell hash table"
    fi

    # Display success
    printStyled success "Homebrew installed"
}

# Install coreutils
coreutils_install() {

    # Check if Coreutils is already installed
    if command -v gdate >/dev/null 2>&1; then
        printStyled success "Coreutils detected"
        return 0
    fi

    # Install coreutils
    printStyled info "coreutils not found → installing with Homebrew..."
    if brew install coreutils; then
        printStyled success "Coreutils installed"
    else
        printStyled error "Failed to install coreutils"
        return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# Functions - GACLI INSTALL
# ────────────────────────────────────────────────────────────────

# Download GACLI (curl + fallback git)
gacli_download() {

    # Check if GACLI is already installed
    if [ -d "${DIR}" ]; then
        if [ "$FORCE_MODE" = "true" ]; then
            rm -rf "${DIR}"
        else
            printStyled error "[GACLI] Error: already installed at ${DIR}"
            printStyled highlight "Use --force to overwrite"
            return 1
        fi
    fi

    # Try download archive
    local tmp_archive="$(mktemp)"
    if curl -fsSL "${ARCHIVE}" -o "${tmp_archive}"; then
        mkdir -p "${DIR}" || {
            echo "${EMOJI_ERR} [GACLI] Failed to create directory: ${DIR}"
            rm -f "${tmp_archive}"
            return 1
        }

        if tar -xzf "${tmp_archive}" --strip-components=1 -C "${DIR}"; then
            rm -f "${tmp_archive}"
            echo "${GREEN}${EMOJI_SUCCESS} GACLI downloaded (via archive)${NONE}"
            return 0
        else
            echo "${EMOJI_WARN} [GACLI] Failed to extract archive"
            rm -f "${tmp_archive}"
        fi
    else
        echo "${EMOJI_WARN} [GACLI] Failed to download archive"
    fi

    # Fallback to git clone
    echo "${EMOJI_INFO} Trying fallback: git clone... ${EMOJI_WAIT}"
    if git clone "${REPO}" "${DIR}" > /dev/null 2>&1; then
        echo "${GREEN}${EMOJI_SUCCESS} GACLI downloaded (via git)${NONE}"
        return 0
    fi

    echo "${EMOJI_ERR} [GACLI] Error: Failed to download GACLI (both archive and git failed)"
    return 1
}

# Make main script executable
make_executable() {
    if ! chmod +x "${ENTRY_POINT}"; then
        printStyled error "[GACLI] Error: Failed to make ${ENTRY_POINT} executable"
        return 1
    fi

    # Display success
    printStyled success "GACLI has been made executable"
}

# Create executable wrapper script for GACLI (instead of symlink for cross-shell compatibility)
create_wrapper() {

    # Create bin folder if needed
    local sym_dir="$(dirname "${SYMLINK}")"
    if ! mkdir -p "${sym_dir}"; then
        printStyled error "[GACLI] Error: Failed to create ${sym_dir}"
        return 1
    fi

    # Remove previous symlink or file if exists
    if [[ -e "${SYMLINK}" || -L "${SYMLINK}" ]]; then
        rm -f "${SYMLINK}" || {
            printStyled warning "[GACLI] Failed to delete existing symlink or file at ${SYMLINK}"
        }
    fi

    # Create executable wrapper
    if ! {
        echo '#!/bin/sh' > "${SYMLINK}" &&
        echo "exec zsh \"${ENTRY_POINT}\" \"\$@\"" >> "${SYMLINK}" &&
        chmod +x "${SYMLINK}"
    }; then
        printStyled error "[GACLI] Error: Failed to create wrapper script at ${SYMLINK}"
        return 1
    fi

    # Display success
    printStyled success "Wrapper created: ${SYMLINK} → ${ENTRY_POINT}"
}

# Update ~/.zshrc to include GACLI in PATH and source gacli.zsh
update_zshrc() {

    # Check if GACLI is already in zshrc
    if grep -q '# GACLI' "${ZSHRC}"; then
        printStyled success ".zshrc already configured"
        return 0
    fi

    # Append GACLI block
    {
        echo ""
        echo ""
        echo "# GACLI"
        echo "export PATH=\"${SYM_DIR}:\$PATH\""
        echo "source \"${ENTRY_POINT}\""
    } >> "${ZSHRC}" || {
        printStyled error "Failed to update ${ZSHRC}"
        return 1
    }

    printStyled success ".zshrc updated"
}

# Launch GACLI after install (only if shell is zsh)
auto_launch() {
    echo ""
    printStyled success "GACLI installed! 🚀"
    echo ""

    # Launch only if shell is zsh
    if [ -n "${ZSH_VERSION}" ]; then
        printStyled info "Reloading shell environment... ${EMOJI_WAIT}"
        echo ""
        exec zsh
    else
        printStyled warning "Open a new terminal window or run: exec zsh"
        echo ""
    fi
}

# ────────────────────────────────────────────────────────────────
# Functions - I/O
# ────────────────────────────────────────────────────────────────

# Display ASCII art logo
display_ascii_logo() {
    print "${ORANGE}  _____          _____ _      _____ ${NONE}"
    print "${ORANGE} / ____|   /\\\\   / ____| |    |_   _|${NONE}"
    print "${ORANGE}| |  __   /  \\\\ | |    | |      | |  ${NONE}"
    print "${ORANGE}| | |_ | / /\\\\ \\\\| |    | |      | |  ${NONE}"
    print "${ORANGE}| |__| |/ ____ \\\\ |____| |____ _| |_ ${NONE}"
    print "${ORANGE} \\\\_____/_/    \\\\_\\\\_____|______|_____|${NONE}"
    print ""
}

# Display formatted message
printStyled() {
    # Variables
    local style=$1
    local raw_message=$2
    local final_message=""
    local color=$NONE

    # Argument check
    if [[ -z "$style" || -z "$raw_message" ]]; then
        printStyled error "Veuillez fournir un ${YELLOW}style${RED} et un ${YELLOW}message${RED} pour afficher du texte"
        return 1
    fi

    # Formatting
    case "$style" in
        error)
            print "${RED}${BOLD}${EMOJI_ERR} ${raw_message}${NONE}" >&2
            return
            ;;
        warning)
            print "${YELLOW}${BOLD}${EMOJI_WARN}  ${raw_message}${NONE}" >&2
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
    print "${color}$final_message${NONE}"
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

main "$@"

