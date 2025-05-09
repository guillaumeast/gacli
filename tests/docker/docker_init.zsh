#!/usr/bin/env zsh
###############################
# FICHIER /tests/docker/docker_init.zsh
###############################

# TODO: add "opensuse-tumbleweed, kali, parot, alpine..."
SUPPORTED_DISTROS=("debian" "ubuntu" "archlinux" "fedora" "opensuse-leap" "mageia")

DIR_DOCKER="${${(%):-%x}:A:h}"
DIR_DOCKERFILES="${DIR_DOCKER}/dockerfiles"
DIR_CONTEXT="${DIR_DOCKER}/context"

DIR_LOCAL_GACLI="${DIR_DOCKER}/../.."
FILE_INSTALLER="${DIR_LOCAL_GACLI}/installer/ipkg.sh"

VOLUME_LOCAL="${DIR_DOCKER}/shared"
VOLUME_VIRTUAL="/shared"

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

main() {

    # Source helpers
    source "${DIR_DOCKER}/../../src/helpers/string.zsh"
    source "${DIR_DOCKER}/../../src/helpers/loader.zsh"
    source "${DIR_DOCKER}/../../src/helpers/style.zsh"
    source "${DIR_DOCKER}/../../src/helpers/arch.zsh"

    docker_init         || exit 1
    docker_build        || exit 2
    docker_run          || exit 3
}

# ────────────────────────────────────────────────────────────────
# INIT
# ────────────────────────────────────────────────────────────────

docker_init() {
    
    echo
    _docker_install || return 1
    _docker_install_buildx || return 2
    echo
}

_docker_install() {

    if command -v docker >/dev/null 2>&1; then
        printui info "Detected → Docker"
        return 0
    fi

    if ! command -v brew >/dev/null 2>&1; then
        printui error "Unable to install ${ORANGE}Docker${NONE} → ${ORANGE}Homebrew${NONE} is missing"
        return 1
    fi

    printui wait "Installing Docker with Homebrew..."
    if ! brew install --cask docker >/dev/null 2>&1; then
        printui error "Unable to install ${ORANGE}Docker${NONE}"
        return 1
    fi

    printui passed "Installed: ${GREEN}Docker${NONE}"
}

_docker_install_buildx() {

    if docker buildx version >/dev/null 2>&1; then
        printui info "Detected → Docker Buildx"
        return 0
    fi

    local arch
    arch="$(get_arch)" || return 1
    local plugin_dir="${HOME}/.docker/cli-plugins"
    local plugin_path="${plugin_dir}/docker-buildx"
    local url="https://github.com/docker/buildx/releases/latest/download/buildx-linux-${arch}"

    mkdir -p "${plugin_dir}" || {
        printui error "Failed to create plugin dir: ${CYAN}${plugin_dir}${NONE}"
        return 1
    }

    printui wait "Downloading Docker Buildx for ${arch}..."
    if ! curl -fsSL "${url}" -o "${plugin_path}"; then
        printui error "Failed to download ${ORANGE}buildx${NONE} binary"
        return 1
    fi

    chmod +x "${plugin_path}" || {
        printui error "Failed to make binary ${ORANGE}executable${NONE}"
        return 1
    }

    if ! docker buildx version >/dev/null 2>&1; then
        printui error "Install failed: ${ORANGE}Buildx${NONE}"
        return 1
    fi

    printui passed "Installed: ${ORANGE}Docker Buildx${NONE}"
}

# ────────────────────────────────────────────────────────────────
# BUILD IMAGES
# ────────────────────────────────────────────────────────────────

docker_build() {

    local passed=0
    local fallback=0
    local failed=0
    local result=0

    printui block-highlight "Building images..."

    # Avoid iterating on non-matching patterns (Zsh expands to literal string)
    setopt null_glob
    for file in "${DIR_DOCKERFILES}"/**/Dockerfile.*; do

        if ! _docker_build_with_fallback "${file}" "${image_name}"; then
            return_value=1
            continue
        fi
    done
    unsetopt null_glob

    printui results bot $passed $fallback $failed
    echo
}

_docker_build_with_fallback() {

    local file="${1}"
    local image="${${file:t}#Dockerfile.}"

    [[ ! -f "${file}" ]] && {
        (( failed++ ))
        printui error "[_docker_build_with_fallback] Expected: <file> <image> (received: '${1}' '${2}')"
        return 1
    }

    loader_start "Building → ${image}"

    if docker build -f "${file}" -t "${image}" "${DIR_CONTEXT}" > /dev/null 2>&1; then
        (( passed++ ))
        loader_stop
        printui passed "Success  → ${GREEN}${image}${NONE}"
        return 0
    fi

    local fallbacks=()
    local platform=""

    fallbacks=("$(get_arch_fallbacks)") || return 1

    for arch in "${fallbacks[@]}"; do

        [[ -z "$arch" ]] && continue

        platform="--platform=linux/${arch}"

        if docker build ${platform} -f "${file}" -t "${image}" "${DIR_CONTEXT}" > /dev/null 2>&1; then

            (( fallback++ ))
            loader_stop
            printui fallback "Fallback → ${GREEN}${image}${ORANGE} ${platform}"
            return 1
        fi
    done

    (( failed++ ))
    loader_stop
    printui error "Failed → ${image}"
    return 2
}

# ────────────────────────────────────────────────────────────────
# RUN CONTAINERS
# ────────────────────────────────────────────────────────────────

docker_run() {
    
    local file=""
    local image=""
    local return_value=0
    local passed=0
    local fallback=0
    local failed=0

    printui block-highlight "Running tests..."

    # Avoid iterating on non-matching patterns (Zsh expands to literal string)
    setopt null_glob
    for file in "${DIR_DOCKERFILES}"/**/Dockerfile.*; do

        [[ ! -f "${file}" ]] && continue
        image="${${file:t}#Dockerfile.}"

        loader_start "Testing → ${image}"

        if ! docker_copy_installer; then
            (( failed++ ))
            loader_stop
            return 1
        fi

        if docker run -it -v "${VOLUME_LOCAL}:${VOLUME_VIRTUAL}" "${image}" sh /shared/ipkg.sh gacli >/dev/null 2>&1; then
            (( passed++ ))
            loader_stop
            printui passed "Passed  → ${GREEN}${image}${GREY}"
        else
            container_exit_code=$?
            return_value=1
            (( failed++ ))
            loader_stop
            printui error "Failed  → ${RED}${image}${GREY} → ${RED}exit ${container_exit_code}${NONE}"
        fi
    done
    unsetopt null_glob

    loader_stop
    printui results bot $passed $fallback $failed
    echo
    return $return_value
}

docker_copy_installer() {

    if ! mkdir -p "${VOLUME_LOCAL}"; then
        printui error "Unable to find local volume: ${CYAN}'${VOLUME_LOCAL}'${CYAN}"
        return 1
    fi

    if ! cp -r "${FILE_INSTALLER}" "${VOLUME_LOCAL}/${FILE_INSTALLER:t}"; then
        printui error "Unable to copy installer"
        return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

main

