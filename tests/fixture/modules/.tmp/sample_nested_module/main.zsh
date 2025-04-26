#!/usr/bin/env zsh

local commands=(
  "nested_command=nested_function"
)

get_commands() {
    local cmd=""
    for cmd in $commands; do
        echo $cmd
    done
}

nested_function() {
    echo "nested answer"
}

