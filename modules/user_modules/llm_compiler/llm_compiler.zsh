###############################
# FICHIER llm_compiler.zsh
###############################

#!/usr/bin/env zsh
# Compile repository into LLM embeddable resources (`.md` or `.txt` + structure file)

# Input variables
COMPILER_PATH="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR_NAME="llm_ressources"
STRUCTURE_FILE_NAME="structure.md"
TEMPLATE_FILE_NAME="structure_template.md"

# Computed variables
TARGET_PATH=""
OUTPUT_DIR=""
GITIGNORE_FILE=""
EXCLUDED_PATHS=("${OUTPUT_DIR_NAME}" ".git")

# Output variables
TREE=""
CREATED_FILES=()
TOTAL=0

# Declare commands provided by this module
get_commands() {
    echo 'llmcompile=llmcompile'
}

# Main
llmcompile() {
    printStyled info "Compiling codebase... ⏳"

    # Init
    resolve_paths "$1" || return 1
    exclude_paths
    clean_output || return 1

    # Generate
    generate_structure || return 1
    generate_codebase || return 1

    # Display results
    display_results "${OUTPUT_DIR}"
}

# Resolve paths
resolve_paths() {
    TARGET_PATH="$1"
    if [[ "${TARGET_PATH}" == "" ]]; then
        TARGET_PATH="${PWD}"
    fi
    OUTPUT_DIR="${TARGET_PATH}/${OUTPUT_DIR_NAME}"
    GITIGNORE_FILE="${TARGET_PATH}/.gitignore"
}

# Exclude paths
exclude_paths() {
    # From Gitignore
    if [[ -f "${GITIGNORE_FILE}" ]]; then
        local line abs_matches match
        while IFS= read -r line; do
            # Ignore empty lines and comments
            [[ -z "$line" || "$line" == \#* ]] && continue

            # Expand glob relative to TARGET_PATH, then absolutize each result
            abs_matches=(${~"${TARGET_PATH}/${line}":A})

            for match in "${abs_matches[@]}"; do
                [[ -e "$match" ]] && EXCLUDED_PATHS+=("${match}")
            done
        done < "${GITIGNORE_FILE}"
    fi
}

# Clean output dir
clean_output() {
    # Delete output dir
    if [[ "${OUTPUT_DIR}" != "/" && -n "${OUTPUT_DIR}" && -d "${OUTPUT_DIR}" ]]; then
        rm -rf -- "${OUTPUT_DIR}" 2>/dev/null || {
            printStyled error "[clean_output] Failed to clean output dir: ${OUTPUT_DIR}"
            return 1
        }
    fi

    # Create new output dir
    if ! mkdir "${OUTPUT_DIR}"; then
        printStyled error "[llmcompile] Failed to create output dir: ${OUTPUT_DIR}"
        return 1
    fi
}

# Generate the tree structure of the target directory
generate_tree() {
    # Join excluded paths with | for the -I option
    local ignored_pattern="$(IFS="|"; echo "${EXCLUDED_PATHS[*]}")"

    # Run tree (excluding unwanted paths)
    if ! TREE=$(tree -a -I "${ignored_pattern}" "${TARGET_PATH}" 2>/dev/null); then
        printStyled error "[generate_tree] Failed to generate directory tree"
        return 1
    fi

    # Replace top path with "repo"
    local repo_name="$(basename "${TARGET_PATH}")"
    if ! TREE=$(printf "%s\n" "${TREE}" | sed "1s|${TARGET_PATH}|${repo_name}|"); then
        printStyled warning "[generate_tree] Failed to replace top path with 'repo'"
    fi
}

# Generate structure file
generate_structure() {
    local structure_file="${OUTPUT_DIR}/${STRUCTURE_FILE_NAME}"

    # Copy template
    if ! cp "${COMPILER_PATH}/${TEMPLATE_FILE_NAME}" "${structure_file}"; then
        printStyled error "[generate_structure] Failed to copy template file"
        return 1
    fi

    # Generate tree
    generate_tree || return 1

    {
        echo ""
        echo "\`\`\`bash"
        echo "${TREE}"
        echo "\`\`\`"
        echo ""
    } >> "${structure_file}" || {
        printStyled error "[generate_structure] Failed to write TREE to structure file"
        return 1
    }
}

# Convert all codebase into .txt/.md embeddable files
generate_codebase() {
    printStyled debug "Generating codebase..."
    printStyled debug "PATH = $PATH"

    # Build exclusion args
    local find_args=()
    for path in "${EXCLUDED_PATHS[@]}"; do
        printStyled debug "Formatting exclusion [${path}]"
        find_args+=(-path "$path" -o) # TODO: fix (les `"` sont interprétés, ils ne s'affichent donc pas dans `find_args`)
    done

    # Remove trailing -o
    find_args=("${find_args[@]:0:${#find_args[@]}-1}")
    printStyled debug "find_args = ${find_args}"

    # Tests
    print ""
    command -v find
    builtin command find "$TARGET_PATH"

    print ""
    printStyled debug ">>> TEST 1 : find simple"
    find "$TARGET_PATH"

    print ""
    printStyled debug ">>> TEST 2 : find + -type f"
    find "$TARGET_PATH" -type f
    print ""


    # # Loop through all files, excluding matched paths
    # # TODO: fix `generate_codebase:16: command not found: find` (je ne veux pas de workaround, je veux identifier la source de mes problèmes de path et la corriger)
    # find "$TARGET_PATH" \( "${find_args[@]}" \) -prune -o -type f -print | while read -r file_path; do
    #     convert_file "$file_path" || {
    #         printStyled warning "[generate_codebase] Failed to convert file: $file_path"
    #     }
    # done
}

# Convert a unique file into .txt/.md embeddable files
convert_file() {
    # Debug
    print ""
    
    # Argument
    local file_path="$1"
    printStyled debug "Converting file [${file_path}]"

    # Argument check
    if [[ -z "$file_path" || ! -f "$file_path" ]]; then
        printStyled error "[convert_file] Invalid or missing file path: '$file_path'"
        return 1
    fi

    # Variables
    local rel_path="${file_path#./}"
    local extension="${file_path##*.}"
    local output_file_name="${rel_path//\//_}"

    # Extension
    if [[ "$extension" != "txt" && "$extension" != "md" ]]; then
        output_file_name="${output_file_name}.txt"
    fi
    local output_file_path="${OUTPUT_DIR}/${output_file_name}"
    printStyled debug "output_file_name = [${output_file_name}]"

    printStyled debug "Copying file..."
    if ! cp "${file_path}" "${output_file_path}"; then
        printStyled error "[convert_file] Failed to copy '${file_path}' to '${output_file_path}'"
        return 1
    fi
    printStyled debug "File created ✅"


    CREATED_FILES+=("${rel_path}|${output_file_name}")
    ((TOTAL++))
}

# Display results
display_results() {
    # Variables
    local OUTPUT_DIR="$1"

    # Results
    printStyled info "Generated files:"
    printf "%-40s | %-40s\n" "origin" "llm_ressources"
    printf "%-40s-+-%-40s\n" "----------------------------------------" "----------------------------------------"
    for file in "${CREATED_FILES[@]}"; do
        local orig="${file%%|*}"
        local llm="${file##*|}"
        printf "%-40s | %-40s\n" "$orig" "$llm"
    done

    # Infos
    print ""
    printStyled success "structure.md + $TOTAL files created 🦾🤖"
    print ""
    printStyled highlight "See ${OUTPUT_DIR}"
    print ""
}

