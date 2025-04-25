#!/usr/bin/env zsh

# Keep it secret
export ULTIMATE_ANSWER=42

get_commands() {
  echo "being_curious=asking_questions"
  echo "ultimate_question=ultimate_answer"
}

asking_questions() {
    echo "..."
}

ultimate_answer() {
    echo "${ULTIMATE_ANSWER}"
}
