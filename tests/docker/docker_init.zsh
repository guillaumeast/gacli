#!/usr/bin/env zsh
###############################
# FICHIER /tests/docker/dockerfiles/.tmp/docker_init.zsh
###############################

# Summary: Merges Dockerfiles with common dockerpart

# ────────────────────────────────────────────────────────────────
# PATHS
# ────────────────────────────────────────────────────────────────

# PATHS
DIR_DOCKER="${${(%):-%x}:A:h}"
DIR_LOCAL_GACLI="${DIR_DOCKER}/../.."

# Tested script
INSTALLER="${DIR_LOCAL_GACLI}/installer/install.sh"

# Dockerfiles
DIR_DOCKERFILES="${DIR_DOCKER}/dockerfiles"
DIR_HEADERS="${DIR_DOCKERFILES}/headers"
DIR_FOOTERS="${DIR_DOCKERFILES}/footers"
DIR_MERGED="${DIR_DOCKERFILES}/.tmp"

# Context
DIR_CONTEXT="${DIR_DOCKER}/context"

# Built images
IMAGES_BUILT=()

# Volumes
DIR_LOCAL_GACLI="${DIR_DOCKER}/../.."
VOLUME_LOCAL="${DIR_DOCKER}/shared"
VOLUME_VIRTUAL="/shared"

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

main() {

    # Source helpers
    source "${DIR_DOCKER}/../style.zsh" # TODO: "{DIR_LOCAL_GACLI}/src/helpers/style.zsh"
    source "${DIR_DOCKER}/../arch.zsh" # TODO: "{DIR_LOCAL_GACLI}/src/helpers/arch.zsh"

    # Init dependencies and fixtures
    docker_init || exit 1
    docker_reset_tmp || exit 2

    # Concatenate Dockerfiles with dockerparts into DIR_MERGED
    docker_merge || exit 3

    # Build images
    docker_build_all || exit 4

    # Run containers
    # docker_run || exit 6
}

# ────────────────────────────────────────────────────────────────
# CORE
# ────────────────────────────────────────────────────────────────

# Merge Dockerfiles (headers) with dockerparts (footers)
docker_merge() {

    local header=""
    local footer=""
    local filename=""
    local output=""
    local passed=0
    local failed=0
    local tmp_failed="false"

    # Merge Dockerfiles (headers) with dockerparts (footers)
    printheader "Generating Dockerfiles..."
    for header in "${DIR_HEADERS}"/*; do

        # Reset status
        tmp_failed="false"

        # Check file integrity
        [[ ! -f "${header}" ]] && continue
        filename="${header:t}"
        output="${DIR_MERGED}/${filename}-sudo"

        # Merge
        if ! cat "${header}" > "${output}"; then
            tmp_failed="true"
            continue
        fi
        for footer in "${DIR_FOOTERS}"/*; do
            [[ ! -f "${footer}" ]] && continue
            if ! cat "${footer}" >> "${output}"; then
                tmp_failed="true"
                continue
            fi
        done

        # Success
        if [[ "$tmp_failed" == "true" ]]; then
            (( failed++ ))
            printStyled warning "Failed → ${RED}${output}${NONE}"
        else
            (( passed++ ))
            printStyled success "Merged → ${GREEN}${output}${NONE}"
        fi
    done

    # Display results
    printresults $passed $failed
}

# Build images
docker_build_all() {

    local image=""
    local passed=0
    local failed=0

    # Build images
    printheader "Building images..."
    for file in "${DIR_MERGED}"/*; do

        # Check integrity
        [[ ! -f "${file}" ]] && continue
        image="${${file:t}#Dockerfile.}"

        # Try to build (TODO: build multi arch images with buildx)
        if docker_build "${file}" "${image}"; then
            (( passed++ ))
            IMAGES_BUILT+=("${image}")
        else
            (( failed++ ))
        fi
    done

    # Display results
    printresults $passed $failed
}

# Try native build + fallbcak archs
docker_build() {

    local file="${1}"
    local image="${2}"
    local fallbacks=()
    local platform=""

    # Check args
    [[ ! -f "${file}" || -z "${image}" ]] && {
        printStyled error "[printresults] Expected: <file> <image> (received: ${1} ${2})"
        return 1
    }

    # Try native build + fallbacks
    if docker build -f "${file}" -t "${image}" "${DIR_CONTEXT}" > /dev/null 2>&1; then
        # Success
        printStyled success "Passed   → ${GREEN}${image}${NONE}"
        return 0
    else
        # Try fallback builds
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

    # Failed
    printStyled warning "Failed   → ${RED}${image}${NONE}"
    return 1
}

# Run containers
docker_run() {

    local image=""
    local passed=0
    local failed=0

    # Run
    printheader "Running images..."
    for image in "${IMAGES_BUILT[@]}"; do

        # Copy origin INSTALLER into shared folder
        mkdir -p "${VOLUME_LOCAL}" || return 1
        if cp -r "${INSTALLER}" "${VOLUME_LOCAL}/${INSTALLER:t}" || {
            printStyled error "Failed → ${RED}${image}${NONE} → Unable to copy installer"
            return 1
        }

        # Run test
        if docker run -it --rm -v "${VOLUME_LOCAL}:${VOLUME_VIRTUAL}" "${image}"; then
            printStyled success "Passed → ${GREEN}${image}${NONE}"
            (( passed++ ))
        else
            printStyled warning "Failed → ${RED}${image}${NONE} → exit $?"
            (( failed++ ))
        fi
    done

    # Display results
    printresults $passed $failed
}

# ────────────────────────────────────────────────────────────────
# DEPENDENCIES
# ────────────────────────────────────────────────────────────────

# Install Docker and Buildx
docker_init() {

    printheader "Checking Docker config..."
    docker_install || return 1
    docker_install_buildx || return 2
    printfooter "$(printStyled success "${GREEN}Configured${NONE}")"
}

# Ensure Docker is installed (via Homebrew if missing)
docker_install() {

    # Check if docker is available
    if command -v docker >/dev/null 2>&1; then
        printStyled success "Detected: ${GREEN}Docker${NONE}"
        return 0
    fi

    # Check if Homebrew is available
    if ! command -v brew >/dev/null 2>&1; then
        printStyled error "Unable to install ${ORANGE}Docker${NONE} → ${ORANGE}Homebrew${NONE} is missing"
        return 1
    fi

    # Install Docker
    printStyled wait "Installing Docker with Homebrew..."
    if ! brew install --cask docker >/dev/null 2>&1; then
        printStyled error "Unable to install ${ORANGE}Docker${NONE}"
        return 1
    fi

    printStyled success "Installed: ${GREEN}Docker${NONE}"
}

# Ensure Docker Buildx is installed (downloads binary if missing)
docker_install_buildx() {

    # Check if Buildx is available
    if docker buildx version >/dev/null 2>&1; then
        printStyled success "Detected: ${GREEN}Docker Buildx${NONE}"
        return 0
    fi

    # Variables
    local arch
    arch="$(get_arch)" || return 1
    local plugin_dir="${HOME}/.docker/cli-plugins"
    local plugin_path="${plugin_dir}/docker-buildx"
    local url="https://github.com/docker/buildx/releases/latest/download/buildx-linux-${arch}"

    # Create plugin directory if needed
    mkdir -p "${plugin_dir}" || {
        printStyled error "Failed to create plugin dir: ${CYAN}${plugin_dir}${NONE}"
        return 1
    }

    # Download binary
    printStyled wait "Downloading Docker Buildx for ${arch}..."
    if ! curl -fsSL "${url}" -o "${plugin_path}"; then
        printStyled error "Failed to download ${ORANGE}buildx${NONE} binary"
        return 1
    fi

    # Make executable
    chmod +x "${plugin_path}" || {
        printStyled error "Failed to make binary ${ORANGE}executable${NONE}"
        return 1
    }

    # Final check
    if ! docker buildx version >/dev/null 2>&1; then
        printStyled error "Install failed: ${ORANGE}Buildx${NONE}"
        return 1
    fi

    printStyled success "Installed: ${ORANGE}Docker Buildx${NONE}"
}

# ────────────────────────────────────────────────────────────────
# HELPERS
# ────────────────────────────────────────────────────────────────

# Reset temporary files
docker_reset_tmp() {
    
    # Try
    [[ -d "${DIR_MERGED}" ]] && rm -r "${DIR_MERGED}"
    mkdir -p "${DIR_MERGED}" && return 0
    
    # Fallback
    printStyled error "Unable to init temporary folder: ${CYAN}${DIR_MERGED}${NONE}"
    return 1
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

main

