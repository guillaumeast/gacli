#!/usr/bin/env zsh

# Add a number of days to a date (MacOS + Linux fallback)
add_days()
{
    local start_date=$1
    local add=$2
    local end_date=$(date -j -v+"$add"d -f "%Y-%m-%d" "$start_date" "+%Y-%m-%d" 2>/dev/null || \
                    date -d "$start_date +$add days" "+%Y-%m-%d")
    echo $end_date
}