###############################
# FICHIER install.sh
###############################

#!/bin/sh

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
EMOJI_SUCCESS="${GREEN}✦${NONE}"
EMOJI_WARN="⚠️"
EMOJI_ERR="❌"
EMOJI_INFO="${GREY}✧${NONE}"
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
    echo "${EMOJI_INFO} Initializing... ${EMOJI_WAIT}"
    parse_args "$@" || exit 02      # Parse args and set command relative variables
    resolve_paths || exit 03        # Resolve relative paths to absolute paths
    check_zsh || exit 04            # Needed to run GACLI

    # Install dependencies
    echo ""
    echo "${EMOJI_INFO} Installing dependencies... ${EMOJI_WAIT}"
    curl_install || exit 05         # Needed to install Homebrew
    git_install || exit 06          # Needed to install Homebrew
    brew_install || exit 07         # Needed to install coreutils
    coreutils_install || exit 08    # Needed for cross-platform compatibility

    # Configure GACLI
    echo ""
    echo "${EMOJI_INFO} Installing GACLI... ${EMOJI_WAIT}"
    gacli_download || exit 09       # Clone GACLI repo
    make_executable || exit 10      # Make GACLI entry point executable
    create_symlink || exit 11       # Create a symlink to enable `gacli <command>` commands
    update_path || exit 12          # Add GACLI to path for global autonomous execution

    # Done
    display_confirm                 # Prompt the user to reload terminal
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
    echo "${EMOJI_SUCCESS} OS supported: ${OSTYPE}"
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
        echo "${EMOJI_WARN} Emojis disabled for compatibilty"
    else
        echo "${EMOJI_SUCCESS} Emojis enabled"
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
                    echo "${EMOJI_WARN} [GACLI] Warning: Installation path cannot be empty"
                done
                ;;
            --force)
                # Enable force mode
                FORCE_MODE="true"
                ;;
            *)
                echo "${EMOJI_ERR} [GACLI] Error: Unknown option [${arg}]"
                return 1
                ;;
        esac
    done

    # Display success
    echo "${EMOJI_SUCCESS} Arguments parsed"
}

# Resolve paths
resolve_paths() {
    # Resolve $HOME path
    if [ -z "${HOME}" ] || [ ! -d "${HOME}" ]; then
        echo "${EMOJI_ERR} [GACLI] Error: \$HOME is not set or invalid"
        return 1
    fi

    # Resolve destination path
    if [ -z "$GACLI_DIR" ]; then
        # Default path
        GACLI_DIR="${HOME}/${GACLI_DIR_REL}"
    else
        # Check custom path correctness
        if [ -z "${GACLI_DIR}" ]; then
            echo "${EMOJI_ERR} [GACLI] Error: invalid destination folder: ${GACLI_DIR}"
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
        echo "${EMOJI_WARN}  .zshrc not found at ${ZSHRC_FILE}"
        echo "${EMOJI_HIGHLIGHT}  Please provide the correct path to your .zshrc file:"
        printf "> "
        read ZSHRC_FILE
        if [ -z "${ZSHRC_FILE}" ]; then
            echo "${EMOJI_ERR} Path cannot be empty"
            exit 1
        fi
    done

    # Display success
    echo "${EMOJI_SUCCESS} Initialization completed"
}

# Check if zsh is installed
check_zsh() {

    # Check
    if ! command -v zsh >/dev/null 2>&1; then
        echo "${EMOJI_ERR} [GACLI] Error: zsh is not installed"
        echo ""
        echo "${EMOJI_HIGHLIGHT} Please install zsh manually before continuing"
        echo "${EMOJI_INFO} macOS : already available, enable it via System Preferences > Shell"
        echo "${EMOJI_INFO} Linux : sudo apt install zsh   # or your distro equivalent"
        echo ""
        return 1
    fi

    # Display success
    echo "${ICON_SUCCESS} Zsh detected"
}

# ────────────────────────────────────────────────────────────────
# Functions - DEPENDENCIES
# ────────────────────────────────────────────────────────────────

# Install curl
curl_install() {

    # Check
    if ! command -v curl >/dev/null 2>&1; then

        echo "${EMOJI_HIGHLIGHT} Installing curl (your password may be asked)... ${EMOJI_WAIT}"

        # Try auto-install
        if [ "$IS_MACOS" = true ]; then
            if brew install curl; then
                echo "${EMOJI_SUCCESS} Curl installed"
                return 0
            fi
        elif [ "$IS_LINUX" = true ]; then
            if command -v apt >/dev/null 2>&1; then
                if sudo apt install curl; then
                    echo "${EMOJI_SUCCESS} Curl installed"
                    return 0
                fi
            elif command -v dnf >/dev/null 2>&1; then
                if sudo dnf install curl; then
                    echo "${EMOJI_SUCCESS} Curl installed"
                    return 0
                fi
            elif command -v pacman >/dev/null 2>&1; then
                if sudo pacman -S curl; then
                    echo "${EMOJI_SUCCESS} Curl installed"
                    return 0
                fi
            fi
        fi

        # Manual fallback
        echo "${EMOJI_ERR} [GACLI] Error: curl is not installed"
        echo ""
        echo "${EMOJI_HIGHLIGHT} Please install curl manually before continuing"
        echo "${EMOJI_INFO} macOS : brew install curl"
        echo "${EMOJI_INFO} Linux : Use your package manager"
        echo ""
        return 1
    fi

    # Display success
    echo "${EMOJI_SUCCESS} Curl detected"
}

# Install git
git_install() {

    # Check
    if ! command -v git >/dev/null 2>&1; then

        echo "${EMOJI_HIGHLIGHT} Installing git (your password may be asked)... ${EMOJI_WAIT}"

        # Try auto-install
        if [ "$IS_MACOS" = true ]; then
            if xcode-select --install; then
                echo "${EMOJI_SUCCESS} Git installed"
                return 0
            fi
        elif [ "$IS_LINUX" = true ]; then 
            if command -v apt >/dev/null 2>&1; then
                if sudo apt install git; then
                    echo "${EMOJI_SUCCESS} Git installed"
                    return 0
                fi
            elif command -v dnf >/dev/null 2>&1; then
                if sudo dnf install git; then
                    echo "${EMOJI_SUCCESS} Git installed"
                    return 0
                fi
            elif command -v pacman >/dev/null 2>&1; then
                if sudo pacman -S git; then
                    echo "${EMOJI_SUCCESS} Git installed"
                    return 0
                fi
            fi
        fi

        # Manual fallback
        echo "${EMOJI_ERR} [GACLI] Error: git is not installed"
        echo ""
        echo "${EMOJI_HIGHLIGHT} Please install git manually before continuing"
        echo "${EMOJI_INFO} macOS : xcode-select --install"
        echo "${EMOJI_INFO} Linux : Use your package manager"
        echo ""
        return 1
    fi

    # Display success
    echo "${EMOJI_SUCCESS} Git detected"
}

# Install Homebrew
brew_install() {

    # Check if Homebrew is already installed
    if ! command -v brew >/dev/null 2>&1; then
        echo "${EMOJI_SUCCESS} Homebrew detected"
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
    echo "${EMOJI_SUCCESS} Homebrew installed"
}

# Install coreutils
coreutils_install() {

    # Check if Coreutils is already installed
    if command -v gdate >/dev/null 2>&1; then
        echo "${EMOJI_SUCCESS} Coreutils detected"
        return 0
    fi

    # Install coreutils
    echo "${EMOJI_INFO} coreutils not found → installing with Homebrew..."
    if brew install coreutils; then
        echo "${EMOJI_SUCCESS} Coreutils installed"
    else
        echo "${EMOJI_ERR} Failed to install coreutils"
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
            echo "${EMOJI_ERR} [GACLI] Error: already installed at ${GACLI_DIR}"
            echo "${EMOJI_HIGHLIGHT} Use --force to overwrite"
            return 1
        fi
    fi

    # Clone repo
    echo "${EMOJI_INFO} Installing GACLI into ${GACLI_DIR}"
    if ! git clone "${GACLI_REPO_URL}" "${GACLI_DIR}"; then
        echo "${EMOJI_ERR} [GACLI] Error: Failed to clone repository"
        return 1
    fi

    # Display success
    echo "${EMOJI_SUCCESS} GACLI downloaded"
}

# Make main script executable
make_executable() {
    if ! chmod +x "${GACLI_ENTRY_POINT}"; then
        echo "${EMOJI_ERR} [GACLI] Error: Failed to make ${GACLI_ENTRY_REL} executable"
        return 1
    fi

    # Display success
    echo "${EMOJI_SUCCESS} GACLI has been made executable"
}

# Create symlink
create_symlink() {
    # Create bin folder if needed
    if ! mkdir -p "${GACLI_SYM_DIR}"; then
        echo "${EMOJI_ERR} [GACLI] Error: Failed to create ${GACLI_SYM_DIR}"
        return 1
    fi

    # Create symlink to run gacli globally
    if ! ln -sf "${GACLI_ENTRY_POINT}" "${GACLI_SYMLINK}"; then
        echo "${EMOJI_ERR} [GACLI] Error: Failed to create symlink at ${GACLI_SYMLINK}"
        return 1
    fi

    # Display success
    echo "${EMOJI_SUCCESS} Symlink created: ${GACLI_SYMLINK} → ${GACLI_ENTRY_POINT}"
}

# Ensure ~/.local/bin is in PATH
update_path() {
    if ! grep -q "export PATH=\"${GACLI_SYM_DIR}:\$PATH\"" "${ZSHRC_FILE}"; then
        if ! printf "\n# GACLI\nexport \"${GACLI_SYM_DIR}:\$PATH\"\n" >> "${ZSHRC_FILE}"; then
            echo "${EMOJI_ERR} Failed to append PATH to ${ZSHRC_FILE}"
            exit 1
        fi
    fi

    # Display success
    echo "${EMOJI_SUCCESS} GACLI added to path"
}

# ────────────────────────────────────────────────────────────────
# Functions - I/O
# ────────────────────────────────────────────────────────────────

# Display ASCII logo
display_ascii_logo() {
    printf "%s\n" "${ORANGE}  _____          _____ _      _____ ${NONE}"
    printf "%s\n" "${ORANGE} / ____|   /\\\\   / ____| |    |_   _|${NONE}"
    printf "%s\n" "${ORANGE}| |  __   /  \\\\ | |    | |      | |  ${NONE}"
    printf "%s\n" "${ORANGE}| | |_ | / /\\\\ \\\\| |    | |      | |  ${NONE}"
    printf "%s\n" "${ORANGE}| |__| |/ ____ \\\\ |____| |____ _| |_ ${NONE}"
    printf "%s\n" "${ORANGE} \\\\_____/_/    \\\\_\\\\_____|______|_____|${NONE}"
    printf "\n"
}

# Display installation confirm + prompt to reload shell
display_confirm() {
    echo ""
    echo "${EMOJI_SUCCESS} GACLI installed !"
    echo ""
    echo "${EMOJI_WARN} Open a new terminal window or run: source ~/.zshrc"
    echo ""
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

main "$@"

