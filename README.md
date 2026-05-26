# 🤖 AI-CLI — Your AI-Powered Development Workflow

> A smart command-line orchestrator that supercharges Claude Code and GitHub Copilot CLI with structured workflows for debugging, code reviews, feature planning, and refactoring.

---

## What is AI-CLI?

AI-CLI is a bash script that acts as an intelligent middleware between you and AI coding assistants (Claude Code CLI and GitHub Copilot CLI). Instead of manually crafting prompts and gathering context every time, AI-CLI automatically collects relevant repository information, combines it with your project's documentation, and sends structured, context-rich prompts to your preferred AI provider.

Think of it as a **context orchestrator** — it knows what information each type of task needs and assembles the perfect prompt automatically.

---

## ✨ Why Use AI-CLI?

| Benefit                            | Description                                                                                   |
| ---------------------------------- | --------------------------------------------------------------------------------------------- |
| **🎯 Structured Workflows**        | Pre-built commands for common dev tasks: `debug`, `review`, `refactor`, `feature`, `planning` |
| **📦 Automatic Context Injection** | Automatically gathers git status, recent commits, changed files, and project structure        |
| **💾 Token Efficiency**            | Sends only relevant context per task type, avoiding unnecessary token consumption             |
| **🔄 Provider Agnostic**           | Switch between Claude and Copilot with a single flag                                          |
| **📝 Persistent Documentation**    | Generates structured markdown files and interactive HTML task plans                           |
| **🧪 Dry-Run Mode**                | Preview the exact prompt before execution                                                     |
| **🔒 Private Output**              | All generated files are stored in `.ai-private/` (add to `.gitignore`)                        |

---

## 🚀 Getting Started

### Prerequisites

Before using AI-CLI, ensure you have the following installed:

1. **Git** — The script works exclusively within git repositories
2. **Claude Code CLI** — [Installation guide](https://docs.anthropic.com/en/docs/claude-code)
   ```bash
   # Install via npm
   npm install -g @anthropic-ai/claude-code
   ```
3. **GitHub Copilot CLI** (optional, if using Copilot provider)
   ```bash
   # Install via GitHub CLI extension
   gh extension install github/gh-copilot
   ```
4. **Environment File** — Create `~/.ai.env` with any required API keys or configurations

### Installation

#### Step 1: Download the Script

```bash
# Create your local bin directory if it doesn't exist
mkdir -p ~/bin

# Copy the ai-cli script
cp ai-cli ~/bin/ai-cli

# Make it executable
chmod +x ~/bin/ai-cli
```

#### Step 2: Add to PATH

Add `~/bin` to your PATH if not already present:

```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="$HOME/bin:$PATH"

# Reload your shell
source ~/.zshrc
```

#### Step 3: Create Environment File

```bash
# Create the environment file
touch ~/.ai.env

# Add your configurations (example)
echo "# AI CLI Environment" > ~/.ai.env
```

#### Step 4: Set Up Your Repository

In your project's root directory, create the required files:

```bash
# Create the base context file
touch CLAUDE.md

# Create the private directory for AI outputs
mkdir -p .ai-private

# Create context files for each workflow
touch .ai-private/FEATURE.md
touch .ai-private/DEBUG.md
touch .ai-private/REFACTOR.md
touch .ai-private/REVIEW.md
touch .ai-private/PLANNING.md

# Add to .gitignore
echo ".ai-private/" >> .gitignore
```

**File Purposes:**

| File                      | Purpose                                                    |
| ------------------------- | ---------------------------------------------------------- |
| `CLAUDE.md`               | Project-wide instructions, conventions, and context for AI |
| `.ai-private/FEATURE.md`  | Feature specifications and requirements                    |
| `.ai-private/DEBUG.md`    | Bug descriptions and reproduction steps                    |
| `.ai-private/REVIEW.md`   | Review output and refactoring suggestions                  |
| `.ai-private/PLANNING.md` | Implementation plans and architecture notes                |
| `.ai-private/REFACTOR.md` | Refactoring summaries                                      |

---

## 📖 Usage Examples

### Basic Syntax

```bash
ai-cli <provider> [command] "your request"
```

**Providers:** `claude` | `copilot`

**Commands:** `debug` | `feature` | `refactor` | `review` | `planning` | (free prompt)

### Code Review

```bash
# Review all changes against master branch
ai-cli claude review "Check for security vulnerabilities and performance issues"

# Using Copilot
ai-cli copilot review "Focus on error handling and edge cases"
```

### Debugging

```bash
# Debug a specific issue
ai-cli claude debug "The login form throws a 500 error when password contains special characters"
```

### Feature Implementation

```bash
# Implement a feature (requires PLANNING.md to be filled)
ai-cli claude feature "Implement user authentication with JWT"
```

### Planning Mode

```bash
# Generate an implementation plan (uses Opus model for complex reasoning)
ai-cli claude planning "Design a caching layer for the API endpoints"
```

### Refactoring

```bash
# Apply refactoring based on REVIEW.md suggestions
ai-cli claude refactor "Apply the suggested performance optimizations"
```

### Free Prompt (Chat)

```bash
# Direct AI interaction without structured workflow
ai-cli claude "Explain how the authentication middleware works"
ai-cli copilot "Generate unit tests for the UserService class"
```

### Dry-Run Mode

Preview the generated prompt without executing:

```bash
ai-cli --dry-run claude review "Check for code smells"
ai-cli -d claude planning "Add WebSocket support"
```

---

## 💡 How It Saves Tokens

AI-CLI is designed with **token efficiency** in mind:

1. **Task-Specific Context** — Each command gathers only the context relevant to that task:
   - `review` → Changed files against master, git diff stats
   - `debug` → Package scripts, recent commits, error-related files
   - `planning` → Broader file tree (up to depth 4), full branch context
   - `feature` → Focused tree (depth 3), changed files list

2. **Truncated Output** — File trees are limited (200-300 files max) to prevent context overflow

3. **Static + Dynamic Separation** — Static context (your docs) is loaded once; dynamic context (git info) is generated fresh

4. **No Redundant Files** — Only existing files are included; missing optional files are skipped with warnings

5. **Structured Prompts** — Clear sections (`### TASK`, `### STATIC CONTEXT`, etc.) help the AI parse efficiently

**Example:** A `review` command might use ~3,000 tokens of context instead of ~15,000 if you manually included your entire codebase.

---

## 🔧 Under the Hood

Here's what AI-CLI does when you run a command:

```
┌─────────────────────────────────────────────────────────────┐
│                     ai-cli claude review                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Validate Environment                                    │
│     • Check if inside git repo                              │
│     • Parse flags (--dry-run)                               │
│     • Identify provider and command                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Gather Static Context                                   │
│     • Read CLAUDE.md (base instructions)                    │
│     • Read relevant .ai-private/*.md files                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Generate Dynamic Context                                │
│     • Current branch name                                   │
│     • git status --short                                    │
│     • git log --oneline (recent commits)                    │
│     • git diff --name-only master...HEAD                    │
│     • File tree (find command, filtered)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Assemble Structured Prompt                              │
│     ### TASK (command-specific instructions)                │
│     ### STATIC CONTEXT (your docs)                          │
│     ### DYNAMIC CONTEXT (git info)                          │
│     ### USER REQUEST (your prompt)                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Execute AI Provider                                     │
│     • Claude: claude --dangerously-skip-permissions         │
│     • Copilot: copilot --allow-all-tools --add-dir          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  6. Output                                                  │
│     • AI response in terminal                               │
│     • Generated files in .ai-private/                       │
│     • Interactive HTML plan (when applicable)               │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

| Function                  | Purpose                                            |
| ------------------------- | -------------------------------------------------- |
| `base_repo_context()`     | Gathers branch, status, and recent commits         |
| `changed_files_context()` | Lists files changed against master                 |
| `review_context()`        | Context optimized for code reviews                 |
| `debug_context()`         | Includes package.json scripts for debugging        |
| `planning_context()`      | Broader file tree for architectural decisions      |
| `feature_context()`       | Balanced context for implementation work           |
| `run_ai()`                | Executes the appropriate CLI with assembled prompt |

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Reporting Issues

1. Check existing issues before creating a new one
2. Include your OS, shell version, and CLI versions
3. Provide the command you ran and the error output
4. Use `--dry-run` to share the generated prompt (without exposing your code)

### Submitting Changes

1. **Fork** the repository
2. **Create a branch** for your feature: `git checkout -b feature/my-feature`
3. **Make your changes** following the existing code style
4. **Test** with both `claude` and `copilot` providers
5. **Submit a PR** with a clear description of what and why

### Ideas for Contributions

- [ ] Add support for more AI providers (Gemini, OpenAI CLI)
- [ ] Create provider-specific optimizations
- [ ] Add `test` command for automated test generation
- [ ] Implement `docs` command for documentation generation
- [ ] Add configuration file support (`.ai-cli.yaml`)
- [ ] Create installation script (`install.sh`)
- [ ] Add shell completions (zsh, bash, fish)

### Code Style

- Use descriptive function names
- Add comments for complex logic
- Follow existing patterns for new commands
- Test with `--dry-run` before final testing

---

## 📄 License

MIT License — Feel free to use, modify, and distribute.

---

## 🙏 Acknowledgments

- [Anthropic](https://anthropic.com) for Claude Code CLI
- [GitHub](https://github.com/features/copilot) for Copilot CLI
- The open-source community for inspiration

---

**Made with ❤️ for developers who want AI to work smarter, not harder.**
