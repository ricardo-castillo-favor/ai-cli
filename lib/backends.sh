#!/usr/bin/env bash
# lib/backends.sh – Wrappers for Claude Code CLI and GitHub Copilot CLI

# Run a prompt through Claude Code CLI (`claude`).
# Arguments: $1 = prompt text
ai_backend_claude() {
    local prompt="$1"

    if ! command -v claude &>/dev/null; then
        echo "Error: 'claude' CLI not found. Install Claude Code: https://docs.anthropic.com/en/docs/claude-code" >&2
        return 1
    fi

    claude --print "$prompt"
}

# Run a prompt through GitHub Copilot CLI (`gh copilot`).
# Arguments: $1 = prompt text
ai_backend_copilot() {
    local prompt="$1"

    if ! command -v gh &>/dev/null; then
        echo "Error: 'gh' CLI not found. Install GitHub CLI: https://cli.github.com/" >&2
        return 1
    fi

    if ! gh extension list 2>/dev/null | grep -q "copilot"; then
        echo "Error: GitHub Copilot CLI extension not installed." >&2
        echo "Install it with: gh extension install github/gh-copilot" >&2
        return 1
    fi

    gh copilot explain "$prompt"
}

# Dispatch a prompt to the selected backend.
# Arguments: $1 = prompt text, $2 = model (claude|copilot), default: claude
ai_backend_run() {
    local prompt="$1"
    local model="${2:-claude}"

    case "$model" in
        claude)
            ai_backend_claude "$prompt"
            ;;
        copilot)
            ai_backend_copilot "$prompt"
            ;;
        *)
            echo "Error: unknown model '$model'. Supported models: claude, copilot" >&2
            return 1
            ;;
    esac
}
