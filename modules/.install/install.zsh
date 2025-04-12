###############################
# FICHIER install.zsh
###############################

#!/usr/bin/env zsh

# Options
FORCE_MODE="false"

# OS variables
IS_MACOS=false
IS_LINUX=false

# GACLI directory
GACLI_REPO_URL="https://github.com/guillaumeast/gacli"
GACLI_DIR_REL=".gacli"
GACLI_DIR=""

# GACLI entry point
GACLI_ENTRY_REL="gacli.zsh"
GACLI_ENTRY_POINT=""

# GACLI symlink directory
GACLI_SYM_DIR_REL=".local/bin"
GACLI_SYM_DIR=""

# GACLI symlink
GACLI_SYM_REL="gacli"
GACLI_SYMLINK=""

# ZSH config file
ZSHRC_REL=".zshrc"
ZSHRC_FILE=""

# Colors
GREEN="$(printf '\033[32m')"
ORANGE="$(printf '\033[38;5;208m')"
RED="$(printf '\033[31m')"
GREY="$(printf '\033[90m')"
NONE="$(printf '\033[0m')"

# Emojis (used only if system supports unicode emojis)
EMOJI_SUCCESS="✦"
EMOJI_WARN="⚠️"
EMOJI_ERR="❌"
EMOJI_INFO="✧"
EMOJI_HIGHLIGHT="👉"
EMOJI_WAIT="⏳"

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

main() {
    
    # Check env compatibility
    check_os || exit 01             # Linux and macOS are supported (Windows is NOT supported)
    check_unicode                   # Enable emojis if system can handle it
    
    # Init
    display_ascii_logo
    printStyled info "Initializing... ${EMOJI_WAIT}"
    parse_args "$@" || exit 02      # Parse args and set command relative variables
    resolve_paths || exit 03        # Resolve relative paths to absolute paths
    check_zsh || exit 04            # Needed to run GACLI

    # Install dependencies
    echo ""
    printStyled info "Installing dependencies... ${EMOJI_WAIT}"
    curl_install || exit 05         # Needed to install Homebrew
    git_install || exit 06          # Needed to install Homebrew
    brew_install || exit 07         # Needed to install coreutils
    coreutils_install || exit 08    # Needed for cross-platform compatibility

    # Configure GACLI
    echo ""
    printStyled info "Installing GACLI... ${EMOJI_WAIT}"
    gacli_download || exit 09       # Clone GACLI repo
    make_executable || exit 10      # Make GACLI entry point executable
    create_symlink || exit 11       # Create a symlink to enable `gacli <command>` commands
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

# Check if system supports unicode emojis
check_unicode() {
    if ! printf "🧪" | grep -q "🧪"; then
        EMOJI_SUCCESS="[OK]"
        EMOJI_WARN="[!]"
        EMOJI_ERR="[X]"
        EMOJI_INFO="[i]"
        EMOJI_HIGHLIGHT="=>"
        EMOJI_WAIT="..."
        printStyled warning "Emojis disabled for compatibilty"
    else
        printStyled success "Emojis enabled"
    fi
}

# Parse arguments
parse_args() {
    for arg in "$@"; do
        case "$arg" in
            --custom)
                # Ask for custom path
                while true; do
                    echo "Please provide the full path where you want to install GACLI:"
                    printf "${EMOJI_HIGHLIGHT} "
                    read custom_path
                    if [ -n "${custom_path}" ]; then
                        GACLI_DIR="${custom_path}"
                        break
                    fi
                    printStyled warning "[GACLI] Warning: Installation path cannot be empty"
                done
                ;;
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
    # Resolve $HOME path
    if [ -z "${HOME}" ] || [ ! -d "${HOME}" ]; then
        printStyled error "[GACLI] Error: \$HOME is not set or invalid"
        return 1
    fi

    # Resolve destination path
    if [ -z "$GACLI_DIR" ]; then
        # Default path
        GACLI_DIR="${HOME}/${GACLI_DIR_REL}"
    else
        # Check custom path correctness
        if [ -z "${GACLI_DIR}" ]; then
            printStyled error "[GACLI] Error: invalid destination folder: ${GACLI_DIR}"
            return 1
        fi
    fi

    # Resolve relative paths
    GACLI_ENTRY_POINT="${GACLI_DIR}/${GACLI_ENTRY_REL}"
    GACLI_SYM_DIR="${HOME}/${GACLI_SYM_DIR_REL}"
    GACLI_SYMLINK="${GACLI_SYM_DIR_REL}/${GACLI_SYM_REL}"
    ZSHRC_FILE="${HOME}/${ZSHRC_REL}"

    # Check .zshrc path
    while [ -z "${ZSHRC_FILE}" ] || [ ! -f "${ZSHRC_FILE}" ]; do
        printStyled warning ".zshrc not found at ${ZSHRC_FILE}"
        printStyled highlight "Please provide the correct path to your .zshrc file:"
        printf "> "
        read ZSHRC_FILE
        if [ -z "${ZSHRC_FILE}" ]; then
            printStyled error "Path cannot be empty"
            exit 1
        fi
    done

    # Display success
    printStyled success "Initialization completed"
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

    # Check
    if ! command -v curl >/dev/null 2>&1; then

        printStyled highlight "Installing curl (your password may be asked)... ${EMOJI_WAIT}"

        # Try auto-install
        if [ "$IS_MACOS" = true ]; then
            if brew install curl; then
                printStyled success "Curl installed"
                return 0
            fi
        elif [ "$IS_LINUX" = true ]; then
            if command -v apt >/dev/null 2>&1; then
                if sudo apt install curl; then
                    printStyled success "Curl installed"
                    return 0
                fi
            elif command -v dnf >/dev/null 2>&1; then
                if sudo dnf install curl; then
                    printStyled success "Curl installed"
                    return 0
                fi
            elif command -v pacman >/dev/null 2>&1; then
                if sudo pacman -S curl; then
                    printStyled success "Curl installed"
                    return 0
                fi
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
    local install_cmd
    if $IS_MACOS || $IS_LINUX; then
        if $IS_LINUX; then
            install_cmd="NONINTERACTIVE=1 "
        fi
        install_cmd="/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    else
        echo "${EMOJI_ERROR} [brew_install] Unsupported OS: ${OSTYPE}"
        return 1
    fi

    # Install Homebrew
    if ! eval "$install_cmd"; then
        echo "${EMOJI_ERROR} [brew_install] Homebrew installation failed"
        return 1
    fi

    # Add Homebrew to PATH
    local brew_exec_path
    if ! brew_exec_path="$(command -v brew)"; then
        echo "${EMOJI_ERROR} [brew_install] Failed to detect brew after installation"
        return 1
    fi

    if ! eval "$("$brew_exec_path" shellenv)"; then
        echo "${EMOJI_ERROR} [brew_install] Failed to set Homebrew environment"
        return 1
    fi

    # Refresh hashmap command table
    if ! hash -r; then
        echo "${EMOJI_ERROR} [brew_install] Failed to refresh shell hash table"
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

# Clone GACLI repo
gacli_download() {

    # Check if GACLI is already installed
    if [ -d "${GACLI_DIR}" ]; then
        if [ "$FORCE_MODE" = "true" ]; then
            rm -rf "${GACLI_DIR}"
        else
            printStyled error "[GACLI] Error: already installed at ${GACLI_DIR}"
            printStyled highlight "Use --force to overwrite"
            return 1
        fi
    fi

    # Clone repo
    printStyled info "Installing GACLI into ${GACLI_DIR}"
    if ! git clone "${GACLI_REPO_URL}" "${GACLI_DIR}"; then
        printStyled error "[GACLI] Error: Failed to clone repository"
        return 1
    fi

    # Display success
    printStyled success "GACLI downloaded"
}

# Make main script executable
make_executable() {
    if ! chmod +x "${GACLI_ENTRY_POINT}"; then
        printStyled error "[GACLI] Error: Failed to make ${GACLI_ENTRY_REL} executable"
        return 1
    fi

    # Display success
    printStyled success "GACLI has been made executable"
}

# Create symlink
create_symlink() {
    # Create bin folder if needed
    if ! mkdir -p "${GACLI_SYM_DIR}"; then
        printStyled error "[GACLI] Error: Failed to create ${GACLI_SYM_DIR}"
        return 1
    fi

    # Create symlink to run gacli globally
    if ! ln -sf "${GACLI_ENTRY_POINT}" "${GACLI_SYMLINK}"; then
        printStyled error "[GACLI] Error: Failed to create symlink at ${GACLI_SYMLINK}"
        return 1
    fi

    # Display success
    printStyled success "Symlink created: ${GACLI_SYMLINK} → ${GACLI_ENTRY_POINT}"
}

# Update ~/.zshrc to include GACLI in PATH and source gacli.zsh
update_zshrc() {

    # Check if GACLI is already in zshrc
    if grep -q '# GACLI' "${ZSHRC_FILE}"; then
        printStyled success ".zshrc already configured"
        return 0
    fi

    # Append GACLI block
    {
        echo ""
        echo "# GACLI"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo "source \"\$HOME/.gacli/gacli.zsh\""
    } >> "${ZSHRC_FILE}" || {
        printStyled error "Failed to update ${ZSHRC_FILE}"
        return 1
    }

    printStyled success ".zshrc updated"
}

# Launch GACLI after install (only if shell is zsh)
auto_launch() {
    echo ""
    printStyled success "GACLI installed !"
    echo ""

    # Launch only if shell is zsh
    if [ -n "${ZSH_VERSION}" ]; then
        printStyled info "Reloading shell environment... ${EMOJI_WAIT}"
        echo ""
        source "${ZSHRC_FILE}"
    else
        printStyled warning "Open a new terminal window or run: source ~/.zshrc"
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
            print "${RED}${BOLD}${ICON_ERROR} ${raw_message}${NONE}" >&2
            return
            ;;
        warning)
            print "${YELLOW}${BOLD}${ICON_WARN}  ${raw_message}${NONE}" >&2
            return
            ;;
        success)
            color=$GREEN
            final_message="${ICON_SUCCESS} ${raw_message}"
            ;;
        info)
            color=$GREY
            final_message="${ICON_INFO} ${raw_message}"
            ;;
        highlight)
            color=$NONE
            final_message="${ICON_HIGHLIGHT} ${raw_message}"
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

