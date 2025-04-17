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
ARCHIVE="${REPO}/archive/refs/heads/dev.tar.gz"

# GACLI paths
DIR=".gacli"
ENTRY_POINT="gacli.zsh"
ZSHRC=".zshrc"

# WRAPPER
SYM_DIR=".local/bin"
SYMLINK="gacli"

# Tools
CLIENTS="curl wget git"
HTTP_CLIENT=""

# Colors
RED="$(printf '\033[31m')"
GREEN="$(printf '\033[32m')"
YELLOW="$(printf '\033[33m')"
ORANGE="$(printf '\033[38;5;208m')"
GREY="$(printf '\033[90m')"
NONE="$(printf '\033[0m')"
BOLD="$(printf '\033[1m')"

# Emojis
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

# Entry point that sequences environment checks, download, install and shell reload
main() {
    check_env      || exit 1
    init_style
    parse_args "$@" || exit 2
    resolve_paths  || exit 3

    echo ""
    printStyled info "Setting up environment... ${EMOJI_WAIT}"
    install_brew   || exit 4
    install_zsh    || exit 5

    echo ""
    printStyled info "Downloading GACLI into \"${DIR}\"... ${EMOJI_WAIT}"
    download_gacli || exit 6
    install_deps   || exit 7

    echo ""
    printStyled info "Installing GACLI... ${EMOJI_WAIT}"
    make_executable || exit 8
    create_wrapper  || exit 9
    update_zshrc    || exit 10

    auto_launch     || exit 11
}

# ────────────────────────────────────────────────────────────────
# CHECK ENV
# ────────────────────────────────────────────────────────────────

# Detects OS, package manager, default shell and available HTTP client
check_env() {
    # Detect OS via uname
    ud=$(uname -s)
    case "$ud" in
        Darwin) IS_MACOS=true ;;
        Linux)  IS_LINUX=true ;;
        *)      printStyled error "[check_env] Unsupported OS: $ud"; return 1 ;;
    esac
    printStyled success "OS detected: $ud"

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
        printStyled warning "[check_env] No supported package manager found"
    fi

    # Detect default shell
    SHELL_PATH=${SHELL:-$(command -v sh)}
    SHELL_NAME=$(basename "$SHELL_PATH")
    printStyled success "Default shell: ${SHELL_NAME} (${SHELL_PATH})"

    # Detect HTTP client
    for client in $CLIENTS; do
        if command -v "$client" >/dev/null 2>&1; then
            HTTP_CLIENT="$client"
            printStyled success "${client} detected"
            break
        fi
    done
    [ -n "$HTTP_CLIENT" ] || { printStyled error "[check_env] No curl, wget or git found"; return 1; }

    return 0
}

# Prints ASCII banner and activates emoji styling when UTF‑8 is supported
init_style() {
    printf "%s\n" "${ORANGE}  _____          _____ _      _____ ${NONE}"
    printf "%s\n" "${ORANGE} / ____|   /\\\\   / ____| |    |_   _|${NONE}"
    printf "%s\n" "${ORANGE}| |  __   /  \\\\ | |    | |      | |  ${NONE}"
    printf "%s\n" "${ORANGE}| | |_ | / /\\\\ \\\\| |    | |      | |  ${NONE}"
    printf "%s\n" "${ORANGE}| |__| |/ ____ \\\\ |____| |____ _| |_ ${NONE}"
    printf "%s\n" "${ORANGE} \\\\_____/_/    \\\\_\\\\_____|______|_____|${NONE}"
    printf "%s\n" ""

    # Détection Unicode
    if printf '%s\n' "${LC_CTYPE:-$LANG}" | grep -qi 'utf-8'; then
        EMOJI_SUCCESS="✦"
        EMOJI_WARN="⚠️"
        EMOJI_ERR="❌"
        EMOJI_INFO="✧"
        EMOJI_HIGHLIGHT="👉"
        EMOJI_DEBUG="🔎"
        EMOJI_WAIT="⏳"
        printStyled success "Emojis enabled"
    else
        printStyled info "[enable_emojis] Unicode unsupported, emojis disabled"
    fi
}

# Centralised formatter to colour‑code and prefix log messages by severity
printStyled() {
    style=$1
    msg=$2
    color=$NONE
    case "$style" in
        error)
            printf "%s\n" "${RED}${BOLD}${EMOJI_ERR} ${msg}${NONE}" >&2
            return
            ;;
        warning)
            printf "%s\n" "${YELLOW}${BOLD}${EMOJI_WARN}  ${msg}${NONE}" >&2
            return
            ;;
        success)
            color=$GREEN
            prefix=$EMOJI_SUCCESS
            ;;
        info)
            color=$GREY
            prefix=$EMOJI_INFO
            ;;
        highlight)
            color=$NONE
            prefix=$EMOJI_HIGHLIGHT
            ;;
        *)
            prefix=""
            ;;
    esac
    printf "%s\n" "${color}${prefix} ${msg}${NONE}"
}

# Parses CLI options (currently only --force) and sets corresponding flags
parse_args() {
    for arg in "$@"; do
        case "$arg" in
            --force)
                FORCE_MODE="true"
                ;;
            *)
                printStyled error "[parse_args] Expected : --force (received : $arg)"
                return 1
                ;;
        esac
    done
    printStyled success "Arguments parsed"
}

# Expands user‑relative paths, ensures .zshrc exists, and defines wrapper targets
resolve_paths() {
    [ -n "$HOME" ] || { printStyled error "[resolve_paths] \$HOME not set"; return 1; }

    DIR="$HOME/$DIR"
    ENTRY_POINT="$DIR/$ENTRY_POINT"
    ZSHRC="$HOME/$ZSHRC"
    SYM_DIR="$HOME/$SYM_DIR"
    SYMLINK="$SYM_DIR/$SYMLINK"

    while [ ! -f "$ZSHRC" ]; do
        printStyled warning ".zshrc not found: $ZSHRC"
        printStyled highlight "Enter path to your .zshrc:"
        printf "> "
        read -r ZSHRC
    done
    printStyled success "Paths resolved"
}

# ────────────────────────────────────────────────────────────────
# SETUP ENV
# ────────────────────────────────────────────────────────────────

# Installs Homebrew non‑interactively when absent, selecting curl or wget as downloader
install_brew() {
    command -v brew >/dev/null 2>&1 && { printStyled success "Homebrew detected"; return 0; }

    [ "$IS_MACOS" = true ] || [ "$IS_LINUX" = true ] || {
        printStyled error "[install_brew] Unsupported OS"; return 1
    }

    if command -v curl >/dev/null 2>&1; then
        downloader="curl -fsSL"
    elif command -v wget >/dev/null 2>&1; then
        downloader="wget -q -O -"
    else
        printStyled error "[install_brew] curl or wget required"; return 1
    fi

    install_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    printStyled info "Installing Homebrew..."
    $downloader "$install_url" | /bin/bash || {
        printStyled error "[install_brew] Failed"; return 1
    }
    command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)" && hash -r 2>/dev/null
    printStyled success "Homebrew installed"
}

# Installs zsh via the detected package manager when it is not already present
install_zsh() {
    command -v zsh >/dev/null 2>&1 && { printStyled success "zsh detected"; return 0; }

    case "$PACKAGE_MANAGER" in
        brew)    install_cmd="brew install zsh" ;;
        apt)     install_cmd="sudo apt-get update && sudo apt-get install -y zsh" ;;
        dnf)     install_cmd="sudo dnf install -y zsh" ;;
        pacman)  install_cmd="sudo pacman -Sy --noconfirm zsh" ;;
        *)       printStyled error "[install_zsh] No supported package manager"; return 1 ;;
    esac

    printStyled info "Installing zsh..."
    eval "$install_cmd" || { printStyled error "[install_zsh] Failed"; return 1; }
    printStyled success "zsh installed"
}

# ────────────────────────────────────────────────────────────────
# DOWNLOAD
# ────────────────────────────────────────────────────────────────

# Retrieves GACLI source (curl, wget or git) into the target directory, honouring --force
download_gacli() {
    [ ! -d "$DIR" ] || {
        [ "$FORCE_MODE" = "true" ] && { rm -rf "$DIR"; } || {
            printStyled error "[download_gacli] $DIR already exists (--force to overwrite)"
            return 1
        }
    }
    mkdir -p "$DIR" || { printStyled error "[download_gacli] Unable to create $DIR"; return 1; }

    case "$HTTP_CLIENT" in
        curl)
            curl -fSL "$ARCHIVE" | tar -xzf - -C "$DIR" --strip-components=1 \
                || { printStyled error "[download_gacli] Failed to download/extract archive"; return 1; }
            ;;
        wget)
            wget -q -O - "$ARCHIVE" | tar -xzf - -C "$DIR" --strip-components=1 \
                || { printStyled error "[download_gacli] Failed to download/extract archive"; return 1; }
            ;;
        git)
            branch="${ARCHIVE##*/}"
            branch="${branch%.tar.gz}"
            git clone --depth 1 --branch "$branch" "$REPO" "$DIR" \
                || { printStyled error "[download_gacli] Failed to clone repository"; return 1; }
            ;;
        *)
            printStyled error "[download_gacli] Unsupported HTTP client: $HTTP_CLIENT"
            return 1
            ;;
    esac
    printStyled success "GACLI downloaded into $DIR"
}

# ────────────────────────────────────────────────────────────────
# INSTALL
# ────────────────────────────────────────────────────────────────

# Runs brew bundle on the downloaded Brewfile to install required formulae and casks
install_deps() {
    brewfile="$DIR/.auto-install/Brewfile"
    if command -v brew >/dev/null 2>&1 && [ -f "$brewfile" ]; then
        printStyled info "Installing dependencies..."
        brew bundle --file="$brewfile" || {
            printStyled error "[install_deps] Failed to run Brewfile"
            return 1
        }
        printStyled success "Dependencies installed"
    else
        printStyled warning "[install_deps] No Brewfile found or brew unavailable → skipping"
    fi
}

# Adds execute permission to the downloaded GACLI entry‑point script
make_executable() {
    chmod +x "$ENTRY_POINT" || {
        printStyled error "[make_executable] Failed make $ENTRY_POINT executable"
        return 1
    }
    printStyled success "Entry point made executable"
}

# Generates a wrapper in $HOME/.local/bin that relays args to the entry point via zsh
create_wrapper() {
    mkdir -p "$SYM_DIR" || {
        printStyled error "[create_wrapper] Failed to create $SYM_DIR"; return 1
    }

    if [ -f "$SYMLINK" ] || [ -d "$SYMLINK" ] || [ -h "$SYMLINK" ]; then
        rm -f "$SYMLINK"
    fi

    {
        printf '%s\n' '#!/usr/bin/env sh'
        printf '%s\n' "exec zsh \"$ENTRY_POINT\" \"\$@\""
    } > "$SYMLINK" && chmod +x "$SYMLINK" || {
        printStyled error "[create_wrapper] Failed to create wrapper"; return 1
    }
    printStyled success "Wrapper created: $SYMLINK → $ENTRY_POINT"
}

# Appends PATH export and source command to the user’s .zshrc when missing
update_zshrc() {
    if grep -q '# GACLI' "$ZSHRC"; then
        printStyled success ".zshrc already configured"
        return 0
    fi
    {
        printf '\n# GACLI\n'
        printf 'export PATH="%s:$PATH"\n' "$SYM_DIR"
        printf 'source "%s"\n' "$ENTRY_POINT"
    } >> "$ZSHRC" || {
        printStyled error "[update_zshrc] Failed update $ZSHRC"; return 1
    }
    printStyled success ".zshrc updated"
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

auto_launch() {
    echo ""
    printStyled success "GACLI successfully installed 🚀"
    echo ""
    if [ -n "$ZSH_VERSION" ]; then
        printStyled info "Reloading shell... ${EMOJI_WAIT}"
        exec zsh
    else
        printStyled warning "Open a new terminal or run: exec zsh"
        echo ""
    fi
}

# Displays success message and either execs a new zsh or prompts the user to reopen a shell
main "$@"
