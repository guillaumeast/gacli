#!/usr/bin/env zsh
###############################
# FICHIER /<TODO: path>/pkg.zsh (move to src/helpers or installer/ ?)
###############################

# Full POSIX sh script to abstract package managers handling

# TODO: add apk, yum, nix-env, xbps-installserver-side to SUPPORTED_PKG ?
SUPPORTED_PKG="brew apt urpmi dnf pacman zypper slackpkg" # slackpkg really sypported ?
UNSUPPORTED_PKG='"emerge=unpredictible packet names" "pkg=unpredictible packet names" "apk=glibc-based distribution required" "yum=git ≥ 2.7.0 not available" "nix-env=FHS required" "xbps-installserver-side SSL/TLS issues"'
CURRENT_PKG=""

# 1. Default formatting rules
FORMAT_DEFAULT="ruby-stdlib=ruby libsasl2-2=cyrus-sasl procps=procps-ng"

# 2. Package manager specific rules
FORMAT_APT="procps-ng=procps cyrus-sasl=libsasl2-2"
FORMAT_PACMAN="ruby=ruby-stdlib nghttp2="
# WIP: 🚧 fixing archlinux (all other distros green)
# WIP: try 1 → ruby-erb     → ✅ manual    → ❌ auto
# WIP: try 2 → ruby-stdlib  → 🚧 manual    → ✅ auto
FORMAT_ZYPPER="procps-ng=procps nghttp2="

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# Install packages
pkg_install() {

    raw_deps=$@
    if [ -z "${raw_deps}" ]; then
        printStyled error "Expected: <@packet_names>; received: '$@'"
        return 1
    fi

    pkg_manager=$(pkg_get_current) || return 1
    formatted_deps=$(_pkg_format_deps "${pkg_manager}" $raw_deps) || return 1
    
    case "${pkg_manager}" in # TODO: add >/dev/null 2>&1
        brew)
            brew upgrade || return 1
            brew install $formatted_deps || return 1
            ;;
        apt)
            apt-get update -y || return 1
            DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential $formatted_deps || return 1
            apt-get clean
            ;;
        urpmi)
            urpmi.update -a || return 1
            urpmi --auto $formatted_deps || return 1
            urpme --auto-orphans
            ;;
        dnf)
            if dnf --version 2>/dev/null | grep -q "5\."; then
                dnf install -y @development-tools || return 1
            else
                dnf group install -y "Development Tools" || return 1
            fi
            dnf install -y $formatted_deps || return 1
            dnf clean all
            ;;
        pacman)
            pacman -Sy --noconfirm base-devel $formatted_deps || return 1
            ;;
        zypper)
            zypper refresh || return 1
            zypper install -y -t pattern devel_basis || return 1
            zypper install -y $formatted_deps || return 1
            ;;
        slackpkg)
            slackpkg update || return 1
            yes | slackpkg install $formatted_deps || return 1
            update-ca-certificates --fresh
            ;;
        *)
            printStyled error "Unsupported package manager: ${ORANGE}${pkg_manager}${RED}"
            return 1
            ;;
    esac
}

pkg_get_current() {

    # Return cached value
    if [ -n "${CURRENT_PKG}" ]; then

        echo "${CURRENT_PKG}"
        return 0
    fi

    for pkg_manager in $SUPPORTED_PKG; do

        if ! command -v "${pkg_manager}" >/dev/null 2>&1; then
            continue
        fi

        CURRENT_PKG=$pkg_manager

        echo "${CURRENT_PKG}"
        return 0
    done

    for pkg_manager in $UNSUPPORTED_PKG; do # TODO: fix (items may contain spaces)

        name="${pkg_manager%%=*}"
        issue="${pkg_manager#*=}"

        if ! command -v "$name" >/dev/null 2>&1; then
            continue
        fi

        printStyled error "Unsupported package manager: ${ORANGE}${name}${RED} → ${issue}"
        return 1
    done

    printStyled error "Unsupported package manager"
    return 1
}

_pkg_format_deps() {

    pkg_manager=$1
    shift
    deps="$@"
    if [ -z "${pkg_manager}" ] || [ -z "${deps}" ]; then
        printStyled error "Expected <pkg_manager> <@deps>; received ${pkg_manager} ${deps}"
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

# ────────────────────────────────────────────────────────────────
# TESTS (TODO: create zunit test)
# ────────────────────────────────────────────────────────────────

printStyled() {

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
        debug)
            printf "%s\n" "${EMOJI_DEBUG} ${YELLOW}Debug: ${msg}${NONE}" >&2
            return ;;
        *)
            emoji=""
            ;;
    esac
    printf "%s\n" "${color_emoji}${emoji} ${color_text}${msg}${NONE}"
}

_pkg_test() {

    BREW_DEPS="bash ruby procps cyrus-sasl nghttp2"
    TEST_DEPS_1="bash ruby procps cyrus-sasl nghttp2"
    TEST_DEPS_2="bash ruby-stdlib procps-ng libsasl2-2 nghttp2"

    for pkg in $SUPPORTED_PKG; do

        echo
        printStyled highlight "pkg: ${pkg}"

        expected=""
        case "${pkg}" in
            apt)
                expected="bash ruby procps libsasl2-2 nghttp2"
            ;;
            pacman)
                expected="bash ruby-stdlib procps-ng cyrus-sasl"
            ;;
            zypper)
                expected="bash ruby procps cyrus-sasl"
            ;;
            *)
                expected="bash ruby procps-ng cyrus-sasl nghttp2"
            ;;
        esac
        printStyled info "→ expected --->${expected}<---"

        result=$(_pkg_format_deps "${pkg}" $TEST_DEPS_1)
        if [ "$result" = "${expected}" ]; then
            printStyled success "→ test 1   --->${result}<---"
        else
            printStyled info_tbd "→ test 1   --->${result}<---"
        fi

        result=$(_pkg_format_deps "${pkg}" $TEST_DEPS_2)
        if [ "$result" = "${expected}" ]; then
            printStyled success "→ test 2   --->${result}<---"
        else
            printStyled info_tbd "→ test 2   --->${result}<---"
        fi
    done

    echo
}

