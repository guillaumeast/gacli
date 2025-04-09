###############################
# FICHIER llm_compiler.zsh
###############################

#!/usr/bin/env zsh
# Compile repository into LLM embeddable resources (`.md` or `.txt` + structure file)

# Input variables
local COMPILER_PATH="$(cd "$(dirname "${(%):-%x}")" && pwd)"
local OUTPUT_DIR_NAME="llm_ressources"
local STRUCTURE_FILE_NAME="structure.md"
local TEMPLATE_FILE_NAME="structure_template.md"

# Computed variables
local TARGET_PATH=""
local OUTPUT_DIR=""
local GITIGNORE_FILE=""


# Output variables
local TREE=""
local -a EXCLUDED_PATHS=("${OUTPUT_DIR_NAME}" ".git")
local -a CREATED_FILES=()
local TOTAL=0

# Declare commands provided by this module
get_commands() {
    echo 'llmcompile=llmcompile'
}

# Main
llmcompile() {
    printStyled info "Compiling codebase... ⏳"

    # Variables
    TARGET_PATH="$PWD"
    OUTPUT_DIR="${TARGET_PATH}/${OUTPUT_DIR_NAME}"
    GITIGNORE_FILE="${TARGET_PATH}/.gitignore"

    # Init
    clean_output || return 1
    exclude_paths

    # Generate
    if ! mkdir "${OUTPUT_DIR}"; then
        printStyled error "[llmcompile] Failed to create output dir: ${OUTPUT_DIR}"
        return 1
    fi
    generate_structure || return 1
    generate_codebase || return 1

    # Display results
    display_results "${OUTPUT_DIR}"
}

# Clean output dir
clean_output() {
    if [[ -d "${OUTPUT_DIR}" ]]; then
        if ! rm -rf "${OUTPUT_DIR}" 2>/dev/null; then
            printStyled error "[clean_output] Failed to remove output dir: ${OUTPUT_DIR}"
            return 1
        fi
    fi
}

# Exclude paths
exclude_paths() {
    # From Gitignore
    if [[ -f "${GITIGNORE_FILE}" ]]; then
        local rel_paths

        # Extract non-empty, non-comment lines from .gitignore
        if ! rel_paths=("${(@f)$(grep -vE '^#|^$' "${GITIGNORE_FILE}")}"); then
            printStyled warning "[exclude_paths] Failed to parse .gitignore"
            return 1
        fi
        EXCLUDED_PATHS+=("${rel_paths[@]}")
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
    if ! TREE=$(sed "1s|${TARGET_PATH}|repo|" <<< "${TREE}"); then
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
    # Format exclusions
    local find_exclude=""
    for path in "${EXCLUDED_PATHS[@]}"; do
        find_exclude+="-path \"./${path}\" -o "
    done
    find_exclude="${find_exclude% -o }"

    # Loop through all files (expect excluded paths)
    (
        cd "$TARGET_PATH" || {
            printStyled error "[generate_codebase] Failed to cd into $TARGET_PATH"
            exit 1
        }

        eval find . \( $find_exclude \) -prune -o -type f -print
    ) | while read -r file_path; do
        convert_file "$file_path" || {
            printStyled warning "[generate_codebase] Failed to convert file: $file_path"
        }
    done
}

# Convert a unique file into .txt/.md embeddable files
convert_file() {
    # Argument
    local file_path="$1"

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

    if ! cp "${file_path}" "${output_file_path}"; then
        printStyled error "[convert_file] Failed to copy '${file_path}' to '${output_file_path}'"
        return 1
    fi

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
    printStyled highlight "See ${OUTPUT_DIR}"
}

