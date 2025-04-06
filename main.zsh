###################################################
# FICHIER main.zsh
###################################################
#!/usr/bin/env zsh
print "\033[90m✌️  Don't panic...\033[0m"

# OS
IS_MACOS=false
IS_LINUX=false

case "$OSTYPE" in
  darwin*) IS_MACOS=true ;;
  linux*)  IS_LINUX=true ;;
esac

# MODULES
GACLI_PATH="$(cd "$(dirname "${(%):-%x}")" && pwd)"
source "$GACLI_PATH/tools.zsh"
source "$GACLI_PATH/style.zsh"
source "$GACLI_PATH/install.zsh"
source "$GACLI_PATH/update.zsh"

# DATE
TODAY="$(date "+%Y-%m-%d")"

# TOOLS LIST (from Brewfile)
if [[ ! -f "$GACLI_PATH/Brewfile" ]]; then
    printStyled "error" "⛔ Brewfile not found in $GACLI_PATH"
else
    FORMULAE=($(grep '^brew "' "$GACLI_PATH/Brewfile" | cut -d'"' -f2))
    CASKS=($(grep '^cask "' "$GACLI_PATH/Brewfile" | cut -d'"' -f2))
fi

# MAIN
main() {
    # Show ASCII art logo
    ascii_logo
                                    
    # Install or update if needed
    if [[ -f "$GACLI_PATH/.config" ]]; then
        # Update (needs coreutils installed)
        if command -v gdate >/dev/null 2>&1; then
            local next_update=$(grep "^next_update =" "$GACLI_PATH/.config" | cut -d= -f2 | xargs)
            if [[ -z "$next_update" || "$(gdate -d "$TODAY" +%s)" -ge "$(gdate -d "$next_update" +%s)" ]]; then
                update_tools
            fi
        else
            # Error if coreutils is not installed
            printStyled error "[main] coreutils is required for date comparison"
            printStyled warning "Auto-update has been disabled"
        fi
    else
        # Install GACLI
        install_gacli
    fi

    # Log tools status
    print_tools
}

main

