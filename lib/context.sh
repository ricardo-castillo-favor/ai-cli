#!/usr/bin/env bash
# lib/context.sh – Context orchestrator
# Collects and formats context from multiple sources:
#   - Explicit --source files provided by the user
#   - A .ai-context file in the project root
#   - Basic git repository metadata

# Collect context from all available sources.
# Sets AI_CONTEXT (string) with the assembled context block.
ai_context_collect() {
    local source_files=("${AI_SOURCE_FILES[@]:-}")
    local extra_context_file="${AI_CONTEXT_FILE:-}"
    local ctx=""

    # 1. Git repository info
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local repo_root
        repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
        local branch
        branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
        local repo_name
        repo_name="$(basename "$repo_root")"
        ctx+="## Repository\n"
        ctx+="- Name: ${repo_name}\n"
        ctx+="- Branch: ${branch}\n"
        ctx+="\n"
    fi

    # 2. Project-level .ai-context file (closest one up the directory tree)
    local project_context_file
    project_context_file="$(ai_context_find_file)"
    if [[ -n "$project_context_file" && -f "$project_context_file" ]]; then
        ctx+="## Project Context\n"
        ctx+="$(cat "$project_context_file")\n\n"
    fi

    # 3. Additional context file passed via --context
    if [[ -n "$extra_context_file" && -f "$extra_context_file" ]]; then
        ctx+="## Additional Context\n"
        ctx+="$(cat "$extra_context_file")\n\n"
    fi

    # 4. Source files passed via --source
    if [[ ${#source_files[@]} -gt 0 && -n "${source_files[0]:-}" ]]; then
        for src in "${source_files[@]}"; do
            if [[ -f "$src" ]]; then
                local ext="${src##*.}"
                ctx+="## Source: ${src}\n"
                ctx+="\`\`\`${ext}\n"
                ctx+="$(cat "$src")\n"
                ctx+="\`\`\`\n\n"
            else
                echo "Warning: source file not found: $src" >&2
            fi
        done
    fi

    AI_CONTEXT="$ctx"
    export AI_CONTEXT
}

# Walk up from CWD looking for a .ai-context file.
ai_context_find_file() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "${dir}/.ai-context" ]]; then
            echo "${dir}/.ai-context"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 0
}

# Format the final prompt that will be sent to the backend.
# Arguments: $1 = task prompt
# Prints the assembled prompt to stdout.
ai_context_build_prompt() {
    local task_prompt="$1"

    ai_context_collect

    local final_prompt=""

    if [[ -n "${AI_CONTEXT:-}" ]]; then
        final_prompt+="$(printf '%b' "$AI_CONTEXT")"
        final_prompt+="\n"
    fi

    final_prompt+="## Task\n"
    final_prompt+="${task_prompt}"

    printf '%b' "$final_prompt"
}
