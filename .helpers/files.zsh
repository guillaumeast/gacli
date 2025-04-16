##############################
# FILE: /.helpers/files.zsh
###############################
#!/usr/bin/env zsh

# File manager:
#   - Resolve paths
#   - Checks paths
#   - Creates/deletes files and directories

# Depends on:
#   - gacli.zsh     → resolves $ROOT_DIR

# Used by:
#   - gacli.zsh     → initiate paths resolution at startup
#   - brew.zsh      → manages Brewfile via parser.zsh
#   - update.zsh    → manages config.yaml via parser.zsh
#   - modules.zsh   → manages module YAMLs via parser.zsh

# Note: All read/write operations are delegated to parser.zsh

# ────────────────────────────────────────────────────────────────
# GLOBAL VAR
# ────────────────────────────────────────────────────────────────


# Config directories
DATA_DIR=".data"
CONFIG_DIR=".data/config"
DEP_DIR=".data/dependencies"

# Config files
CONFIG="${CONFIG_DIR}/config.yaml"
USER_TOOLS="tools.yaml"
CORE_BREWFILE="${DEP_DIR}/core_Brewfile"
MERGED_BREWFILE="${DEP_DIR}/merged_Brewfile"
INSTALLED_TOOLS="${CONFIG_DIR}/installed_tools.yaml"

# Scripts directories
HELPERS_DIR=".helpers"
CORE_DIR=".run"
MODULES_DIR="modules"

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

files_init() {
    local DIRS=()
    local FILES=()
    
    # Config directories
    DATA_DIR="${ROOT_DIR}/${DATA_DIR}" && DIRS+=("${DATA_DIR}")
    CONFIG_DIR="${ROOT_DIR}/${CONFIG_DIR}" && DIRS+=("${CONFIG_DIR}")
    DEP_DIR="${ROOT_DIR}/${DEP_DIR}" && DIRS+=("${DEP_DIR}")

    # Config files
    CONFIG="${ROOT_DIR}/${CONFIG}" && FILES+=("${CONFIG}")
    USER_TOOLS="${ROOT_DIR}/${USER_TOOLS}" && FILES+=("${USER_TOOLS}")
    CORE_BREWFILE="${ROOT_DIR}/${CORE_BREWFILE}" && FILES+=("${CORE_BREWFILE}")
    MERGED_BREWFILE="${ROOT_DIR}/${MERGED_BREWFILE}" && FILES+=("${MERGED_BREWFILE}")
    INSTALLED_TOOLS="${ROOT_DIR}/${INSTALLED_TOOLS}" && FILES+=("${INSTALLED_TOOLS}")

    # Script directories
    HELPERS_DIR="${ROOT_DIR}/${HELPERS_DIR}" && DIRS+=("${HELPERS_DIR}")
    CORE_DIR="${ROOT_DIR}/${CORE_DIR}" && DIRS+=("${CORE_DIR}")
    MODULES_DIR="${ROOT_DIR}/${MODULES_DIR}" && DIRS+=("${MODULES_DIR}")

    # Script files
    UNINSTALLER="${ROOT_DIR}/${UNINSTALLER}" && FILES+=("${UNINSTALLER}")

    # Check integrity
    for dir in $DIRS; do
        [[ -d "${dir}" ]] || {
            printstyled error "[files_init] Unable to resolve dir: ${dir}"
            return 1
        }
    done
        for file in $FILES; do
        [[ -f "${file}" ]] || {
            printstyled error "[files_init] Unable to resolve file: ${dir}"
            return 1
        }
    done
}

# ────────────────────────────────────────────────────────────────
# PUBLIC
# ────────────────────────────────────────────────────────────────

# Check if <file/dir> exists (if $3 = "true" => create it if it doesn't exist)
# Usage: _check <file/dir> <path> <true/false> (if true => create it if it doesn't exist)
files_check() {
    local type="$1"
    local path="$2"
    local create="$3"

    # Check args
    if [[ -z "$type" || -z "$path" ]]; then
        printstyled error "" # TODO usage
    fi

    # Process check and optional creation
    case "$type" in
        "folder ")
            [[ $create = true ]] && mkdir -p "${path}"
            [[ -d "${path}" ]] || return 1
            ;;
        "file")
            [[ $create = true ]] && mkdir -p "$(dirname "$path")" && touch "$path"
            [[ -f "${path}" ]] || return 1
            ;;
        *)
            printstyled error "" # TODO usage
            return 1
    esac
}

# ────────────────────────────────────────────────────────────────
# AUTO-RUN
# ────────────────────────────────────────────────────────────────

files_init || return 1

