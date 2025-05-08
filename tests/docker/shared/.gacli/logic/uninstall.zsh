#!/usr/bin/env zsh
###############################
# FICHIER /src/logic/uninstall.zsh
###############################

# Uninstall GACLI: remove all file and cleanup .zshrc
gacli_uninstall() {
    printui info "Uninstalling... ⏳"

    # Variables
    local zshrc_file="${HOME}/.zshrc"

    # Remove GACLI lines from .zshrc
    print ""
    printui info "Updating .zshrc file... ⏳"
    if [[ -f "${zshrc_file}" ]]; then
        cp "${zshrc_file}" "${zshrc_file}.bak" || {
            printui error "Failed to backup zshrc file"
            return 1
        }

        # Remove all GACLI lines (header + source + alias)
        local grep_1="^export PATH=\"${DIR_GACLI}/.local/bin:\$PATH\""
        local grep_2="^source \"${DIR_GACLI}/.gacli/main.zsh\""
        local grep="${grep_1}\$|${grep_2}\$"
        grep -vE "${grep}" "${zshrc_file}" > "${zshrc_file}.tmp" || {
            printui error "Failed to parse zshrc file"
            return 1
        }


        mv "${zshrc_file}.tmp" "$zshrc_file" || {
            printui error "Failed to update zshrc file"
            return 1
        }

    else
        printui warning ".zshrc file not found ($zshrc_file)"
    fi
    printui success "Updated"

    # Remove GACLI wrapper
    print ""
    printui info "Removing wrapper... ⏳"
    local wrapper_path="${HOME}/.local/bin/gacli"
    if [[ -f "${wrapper_path}" ]]; then
        rm -f "${wrapper_path}" || {
            printui warning "Failed to delete wrapper ${wrapper_path}"
        }
    fi
    printui success "Removed"

    # Delete GACLI directory
    print ""
    printui info "Deleting GACLI files... ⏳"
    if [[ -d "${DIR_GACLI}" ]]; then
        rm -rf "${DIR_GACLI}" || {
            printui error "Failed to delete directory ${DIR_GACLI}"
            return 1
        }
    else
        printui error "Unable to find GACLI directory: ${DIR_GACLI}"
        return 1
    fi
    printui success "Deleted"

    print ""
    printui success "Uninstall complete ✅"
    print ""
    printui highlight "Restart your terminal"
    print ""
}

