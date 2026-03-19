# Dotfiles

This repository contains personal configuration files and development environment setup.

## Setup

### Claude Code Skills

To use the custom Claude Code skills globally across all projects, create a symbolic link:

```bash
ln -s "$(pwd)/.claude/skills" ~/.claude/skills
```

This will make the skills available in any project where you use Claude Code.


**To verify the skills are available:**
After updating the skills, you can check they're properly linked:

```bash
ls -la ~/.claude/skills
```

This should show the symlink pointing to your dotfiles repository.

### Claude Code Settings

To use the global Claude Code settings from this repository, create a symbolic link:

```bash
ln -s "$(pwd)/.claude/settings.json" ~/.claude/settings.json
```

**To verify the settings are linked:**

```bash
ls -la ~/.claude/settings.json
```

This should show the symlink pointing to your dotfiles repository.

### CLI Tools

Add the `bin` directory to your PATH. From this dotfiles directory, run:

```bash
echo "export PATH=\"$(pwd)/bin:\$PATH\"" >> ~/.zshrc
source ~/.zshrc
```

This will automatically use the correct absolute path to the bin directory.

**Available commands:**
- `nk <task-name>` - Create a new task directory in `.claude/tasks/<task-name>/` with a requirements.md template for Claude Code workflows
