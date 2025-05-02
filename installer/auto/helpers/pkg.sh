#!/usr/bin/env zsh
###############################
# FICHIER /<TODO: path>/pkg.zsh (move to src/helpers or installer/ ?)
###############################

# Full POSIX sh script to abstract package managers handling

# Supported package managers (TODO: add apk, yum, nix-env, xbps-installserver-side)
SUPPORTED_PKG='brew apt urpmi dnf pacman zypper emerge slackpkg pkg'

# Unsupported "<name>=<issue>" (TODO: it's GACLI specific → move it into install.sh)
UNSUPPORTED_PKG='"apk=glibc-based distribution required" "yum=git ≥ 2.7.0 not available" "nix-env=FHS required" "xbps-installserver-side SSL/TLS issues"'

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# Install packages
pkg_install() {

    # Paquets to install
    packets="$@"

    # Check args
    [ "${#packets[@]}" > 0 ] && [ -n "${packets[1]}" ] || {
        printStyled error "Expected: <@packet_names>; received: '$@'"
        return 1
    }

    # Update package manager
    _pkg_update || return 1

    # Install packets
    pkg="$(_pkg_get_current)" || return 1
    case "${pkg}" in
        brew)
            brew install "${packets}"
            ;;
        apt)
            apt-get install -y "${packets}"
            ;;
        urpmi)
            urpmi --auto "${packets}"
            ;;
        dnf)
            dnf install -y "${packets}"
            ;;
        pacman)
            pacman -Sy --noconfirm "${packets}"
            ;;
        zypper)
            zypper install -y -t pattern devel_basis "${packets}"
            ;;
        emerge)
            # TODO: do not support (unpredictible custom packet names ??)
            prefixed=""
            for raw in $packets; do
                prefixed+="sys-devel/${raw}"
            done
            emerge -n --quiet "${prefixed}"
            ;;
        slackpkg)
            yes | slackpkg install "${packets}"
            ;;
        pkg)
            pkg install -y "${packets}"
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

# PRIVATE - Detects current package manager
_pkg_get_current() {

    # Return cached value
    if [ -n "${CURRENT_PKG}" ]; then
        echo "${CURRENT_PKG}"
        return 0
    fi

    # Test supported package managers
    for pkg in $SUPPORTED_PKG; do
        command -v "$pkg" || continue
        CURRENT_PKG=$pkg
        echo "${CURRENT_PKG}"
        return 0
    done

    # Test unsupported package managers
    for pkg in "${UNSUPPORTED_PKG[@]}"; do
        [[ -n "$pkg" && $pkg == *=* ]] || continue
        name="${pkg%%=*}"
        issue="${pkg#*=}"
        command -v "$name" || continue
        printStyled error "Unsupported package manager: ${ORANGE}${name}${RED} → ${issue}"
        return 1
    done

    # Fallback - unknown package manager
    printStyled error "Unsupported package manager: ${ORANGE}${name}${RED}"
    return 1
}

# PRIVATE - Update package manager
_pkg_update() {

    pkg="$(_pkg_get_current)" || return 1
    case "${pkg}" in
        brew)
            brew upgrade
            ;;
        apt)
            apt-get update -y
            ;;
        urpmi)
            urpmi.update -a
            ;;
        dnf)
            # TODO: do nothing or dot the above ?!
            if dnf --version 2>/dev/null | grep -q "5\."; then
                package_manager="dnf v5"
                step_1="dnf install -y @development-tools"
            else
                package_manager="dnf v4"
                step_1="dnf group install -y \"Development Tools\""
            fi
            ;;
        pacman)
            # TODO: do nothing ?!
            ;;
        zypper)
            zypper refresh
            ;;
        emerge)
            emerge --sync
            ;;
        slackpkg)
            slackpkg update
            ;;
        pkg)
            pkg update -f
            ;;
        *)
            printStyled error "Unsupported package manager: ${ORANGE}${name}${RED}"
            return 1
            ;;
    esac

    # Check success
    if ( ${?} > 0 ); then
        printStyled error "Install failed"
        return 1
    fi
}


