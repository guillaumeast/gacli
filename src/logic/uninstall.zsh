#!/usr/bin/env zsh
###############################
# FICHIER /src/logic/uninstall.zsh
###############################

# Uninstall GACLI: remove all file and cleanup .zshrc
gacli_uninstall() {
    printStyled info "Uninstalling... ⏳"

    # Variables
    local zshrc_file="$HOME/.zshrc"

    # Remove GACLI lines from .zshrc
    print ""
    printStyled info "Updating .zshrc file... ⏳"
    if [[ -f "${zshrc_file}" ]]; then
        cp "${zshrc_file}" "${zshrc_file}.bak" || {
            printStyled error "Failed to backup zshrc file"
            return 1
        }

        # Remove all GACLI lines (header + source + alias)
        grep -vE '^# GACLI$|^export PATH="\$HOME/.local/bin:\$PATH"$|^source "\$HOME/.gacli/gacli.zsh"$' "${zshrc_file}" > "${zshrc_file}.tmp" || {
            printStyled error "Failed to parse zshrc file"
            return 1
        }


        mv "${zshrc_file}.tmp" "$zshrc_file" || {
            printStyled error "Failed to update zshrc file"
            return 1
        }

    else
        printStyled warning ".zshrc file not found ($zshrc_file)"
    fi
    printStyled success "Updated"

    # Remove GACLI wrapper
    print ""
    printStyled info "Removing wrapper... ⏳"
    local wrapper_path="${HOME}/.local/bin/gacli"
    if [[ -f "${wrapper_path}" ]]; then
        rm -f "${wrapper_path}" || {
            printStyled warning "Failed to delete wrapper ${wrapper_path}"
        }
    fi
    printStyled success "Removed"

    # Delete GACLI directory
    print ""
    printStyled info "Deleting GACLI files... ⏳"
    if [[ -d "${GACLI_DIR}" ]]; then
        rm -rf "${GACLI_DIR}" || {
            printStyled error "Failed to delete directory ${GACLI_DIR}"
            return 1
        }
    else
        printStyled error "Unable to find GACLI directory: ${GACLI_DIR}"
        return 1
    fi
    printStyled success "Deleted"

    print ""
    printStyled success "Uninstall complete ✅"
    print ""
    printStyled highlight "Restart your terminal"
    print ""
}

