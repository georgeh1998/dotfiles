# Dotfiles

This repository contains personal configuration files and development environment setup.

## Setup

### Claude Code Commands

To use the custom Claude Code commands, create a symbolic link:

```bash
ln -s dotfiles/claude/commands .claude/commands
```

This will link the commands directory to your Claude Code configuration.

### CLI Tools

Add the `bin` directory to your PATH. From this dotfiles directory, run:

```bash
echo "export PATH=\"$(pwd)/bin:\$PATH\"" >> ~/.zshrc
source ~/.zshrc
```

This will automatically use the correct absolute path to the bin directory.

**Available commands:**
- `nk <task-name>` - Create a new task directory in `.claude/tasks/<task-name>/` with a requirements.md template for Claude Code workflows
- `nw <branch-name>` - Create a new git worktree for the specified branch in `../worktrees/<branch-name>/`
