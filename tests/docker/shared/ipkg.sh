#!/usr/bin/env sh

# Native package managers abstraction
# (Native Package Manager Interface)

REPO="guillaumeast/gacli" # TODO: Create own repo ?
BRANCH="dev"
GH_RAW_URL="https://raw.githubusercontent.com/${REPO}/refs/heads/${BRANCH}"
INSTALLER_BREW="${GH_RAW_URL}/installers/ibrew.sh"
INSTALLER_GACLI="${GH_RAW_URL}/installers/igacli.sh"

HTTP_CLIENTS="curl wget"
HTTP_CLIENT=""

# ────────────────────────────────────────────────────────────────
# LOADER
# ────────────────────────────────────────────────────────────────

FRAMES="⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"
DELAY=0.05
DEFAULT_MESSAGE="Loading..."
MESSAGE=""
PAUSED="false"
SPINNER_PID=""

# ⚠️ Don't forget in calling function → trap 'loader_stop' EXIT
loader_start() {

    message="${1:-$DEFAULT_MESSAGE}"

    [ "${PAUSED}" = "false" ] && MESSAGE="${message}"

    # Kill previous loader process if exists
    PAUSED="false"
    loader_stop

    # Create process
    {
        while true; do
            for frame in $FRAMES; do
                printf "\r\033[K%s %s" "${ORANGE}${frame}${NONE}" "${ORANGE}${MESSAGE}${NONE}"
                sleep $DELAY
            done
        done
    } &

    # Save process ID
    SPINNER_PID=$!
}

loader_pause() {
    
    PAUSED="true"
    loader_stop
}

loader_stop() {

    if [ -n "$SPINNER_PID" ] && kill -0 "$SPINNER_PID" 2>/dev/null; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
        SPINNER_PID=""
        printf "\r\033[K"
    fi
}

loader_is_active() {

    [ -n "$SPINNER_PID" ] || return 1
}

# ────────────────────────────────────────────────────────────────
# I/O FORMATTING
# ────────────────────────────────────────────────────────────────

RED="$(printf '\033[31m')"
GREEN="$(printf '\033[32m')"
YELLOW="$(printf '\033[33m')"
CYAN="$(printf '\033[36m')"
ORANGE="$(printf '\033[38;5;208m')"
GREY="$(printf '\033[90m')"
NONE="$(printf '\033[0m')"

EMOJI_SUCCESS="✓"
EMOJI_WARN="⚠️ "
EMOJI_ERR="🛑"
EMOJI_INFO="✧"
EMOJI_TBD="⚐"
EMOJI_HIGHLIGHT="→"
EMOJI_DEBUG="🔎"
EMOJI_WAIT="✧ ⏳"

printStyled() {

    style=$1
    text=$2

    case "${style}" in
        error)
            prefix="Error: "
            color_text=$RED
            color_emoji=$RED
            emoji=$EMOJI_ERR
            output_stream=2
            ;;
        warning)
            prefix="Warning: "
            color_text=$YELLOW
            color_emoji=$YELLOW
            emoji=$EMOJI_WARN
            output_stream=2
            ;;
        success)
            prefix=""
            color_text=$GREY
            color_emoji=$GREEN
            emoji=$EMOJI_SUCCESS
            output_stream=1
            ;;
        wait)
            prefix=""
            color_text=$GREY
            color_emoji=$GREY
            emoji=$EMOJI_WAIT
            output_stream=1
            ;;
        info)
            prefix=""
            color_text=$GREY
            color_emoji=$GREY
            emoji=$EMOJI_INFO
            output_stream=1
            ;;
        fallback)
            prefix=""
            color_text=$GREY
            color_emoji=$ORANGE
            emoji=$EMOJI_TBD
            output_stream=1
            ;;
        highlight)
            prefix=""
            color_text=$NONE
            color_emoji=$NONE
            emoji=$EMOJI_HIGHLIGHT
            output_stream=1
            ;;
        debug)
            prefix="Debug: "
            color_text=$YELLOW
            color_emoji=$YELLOW
            emoji=$EMOJI_DEBUG
            output_stream=2
            ;;
        *)
            prefix=""
            color_text=$NONE
            color_emoji=$NONE
            emoji=""
            output_stream=1
            ;;
    esac

    text="${color_emoji}${emoji} ${color_text}${prefix}${text}${NONE}"

    if loader_is_active; then
        loader_pause
        echo "$text" >&"$output_stream"
        loader_start
    else
        echo "$text" >&"$output_stream"
    fi
}

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

# TODO: add --install       → install ipkg command
# TODO: add --bulk          → install all deps at once
# TODO: add --no-update     → don't update before install
# TODO: add --force         → don't skip already installed packages
# TODO: add --no-cleanup    → don't clean after install
# TODO: add --quiet         → only show error messages
# TODO: add --verbose       → show all raw commands outputs
main() {

    raw_packets="$@"

    echo

    posix_guard     || exit 1
    force_sudo "$@" || exit 2

    install_brew="false"
    install_gacli="false"
    formatted_packets=""
    for packet in $raw_packets; do
        
        [ $packet = "brew" ] && install_brew="true" && continue
        [ $packet = "gacli" ] && install_gacli="true" && continue

        [ -z "$formatted_packets" ] && formatted_packets="${packet}" && continue
        formatted_packets="${formatted_packets} ${packet}"
    done

    if [ -n "${formatted_packets}" ]; then
        pkg_install "$formatted_packets" || exit 3
    fi

    if [ $install_brew = "true" ]; then
        install_brew || exit 4
    fi

    if [ $install_gacli = "true" ]; then
        install_gacli || exit 5
    fi

    echo
}

# ────────────────────────────────────────────────────────────────
# INIT
# ────────────────────────────────────────────────────────────────

posix_guard() {

    shell_name="$(ps -p $$ -o comm= 2>/dev/null)"

    case "${shell_name}" in
        zsh)
            # Force POSIX mode (Zsh is not POSIX by default)
            emulate -L sh || return 1
        ;;
        fish)
            # Abort if sourced (Fish is not POSIX-compatible)
            echo "❌ This script is POSIX. Run with: sh install.sh" >&2
            return 1
        ;;
    esac
}

force_sudo() {

    # Root → fine
    if [ "$(id -u)" -eq 0 ]; then
        printStyled success "Privilege   → ${GREEN}root${NONE}"
        return 0
    fi

    # Sudo → Retry in sudo mode
    if command -v sudo >/dev/null 2>&1; then
        echo "🔐 ${YELLOW}Password may be required${NONE}"
        # TODO: fix pipe support ! (fails on archlinux when `... | sh`)
        exec sudo -E sh "$0" "$@"
    fi

    # No sudo → Warn install may fail
    printStyled fallback "Privilege   → ${ORANGE}non-root user${GREY} (${ORANGE}sudo${GREY} not detected)${NONE}"
    printStyled warning "Non-root install may fail"
}

# ────────────────────────────────────────────────────────────────
# PACKAGE MANAGER ABSTRACTION
# ────────────────────────────────────────────────────────────────

# TODO: add apk, yum, nix-env, xbps-installserver-side to SUPPORTED_PKG ?
SUPPORTED_PKG="brew apt urpmi dnf pacman zypper slackpkg" # slackpkg really sypported ?
UNSUPPORTED_PKG='"emerge=unpredictible packet names" "pkg=unpredictible packet names" "apk=glibc-based distribution required" "yum=git ≥ 2.7.0 not available" "nix-env=FHS required" "xbps-installserver-side SSL/TLS issues"'
CURRENT_PKG=""

FORMAT_DEFAULT="ruby-stdlib=ruby libsasl2-2=cyrus-sasl procps=procps-ng"
FORMAT_APT="procps-ng=procps cyrus-sasl=libsasl2-2"
FORMAT_PACMAN="ruby=ruby-stdlib nghttp2="
FORMAT_ZYPPER="procps-ng=procps nghttp2="

# TODO: pkg_install → update x 1 → install x N → clean x 1
# TODO: progress bar (current = installed / total)
pkg_install() {

    raw_deps="$@"

    if [ -z "${raw_deps}" ]; then
        printStyled error "Expected: <@packet_names>; received: '$@'"
        echo
        return 1
    fi

    pkg_manager=$(pkg_get_current) || return 1
    printStyled success "Pkg manager → ${pkg_manager}"

    printStyled success "Raw         → ${raw_deps}"
    formatted_deps=$(_pkg_format_deps "${pkg_manager}" $raw_deps) || return 1
    printStyled success "Formatted   → ${formatted_deps}"

    echo
    return_value=0

    _pkg_update "${pkg_manager}" || printStyled warning "  → Package manager update failed"    
    _pkg_install "${pkg_manager}" "${formatted_deps}" || return_value=1
    _pkg_clean "${pkg_manager}" || printStyled warning "  → Cleanup failed"
    
    echo
    return $return_value
}

pkg_get_current() {

    # Return cached value
    if [ -n "${CURRENT_PKG}" ]; then

        echo "${CURRENT_PKG}"
        return 0
    fi

    for pkg_manager in $SUPPORTED_PKG; do

        ! command -v "${pkg_manager}" >/dev/null 2>&1 && continue

        CURRENT_PKG=$pkg_manager

        echo "${CURRENT_PKG}"
        return 0
    done

    for pkg_manager in $UNSUPPORTED_PKG; do

        name="${pkg_manager%%=*}"
        issue="${pkg_manager#*=}"

        ! command -v "$name" >/dev/null 2>&1 && continue

        printStyled error "Unsupported package manager: ${ORANGE}${name}${RED} → ${issue}"
        echo
        return 1
    done

    printStyled error "Unsupported package manager"
    echo
    return 1
}

_pkg_format_deps() {

    pkg_manager=$1
    shift
    deps="$@"
    if [ -z "${pkg_manager}" ] || [ -z "${deps}" ]; then
        printStyled error "Expected <pkg_manager> <@deps>; received ${pkg_manager} ${deps}"
        echo
        return 1
    fi

    rules=""
    case "${pkg_manager}" in
        apt)
            rules="$FORMAT_APT"
        ;;
        pacman)
            rules="$FORMAT_PACMAN"
        ;;
        zypper)
            rules="$FORMAT_ZYPPER"
        ;;
    esac

    out=""
    for dep in $deps;do

        # 1. Default rules
        for rule in $FORMAT_DEFAULT; do

            raw="${rule%%=*}"
            formatted="${rule#*=}"

            [ "${dep}" != "${raw}" ] && continue

            dep=$formatted
            break
        done

        # 2. Package manager specific rules
        for rule in $rules; do

            raw="${rule%%=*}"
            formatted="${rule#*=}"

            [ "${dep}" != "${raw}" ] && continue

            dep=$formatted
            break
        done
        
        [ -z "${dep}" ] && continue


        if [ -z "${out}" ]; then
            out=$dep
        else
            out="${out} ${dep}"
        fi

    done

    # Use printf to avoid word splitting and preserve spaces
    printf '%s\n' "$out"
}

_pkg_update() {

    pkg_manager="${1}"

    if [ -z "${pkg_manager}" ]; then
        printStyled error "[_pkg_update] Expected: <pkg_manager>"
        echo
        return 1
    fi

    loader_start "Updating    → ${pkg_manager}"
    trap 'loader_stop' EXIT

    case "${pkg_manager}" in
        brew)
            brew upgrade >/dev/null 2>&1 || return 1
            ;;
        apt)
            apt-get update >/dev/null 2>&1 || return 1
            apt-get install -y build-essential >/dev/null 2>&1 || return 1
            ;;
        urpmi)
            urpmi.update -a >/dev/null 2>&1 || return 1
            ;;
        dnf)
            dnf makecache >/dev/null 2>&1 || return 1
            if dnf --version 2>/dev/null | grep -q "5\."; then
                dnf install -y @development-tools >/dev/null 2>&1 || return 1
            else
                dnf group install -y "Development Tools" >/dev/null 2>&1 || return 1
            fi
            ;;
        pacman)
            pacman -Syu --noconfirm --needed base-devel || return 1
            ;;
        zypper)
            zypper refresh >/dev/null 2>&1 || return 1
            zypper install -y -t pattern devel_basis >/dev/null 2>&1 || return 1
            ;;
        slackpkg)
            slackpkg update >/dev/null 2>&1 || return 1
            ;;
        *)
            printStyled error "Unsupported package manager: ${ORANGE}${pkg_manager}${RED}"
            echo
            return 1
            ;;
    esac

    loader_stop
    printStyled success "Updated     → ${pkg_manager}"
}

_pkg_install() {

    pkg_manager="${1}"
    shift
    deps="$@"

    if [ -z "${pkg_manager}" ] || [ -z "${deps}" ]; then
        printStyled error "[_pkg_install] Expected: <pkg_manager> <@deps>"
        echo
        return 1
    fi

    are_all_installed="true"
    for dep in $deps; do
        loader_start "Installing  → ${dep}"
        trap 'loader_stop' EXIT

        is_installed="true"
        case "${pkg_manager}" in
            brew)
                brew install $dep >/dev/null 2>&1 || is_installed="false"
                ;;
            apt)
                DEBIAN_FRONTEND=noninteractive apt-get install -y $dep >/dev/null 2>&1 || is_installed="false"
                ;;
            urpmi)
                urpmi --auto $dep >/dev/null 2>&1 || is_installed="false"
                ;;
            dnf)
                dnf install -y $dep >/dev/null 2>&1 || is_installed="false"
                ;;
            pacman)
                pacman --noconfirm --needed $dep >/dev/null 2>&1 || is_installed="false"
                ;;
            zypper)
                zypper install -y $dep >/dev/null 2>&1 || is_installed="false"
                ;;
            slackpkg)
                yes | slackpkg install $dep >/dev/null 2>&1 || is_installed="false"
                ;;
            *)
                printStyled error "Unsupported package manager: ${ORANGE}${pkg_manager}${RED}"
                echo
                return 1
                ;;
        esac

        loader_stop
        if [ $is_installed = "true" ]; then
            printStyled success "Installed   → ${GREEN}${dep}${NONE}"
        else
            are_all_installed="false"
            printStyled warning "  → ${RED}${dep}${YELLOW} install failed"
        fi
    done

    [ $are_all_installed = "false" ] && return 1
}

_pkg_clean() {

    pkg_manager="${1}"

    if [ -z "${pkg_manager}" ]; then
        printStyled error "[_pkg_clean] Expected: <pkg_manager>"
        echo
        return 1
    fi

    loader_start "Cleaning"
    trap 'loader_stop' EXIT

    case "${pkg_manager}" in
        brew)
            brew cleanup >/dev/null 2>&1
            ;;
        apt)
            apt-get clean >/dev/null 2>&1 
            ;;
        urpmi)
            urpme --auto-orphans >/dev/null 2>&1 
            ;;
        dnf)
            dnf clean all >/dev/null 2>&1 
            ;;
        pacman)
            # pacman clean skipped (not recommended automatically)
            ;;
        zypper)
            # zypper clean skipped (optional)
            ;;
        slackpkg)
            # no reliable clean command for slackpkg
            # update-ca-certificates --fresh >/dev/null 2>&1 # TODO: where to put it ? install_brew.sh ..?
            ;;
        *)
            printStyled error "Unsupported package manager: ${ORANGE}${pkg_manager}${RED}"
            echo
            return 1
            ;;
    esac

    loader_stop
    printStyled success "Cleaned"
}

# ────────────────────────────────────────────────────────────────
# HTTP CLIENT ABSTRACTION
# ────────────────────────────────────────────────────────────────

http_download() {

    url="${1}"
    destination="${2}"

    if [ -z "${url}" ] || [ -z "${destination}" ]; then
        printStyled error "Exepcted: <url:source> <path:destination>; received: $@"
        echo
        return 1
    fi

    _http_install || return 1

    case "${HTTP_CLIENT}" in
        curl)
            download_cmd="curl -fsSL"
            ;;
        wget)
            download_cmd="wget -qO-"
            ;;
        *)
            printStyled error "Unable to find http client"
            echo
            return 1
            ;;
    esac

    loader_start "Downloading from '${CYAN}${url}${ORANGE}'..."
    trap 'loader_stop' EXIT

    if ! "${download_cmd}" "${url}" > "${destination}" > /dev/null 2>&1; then
        loader_stop
        printStyled error "Failed to download from '${CYAN}${url}${NONE}'"
        echo
        return 1
    fi
    
    loader_stop
    printStyled success "Downloaded"
}

_http_install() {

    _http_check && return 0

    for client in $HTTP_CLIENTS; do
        pkg_install "${client}" && HTTP_CLIENT="$client" && return 0
    done

    printStyled error "Unable to install http client (tried: ${ORANGE}${HTTP_CLIENTS}${YELLOW})${NONE}"
    echo
    return 1
}

_http_check() {

    for client in $HTTP_CLIENTS; do

        ! command -v "$client" >/dev/null 2>&1 && continue

        HTTP_CLIENT="$client"
        printStyled success "HTTP client → ${HTTP_CLIENT}"
        return 0
    done

    printStyled fallback "No HTTP client found"
    return 1
}

# ────────────────────────────────────────────────────────────────
# INSTALL BREW
# ────────────────────────────────────────────────────────────────

install_brew() {
    
    # TODO: use mktemp
    tmp_installer="/tmp/install_brew.sh"
    trap 'rm -f ${tmp_installer}' EXIT

    http_download "${INSTALLER_BREW}" "${tmp_installer}" || return 1

    . "${tmp_installer}" || return 1
}

# ────────────────────────────────────────────────────────────────
# INSTALL GACLI
# ────────────────────────────────────────────────────────────────

install_gacli() {

    # TODO: use mktemp
    tmp_installer="/tmp/install_gacli.sh"
    trap 'rm -f ${tmp_installer}' EXIT

    http_download "${INSTALLER_GACLI}" "${tmp_installer}" || return 1

    . "${tmp_installer}" || return 1
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

main "$@"

