#!/usr/bin/env zsh
###############################
# FICHIER /tests/docker/dockerfiles/.tmp/docker_init.zsh
###############################

# Summary: Merges Headers with footers into .tmp Dockerfiles

DIR_DOCKER="${${(%):-%x}:A:h}"
DIR_DOCKERFILES="${DIR_DOCKER}/dockerfiles"
DIR_CONTEXT="${DIR_DOCKER}/context"

DIR_LOCAL_GACLI="${DIR_DOCKER}/../.."
FILE_INSTALLER="${DIR_LOCAL_GACLI}/installer/manual/install.sh"

VOLUME_LOCAL="${DIR_DOCKER}/shared"
VOLUME_VIRTUAL="/shared"

IMAGES_BUILT=()

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

main() {

    # Source helpers
    source "${DIR_DOCKER}/../_support/style.zsh" # TODO: "{DIR_LOCAL_GACLI}/src/helpers/style.zsh" ?
    source "${DIR_DOCKER}/../_support/arch.zsh" # TODO: "{DIR_LOCAL_GACLI}/src/helpers/arch.zsh" ?

    docker_init || exit 1
    docker_build_images || exit 2
    docker_run || exit 3
}

# ────────────────────────────────────────────────────────────────
# INIT
# ────────────────────────────────────────────────────────────────

docker_init() {

    printheader "Checking Docker config..."
    _docker_install || return 1
    _docker_install_buildx || return 2
    printfooter "$(printStyled success "${GREEN}Configured${NONE}")"
}

_docker_install() {

    if command -v docker >/dev/null 2>&1; then
        printStyled success "Detected: ${GREEN}Docker${NONE}"
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
        printStyled success "Detected: ${GREEN}Docker Buildx${NONE}"
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

    local image=""
    local passed=0
    local failed=0

    print -n "👉 ${BOLD}Rebuild images? [y/n] ${NONE}"
    read -r answer
    [[ "${answer}" != "y" && "${answer}" != "Y" ]] && return 0

    printheader "Building images..."
    for file in "${DIR_DOCKERFILES}"/**/*; do

        [[ ! -f "${file}" ]] && continue
        image="${${file:t}#Dockerfile.}"

        if _docker_build "${file}" "${image}"; then
            (( passed++ ))
            IMAGES_BUILT+=("${image}")
        else
            (( failed++ ))
        fi
    done

    printresults $passed $failed
}

# Try native build + fallbcak archs
_docker_build() {

    local file="${1}"
    local image="${2}"
    local fallbacks=()
    local platform=""

    [[ ! -f "${file}" || -z "${image}" ]] && {
        printStyled error "[printresults] Expected: <file> <image> (received: ${1} ${2})"
        return 1
    }

    if docker build -f "${file}" -t "${image}" "${DIR_CONTEXT}" > /dev/null 2>&1; then
        printStyled success "Passed   → ${GREEN}${image}${NONE}"
        return 0
    else
        fallbacks=("$(get_arch_fallbacks)") || return 1
        for arch in "${fallbacks[@]}"; do
            [[ -z "$arch" ]] && continue
            platform="--platform=linux/${arch}"
            if docker build ${platform} -f "${file}" -t "${image}" "${DIR_CONTEXT}" > /dev/null 2>&1; then
                printStyled info_tbd "Fallback → ${GREEN}${image}${NONE} ${ORANGE}${platform}${NONE}"
                return 0
            fi
        done
    fi

    printStyled warning "Failed   → ${RED}${image}${NONE}"
    return 1
}

# ────────────────────────────────────────────────────────────────
# RUN CONTAINERS
# ────────────────────────────────────────────────────────────────

docker_run() {

    local image=""
    local passed=0
    local failed=0

    printheader "Running containers..."
    for file in "${DIR_DOCKERFILES}"/**/*; do

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
            printStyled success "Passed  → ${GREEN}${image}${NONE}"
            (( passed++ ))
        else
            printStyled error "Failed  → ${RED}${image}${GREY} → ${RED}'exit ${?}'${NONE}"
            (( failed++ ))
        fi
    done

    printresults $passed $failed
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

main

