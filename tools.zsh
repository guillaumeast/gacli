###################################################
# FICHIER tools.zsh
###################################################
#!/usr/bin/env zsh

# Add a number of days to a date (requires coreutils)
add_days() {
    local start_date=$1
    local add=$2

    if ! command -v gdate >/dev/null 2>&1; then
        printStyled error "[add_days] Missing dependency: gdate (from coreutils)"
        return 1
    fi

    gdate -d "$start_date +$add days" "+%Y-%m-%d"
}

