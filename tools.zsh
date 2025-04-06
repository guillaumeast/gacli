#!/usr/bin/env zsh

# Add a number of days to a date (requires coreutils)
add_days() {
    local start_date=$1
    local add=$2
    gdate -d "$start_date +$add days" "+%Y-%m-%d"
}
