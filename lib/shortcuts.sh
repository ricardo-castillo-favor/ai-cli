#!/usr/bin/env bash
# lib/shortcuts.sh – Prompt templates for common AI-assisted development tasks

# Build a "debug" prompt for the given description.
# Arguments: $1 = optional description of the bug
ai_shortcut_debug() {
    local description="${1:-}"
    local prompt="You are an expert debugger. Analyze the provided code and context.\n"
    prompt+="Identify bugs, errors, or unexpected behaviors.\n"
    prompt+="For each issue found:\n"
    prompt+="1. Describe the root cause clearly.\n"
    prompt+="2. Show the exact fix with a code snippet.\n"
    prompt+="3. Explain why the fix resolves the issue.\n"
    if [[ -n "$description" ]]; then
        prompt+="\nProblem description: ${description}"
    fi
    printf '%b' "$prompt"
}

# Build a "feature" prompt for the given description.
# Arguments: $1 = feature description
ai_shortcut_feature() {
    local description="${1:-}"
    local prompt="You are an expert software engineer. Implement the following feature in the provided codebase.\n"
    prompt+="Follow the existing code style, patterns, and conventions.\n"
    prompt+="Include:\n"
    prompt+="1. The full implementation with code.\n"
    prompt+="2. Any necessary tests.\n"
    prompt+="3. A brief explanation of design decisions.\n"
    if [[ -n "$description" ]]; then
        prompt+="\nFeature request: ${description}"
    fi
    printf '%b' "$prompt"
}

# Build a "refactor" prompt for the given description.
# Arguments: $1 = optional refactoring goal
ai_shortcut_refactor() {
    local description="${1:-}"
    local prompt="You are an expert software engineer focused on code quality. Refactor the provided code.\n"
    prompt+="Goals:\n"
    prompt+="1. Improve readability and maintainability without changing behavior.\n"
    prompt+="2. Apply SOLID principles and reduce duplication (DRY).\n"
    prompt+="3. Provide a before/after diff or the full refactored code.\n"
    prompt+="4. Briefly explain each significant change.\n"
    if [[ -n "$description" ]]; then
        prompt+="\nRefactoring goal: ${description}"
    fi
    printf '%b' "$prompt"
}

# Build a "review" prompt for the given description.
# Arguments: $1 = optional focus area for the review
ai_shortcut_review() {
    local description="${1:-}"
    local prompt="You are a senior software engineer performing a code review. Review the provided code.\n"
    prompt+="Evaluate:\n"
    prompt+="1. Correctness and potential bugs.\n"
    prompt+="2. Security vulnerabilities.\n"
    prompt+="3. Performance concerns.\n"
    prompt+="4. Code style and best practices.\n"
    prompt+="5. Test coverage gaps.\n"
    prompt+="Provide actionable, prioritized feedback.\n"
    if [[ -n "$description" ]]; then
        prompt+="\nFocus area: ${description}"
    fi
    printf '%b' "$prompt"
}

# Build a "planning" prompt for the given topic.
# Arguments: $1 = topic or feature to plan
ai_shortcut_planning() {
    local description="${1:-}"
    local prompt="You are a senior software architect. Create a detailed implementation plan.\n"
    prompt+="Include:\n"
    prompt+="1. High-level architecture and component breakdown.\n"
    prompt+="2. Step-by-step implementation tasks (ordered by dependency).\n"
    prompt+="3. Potential risks and mitigation strategies.\n"
    prompt+="4. Estimated complexity for each task (low/medium/high).\n"
    if [[ -n "$description" ]]; then
        prompt+="\nTopic: ${description}"
    fi
    printf '%b' "$prompt"
}

# Dispatch to the correct shortcut by name.
# Arguments: $1 = shortcut name, $2 = description
ai_shortcut_run() {
    local name="$1"
    local description="${2:-}"
    case "$name" in
        debug)    ai_shortcut_debug    "$description" ;;
        feature)  ai_shortcut_feature  "$description" ;;
        refactor) ai_shortcut_refactor "$description" ;;
        review)   ai_shortcut_review   "$description" ;;
        planning) ai_shortcut_planning "$description" ;;
        *)
            echo "Error: unknown shortcut '$name'. Available: debug, feature, refactor, review, planning" >&2
            return 1
            ;;
    esac
}
