# ai-cli

A bash CLI wrapper for **Claude Code** and **GitHub Copilot CLI** that provides:

1. **CLI wrapper** – unified interface for both Claude Code (`claude`) and Copilot (`gh copilot`)
2. **Context orchestrator** – automatically assembles context from source files, a per-project `.ai-context` file, and git metadata
3. **Task shortcuts** – opinionated prompts for `debug`, `feature`, `refactor`, `review`, and `planning`
4. **Contacts** – save/load named configurations combining _source_ + _context_ + _model_ + _prompt_

---

## Requirements

| Tool | Install |
|------|---------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `npm install -g @anthropic-ai/claude-code` |
| [GitHub CLI](https://cli.github.com/) + Copilot extension | `gh extension install github/gh-copilot` |

At least one of the two backends must be installed. Both are optional – only the one you use needs to be present.

---

## Installation

```bash
git clone https://github.com/ricardo-castillo-favor/ai-cli.git
cd ai-cli
# Add to PATH (pick one):
export PATH="$PWD:$PATH"           # temporary
echo "export PATH=\"$PWD:\$PATH\"" >> ~/.bashrc  # permanent
```

---

## Usage

```
ai [OPTIONS] <command> [DESCRIPTION]
ai contact <subcommand> [NAME]
```

### Commands

| Command | Description |
|---------|-------------|
| `debug [desc]` | Find and fix bugs in source files |
| `feature [desc]` | Implement a new feature |
| `refactor [desc]` | Improve code quality without changing behavior |
| `review [desc]` | Code review with actionable feedback |
| `planning [topic]` | Architecture and implementation planning |
| `ask <prompt>` | Send a free-form prompt |

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `-m, --model MODEL` | `claude` | AI backend: `claude` or `copilot` |
| `-s, --source FILE` | – | Source file to include (repeatable) |
| `-c, --context FILE` | – | Additional context file |
| `-p, --prompt TEXT` | – | Inline task description |
| `--contact NAME` | – | Load a saved contact before running |
| `-h, --help` | – | Show help |

---

## Examples

```bash
# Debug a Python file using Claude Code
ai debug -s src/api.py "getting a KeyError on line 42"

# Add a feature with extra context, using Copilot
ai feature -m copilot -s src/auth.js -c docs/auth-spec.md "add JWT refresh tokens"

# Review code quality
ai review -s lib/utils.ts

# Refactor using a saved contact
ai --contact myproject refactor "extract helper functions"

# Free-form prompt
ai ask "What design pattern should I use for this plugin system?"

# Create an implementation plan
ai planning "migrate REST API to GraphQL"
```

---

## Context orchestrator

The context orchestrator automatically collects and assembles context before each request:

1. **Git metadata** – repository name and current branch (if inside a git repo)
2. **`.ai-context` file** – place a `.ai-context` file in any project root; the tool walks up the directory tree to find the nearest one
3. **`--context` file** – an explicit context file passed on the command line
4. **`--source` files** – source code files, included as fenced code blocks

**Example `.ai-context`:**
```markdown
This is a Node.js REST API built with Express 4 and TypeScript.
Database: PostgreSQL via Prisma ORM.
Auth: JWT, using the `jsonwebtoken` library.
Style guide: follow ESLint rules in .eslintrc.json.
```

---

## Contacts

Contacts store a reusable combination of **source + context + model + prompt** so you don't have to repeat yourself.

```bash
# Save current options as a contact
ai -m claude -s src/auth.py -c docs/context.md -p "security review" contact save myproject

# Load a contact and run a shortcut
ai --contact myproject review

# List all saved contacts
ai contact list

# Delete a contact
ai contact delete myproject
```

Contacts are stored in `~/.ai-cli/contacts/<name>.env`.

---

## Project structure

```
ai-cli/
├── ai               # Entry-point script
├── lib/
│   ├── backends.sh  # Claude Code & Copilot CLI wrappers
│   ├── context.sh   # Context orchestrator
│   ├── contacts.sh  # Contact save/load/list/delete
│   └── shortcuts.sh # Task prompt templates
└── tests/
    └── test_ai.sh   # Test suite (bash, no deps)
```

## Running tests

```bash
bash tests/test_ai.sh
```
