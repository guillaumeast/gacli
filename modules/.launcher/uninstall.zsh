###############################
# FICHIER uninstall.zsh
###############################

#!/usr/bin/env zsh

# Uninstall GACLI: remove all file and cleanup .zshrc
gacli_uninstall() {
    printStyled info "Uninstalling... ⏳"

    # Variables
    local zshrc_file="$HOME/.zshrc"
    local config_file="${CONFIG_FILE}"

    # Remove GACLI lines from .zshrc
    print ""
    printStyled info "Updating .zshrc file... ⏳"
    if [[ -f "${zshrc_file}" ]]; then
        cp "${zshrc_file}" "${zshrc_file}.bak" || {
            printStyled error "[gacli_uninstall] Failed to backup zshrc file"
            return 1
        }

        # Remove all GACLI lines (header + source + alias)
        grep -vE '^# GACLI$|^export PATH="\$HOME/.local/bin:\$PATH"$|^source "\$HOME/.gacli/gacli.zsh"$' "${zshrc_file}" > "${zshrc_file}.tmp" || {
            printStyled error "[gacli_uninstall] Failed to parse zshrc file"
            return 1
        }


        mv "${zshrc_file}.tmp" "$zshrc_file" || {
            printStyled error "[gacli_uninstall] Failed to update zshrc file"
            return 1
        }

    else
        printStyled warning "[gacli_uninstall] .zshrc file not found ($zshrc_file)"
    fi
    printStyled success "Updated"

    # Remove symlink
    print ""
    printStyled info "Removing symlink... ⏳"
    local sym_path="${HOME}/.local/bin/gacli"
    if [[ -L "${sym_path}" ]]; then
        rm "${sym_path}" || {
            printStyled warning "[gacli_uninstall] Failed to delete symlink ${sym_path}"
        }
    fi
    printStyled success "Removed"

    # Delete GACLI directory
    print ""
    printStyled info "Deleting GACLI files... ⏳"
    if [[ -d "${GACLI_PATH}" ]]; then
        rm -rf "${GACLI_PATH}" || {
            printStyled error "[gacli_uninstall] Failed to delete directory ${GACLI_PATH}"
            return 1
        }
    else
        printStyled error "[gacli_uninstall] Unable to find GACLI directory: ${GACLI_PATH}"
        return 1
    fi
    printStyled success "Deleted"

    print ""
    printStyled success "Uninstall complete ✅"
    print ""
    printStyled highlight "Restart your terminal"
    print ""
}

