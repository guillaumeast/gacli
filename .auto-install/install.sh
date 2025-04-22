#!/usr/bin/env sh
###############################
# FICHIER /.auto-install/install.sh
###############################

# Run it automaticaly: ``

# Run it manually:
    # docker run --name "test" -v "/Users/gui/Repos/docker/shared:/shared" -it "ubuntu" "sh"
    # . ./shared/install.sh
#

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
# |→ ✅ install_gacli_deps        → Install GACLI dependencies from "${DIR}/.auto-install/Brewfile"
# |→ ✅ make_executable           → Ensure GACLI entry point is executable
# |→ ✅ create_wrapper            → Generate a small shell script to launch GACLI reliably across shells
# |→ ✅ update_zshrc              → Append GACLI to PATH and source its entry point in ~/.zshrc
# |
# |→ ✅ auto_launch               → Launch GACLI

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

    # echo ""
    # printStyled highlight "Installing shell: zsh..."
    # TODO: fix install_zsh     || return 5

    echo ""
    printStyled highlight "Downloading GACLI ${GREY}→${CYAN} ${DIR}${GREY}...${NONE}"
    download_gacli  || return 6

    echo ""
    printStyled highlight "Installing GACLI dependencies... ${EMOJI_WAIT}"
    install_gacli_deps    || return 7

    echo ""
    printStyled highlight "Installing GACLI CLI..."
    make_executable || return 8
    create_wrapper  || return 9
    update_zshrc    || return 10

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
    printStyled info "Arguments: ${GREEN}parsed${NONE}"
}

# Expands user‑relative paths, ensures .zshrc exists, and defines wrapper targets
resolve_paths() {
    [ -n "$HOME" ] || { printStyled error "\$HOME not set"; return 1; }

    DIR="$HOME/$DIR"
    ENTRY_POINT="$DIR/$ENTRY_POINT"
    ZSHRC="$HOME/$ZSHRC"
    SYM_DIR="$HOME/$SYM_DIR"
    SYMLINK="$SYM_DIR/$SYMLINK"
    printStyled info "Paths: ${GREEN}resolved${NONE}"
}

# Detects OS, default shell and privilege
check_env() {
    # Detect OS via uname
    ud=$(uname -s)
    case "$ud" in
        Darwin) IS_MACOS=true ;;
        Linux)  IS_LINUX=true ;;
        *)      printStyled error "Unsupported OS: $ud"; return 1 ;;
    esac
    printStyled info "OS detected: ${GREEN}$ud${NONE}"

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
    printStyled info "Default shell: ${color}${SHELL_NAME}${GREY} → ${CYAN}${SHELL_PATH}${NONE}"

    # — Privilege escalation setup —
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
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
    install_brew_deps

    # Install
    printStyled info "Installing ${ORANGE}Homebrew${GREY}... ${EMOJI_WAIT}"
    yes '' | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null 2>&1
    
    # Setup Linux env
    if [ "$IS_LINUX" = true ]; then
        files="/root/.profile /root/.kshrc /root/.bashrc /root/.zshrc /root/.dashrc /root/.tcshrc /root/.cshrc"
        printStyled info "Configuring ${ORANGE}Linux${GREY}..."

        # Add Homebrew to all source files
        for file in $files; do
            echo >> "$file"
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$file"
        done

        # Add Homebrew to current session
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

        # Install gcc if missing
        if ! command -v gcc >/dev/null 2>&1; then
            brew install gcc >/dev/null 2>&1
        fi
    fi

    # Check install
    if ! command -v brew >/dev/null 2>&1; then
        printStyled error "Unable to install ${GREEN}Homebrew${NONE}"
        return 1
    fi
    
    # Success
    printStyled info "Installed: ${GREEN}Homebrew${NONE}"
}

# Installs Homebrew dependencies
install_brew_deps() {
    
    # Depending on current package manager
    if command -v apt >/dev/null 2>&1; then
        printStyled info "Current package manager: ${ORANGE}apt${NONE}"
        printStyled info "Installing Homebrew dependencies... ${EMOJI_WAIT}"
        $SUDO apt-get update -y >/dev/null 2>&1
        $SUDO apt-get install -y build-essential procps curl file git bash >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        printStyled info "Current package manager: ${ORANGE}dnf${NONE}"
        printStyled info "Installing Homebrew dependencies... ${EMOJI_WAIT}"
        $SUDO dnf groupinstall -y "Development Tools" >/dev/null 2>&1
        $SUDO dnf install -y procps-ng file bash >/dev/null 2>&1
    elif command -v pacman >/dev/null 2>&1; then
        printStyled info "Current package manager: ${ORANGE}pacman${NONE}"
        printStyled info "Installing Homebrew dependencies... ${EMOJI_WAIT}"
        $SUDO pacman -Sy --noconfirm base-devel procps-ng curl file git bash >/dev/null 2>&1
    elif command -v yum >/dev/null 2>&1; then
        printStyled info "Current package manager: ${ORANGE}yum${NONE}"
        printStyled info "Installing Homebrew dependencies... ${EMOJI_WAIT}"
        $SUDO yum groupinstall 'Development Tools' >/dev/null 2>&1
        $SUDO yum install -y procps-ng curl file git bash >/dev/null 2>&1
    else
        printStyled warning "No supported package manager found"
    fi
}

# Install zsh (if needed) and make it the user’s default login shell
install_zsh() {
    printStyled info "Trying to install zsh..."

    target_shell=$(command -v zsh)
    [ -z "$target_shell" ] && {
        printStyled error "zsh not found in PATH"
        return 1
    }

    # Ajoute zsh dans /etc/shells si besoin
    if [ -n "$SUDO" ] && [ -w /etc/shells ] && ! grep -q "$target_shell" /etc/shells 2>/dev/null; then
        echo "$target_shell" | $SUDO tee -a /etc/shells >/dev/null
    fi

    # Détermine le shell actuel
    current_shell=$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)
    [ -z "$current_shell" ] && current_shell="$SHELL"

    if [ "$current_shell" = "$target_shell" ]; then
        printStyled success "Default shell already ${GREEN}zsh${NONE}"
        return 0
    fi

    printStyled info "Switching default shell to ${ORANGE}zsh${GREY}..."
    
    # Ne tente pas de changer dans un conteneur Docker
    if grep -qa 'docker\|lxc' /proc/1/cgroup 2>/dev/null; then
        printStyled warning "Running in a container → skipping chsh"
        return 0
    fi

    if command -v chsh >/dev/null 2>&1; then
        if [ -n "$SUDO" ]; then
            $SUDO chsh -s "$target_shell" "$(id -un)" >/dev/null 2>&1
        else
            chsh -s "$target_shell" >/dev/null 2>&1
        fi
        printStyled success "Default shell changed: ${GREEN}zsh${NONE}"
    else
        printStyled warning "chsh not available → cannot change default shell"
    fi
}

# ────────────────────────────────────────────────────────────────
# INSTALL GACLI
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

    # Download
    if curl -fsSL "$ARCHIVE" | tar -xzf - -C "$DIR" --strip-components=1 >/dev/null 2>&1; then
        printStyled success "Downloaded"
        return 0
    else
        printStyled warning "Download failed"
    fi
}

# Runs brew bundle on the downloaded Brewfile to install required formulae and casks
install_gacli_deps() {
    brewfile="$DIR/.auto-install/Brewfile"
    if command -v brew >/dev/null 2>&1 && [ -f "$brewfile" ]; then
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
        printStyled warning "Failed make $ENTRY_POINT executable"
        return 1
    }
    printStyled info "Entry point: ${GREEN}executable${NONE}"
}

# Generates a wrapper in $HOME/.local/bin that relays args to the entry point via zsh
create_wrapper() {
    mkdir -p "$SYM_DIR" || {
        printStyled warning "Failed to create $SYM_DIR"; return 1
    }

    if [ -f "$SYMLINK" ] || [ -d "$SYMLINK" ] || [ -L "$SYMLINK" ]; then
        rm -f "$SYMLINK"
    fi

    {
        printf '%s\n' '#!/usr/bin/env sh'
        printf '%s\n' "exec zsh \"$ENTRY_POINT\" \"\$@\""
    } > "$SYMLINK" && chmod +x "$SYMLINK" || {
        printStyled warning "Failed to create wrapper"; return 1
    }
    printStyled info "Wrapper: ${GREEN}created${GREY} → ${CYAN}$SYMLINK${GREY} → ${CYAN}$ENTRY_POINT${NONE}"
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
        printStyled warning "Failed update $ZSHRC"; return 1
    }
    printStyled info ".zshrc: ${GREEN}updated${NONE}"
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

