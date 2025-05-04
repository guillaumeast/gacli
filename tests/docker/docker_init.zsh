#!/usr/bin/env zsh
###############################
# FICHIER /tests/docker/docker_init.zsh
###############################

# TODO: add "opensuse-tumbleweed"
SUPPORTED_DISTROS=("debian" "ubuntu" "archlinux" "fedora" "opensuse-leap" "mageia")

DIR_DOCKER="${${(%):-%x}:A:h}"
DIR_DOCKERFILES="${DIR_DOCKER}/dockerfiles"
DIR_CONTEXT="${DIR_DOCKER}/context"

DIR_LOCAL_GACLI="${DIR_DOCKER}/../.."
FILE_INSTALLER="${DIR_LOCAL_GACLI}/installer/manual/install.sh"

VOLUME_LOCAL="${DIR_DOCKER}/shared"
VOLUME_VIRTUAL="/shared"

IMAGES_BUILT=()
ARCH_FALLBACK=""

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

main() {

    # Source helpers
    source "${DIR_DOCKER}/../_support/style.zsh" # TODO: "{DIR_LOCAL_GACLI}/src/helpers/style.zsh" ?
    source "${DIR_DOCKER}/../_support/arch.zsh" # TODO: "{DIR_LOCAL_GACLI}/src/helpers/arch.zsh" ?

    printheader "Building images..."
    docker_init         || exit 1
    docker_build_images || exit 2

    printheader "Running tests into containers..."
    # TODO: uncomment after style.zsh tests
    # docker_run          || exit 3
}

# ────────────────────────────────────────────────────────────────
# INIT
# ────────────────────────────────────────────────────────────────

docker_init() {

    _docker_install || return 1
    _docker_install_buildx || return 2
}

_docker_install() {

    if command -v docker >/dev/null 2>&1; then
        printStyled info "Detected → Docker"
        return 0
    fi

    if ! command -v brew >/dev/null 2>&1; then
        printStyled error "Unable to install ${ORANGE}Docker${NONE} → ${ORANGE}Homebrew${NONE} is missing"
        return 1
    fi

    printStyled wait "Installing Docker with Homebrew..."
    if ! brew install --cask docker >/dev/null 2>&1; then
        printStyled error "Unable to install ${ORANGE}Docker${NONE}"
        return 1
    fi

    printStyled success "Installed: ${GREEN}Docker${NONE}"
}

_docker_install_buildx() {

    if docker buildx version >/dev/null 2>&1; then
        printStyled info "Detected → Docker Buildx"
        return 0
    fi

    local arch
    arch="$(get_arch)" || return 1
    local plugin_dir="${HOME}/.docker/cli-plugins"
    local plugin_path="${plugin_dir}/docker-buildx"
    local url="https://github.com/docker/buildx/releases/latest/download/buildx-linux-${arch}"

    mkdir -p "${plugin_dir}" || {
        printStyled error "Failed to create plugin dir: ${CYAN}${plugin_dir}${NONE}"
        return 1
    }

    printStyled wait "Downloading Docker Buildx for ${arch}..."
    if ! curl -fsSL "${url}" -o "${plugin_path}"; then
        printStyled error "Failed to download ${ORANGE}buildx${NONE} binary"
        return 1
    fi

    chmod +x "${plugin_path}" || {
        printStyled error "Failed to make binary ${ORANGE}executable${NONE}"
        return 1
    }

    if ! docker buildx version >/dev/null 2>&1; then
        printStyled error "Install failed: ${ORANGE}Buildx${NONE}"
        return 1
    fi

    printStyled success "Installed: ${ORANGE}Docker Buildx${NONE}"
}

# ────────────────────────────────────────────────────────────────
# BUILD IMAGES
# ────────────────────────────────────────────────────────────────

docker_build_images() {

    local passed=0
    local fallback=0
    local failed=0
    local result=0

    for distro in "${SUPPORTED_DISTROS[@]}"; do
        _docker_build_distro "${distro}"
        result=$?
        if (( $result == 0 )); then
            printStyled success "Built    → ${GREEN}${distro}${NONE}"
        elif (( $result == 1 )); then
            printStyled fallback "Fallback → ${GREEN}${distro} ${ORANGE}${ARCH_FALLBACK}${NONE}"
        fi
    done

    print_results $passed $fallback $failed
}

_docker_build_distro() {
    
    local distro=$1
    local file=""
    local image_name=""
    local return_value=0

    if [ -z "${distro}" ]; then
        printStyled error "Expected: <distro>; received: '${1}'"
        return 1
    fi

    # Avoid iterating on non-matching patterns (Zsh expands to literal string)
    setopt null_glob
    for file in "${DIR_DOCKERFILES}"/**/Dockerfile."${distro}"*; do

        [[ ! -f "${file}" ]] && continue
        image_name="${${file:t}#Dockerfile.}"

        if _docker_build_with_fallback "${file}" "${image_name}"; then
            IMAGES_BUILT+=("${image_name}")
        else
            return_value=$?
        fi
    done
    unsetopt null_glob

    return $return_value
}

_docker_build_with_fallback() {

    local file="${1}"
    local image="${2}"
    local fallbacks=()
    local platform=""

    [[ ! -f "${file}" || -z "${image}" ]] && {
        printStyled error "[_docker_build_with_fallback] Expected: <file> <image> (received: '${1}' '${2}')"
        return 1
    }

    if docker build -f "${file}" -t "${image}" "${DIR_CONTEXT}" > /dev/null 2>&1; then
        (( passed++ ))
        return 0
    fi

    fallbacks=("$(get_arch_fallbacks)") || return 1
    ARCH_FALLBACK=""
    for arch in "${fallbacks[@]}"; do
        [[ -z "$arch" ]] && continue
        platform="--platform=linux/${arch}"
        if docker build ${platform} -f "${file}" -t "${image}" "${DIR_CONTEXT}" > /dev/null 2>&1; then
            ARCH_FALLBACK=$platform
            (( fallback++ ))
            return 1
        fi
    done

    printStyled error "Failed → ${image}"
    (( failed++ ))
    return 2
}

# ────────────────────────────────────────────────────────────────
# RUN CONTAINERS
# ────────────────────────────────────────────────────────────────

docker_run() {

    local passed=0
    local fallback=0
    local failed=0

    for distro in "${SUPPORTED_DISTROS[@]}"; do
        _docker_run_distro "${distro}" && printStyled success "Passed  → ${GREEN}${distro}${NONE}"
    done

    print_results $passed $fallback $failed
}

_docker_run_distro() {
    
    local distro=$1
    local file=""
    local image=""
    local return_value=0

    if [ -z "${distro}" ]; then
        printStyled error "Expected: <distro>; received: '${1}'"
        return 1
    fi

    # Avoid iterating on non-matching patterns (Zsh expands to literal string)
    setopt null_glob
    for file in "${DIR_DOCKERFILES}"/**/Dockerfile."${distro}"*; do

        [[ ! -f "${file}" ]] && continue
        image="${${file:t}#Dockerfile.}"

        mkdir -p "${VOLUME_LOCAL}" || {
            printStyled error "Unable to find local volume: ${CYAN}'${VOLUME_LOCAL}'${CYAN}"
            return 1
        }
        cp -r "${FILE_INSTALLER}" "${VOLUME_LOCAL}/${FILE_INSTALLER:t}" || {
            printStyled error "Unable to copy installer"
            return 1
        }

        if docker run -it -v "${VOLUME_LOCAL}:${VOLUME_VIRTUAL}" "${image}" >/dev/null 2>&1; then
            (( passed++ ))
        else
            printStyled error "Failed  → ${RED}${image}${GREY} → ${RED}'exit ${?}'${NONE}"
            return_value=1
            (( failed++ ))
        fi
    done
    unsetopt null_glob

    return $return_value
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

main

