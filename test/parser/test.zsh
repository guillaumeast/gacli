#!/usr/bin/env zsh

# Input and Output
PARSER="/Users/gui/Repos/gacli/gacli/src/.helpers/parser.zsh"

# JSON files
D_JSON="/Users/gui/Repos/gacli/gacli/test/parser/json_files"
F_JSON_READ="${D_JSON}/read.json"
F_JSON_WRITE_TEMPLATE="${D_JSON}/write_template.json"
F_JSON_WRITE_TO="${D_JSON}/write_to.json"

# Brewfile files
D_BREW="/Users/gui/Repos/gacli/gacli/test/parser/brewfiles"
F_BREW_READ="${D_BREW}/read.Brewfile"
F_BREW_WRITE_TEMPLATE="${D_BREW}/write_template.Brewfile"
F_BREW_WRITE_TO="${D_BREW}/write_to.Brewfile"

# Results
TOTAL=0
SUCCESS=0
FAILED=0

# ────────────────────────────────────────────────────────────────
# Source scripts to test
# ────────────────────────────────────────────────────────────────

# Source scripts to test
source "${PARSER}"

test_parser() {
  print_section "Testing JSON parser..."
  test_json

  print_section "Testing Brewfile parser..."
  test_brew

  print_section "Testing unified parser..."
  test_unified

  print_total || return 1
}

# Test JSON parser
test_json() {

  # Test _json_read
  print "\n👉 ${GREY}Testing read...${NONE}"
  run_test "_json_read scalar_empty" "$(_json_read "${F_JSON_READ}" "scalar_empty")" ""                         # Should return empty value
  run_test "_json_read scalar_value" "$(_json_read "${F_JSON_READ}" "scalar_value")" "value 1"                  # Should return "value 1" as a unique value (not "value" "1")
  run_test "_json_read list_empty" "$(_json_read "${F_JSON_READ}" "list_empty")" ""                         # Should return empty list
  run_test "_json_read list_value" "$(_json_read "${F_JSON_READ}" "list_value")" "\"value 2\" \"value 3\""  # Should return a list with two values (no less, no more) which are "value 1" and "value 2"

  # Now we assume that _json_read is working as expected
  # So we'll check further writing functions by reading the output file with _json_read

  # Reset output file
  cp "${F_JSON_WRITE_TEMPLATE}" "${F_JSON_WRITE_TO}"

  # Test _json_write
  print "\n👉 ${GREY}Testing write scalar...${NONE}"
  run_test "_json_write scalar_empty" "$(_json_write "${F_JSON_WRITE_TO}" "scalar_empty" "" && _json_read "${F_JSON_WRITE_TO}" "scalar_empty")" ""
  run_test "_json_write scalar_value (1/2)" "$(_json_write "${F_JSON_WRITE_TO}" "scalar_value" "tmp value" && _json_read "${F_JSON_WRITE_TO}" "scalar_value")" "tmp value"
  run_test "_json_write scalar_value (2/2)" "$(_json_write "${F_JSON_WRITE_TO}" "scalar_value" "value 1" && _json_read "${F_JSON_WRITE_TO}" "scalar_value")" "value 1"

  print "\n👉 ${GREY}Testing write list...${NONE}"

  # Test _json_reset
  run_test "_json_reset list_reset" "$(_json_reset "${F_JSON_WRITE_TO}" "list_reset" && _json_read "${F_JSON_WRITE_TO}" "list_reset")" ""

  # Test _json_add
  run_test "_json_add list_add (1/2)" "$(_json_add "${F_JSON_WRITE_TO}" "list_add" "value 2" && _json_read "${F_JSON_WRITE_TO}" "list_add")" "\"value 2\""
  run_test "_json_add list_add (2/2)" "$(_json_add "${F_JSON_WRITE_TO}" "list_add" "value 3" && _json_read "${F_JSON_WRITE_TO}" "list_add")" "\"value 2\" \"value 3\""

  # Test _json_rm
  run_test "_json_rm list_rm (1/2)" "$(_json_rm "${F_JSON_WRITE_TO}" "list_rm" "old value 4" && _json_read "${F_JSON_WRITE_TO}" "list_rm")" "\"old value 5\" \"old value 6\" \"old value 7\""
  run_test "_json_rm list_rm (2/2)" "$(_json_rm "${F_JSON_WRITE_TO}" "list_rm" "old value 5" && _json_read "${F_JSON_WRITE_TO}" "list_rm")" "\"old value 6\" \"old value 7\""
}

# Test Brewfile parser
test_brew() {

  # Test _brew_read
  print "\n👉 ${GREY}Testing read...${NONE}"
  run_test "_brew_read formulae" "$(_brew_read "${F_BREW_READ}" "formulae")" "\"my formula 1\" \"my formula 2\""
  run_test "_brew_read casks" "$(_brew_read "${F_BREW_READ}" "casks")" "\"my cask 1\" \"my cask 2\"" 

  # Now we assume that _brew_read is working as expected
  # So we'll check further writing functions by reading the output file with _brew_read

  # Reset output file
  cp "${F_BREW_WRITE_TEMPLATE}" "${F_BREW_WRITE_TO}"

  print "\n👉 ${GREY}Testing write...${NONE}"

  # Test _brew_reset
  run_test "_brew_reset formulae" "$(_brew_reset "${F_BREW_WRITE_TO}" "formulae" && _brew_read "${F_BREW_WRITE_TO}" "formulae")" ""
  run_test "_brew_reset casks" "$(_brew_reset "${F_BREW_WRITE_TO}" "casks" && _brew_read "${F_BREW_WRITE_TO}" "casks")" ""

  # Test _brew_add
  run_test "_brew_add formulae (1/2)" "$(_brew_add "${F_BREW_WRITE_TO}" "formulae" "formula 1" && _brew_read "${F_BREW_WRITE_TO}" "formulae")" "\"formula 1\""
  run_test "_brew_add formulae (2/2)" "$(_brew_add "${F_BREW_WRITE_TO}" "formulae" "formula 2" && _brew_read "${F_BREW_WRITE_TO}" "formulae")" "\"formula 1\" \"formula 2\""
  run_test "_brew_add casks (1/2)" "$(_brew_add "${F_BREW_WRITE_TO}" "casks" "cask 1" && _brew_read "${F_BREW_WRITE_TO}" "casks")" "\"cask 1\""
  run_test "_brew_add casks (2/2)" "$(_brew_add "${F_BREW_WRITE_TO}" "casks" "cask 2" && _brew_read "${F_BREW_WRITE_TO}" "casks")" "\"cask 1\" \"cask 2\""

  # Test _brew_rm
  run_test "_brew_rm formulae" "$(_brew_rm "${F_BREW_WRITE_TO}" "formulae" "formula 1" && _brew_read "${F_BREW_WRITE_TO}" "formulae")" "\"formula 2\""
  run_test "_brew_rm casks" "$(_brew_rm "${F_BREW_WRITE_TO}" "casks" "cask 1" && _brew_read "${F_BREW_WRITE_TO}" "casks")" "\"cask 2\""
}

# Test unified parser
test_unified() {

  # JSON
  print "\n👉 ${GREY}Testing JSON support...${NONE}"

  # Test file_read
  print "\n👉 ${GREY}Testing read...${NONE}"
  run_test "file_read scalar_empty" "$(file_read "${F_JSON_READ}" "scalar_empty")" ""                     # Should return empty value
  run_test "file_read scalar_value" "$(file_read "${F_JSON_READ}" "scalar_value")" "value 1"              # Should return "value 1" as a unique value (not "value" "1")
  run_test "file_read list_empty" "$(file_read "${F_JSON_READ}" "list_empty")" ""                         # Should return empty list
  run_test "file_read list_value" "$(file_read "${F_JSON_READ}" "list_value")" "\"value 2\" \"value 3\""  # Should return a list with two values (no less, no more) which are "value 1" and "value 2"

  # Now we assume that file_read is working as expected
  # So we'll check further writing functions by reading the output file with file_read

  # Reset output file
  cp "${F_JSON_WRITE_TEMPLATE}" "${F_JSON_WRITE_TO}"

  # Test file_write
  print "\n👉 ${GREY}Testing write scalar...${NONE}"
  run_test "file_write scalar_empty" "$(file_write "${F_JSON_WRITE_TO}" "scalar_empty" "" && file_read "${F_JSON_WRITE_TO}" "scalar_empty")" ""
  run_test "file_write scalar_value (1/2)" "$(file_write "${F_JSON_WRITE_TO}" "scalar_value" "tmp value" && file_read "${F_JSON_WRITE_TO}" "scalar_value")" "tmp value"
  run_test "file_write scalar_value (2/2)" "$(file_write "${F_JSON_WRITE_TO}" "scalar_value" "value 1" && file_read "${F_JSON_WRITE_TO}" "scalar_value")" "value 1"

  print "\n👉 ${GREY}Testing write list...${NONE}"

  # Test file_reset
  run_test "file_reset list_reset" "$(file_reset "${F_JSON_WRITE_TO}" "list_reset" && file_read "${F_JSON_WRITE_TO}" "list_reset")" ""

  # Test file_add
  run_test "file_add list_add one" "$(file_add "${F_JSON_WRITE_TO}" "list_add" "value 2" && file_read "${F_JSON_WRITE_TO}" "list_add")" "\"value 2\""
  run_test "file_add list_add list" "$(file_add "${F_JSON_WRITE_TO}" "list_add" "value 3" "value 4" && file_read "${F_JSON_WRITE_TO}" "list_add")" "\"value 2\" \"value 3\" \"value 4\""

  # Test file_rm
  run_test "file_rm list_rm one" "$(file_rm "${F_JSON_WRITE_TO}" "list_rm" "old value 4" && file_read "${F_JSON_WRITE_TO}" "list_rm")" "\"old value 5\" \"old value 6\" \"old value 7\""
  run_test "file_rm list_rm list" "$(file_rm "${F_JSON_WRITE_TO}" "list_rm" "old value 5" "old value 7" && file_read "${F_JSON_WRITE_TO}" "list_rm")" "\"old value 6\""

  # BREW
  print "\n👉 ${GREY}Testing Brewfile support...${NONE}"

  # Test file_read
  print "\n👉 ${GREY}Testing read...${NONE}"
  run_test "file_read formulae" "$(file_read "${F_BREW_READ}" "formulae")" "\"my formula 1\" \"my formula 2\""
  run_test "file_read casks" "$(file_read "${F_BREW_READ}" "casks")" "\"my cask 1\" \"my cask 2\"" 

  # Now we assume that file_read is working as expected
  # So we'll check further writing functions by reading the output file with file_read

  # Reset output file
  cp "${F_BREW_WRITE_TEMPLATE}" "${F_BREW_WRITE_TO}"

  print "\n👉 ${GREY}Testing write...${NONE}"

  # Test file_reset
  run_test "file_reset formulae" "$(file_reset "${F_BREW_WRITE_TO}" "formulae" && file_read "${F_BREW_WRITE_TO}" "formulae")" ""
  run_test "file_reset casks" "$(file_reset "${F_BREW_WRITE_TO}" "casks" && file_read "${F_BREW_WRITE_TO}" "casks")" ""

  # Test file_add
  run_test "file_add one formula" "$(file_add "${F_BREW_WRITE_TO}" "formulae" "formula 1" && file_read "${F_BREW_WRITE_TO}" "formulae")" "\"formula 1\""
  run_test "file_add list formulae" "$(file_add "${F_BREW_WRITE_TO}" "formulae" "formula 2" "formula 3" && file_read "${F_BREW_WRITE_TO}" "formulae")" "\"formula 1\" \"formula 2\" \"formula 3\""
  run_test "file_add one cask" "$(file_add "${F_BREW_WRITE_TO}" "casks" "cask 1" && file_read "${F_BREW_WRITE_TO}" "casks")" "\"cask 1\""
  run_test "file_add list casks" "$(file_add "${F_BREW_WRITE_TO}" "casks" "cask 2" "cask 3" && file_read "${F_BREW_WRITE_TO}" "casks")" "\"cask 1\" \"cask 2\" \"cask 3\""

  # Test file_rm
  run_test "file_rm one formula" "$(file_rm "${F_BREW_WRITE_TO}" "formulae" "formula 2" && file_read "${F_BREW_WRITE_TO}" "formulae")" "\"formula 1\" \"formula 3\""
  run_test "file_rm list" "$(file_rm "${F_BREW_WRITE_TO}" "casks" "cask 1" "cask 3" && file_read "${F_BREW_WRITE_TO}" "casks")" "\"cask 2\""
}

# ────────────────────────────────────────────────────────────────
# TEST LOGIQUE (don't modify this)
# ────────────────────────────────────────────────────────────────

# run_test <test_name> <result> <expected_result>
run_test() {
  local test_name=$1
  local result=$2
  local expected=$3

  # Increment total tests count
  ((TOTAL++))

  # Compare output with expected result
  if [[ "$result" == "$expected" ]]; then
    ((SUCCESS++))
    print "    ✅ ${GREY}${test_name} → '${GREEN}${result}${GREY}'${NONE}"
  else
    ((FAILED++))
    print "    ❌ ${GREY}${test_name} → '${RED}${result}${GREY}' ≠ '${ORANGE}${expected}${GREY}'${NONE}"
  fi
}

print_section() {
  print -- "${GREY}\n--------------------------------------${NONE}"
  print "${GREY} → ${1}${NONE}"
  print -- "${GREY}--------------------------------------${NONE}"
}

print_total() {
  local failed_pourcent=$((FAILED * 100 / TOTAL))
  local success_pourcent=$((SUCCESS * 100 / TOTAL))
  local message=""
  local color=$RED

  # Compute message
  if [[ $failed_pourcent == 0 ]]; then
    color=$GREEN
    message="    └→ ✅ ${SUCCESS} TESTS PASSED"
  else
    message="    └→ ❌ ${FAILED} TESTS FAILED"
  fi

  # Display results
  print -- "${BOLD}${color}\n--------------------------------------${NONE}"
  print -- "${BOLD}${color}--------------------------------------${NONE}"
  print "${BOLD}${color} → FINAL RESULT = ${ORANGE}${success_pourcent} %${NONE}"
  print "${BOLD}${color}${message}${NONE}"
  print -- "${BOLD}${color}--------------------------------------${NONE}"
  print -- "${BOLD}${color}--------------------------------------\n${NONE}"

  [[ $failed_pourcent == 0 ]] || return 1
}

# ────────────────────────────────────────────────────────────────
# RUN
# ────────────────────────────────────────────────────────────────

test_parser

