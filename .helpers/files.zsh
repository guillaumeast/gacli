##############################
# FILE: /.helpers/files.zsh
###############################
#!/usr/bin/env zsh

# File manager:
#   - Resolve paths
#   - Checks integrity of folders and files

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

# Note: $ROOT_DIR is already resolved by gacli.zsh when this file is sourced

# Directories
HELPERS_DIR="${ROOT_DIR}/.helpers"
CORE_DIR="${ROOT_DIR}/.run"
MODULES_DIR="${ROOT_DIR}/modules"

# Files
CONFIG="${ROOT_DIR}/.data/config/update.config.yaml"
CORE_TOOLS="${ROOT_DIR}/.data/tools/core.tools.yaml"
USER_TOOLS="${ROOT_DIR}/tools.yaml"
INSTALLED_TOOLS="${ROOT_DIR}/.data/tools/installed.tools.yaml"

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────

local dirs=("${HELPERS_DIR}" "${CORE_DIR}" "${MODULES_DIR}")
local files=("${CONFIG}" "${CORE_TOOLS}" "${USER_TOOLS}" "${INSTALLED_TOOLS}")

# Check directories integrity
for dir in $dirs; do
    mkdir -p "${MODULES_DIR}" || {
        printstyled error "[files_init] Unable to resolve dir: ${dir}"
        return 1
    }
done

# Check directories integrity
for file in $files; do
    [[ -f "${file}" ]] || {
        printstyled error "[files_init] Unable to resolve file: ${dir}"
        return 1
    }
done

