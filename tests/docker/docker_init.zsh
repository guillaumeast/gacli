#!/usr/bin/env zsh
###############################
# FICHIER /tests/docker/dockerfiles/.tmp/docker_init.zsh
###############################

# Summary: Merges Dockerfiles with common dockerpart

# ────────────────────────────────────────────────────────────────
# PATHS
# ────────────────────────────────────────────────────────────────

# User specific
ARCH_FALLBACK=("--platform=linux/amd64")

# Tests/docker dir absolute path
DIR_DOCKER="${${(%):-%x}:A:h}"
DIR_LOCAL_GACLI="${DIR_DOCKER}/../.."
source "${DIR_DOCKER}/../style.zsh" # TODO: "{DIR_LOCAL_GACLI}/src/helpers/style.zsh"

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
    # Reset temporary files
    [[ -d "${DIR_MERGED}" ]] && rm -r "${DIR_MERGED}"
    mkdir -p "${DIR_MERGED}" || exit 1

    # Concatenate Dockerfiles with dockerparts into DIR_MERGED
    docker_merge || exit 2

    # Build images
    docker_build || exit 3

    # Run containers
    # docker_run || exit 4
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
    local count=0

    # Log
    echo
    echo "----------------------------"
    printStyled highlight "Generating Dockerfiles..."
    echo "${GREY}----------------------------${NONE}"

    # Merge Dockerfiles (headers) with dockerparts (footers)
    for header in "${DIR_HEADERS}"/*; do

        # Check file integrity
        [[ ! -f "${header}" ]] && continue
        filename="${header:t}"
        output="${DIR_MERGED}/${filename}-sudo"

        # Merge
        cat "${header}" > "${output}"
        for footer in "${DIR_FOOTERS}"/*; do
            [[ ! -f "${footer}" ]] && continue
            cat "${footer}" >> "${output}"
        done

        # Success
        (( count++ ))
        printStyled success "Passed → ${CYAN}${output}${NONE}"
    done

    # Success
    echo "${GREY}----------------------------${NONE}"
    printStyled success "→ ${GREEN}Created ${count} files${NONE}"
    echo "----------------------------"
    echo
}

# Build images
docker_build() {

    local image=""
    local success_count=0
    local fail_count=0

    # Log
    echo
    echo "----------------------------"
    printStyled highlight "Building images..."
    echo "${GREY}----------------------------${NONE}"

    for file in "${DIR_MERGED}"/*; do

        # Check integrity
        [[ ! -f "${file}" ]] && continue
        image="${${file:t}#Dockerfile.}"
        printStyled debug "file → ${file}"
        printStyled debug "image → ${image}"
        printStyled debug "context → ${DIR_CONTEXT}"
        echo "----------------------------"

        # Try to build
        if docker build -f "${file}" -t "${image}" "${DIR_CONTEXT}" > /dev/null; then
            (( success_count++ ))
            IMAGES_BUILT+=("${image}")
            printStyled success "Passed → ${GREEN}${image}${NONE}"
        else
            (( fail_count++ ))
            printStyled warning "Failed → ${RED}${image}${NONE}"
        fi
    done

    Success
    if (( fail_count == 0 )); then
        echo "${GREY}----------------------------${NONE}"
        printStyled success "→ ${GREEN}Built → $success_count${NONE}"
        echo "----------------------------"
        echo
    elif (( success_count == 0 )); then
        echo "${GREY}----------------------------${NONE}"
        printStyled error "→ ${RED}No image built${NONE}"
        echo "----------------------------"
        echo
    else
        echo "${GREY}----------------------------${NONE}"
        printStyled success "→ Built  → ${GREEN}$success_count${NONE}"
        printStyled warning "→ Failed → ${ORANGE}$fail_count${NONE}"
        echo "----------------------------"
        echo
    fi
}

# Run containers
docker_run() {

    local image=""
    local success_count=0
    local fail_count=0
    
    for image in "${IMAGES_BUILT[@]}"; do

        # Copy local INSTALLER into shared folder
        mkdir -p "${VOLUME_LOCAL}" || return 1
        if cp -r "${INSTALLER}" "${VOLUME_LOCAL}/${INSTALLER:t}" || {
            printStyled error "Failed → ${RED}${image}${NONE} → Unable to copy installer"
            return 1
        }

        # Run test
        if docker run -it --rm -v "${VOLUME_LOCAL}:${VOLUME_VIRTUAL}" "${image}"; then
            (( success_count++ ))
            printStyled success "Passed → ${GREEN}${image}${NONE}"
        else
            printStyled warning "Failed → ${RED}${image}${NONE} → exit $?"
            (( fail_count++ ))
        fi
    done
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

main



