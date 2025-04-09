###############################
# FICHIER uninstall.zsh
###############################

#!/usr/bin/env zsh

# Uninstall GACLI: remove config file and cleanup .zshrc
gacli_uninstall() {
    printStyled info "Uninstalling... ⏳"

    # Variables
    local zshrc_file="$HOME/.zshrc"
    local config_file="${CONFIG_FILE}"

    # Delete config file
    if [[ -f "${config_file}" ]]; then
        rm "${config_file}" || {
            printStyled warning "[gacli_uninstall] Failed to delete config file ${config_file}"
        }
    else
        printStyled warning "[gacli_uninstall] Config file not found (${config_file})"
    fi

    # Remove GACLI lines from .zshrc
    if [[ -f "${zshrc_file}" ]]; then
        cp "${zshrc_file}" "${zshrc_file}.bak" || {
            printStyled error "[gacli_uninstall] Failed to backup zshrc file"
            return 1
        }

        # Remove all GACLI lines (header + source + alias)
        grep -vE '^# GACLI$|^source ".*gacli.zsh"$|^alias gacli="zsh .*gacli.zsh"$' "${zshrc_file}" > "${zshrc_file}.tmp" || {
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

    printStyled success "Uninstall complete ✅"
    print ""
    printStyled warning "Restart your terminal"
    print ""
}

