#!/usr/bin/env bash
# lib/contacts.sh – Save and load named contacts (source + context + model + prompt)
#
# A "contact" is a saved combination of:
#   source  – one or more source files
#   context – an additional context file
#   model   – the AI backend (claude|copilot)
#   prompt  – a default prompt or task description
#
# Contacts are stored in ~/.ai-cli/contacts/<name>.env

AI_CONTACTS_DIR="${AI_CONTACTS_DIR:-${HOME}/.ai-cli/contacts}"

# Save a contact.
# Arguments: $1 = contact name
# Reads from current AI_SOURCE_FILES, AI_CONTEXT_FILE, AI_MODEL, AI_PROMPT globals.
ai_contact_save() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Error: contact name required." >&2
        return 1
    fi

    mkdir -p "$AI_CONTACTS_DIR"
    local file="${AI_CONTACTS_DIR}/${name}.env"

    # Serialize AI_SOURCE_FILES array as colon-separated list
    local sources_serialised
    sources_serialised="$(IFS=':'; echo "${AI_SOURCE_FILES[*]:-}")"

    cat >"$file" <<EOF
AI_MODEL='${AI_MODEL:-claude}'
AI_CONTEXT_FILE='${AI_CONTEXT_FILE:-}'
AI_SOURCE_FILES_SERIALISED='${sources_serialised}'
AI_PROMPT='${AI_PROMPT:-}'
EOF

    echo "Contact '${name}' saved to ${file}"
}

# Load a contact by name.
# Exports AI_SOURCE_FILES, AI_CONTEXT_FILE, AI_MODEL, AI_PROMPT.
ai_contact_load() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Error: contact name required." >&2
        return 1
    fi

    local file="${AI_CONTACTS_DIR}/${name}.env"
    if [[ ! -f "$file" ]]; then
        echo "Error: contact '${name}' not found (${file})." >&2
        return 1
    fi

    # Source the file to load variables
    # shellcheck source=/dev/null
    source "$file"

    # Deserialize AI_SOURCE_FILES from colon-separated list
    if [[ -n "${AI_SOURCE_FILES_SERIALISED:-}" ]]; then
        IFS=':' read -r -a AI_SOURCE_FILES <<<"$AI_SOURCE_FILES_SERIALISED"
        export AI_SOURCE_FILES
    fi

    export AI_MODEL
    export AI_CONTEXT_FILE
    export AI_PROMPT
}

# List all saved contacts.
ai_contact_list() {
    if [[ ! -d "$AI_CONTACTS_DIR" ]] || [[ -z "$(ls -A "$AI_CONTACTS_DIR" 2>/dev/null)" ]]; then
        echo "No contacts saved yet. Use 'ai contact save <name>' to save one."
        return 0
    fi

    echo "Saved contacts:"
    for f in "${AI_CONTACTS_DIR}"/*.env; do
        local name
        name="$(basename "$f" .env)"
        printf "  %s\n" "$name"
        # shellcheck source=/dev/null
        (
            source "$f"
            [[ -n "${AI_MODEL:-}" ]] && printf "    model:   %s\n" "$AI_MODEL"
            [[ -n "${AI_CONTEXT_FILE:-}" ]] && printf "    context: %s\n" "$AI_CONTEXT_FILE"
            [[ -n "${AI_SOURCE_FILES_SERIALISED:-}" ]] && printf "    source:  %s\n" "$AI_SOURCE_FILES_SERIALISED"
            [[ -n "${AI_PROMPT:-}" ]] && printf "    prompt:  %s\n" "$AI_PROMPT"
        )
    done
}

# Delete a contact.
# Arguments: $1 = contact name
ai_contact_delete() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Error: contact name required." >&2
        return 1
    fi

    local file="${AI_CONTACTS_DIR}/${name}.env"
    if [[ ! -f "$file" ]]; then
        echo "Error: contact '${name}' not found." >&2
        return 1
    fi

    rm "$file"
    echo "Contact '${name}' deleted."
}
