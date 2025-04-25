#!/usr/bin/env zsh
###############################
# FICHIER /tests/fixture/modules/valid_module/main.zsh
###############################

# Keep it secret
export ULTIMATE_ANSWER=42

get_commands() {
  local commands=( \ 
    "being_curious=asking_questions" \ 
    "ultimate_question=ultimate_answer" \ 
  )
  echo "${commands[@]}"
}

asking_questions() {
    echo "..."
}

ultimate_answer() {
    echo "${ULTIMATE_ANSWER}"
}
