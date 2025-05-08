#!/usr/bin/env zsh
###############################
# FICHIER /src/helpers/arch.zsh
###############################

ARCH_DEPS=()

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

get_arch_formatted() {

    case "$(uname -m)" in
        x86_64 | amd64) echo "amd64" ;;
        aarch64 | arm64) echo "arm64" ;;
        armv7* | armv6*) echo "arm" ;;
        i386 | i686) echo "386" ;;
        riscv64) echo "riscv64" ;;
        ppc64le) echo "ppc64le" ;;
        s390x) echo "s390x" ;;
        *)
            printStyled error "Unsupported architecture: $(uname -m)"
            return 1
            ;;
    esac
}

get_arch_fallbacks() {

    local native
    local fallbacks=()

    native="$(get_arch_formatted)" || return 1

    case "$native" in
        amd64)
            _is_amd64_v2 && fallbacks+=("amd64/v2")
            fallbacks+=("arm64")
            ;;
        arm64)
            fallbacks+=("amd64")
            ;;
        *)
            fallbacks+=("amd64")
            ;;
    esac

    echo "${fallbacks[@]}"
}

# ────────────────────────────────────────────────────────────────
# PRIVATE
# ────────────────────────────────────────────────────────────────

_is_amd64_v2() {

    [ "$(uname -m)" != "x86_64" ] && return 1
    grep -q 'sse4_2' /proc/cpuinfo || return 1
}

