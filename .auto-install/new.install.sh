#!/usr/bin/env sh
###############################
# FICHIER /.auto-install/install.sh
###############################

# Options
FORCE_MODE="false"

# OS variables
IS_MACOS=false
IS_LINUX=false
SHELL_PATH=""
SHELL_NAME=""

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
CLIENTS="curl wget"
HTTP_CLIENT=""
GIT_IS_INSTALLED=false
PACKAGE_MANAGER=""

# Colors
RED="$(printf '\033[31m')"
GREEN="$(printf '\033[32m')"
YELLOW="$(printf '\033[33m')"
ORANGE="$(printf '\033[38;5;208m')"
GREY="$(printf '\033[90m')"
NONE="$(printf '\033[0m')"
BOLD="$(printf '\033[1m')"

# Emojis
EMOJI_SUCCESS="✦"
EMOJI_WARN="⚠️ "
EMOJI_ERR="❌"
EMOJI_INFO="✧"
EMOJI_HIGHLIGHT="👉"
EMOJI_DEBUG="🔎"
EMOJI_WAIT="⏳"

# ────────────────────────────────────────────────────────────────
# PSEUDO-CODE
# ────────────────────────────────────────────────────────────────

# main()
# |→ check_env                  → Checks env:
# |     |→ ✅ init_style                → Enable emojis if system can handle it + welcome message
# |     |→ ✅ check_env                 → Detect environment: OS, package manager and default shell
# |     |→ ✅ parse_args                → Inits global variables referring to given args
# |     |→ ✅ resolve_paths             → Resolve relative paths to absolute paths
# |→ setup_env                  → Setup required tools:
# |     |→ ✅ install_http              → Try to install curl or wget if missing
# |     |→ ✅ install_bash              → Try to install bash if missing
# |     |→ ✅ install_git               → Try to install git if missing
# |     |→ ✅ install_brew              → Try to install Homebrew if missing
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

    init_style

    printf "%s\n" "${GREY}${EMOJI_INFO}Checking environment... ${NONE}${EMOJI_WAIT}"
    check_env       || exit 1

    echo ""
    printStyled info "Initializing... ${EMOJI_WAIT}"
    parse_args "$@" || exit 2
    resolve_paths   || exit 3

    echo ""
    printStyled info "Setting up environment... ${EMOJI_WAIT}"
    install_http    || exit 4
    install_bash    || exit 5
    install_git     || exit 6
    install_brew    || exit 7

    echo ""
    printStyled info "Downloading ${ORANGE}GACLI${GREY} → ${NONE}\"${DIR}\"${GREY}... ${EMOJI_WAIT}"
    download_gacli  || exit 8

    echo ""
    printStyled info "Installing dependencies... ${EMOJI_WAIT}"
    install_deps    || exit 9

    echo ""
    printStyled info "Installing ${ORANGE}GACLI${GREY}... ${EMOJI_WAIT}"
    make_executable || exit 10
    create_wrapper  || exit 11
    update_zshrc    || exit 12

    auto_launch     || exit 13
}

# ────────────────────────────────────────────────────────────────
# FORMATTING
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

# Centralised formatter to colour‑code and prefix log messages by severity
printStyled() {
    style=$1
    msg=$2
    color=$NONE
    case "$style" in
        error)
            printf "%s\n" "${RED}${BOLD}${EMOJI_ERR} ${msg}${NONE}" >&2
            return ;;
        warning)
            printf "%s\n" "${YELLOW}${BOLD}${EMOJI_WARN} ${msg}${NONE}" >&2
            return ;;
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
        *)      printStyled error "Unsupported OS: $ud"; return 1 ;;
    esac
    printStyled info "OS detected: ${GREEN}$ud${NONE}"

    # — Privilege escalation setup —
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null; then
            SUDO="sudo"
            printStyled info "Privilege: ${GREEN}sudo enabled${NONE}"
        else
            SUDO=""
            printStyled info "Privilege: ${ORANGE}No sudo detected → non-root installs may fail${NONE}"
        fi
    else
        SUDO=""
        printStyled info "Privilege: ${GREEN}root${NONE}"
    fi

    # Detect default shell
    SHELL_PATH=${SHELL:-$(command -v sh)}
    SHELL_NAME=$(basename "$SHELL_PATH")
    if [ $SHELL_NAME = "zsh" ]; then
        color="${GREEN}"
    elif [ -n "$SHELL_NAME" ]; then
        color="${ORANGE}"
    else
        color="${RED}"
        SHELL_NAME="unknwon"
    fi
    printStyled info "Default shell: ${color}${SHELL_NAME}${GREY} → ${NONE}${SHELL_PATH}"

    # Detect package manager
    if command -v brew >/dev/null; then
        PACKAGE_MANAGER="brew"
        printStyled info "Package manager: ${GREEN}Homebrew${NONE}"
    fi

    printStyled info "Installing build tools... ${ORANGE}build-essential${NONE} ${ORANGE}procps${NONE} ${ORANGE}curl${NONE} ${ORANGE}file${NONE} ${ORANGE}git${NONE} (password may be requested)"
    if command -v apt >/dev/null; then
        PACKAGE_MANAGER="apt"
        $SUDO apt-get update -y >/dev/null
        $SUDO apt-get install -y build-essential procps curl file git >/dev/null
        printStyled info "Package manager: ${ORANGE}apt${NONE}"
    elif command -v dnf >/dev/null; then
        PACKAGE_MANAGER="dnf"
        $SUDO dnf groupinstall -y "Development Tools" >/dev/null
        $SUDO dnf install -y procps-ng file >/dev/null
        printStyled info "Package manager: ${ORANGE}dnf${NONE}"
    elif command -v pacman >/dev/null; then
        PACKAGE_MANAGER="pacman"
        $SUDO pacman -S base-devel procps-ng curl file git >/dev/null
        printStyled info "Package manager: ${ORANGE}pacman${NONE}"
    elif command -v yum >/dev/null; then
        PACKAGE_MANAGER="yum"
        $SUDO yum groupinstall 'Development Tools' >/dev/null
        $SUDO yum install procps-ng curl file git >/dev/null
        printStyled info "Package manager: ${ORANGE}yum${NONE}"
    else
        printStyled warning "No supported package manager found"
        PACKAGE_MANAGER=""
    fi

    # Detect/ download HTTP client
    for client in $CLIENTS; do
        if command -v "$client" >/dev/null; then
            HTTP_CLIENT="$client"
            printStyled success "HTTP client: ${ORANGE}${client}${NONE}"
            break
        fi
    done
    [ -n "$HTTP_CLIENT" ] || printStyled info "HTTP client: ${RED}none${NONE}"
}

# Parses CLI options (currently only --force) and sets corresponding flags
parse_args() {
    for arg in "$@"; do
        case "$arg" in
            --force)
                FORCE_MODE="true"
                ;;
            *)
                printStyled error "Expected : --force (received : $arg)"
                return 1
                ;;
        esac
    done
    printStyled info "Arguments ${GREEN}parsed${NONE}"
}

# Expands user‑relative paths, ensures .zshrc exists, and defines wrapper targets
resolve_paths() {
    [ -n "$HOME" ] || { printStyled error "\$HOME not set"; return 1; }

    DIR="$HOME/$DIR"
    ENTRY_POINT="$DIR/$ENTRY_POINT"
    ZSHRC="$HOME/$ZSHRC"
    SYM_DIR="$HOME/$SYM_DIR"
    SYMLINK="$SYM_DIR/$SYMLINK"
    printStyled info "Paths ${GREEN}resolved${NONE}"
}

# ────────────────────────────────────────────────────────────────
# SETUP ENV
# ────────────────────────────────────────────────────────────────

# Try to install curl, fallback to wget
install_http() {

    # CURL - Check if already installed
    if command -v curl >/dev/null; then
        HTTP_CLIENT=curl
        printStyled success "Already installed: ${ORANGE}curl${NONE}"
        return 0
    fi

    # CURL - Install (prioritary option)
    if ! command -v curl >/dev/null; then
        printStyled info "Installing ${ORANGE}curl${NONE}..."
        case "$PACKAGE_MANAGER" in
            brew)    brew install curl >/dev/null ;;
            apt)     $SUDO apt-get update >/dev/null && $SUDO apt-get install -y curl >/dev/null ;;
            dnf)     $SUDO dnf install -y curl >/dev/null ;;
            pacman)  $SUDO pacman -Sy --noconfirm curl >/dev/null ;;
            yum)     # TODO
            *)       printStyled warning "Package manager does not support ${ORANGE}curl${NONE}" ;;
        esac
        
        # Check install
        if command -v curl >/dev/null; then
            HTTP_CLIENT="curl"
            printStyled success "Installed: ${ORANGE}curl${NONE}"
            return 0
        else
            printStyled warning "Install failed: ${ORANGE}curl${NONE}"
        fi
    fi

    # WGET - Check if already installed
    printStyled info "→ trying ${ORANGE}wget${NONE}..."
    if command -v wget >/dev/null; then
        HTTP_CLIENT=wget
        printStyled success "Already installed: ${ORANGE}wget${NONE}"
        return 0
    fi

    # WGET - Install
    if ! command -v wget >/dev/null; then
        printStyled info "Installing ${ORANGE}wget${NONE}..."
        case "$PACKAGE_MANAGER" in
            brew)    brew install wget >/dev/null ;;
            apt)     $SUDO apt-get update && $SUDO apt-get install -y wget >/dev/null ;;
            dnf)     $SUDO dnf install -y wget >/dev/null ;;
            pacman)  $SUDO pacman -Sy --noconfirm wget >/dev/null ;;
            yum)     # TODO
            *)       printStyled error "Package manager not supported" ; return 1;;
        esac
        
        # Check install
        if command -v wget >/dev/null; then
            HTTP_CLIENT="wget"
            printStyled success "Installed: ${ORANGE}wget${NONE}"
            return 0
        else
            printStyled warning "Install failed: ${ORANGE}wget${NONE}"
        fi
    fi

    # Fallback error
    printStyled error "Unable to install any HTTP client"
    return 1
}

# Installs git when absent, using the detected package manager
install_git() {

    # Check if already installed
    if command -v git >/dev/null; then
        printStyled success "Already installed: ${ORANGE}git${NONE}"
        return 0
    fi
    
    # Install
    printStyled info "Installing ${ORANGE}git${GREY}... ${EMOJI_WAIT}"
    case "$PACKAGE_MANAGER" in
        brew)    brew install git >/dev/null ;;
        apt)     $SUDO apt-get update >/dev/null && $SUDO apt-get install -y git >/dev/null ;;
        dnf)     $SUDO dnf install -y git >/dev/null ;;
        pacman)  $SUDO pacman -Sy --noconfirm git >/dev/null ;;
        yum)     # TODO
        *)       printStyled error "Package manager not supported" ; return 1;;
    esac

    # Check install
    if command -v git >/dev/null; then
        printStyled success "Installed: ${ORANGE}git${NONE}"
        return 0
    else
        printStyled error "Unable to install ${ORANGE}git${NONE}"
        return 1
    fi
}

install_bash() {

    # Check if already installed
    if command -v bash >/dev/null; then
        printStyled success "Already installed: ${ORANGE}bash${NONE}"
        return 0
    fi

    # Install
    printStyled info "Installing ${ORANGE}bash${GREY}..."
    case "$PACKAGE_MANAGER" in
        apt)    $SUDO apt-get install -y bash >/dev/null || return 1 ;;
        dnf)    $SUDO dnf install -y bash >/dev/null || return 1 ;;
        pacman) $SUDO pacman -Sy --noconfirm bash >/dev/null || return 1 ;;
        brew)   brew install bash >/dev/null || return 1 ;;
        yum)     # TODO
        *)      printStyled error "Package manager not supported" ; return 1;;
    esac
    printStyled success "Installed: ${ORANGE}bash${GREY}"
}

# Installs Homebrew when absent, selecting curl or wget as downloader
install_brew() {
    
    # Check if already installed
    if command -v brew >/dev/null; then
        printStyled success "Detected: ${ORANGE}Homebrew${NONE}"
        return 0
    fi

    # On Linux, install the compiler tool‑chain Homebrew needs
    if [ "$IS_LINUX" = true ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" || true
        printStyled info "[LINUX - ${ORANGE}apt${GREY}] → Added to path: ${ORANGE}linuxbrew${NONE}"

        case "$PACKAGE_MANAGER" in
            apt)
                printStyled info "[LINUX - ${ORANGE}apt${GREY}] → Installing the compiler tool-chain Homebrew needs..."
                $SUDO apt-get update -y  >/dev/null
                $SUDO apt-get install -y build-essential >/dev/null || printStyled warning "Install failed: ${ORANGE}build-essential${NONE}"
                ;;
            dnf)
                printStyled info "[LINUX - ${ORANGE}dnf${GREY}] → Installing the compiler tool-chain Homebrew needs..."
                $SUDO dnf groupinstall -y "Development Tools" >/dev/null || printStyled warning "Install failed: ${ORANGE}Development Tools${NONE}"
                ;;
            pacman)
                printStyled info "[LINUX - ${ORANGE}pacman${GREY}] → Installing the compiler tool-chain Homebrew needs..."
                $SUDO pacman -Sy --noconfirm base-devel >/dev/null || printStyled warning "Install failed: ${ORANGE}base-devel${NONE}"
                ;;
            yum)     # TODO
        esac
    fi

    # Install Homebrew
    printStyled info "Installing ${ORANGE}Homebrew${GREY}... ${EMOJI_WAIT}"
    case "$HTTP_CLIENT" in
        curl)
            if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null; then
                printStyled error "Install failed: ${ORANGE}Homebrew${NONE}"
                return 1
            fi
            ;;
        wget)
            if ! /bin/bash -c "$(wget -q -O - https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null; then
                printStyled error "Install failed: ${ORANGE}Homebrew${NONE}"
                return 1
            fi
            ;;
        *) 
    esac

    # Check install
    if ! command -v brew >/dev/null; then
        printStyled error "Unable to install ${ORANGE}Homebrew${NONE}"
        return 1
    fi
    PACKAGE_MANAGER="brew"
    
    # Load Homebrew into the current shell
    if [ -d "$HOME/.linuxbrew" ]; then
        eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
    elif [ -d /home/linuxbrew/.linuxbrew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    # Persist Homebrew for future sessions (default shell + zsh)
    files="bashrc zshrc kshrc profile"
    for file in $files; do
        [ -n "$file" ] || continue
        [ -e "$file" ] || touch "$file"
        if ! grep -q 'brew shellenv' "$file"; then
            printf 'eval "$(%s/bin/brew shellenv)"\n' "$(brew --prefix)" >> "$file"
        fi
    done
    
    # Success
    printStyled success "Installed: ${ORANGE}Homebrew${NONE}"
}

# ────────────────────────────────────────────────────────────────
# DOWNLOAD
# ────────────────────────────────────────────────────────────────

# Retrieves GACLI source (curl, wget or git) into the target directory, honouring --force
download_gacli() {

    # Create destination folder
    [ ! -d "$DIR" ] || {
        [ "$FORCE_MODE" = "true" ] && { rm -rf "$DIR"; } || {
            printStyled error "$DIR already exists (--force to overwrite)"
            return 1
        }
    }
    mkdir -p "$DIR" || { printStyled error "Unable to create $DIR"; return 1; }

    # HTTP try
    case "$HTTP_CLIENT" in
        curl)
            if curl -fsSL "$ARCHIVE" | tar -xzf - -C "$DIR" --strip-components=1 >/dev/null; then
                printStyled success "Downloaded"
                return 0
            else
                printStyled warning "Download failed"
            fi
            ;;
        wget)
            if wget -q -O - "$ARCHIVE" | tar -xzf - -C "$DIR" --strip-components=1 >/dev/null; then
                printStyled success "Downloaded"
                return 0
            else
                printStyled warning "Download failed"
            fi
            ;;
        *) printStyled error "No HTTP client" ;;
    esac

    # Git fallback
    printStyled info "→ Fallback on ${ORANGE}git${NONE}..."
    branch="${ARCHIVE##*/}"
    branch="${branch%.tar.gz}"
    if git clone --depth 1 --branch "$branch" "$REPO" "$DIR"; then
        printStyled success "Downloaded"
        return 0
    else
        printStyled error "Failed to clone repository"
        return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# INSTALL
# ────────────────────────────────────────────────────────────────

# Runs brew bundle on the downloaded Brewfile to install required formulae and casks
install_deps() {
    brewfile="$DIR/.auto-install/Brewfile"
    if command -v brew >/dev/null && [ -f "$brewfile" ]; then
        brew bundle --file="$brewfile" >/dev/null || {
            printStyled error "Failed to run Brewfile"
            return 1
        }
        printStyled success "Installed"
    else
        printStyled warning "No Brewfile found or brew unavailable → skipping"
    fi
}

# Adds execute permission to the downloaded GACLI entry‑point script
make_executable() {
    chmod +x "$ENTRY_POINT" || {
        printStyled error "Failed make $ENTRY_POINT executable"
        return 1
    }
    printStyled success "Entry point made executable"
}

# Generates a wrapper in $HOME/.local/bin that relays args to the entry point via zsh
create_wrapper() {
    mkdir -p "$SYM_DIR" || {
        printStyled error "Failed to create $SYM_DIR"; return 1
    }

    if [ -f "$SYMLINK" ] || [ -d "$SYMLINK" ] || [ -L "$SYMLINK" ]; then
        rm -f "$SYMLINK"
    fi

    {
        printf '%s\n' '#!/usr/bin/env sh'
        printf '%s\n' "exec zsh \"$ENTRY_POINT\" \"\$@\""
    } > "$SYMLINK" && chmod +x "$SYMLINK" || {
        printStyled error "Failed to create wrapper"; return 1
    }
    printStyled success "Wrapper created → ${NONE}$SYMLINK${GREY} → ${NONE}$ENTRY_POINT"
}

# Appends PATH export and source command to the user’s .zshrc when missing
update_zshrc() {

    touch "$ZSHRC" || {
        printStyled error "Unable to create .zshrc file: $ZSHRC"
        return 1
    }

    if grep -q '# GACLI' "$ZSHRC"; then
        printStyled success ".zshrc already configured"
        return 0
    fi
    {
        printf '\n\n# GACLI\n'
        printf 'export PATH="%s:$PATH"\n' "$SYM_DIR"
        printf 'source "%s"\n' "$ENTRY_POINT"
    } >> "$ZSHRC" || {
        printStyled error "Failed update $ZSHRC"; return 1
    }
    printStyled success ".zshrc updated"
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

auto_launch() {
    echo ""
    printStyled success "${ORANGE}GACLI${GREEN} successfully installed 🚀"
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
