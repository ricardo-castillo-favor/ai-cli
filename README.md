# AI-CLI — AI-Powered Development Workflow

> A command-line orchestrator that supercharges Claude Code and GitHub Copilot CLI with structured workflows for debugging, code reviews, feature planning, refactoring, and more.

---

## What is AI-CLI?

AI-CLI is a bash script that acts as an intelligent middleware between you and AI coding assistants (Claude Code CLI and GitHub Copilot CLI). Instead of manually crafting prompts and gathering context every time, AI-CLI automatically collects relevant repository information, combines it with your project's documentation, and sends structured, context-rich prompts to your preferred AI provider.

Think of it as a **context orchestrator** — it knows what information each type of task needs and assembles the perfect prompt automatically.

---

## Why Use AI-CLI?

| Benefit                            | Description                                                                                   |
| ---------------------------------- | --------------------------------------------------------------------------------------------- |
| **Structured Workflows**           | 14 pre-built commands for common dev tasks across the full development lifecycle              |
| **Automatic Context Injection**    | Automatically gathers git status, recent commits, changed files, and project structure        |
| **Token Efficiency**               | Sends only relevant context per task type, avoiding unnecessary token consumption             |
| **Provider Agnostic**              | Switch between Claude and Copilot with a single word                                          |
| **Persistent Documentation**       | Generates structured markdown files and interactive HTML task plans in `.ai-private/`         |
| **Dry-Run Mode**                   | Preview the exact prompt and command before execution                                         |
| **Model Override**                 | Override the default model per-run with `--model`                                             |

---

## Getting Started

### Prerequisites

1. **Git** — The script works exclusively within git repositories
2. **Claude Code CLI** — [Installation guide](https://docs.anthropic.com/en/docs/claude-code)
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```
3. **GitHub Copilot CLI** (optional, if using the `copilot` provider)
   ```bash
   gh extension install github/gh-copilot
   ```
4. **gh CLI** (optional, required for the `suggestions` command)
   ```bash
   brew install gh
   ```

### Installation

```bash
mkdir -p ~/bin
cp ai-cli ~/bin/ai-cli
chmod +x ~/bin/ai-cli
```

Add `~/bin` to your PATH if not already present:

```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="$HOME/bin:$PATH"
source ~/.zshrc
```

### Environment File

AI-CLI optionally sources `~/.ai.env` at startup. If the file is absent, a warning is printed and execution continues.

```bash
touch ~/.ai.env
# Add any API keys or environment variables your providers need
```

### Repository Setup

In your project's root directory:

```bash
# Required: base context file read by all commands
touch CLAUDE.md

# Optional: private context files (add .ai-private/ to .gitignore)
mkdir -p .ai-private
touch .ai-private/PLANNING.md   # feature specs and implementation plans
touch .ai-private/DEBUG.md      # bug descriptions and reproduction steps
touch .ai-private/REVIEW.md     # review output and fix suggestions
touch .ai-private/REFACTOR.md   # refactoring summaries

echo ".ai-private/" >> .gitignore
```

**File purposes:**

| File                      | Purpose                                                    |
| ------------------------- | ---------------------------------------------------------- |
| `CLAUDE.md`               | Project-wide instructions, conventions, and context for AI |
| `.ai-private/PLANNING.md` | Feature specs and implementation plans (read by `feature`, written by `planning`) |
| `.ai-private/DEBUG.md`    | Bug descriptions and reproduction steps (read by `debug`)  |
| `.ai-private/REVIEW.md`   | Review output and fix suggestions (written by `review`, `debug`, `suggestions`; read by `fix`, `refactor`) |
| `.ai-private/REFACTOR.md` | Refactoring summaries (written by `refactor`)              |
| `.ai-private/tasks/`      | Interactive HTML plans (written by `debug`, `review`, `planning`) |

> **Migration note:** `.ai-private/FEATURE.md` is no longer used. The `feature` command now reads from `.ai-private/PLANNING.md`. If you have an existing `FEATURE.md`, move its contents to `PLANNING.md`.

---

## Usage

### Basic Syntax

```bash
ai-cli [flags] <provider> [flags] <command> "your request"
```

**Providers:** `claude` | `copilot`

### Flags

| Flag | Short | Description |
| ---- | ----- | ----------- |
| `--dry-run` | `-d` | Show the generated prompt and provider command without executing |
| `--model <name>` | `-m <name>` | Override the default model for this run |

Flags can appear **before or after** the provider:

```bash
ai-cli --dry-run claude review "..."
ai-cli claude --dry-run review "..."

ai-cli --model haiku claude lint "..."
ai-cli claude --model haiku lint "..."
```

---

## Commands

### `commit` — Generate a commit message

Analyzes staged changes and generates a semantic commit message.

```bash
ai-cli claude commit "focus on the auth changes"
```

- **Context:** `git diff --cached` (staged diff)
- **Model:** sonnet
- **Reads:** `CLAUDE.md`
- **Output:** Commit message printed to terminal

---

### `debug` — Root cause analysis

Analyzes the bug described in `DEBUG.md`, traces the root cause, proposes the smallest safe fix, and writes findings to `REVIEW.md`.

```bash
# Uses opus by default (most capable — see note on cost below)
ai-cli claude debug "login throws 500 on special characters"

# Override to a cheaper model
ai-cli claude --model sonnet debug "..."
```

- **Context:** branch, status, commits, changed files, diff stats, `package.json` scripts
- **Model:** **opus** (override with `--model sonnet` to reduce cost)
- **Reads:** `CLAUDE.md`, `.ai-private/DEBUG.md`
- **Output:** `.ai-private/REVIEW.md`, `.ai-private/tasks/debug-{timestamp}.html`
- **Does NOT modify source files**

---

### `explain` — Explain code or architecture

Explains a piece of code, a design pattern, or how a feature works.

```bash
ai-cli claude explain "how does the auth middleware work?"
ai-cli copilot explain "what is the data flow in the checkout process?"
```

- **Context:** branch, status, commits, changed files, relevant file tree (depth 3)
- **Model:** **opus**
- **Reads:** `CLAUDE.md`
- **Output:** Explanation printed to terminal

---

### `feature` — Implement a feature

Implements the feature described in `.ai-private/PLANNING.md`. Fails immediately if `PLANNING.md` does not exist.

```bash
# First, describe what to build in .ai-private/PLANNING.md
ai-cli claude feature "implement the user auth flow"
```

- **Context:** branch, status, commits, changed files, relevant file tree (depth 3)
- **Model:** sonnet (default)
- **Reads:** `CLAUDE.md`, `.ai-private/PLANNING.md` **(required)**
- **Output:** Source file changes

---

### `fix` — Apply fixes from a review

Applies the bugs and improvements listed in `.ai-private/REVIEW.md`. Only touches files changed in this branch.

```bash
ai-cli claude fix "apply the security and performance suggestions"
```

- **Context:** branch, status, commits, changed files
- **Model:** sonnet
- **Reads:** `CLAUDE.md`, `.ai-private/REVIEW.md`
- **Output:** Source file changes

---

### `lint` — Fix linting issues

Fixes ESLint and Prettier issues in the changed files.

```bash
ai-cli claude lint "fix all lint errors in the changed files"
```

- **Context:** branch, status, commits, changed files
- **Model:** sonnet
- **Reads:** `CLAUDE.md`
- **Output:** Source file changes

---

### `planning` — Generate an implementation plan

Creates a detailed implementation plan and writes it to `.ai-private/PLANNING.md`. Does not modify source files.

```bash
ai-cli claude planning "design a caching layer for the API endpoints"
```

- **Context:** branch, status, commits, changed files, source files (.ts/.tsx/.js), full file tree (depth 3, max 100)
- **Model:** **opus**
- **Reads:** `CLAUDE.md`, `.ai-private/PLANNING.md`
- **Output:** `.ai-private/PLANNING.md`, `.ai-private/tasks/planning-{timestamp}.html`
- **Does NOT modify source files**

---

### `pr` — Generate a PR description

Generates a pull request description for the current branch against master.

```bash
ai-cli claude pr "highlight the security improvements"
```

- **Context:** branch, status, commits, changed files
- **Model:** sonnet
- **Reads:** `CLAUDE.md`
- **Output:** PR description printed to terminal

---

### `refactor` — Apply a refactoring

Applies the refactoring described in `.ai-private/REVIEW.md`, preserving behavior while improving code quality.

```bash
ai-cli claude refactor "apply the suggested performance optimizations"
```

- **Context:** branch, status, staged files, unstaged files, changed files
- **Model:** sonnet
- **Reads:** `CLAUDE.md`, `.ai-private/REVIEW.md`
- **Output:** Source file changes, `.ai-private/REFACTOR.md`

---

### `review` — Code review

Reviews all changed files against master, checks for bugs, style violations, missing tests, performance issues, and security concerns. Writes findings to `REVIEW.md`.

```bash
ai-cli claude review "focus on security and error handling"
ai-cli copilot review "check for performance regressions"
```

- **Context:** branch, status, commits, changed files
- **Model:** sonnet
- **Reads:** `CLAUDE.md`, `.ai-private/REVIEW.md`
- **Output:** `.ai-private/REVIEW.md`, `.ai-private/tasks/review-{timestamp}.html`
- **Does NOT modify source files**

---

### `suggestions` — Fetch PR review comments

Fetches suggestion comments from the open GitHub PR for this branch, creates a fix plan, and writes it to `REVIEW.md`.

```bash
ai-cli claude suggestions "prioritize the blocking comments"
```

- **Context:** branch, status, commits, changed files, current PR info (number, URL, title)
- **Model:** sonnet
- **Reads:** `CLAUDE.md`
- **Output:** `.ai-private/REVIEW.md`
- **Requires:** `gh` CLI and an open PR for the current branch

---

### `test` — Analyze test failures

Runs `npm run test`, captures the output, and asks the AI to diagnose root causes and suggest fixes.

```bash
ai-cli claude test "the auth tests are failing after the middleware refactor"
```

- **Context:** branch, status, commits, changed files, **live test output** (`npm run test`)
- **Model:** sonnet
- **Reads:** `CLAUDE.md`
- **Output:** Fix suggestions printed to terminal

---

### `types` — Fix TypeScript errors

Fixes TypeScript type errors in the changed files. Avoids `any` — uses `$TSFixMe` with a comment as a last resort.

```bash
ai-cli claude types "fix the type errors introduced by the new API response shape"
```

- **Context:** branch, status, commits, changed files
- **Model:** sonnet
- **Reads:** `CLAUDE.md`
- **Output:** Source file changes

---

### Free prompt (chat)

Any unrecognized command is treated as a free-form prompt — direct AI interaction without a structured workflow.

```bash
ai-cli claude "explain how the authentication middleware works"
ai-cli copilot "generate unit tests for the UserService class"
```

---

## Model Reference

| Command | Default Model | Notes |
| ------- | ------------- | ----- |
| `debug` | opus | Most expensive; override with `--model sonnet` if cost is a concern |
| `planning` | opus | Complex reasoning task |
| `explain` | opus | Best for architectural explanations |
| `commit` | sonnet | |
| `feature` | sonnet | |
| `fix` | sonnet | |
| `lint` | sonnet | |
| `pr` | sonnet | |
| `refactor` | sonnet | |
| `review` | sonnet | |
| `suggestions` | sonnet | |
| `test` | sonnet | |
| `types` | sonnet | |

**Claude model aliases:** `opus`, `sonnet`, `haiku`

**Copilot models:** `gpt-4o`, `gpt-4o-mini`, `gpt-3.5-turbo`, `claude-sonnet-4`, etc. Claude aliases (`opus`, `sonnet`, `haiku`) are silently mapped to the Copilot default. Full Claude model IDs (e.g. `claude-3-5-sonnet-20241022`) will produce a warning and fall back to the Copilot default.

---

## How It Works

```
ai-cli claude review "check for security issues"
         │
         ▼
1. Parse flags (--dry-run, --model) and provider
2. Validate: inside a git repo, CLAUDE.md exists
3. Auto-create .ai-private/ if missing
         │
         ▼
4. Load static context
   • CLAUDE.md (always)
   • .ai-private/*.md (command-specific)
         │
         ▼
5. Generate dynamic context
   • git branch, status, log
   • git diff --name-only master...HEAD
   • File tree / diff stats (command-specific)
   • Live command output (test command only)
   • PR info from gh pr view (suggestions only)
         │
         ▼
6. Assemble structured prompt
   ### TASK       — command instructions
   ### STATIC CONTEXT  — your docs
   ### DYNAMIC CONTEXT — git info + command output
   ### USER REQUEST    — your prompt
         │
         ▼
7. Execute AI provider
   • claude --dangerously-skip-permissions [--model X] "<prompt>"
   • copilot --allow-all-tools --allow-all-paths --add-dir $REPO_ROOT -p "<prompt>"
         │
         ▼
8. Output
   • AI response in terminal
   • Generated .md files in .ai-private/
   • Interactive HTML plans in .ai-private/tasks/
```

### Context Functions

| Function | Used by | What it includes |
| -------- | ------- | ---------------- |
| `base_repo_context()` | all | Branch name, `git status`, last 8 commits |
| `review_context()` | commit, fix, lint, pr, refactor, review, suggestions, test, types | `base_repo_context` + changed files vs master |
| `feature_context()` | explain, feature | `review_context` + file tree (depth 3, max 200) |
| `refactor_context()` | refactor | `base_repo_context` + staged, unstaged, and changed files |
| `debug_context()` | debug | `review_context` + diff stats + `package.json` scripts |
| `planning_context()` | planning | `review_context` + branch commits + source files + full tree (depth 3, max 100) |

---

## Dry-Run Mode

Preview the exact prompt and provider command without executing anything:

```bash
ai-cli --dry-run claude review "check for code smells"
ai-cli -d claude planning "add WebSocket support"
```

The dry-run output shows:
- Provider, command, branch, model, dry-run flag
- The exact CLI command that would be run
- The full prompt (without static context to keep it readable)
- Prompt size in characters and lines

---

## Token Efficiency

Each command gathers only the context relevant to its task:

| Command | Why scoped this way |
| ------- | ------------------- |
| `commit` | Only needs the staged diff |
| `review`, `fix`, `lint`, `types` | Only needs changed files list |
| `debug` | Adds diff stats and package scripts for runtime context |
| `feature`, `explain` | Adds a file tree so the AI knows where to write/look |
| `planning` | Broadest context — needs the full project picture |
| `refactor` | Needs staged vs unstaged distinction |
| `test` | Runs tests live and injects the real output |

File trees are capped at 100–200 entries and limited to depth 3 to prevent context overflow.

---

## Contributing

### Reporting Issues

1. Check existing issues before creating a new one
2. Include your OS, shell version, and CLI versions
3. Provide the command you ran and the error output
4. Use `--dry-run` to share the generated prompt without exposing your code

### Submitting Changes

1. Fork the repository
2. Create a branch: `git checkout -b feature/my-feature`
3. Follow the existing patterns for new commands
4. Test with both `claude` and `copilot` providers using `--dry-run`
5. Submit a PR with a clear description of what and why

### Adding a New Command

1. Add the command name to `KNOWN_COMMANDS` (line ~122)
2. Add a `context_function()` if the command needs custom context gathering
3. Add a `case` block calling `run()` with the instruction, context, model, and files
4. Add the command to `usage()`
5. Document it in this README

---

## License

MIT License — Feel free to use, modify, and distribute.

---

**Made for developers who want AI to work smarter, not harder.**
