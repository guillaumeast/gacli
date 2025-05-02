#!/usr/bin/env zsh
###############################
# FICHIER /<TODO: path>/arch.zsh (move to src/helpers or installer/ ?)
###############################

# Return the system architecture (normalized)
get_arch() {

  # Variables
  local raw_arch
  raw_arch="$(uname -m)"

  # Normalize
  case "${raw_arch}" in
    x86_64 | amd64) echo "amd64" ;;
    aarch64 | arm64) echo "arm64" ;;
    armv7* | armv6*) echo "arm" ;;
    i386 | i686) echo "386" ;;
    riscv64) echo "riscv64" ;;
    ppc64le) echo "ppc64le" ;;
    s390x) echo "s390x" ;;
    *)
      printStyled error "Unsupported architecture: ${raw_arch}"
      return 1
      ;;
  esac
}

# Return 0 if amd64/v2 level is available
_is_amd64_v2() {

  [ "$(uname -m)" != "x86_64" ] && return 1
  grep -q 'sse4_2' /proc/cpuinfo || return 1
}

# Return archs fallbacks for current arch
get_arch_fallbacks() {
  local native="$(get_arch)" || return 1
  local fallbacks=()

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

