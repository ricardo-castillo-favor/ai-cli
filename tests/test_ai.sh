#!/usr/bin/env bash
# tests/test_ai.sh – Unit tests for ai-cli
#
# Run with:  bash tests/test_ai.sh
# Uses a minimal built-in test harness (no external dependencies).

# NOTE: Do NOT use 'set -e' here; exit codes are checked explicitly in tests.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# ---------------------------------------------------------------------------
# Test harness
# ---------------------------------------------------------------------------
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  PASS: $*"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $*"; }

assert_contains() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    if echo "$actual" | grep -qF "$expected"; then
        pass "$description"
    else
        fail "$description — expected to contain: '$expected', got: '$actual'"
    fi
}

assert_not_contains() {
    local description="$1"
    local unexpected="$2"
    local actual="$3"
    if echo "$actual" | grep -qF "$unexpected"; then
        fail "$description — expected NOT to contain: '$unexpected', got: '$actual'"
    else
        pass "$description"
    fi
}

assert_exit_code() {
    local description="$1"
    local expected_code="$2"
    local actual_code="$3"
    if [[ "$actual_code" -eq "$expected_code" ]]; then
        pass "$description"
    else
        fail "$description — expected exit code $expected_code, got $actual_code"
    fi
}

# ---------------------------------------------------------------------------
# Setup: create a temp working directory used by tests
# ---------------------------------------------------------------------------
TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# Override contacts directory so tests don't pollute ~/.ai-cli
export AI_CONTACTS_DIR="${TMP_DIR}/contacts"

# ---------------------------------------------------------------------------
# Source lib modules for unit-level tests
# ---------------------------------------------------------------------------
# shellcheck source=../lib/context.sh
source "${ROOT_DIR}/lib/context.sh"
# shellcheck source=../lib/shortcuts.sh
source "${ROOT_DIR}/lib/shortcuts.sh"
# shellcheck source=../lib/contacts.sh
source "${ROOT_DIR}/lib/contacts.sh"

# ---------------------------------------------------------------------------
# Tests: shortcuts
# ---------------------------------------------------------------------------
echo ""
echo "=== Shortcuts ==="

out="$(ai_shortcut_debug 'null pointer')"
assert_contains "debug prompt includes 'debugger'"        "debugger"         "$out"
assert_contains "debug prompt includes description"       "null pointer"     "$out"

out="$(ai_shortcut_feature 'add login')"
assert_contains "feature prompt includes 'engineer'"      "engineer"         "$out"
assert_contains "feature prompt includes description"     "add login"        "$out"

out="$(ai_shortcut_refactor 'extract method')"
assert_contains "refactor prompt includes 'readability'"  "readability"      "$out"
assert_contains "refactor prompt includes description"    "extract method"   "$out"

out="$(ai_shortcut_review 'security')"
assert_contains "review prompt includes 'Security'"       "Security"         "$out"
assert_contains "review prompt includes description"      "security"         "$out"

out="$(ai_shortcut_planning 'auth service')"
assert_contains "planning prompt includes 'architect'"    "architect"        "$out"
assert_contains "planning prompt includes description"    "auth service"     "$out"

out="$(ai_shortcut_debug)"
assert_not_contains "debug with no description has no empty placeholder" "description:" "$out"

# ---------------------------------------------------------------------------
# Tests: shortcut dispatch
# ---------------------------------------------------------------------------
echo ""
echo "=== Shortcut dispatch ==="

for cmd in debug feature refactor review planning; do
    out="$(ai_shortcut_run "$cmd" "test description")"
    assert_contains "shortcut_run $cmd produces output" "test description" "$out"
done

# Unknown shortcut returns error
out="$(ai_shortcut_run "unknown" "x" 2>&1 || true)"
exit_code="$(ai_shortcut_run "unknown" "x" > /dev/null 2>&1; echo $?)"
assert_exit_code "unknown shortcut exits non-zero" 1 "$exit_code"

# ---------------------------------------------------------------------------
# Tests: context orchestrator
# ---------------------------------------------------------------------------
echo ""
echo "=== Context orchestrator ==="

# Test source file inclusion
SAMPLE_SRC="${TMP_DIR}/hello.py"
echo 'print("hello")' >"$SAMPLE_SRC"

AI_SOURCE_FILES=("$SAMPLE_SRC")
AI_CONTEXT_FILE=""
ai_context_collect
assert_contains "context includes source filename"     "hello.py"            "$AI_CONTEXT"
assert_contains "context includes source content"      'print("hello")'      "$AI_CONTEXT"
AI_SOURCE_FILES=()

# Test context file inclusion
CONTEXT_FILE="${TMP_DIR}/ctx.md"
echo "This is my project context." >"$CONTEXT_FILE"

AI_SOURCE_FILES=()
AI_CONTEXT_FILE="$CONTEXT_FILE"
ai_context_collect
assert_contains "context includes context file content" "This is my project context." "$AI_CONTEXT"
AI_CONTEXT_FILE=""

# Test build_prompt assembles correctly
AI_SOURCE_FILES=()
AI_CONTEXT_FILE=""
AI_CONTEXT=""
out="$(ai_context_build_prompt "Fix the bug")"
assert_contains "build_prompt includes task section"  "## Task"    "$out"
assert_contains "build_prompt includes task text"     "Fix the bug" "$out"

# ---------------------------------------------------------------------------
# Tests: contacts
# ---------------------------------------------------------------------------
echo ""
echo "=== Contacts ==="

# Save and load a contact
AI_MODEL="copilot"
AI_CONTEXT_FILE="${CONTEXT_FILE}"
AI_SOURCE_FILES=("${SAMPLE_SRC}")
AI_PROMPT="review this file"

ai_contact_save "testcontact"

# Reset globals
AI_MODEL="claude"
AI_CONTEXT_FILE=""
AI_SOURCE_FILES=()
AI_PROMPT=""

ai_contact_load "testcontact"

assert_contains "loaded contact model"          "copilot"             "$AI_MODEL"
assert_contains "loaded contact context file"   "$CONTEXT_FILE"       "$AI_CONTEXT_FILE"
assert_contains "loaded contact prompt"         "review this file"    "$AI_PROMPT"
assert_contains "loaded contact source files"   "$SAMPLE_SRC"         "${AI_SOURCE_FILES[*]}"

# List contacts
out="$(ai_contact_list)"
assert_contains "contact list shows saved contact" "testcontact" "$out"

# Delete contact
ai_contact_delete "testcontact"
out="$(ai_contact_list)"
assert_not_contains "deleted contact no longer listed" "testcontact" "$out"

# ---------------------------------------------------------------------------
# Tests: CLI – argument parsing and routing (no real AI backend needed)
# ---------------------------------------------------------------------------
echo ""
echo "=== CLI argument parsing ==="

# Unset globals that were set by previous tests so they don't leak into
# the CLI subprocess (which inherits the current environment).
unset AI_MODEL AI_CONTEXT_FILE AI_PROMPT

# --help should print usage and exit 0
out="$(bash "${ROOT_DIR}/ai" --help 2>&1 || true)"
ec="$(bash "${ROOT_DIR}/ai" --help > /dev/null 2>&1; echo $?)"
assert_contains "--help shows USAGE"            "USAGE"    "$out"
assert_exit_code "--help exits 0"               0          "$ec"

# No command → error
out="$(bash "${ROOT_DIR}/ai" 2>&1 || true)"
ec="$(bash "${ROOT_DIR}/ai" > /dev/null 2>&1; echo $?)"
assert_contains "no command shows error"        "no command" "$out"
assert_exit_code "no command exits non-zero"    1            "$ec"

# Unknown command → error
out="$(bash "${ROOT_DIR}/ai" unknowncmd 2>&1 || true)"
ec="$(bash "${ROOT_DIR}/ai" unknowncmd > /dev/null 2>&1; echo $?)"
assert_contains "unknown command shows error"   "unknown command" "$out"
assert_exit_code "unknown command exits non-zero" 1              "$ec"

# Unknown option → error
out="$(bash "${ROOT_DIR}/ai" --zap 2>&1 || true)"
ec="$(bash "${ROOT_DIR}/ai" --zap > /dev/null 2>&1; echo $?)"
assert_contains "unknown option shows error"    "unknown option"  "$out"
assert_exit_code "unknown option exits non-zero" 1               "$ec"

# ask without prompt → error
out="$(bash "${ROOT_DIR}/ai" ask 2>&1 || true)"
ec="$(bash "${ROOT_DIR}/ai" ask > /dev/null 2>&1; echo $?)"
assert_contains "'ask' without prompt shows error" "requires a prompt" "$out"
assert_exit_code "'ask' without prompt exits non-zero" 1              "$ec"

# contact list (empty)
out="$(AI_CONTACTS_DIR="${TMP_DIR}/empty_contacts" bash "${ROOT_DIR}/ai" contact list 2>&1 || true)"
ec="$(AI_CONTACTS_DIR="${TMP_DIR}/empty_contacts" bash "${ROOT_DIR}/ai" contact list > /dev/null 2>&1; echo $?)"
assert_contains "contact list empty shows message" "No contacts" "$out"
assert_exit_code "contact list exits 0" 0 "$ec"

# contact unknown subcommand
out="$(bash "${ROOT_DIR}/ai" contact badcmd 2>&1 || true)"
ec="$(bash "${ROOT_DIR}/ai" contact badcmd > /dev/null 2>&1; echo $?)"
assert_contains "contact unknown subcmd shows error" "unknown contact subcommand" "$out"
assert_exit_code "contact unknown subcmd exits non-zero" 1 "$ec"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed."
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
