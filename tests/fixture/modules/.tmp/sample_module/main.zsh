#!/usr/bin/env zsh

# Keep it secret
export ULTIMATE_ANSWER=42
local commands=(
  "being_curious=asking_questions"
  "ultimate_question=ultimate_answer"
)

get_commands() {
    local cmd=""
    for cmd in $commands; do
        echo $cmd
    done
}

asking_questions() {
    echo "..."
}

ultimate_answer() {
    echo "${ULTIMATE_ANSWER}"
}
