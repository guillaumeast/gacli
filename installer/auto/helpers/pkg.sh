#!/usr/bin/env zsh
###############################
# FICHIER /<TODO: path>/pkg.zsh (move to src/helpers or installer/ ?)
###############################

# Full POSIX sh script to abstract package managers handling

# Supported package managers (TODO: add apk, yum, nix-env, xbps-installserver-side)
SUPPORTED_PKG="brew apt urpmi dnf pacman zypper emerge slackpkg pkg"

# Unsupported "<name>=<issue>" (TODO: it's GACLI specific → move it into install.sh)
UNSUPPORTED_PKG='"apk=glibc-based distribution required" "yum=git ≥ 2.7.0 not available" "nix-env=FHS required" "xbps-installserver-side SSL/TLS issues"'

CURRENT_PKG=""

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# Install packages
pkg_install() {

    packets="$@"
    if [ -z "${packets}" ]; then
        printStyled error "Expected: <@packet_names>; received: '$@'"
        return 1
    fi

    pkg=$(_pkg_get_current) || return 1

    case "${pkg}" in # TODO: add >/dev/null 2>&1
        brew)
            brew upgrade || return 1
            brew install "${packets}" || return 1
            ;;
        apt)
            apt-get update -y || return 1
            apt-get install -y "${packets}" || return 1
            ;;
        urpmi)
            urpmi.update -a || return 1
            urpmi --auto "${packets}" || return 1
            ;;
        dnf)
            if dnf --version 2>/dev/null | grep -q "5\."; then
                dnf install -y @development-tools || return 1
            else
                dnf group install -y "Development Tools" || return 1
            fi
            dnf install -y "${packets}" || return 1
            ;;
        pacman)
            pacman -Sy --noconfirm "${packets}" || return 1
            ;;
        zypper)
            zypper refresh || return 1
            zypper install -y -t pattern devel_basis "${packets}" || return 1
            ;;
        emerge)
            # TODO: do not support (unpredictible custom packet names ??)
            emerge --sync || return 1
            prefixed=""
            for raw in $packets; do
                prefixed+="sys-devel/${raw}"
            done
            emerge -n --quiet "${prefixed}" || return 1
            ;;
        slackpkg)
            slackpkg update || return 1
            yes | slackpkg install "${packets}" || return 1
            ;;
        pkg)
            pkg update -f || return 1
            pkg install -y "${packets}" || return 1
            ;;
        *)
            printStyled error "Unsupported package manager: ${ORANGE}${name}${RED}"
            return 1
            ;;
    esac

    # TODO: Cleanup

    # TODO: Check install
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

_pkg_get_current() {

    # Return cached value
    if [ -n "${CURRENT_PKG}" ]; then

        echo "${CURRENT_PKG}"
        return 0
    fi

    for pkg in $SUPPORTED_PKG; do

        if ! command -v "${pkg}" >/dev/null 2>&1; then
            continue
        fi

        CURRENT_PKG=$pkg

        echo "${CURRENT_PKG}"
        return 0
    done

    for pkg in $UNSUPPORTED_PKG; do # TODO: fix (items may contain spaces)

        name="${pkg%%=*}"
        issue="${pkg#*=}"

        if ! command -v "$name" >/dev/null 2>&1; then
            continue
        fi

        printStyled error "Unsupported package manager: ${ORANGE}${name}${RED} → ${issue}"
        return 1
    done

    printStyled error "Unsupported package manager"
    return 1
}

