# Claude Worktree

A CLI toolkit for setting up git worktree workflows optimized for parallel development with Claude Code AI agents.

## What This Does

- Creates a **bare git repository** structure with worktrees for parallel branch work
- Sets up a shared **`.claude` directory** with configuration, skills, and settings
- Generates **Claude Code skills** for commits, PRs, ticket planning, and implementation
- Creates a **VS Code/Cursor workspace** file for multi-worktree development
- Configures **pre-commit verification hooks** (type check, build, test)

## Installation

```bash
git clone https://github.com/your-org/claude-worktree.git
cd claude-worktree
./install.sh
```

Or manually:

```bash
ln -sf /path/to/claude-worktree/bin/cwt-init ~/.local/bin/cwt-init
export PATH="$HOME/.local/bin:$PATH"
```

## Quick Start

### Initialize a New Project

```bash
cwt-init git@github.com:org/repo.git my-project
cd my-project
```

The interactive setup will ask for:
- Project name
- Default base branch (auto-detected)
- Ticket system (none, Linear, GitHub, Jira)
- Package manager / project type (auto-detected)
- Verification commands (type check, build, test, lint)

### Project Structure After Init

```
my-project/
├── .bare/                    # Bare git repository
├── .claude/                  # Shared Claude configuration
│   ├── bin/wt               # Worktree management utility
│   ├── config.sh            # Project configuration
│   ├── CLAUDE.md            # Project documentation for Claude
│   ├── settings.local.json  # Claude permissions
│   ├── plans/               # Implementation plans
│   └── skills/              # Claude skills
│       ├── commit/
│       ├── pr/
│       ├── plan-ticket/
│       ├── implement-ticket/
│       └── work-tickets/    # (if Linear selected)
├── my-project.code-workspace # VS Code/Cursor workspace
└── main/                     # Main branch worktree
    └── .claude/
        └── CLAUDE.md → symlink to shared
```

## Using Worktrees

After initialization, use the `wt` command (installed in `.claude/bin/wt`):

```bash
# Create a new worktree for a feature
wt add my-feature              # Creates feature/my-feature branch
wt add eng-1234                # Creates eng-1234 branch (ticket ID pattern)
wt add bugfix main             # Creates from main instead of default branch

# List all worktrees
wt list

# Check status of all worktrees
wt status

# Remove a worktree
wt remove my-feature

# Sync workspace file after changes
wt sync

# Open in Cursor/VS Code
wt open                        # Opens workspace with all worktrees
wt open my-feature             # Opens specific worktree

# Install dependencies in worktree(s)
wt install-deps my-feature     # Specific worktree
wt install-deps                # All worktrees
```

## Available Skills

After setup, these Claude Code skills are available:

| Skill | Command | Description |
|-------|---------|-------------|
| Commit | `/commit` | Create conventional commits with pre-commit verification |
| PR | `/pr` | Create GitHub PRs with proper formatting |
| Plan Ticket | `/plan-ticket <id>` | Investigate codebase and create implementation plan |
| Implement Ticket | `/implement-ticket <id>` | Execute plan with verification hooks |
| Work Tickets | `/work-tickets` | (Linear only) Full automation: fetch → plan → implement |

## Configuration

Project configuration is stored in `.claude/config.sh`:

```bash
# Project settings
export WT_PROJECT_NAME="my-project"
export WT_DEFAULT_BRANCH="main"
export WT_TICKET_SYSTEM="linear"
export WT_PACKAGE_MANAGER="pnpm"

# Verification commands
export WT_TYPE_CHECK_CMD="pnpm tsc --noEmit"
export WT_BUILD_CMD="pnpm build"
export WT_TEST_CMD="pnpm test"
export WT_LINT_CMD="pnpm lint"

# Ticket system config
export WT_LINEAR_TEAM="ENG"
```

## Supported Project Types

The init script auto-detects and configures for:

- **Node.js**: pnpm, npm, yarn
- **Rust**: cargo
- **Go**: go modules
- **Python**: pip, poetry, pyproject.toml

## Why Bare Repo + Worktrees?

1. **Parallel Development**: Work on multiple branches simultaneously without stashing
2. **AI Agent Friendly**: Each worktree is independent - agents can work in parallel
3. **Shared Configuration**: Single `.claude` directory shared across all worktrees
4. **Clean Separation**: No "main" checkout that's special - all branches are equal
5. **IDE Support**: Workspace file shows all worktrees in one window

## Linear Integration

If you select Linear as your ticket system:

1. Install the [Linear MCP server](https://github.com/anthropics/claude-code-mcp-servers)
2. The `/work-tickets` skill becomes available
3. Skills will fetch ticket details automatically

## Customization

### Adding Custom Skills

Create a new directory in `.claude/skills/`:

```
.claude/skills/my-skill/SKILL.md
```

### Modifying Verification

Edit the hooks in skill files or modify `.claude/config.sh`.

### Updating CLAUDE.md

Edit `.claude/CLAUDE.md` to add project-specific documentation, commands, and conventions.

## Troubleshooting

### "Not in a wt-managed project"

Make sure you're in a directory that contains `.bare/` or is a worktree created by `wt`.

### Workspace not showing git changes

Each worktree has independent git integration. The parent directory (with `.bare`) is a bare repo and doesn't show changes.

### Broken worktree references

```bash
cd .bare
git worktree repair
```

### Permission denied on wt

```bash
chmod +x .claude/bin/wt
```

## License

MIT
