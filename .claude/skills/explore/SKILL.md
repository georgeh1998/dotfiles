---
name: explore
description: Investigate codebase based on task specifications in .claude/tasks/[task-name]/spec.md and generate research findings. Trigger ONLY when the user types `/explore [task-name]` with an exact task name argument. Do not trigger for general exploration requests, codebase questions, or investigative tasks unless the exact command format is used.
---

# Explore Skill

This skill helps you systematically investigate a codebase based on task specifications and produce comprehensive research findings.

## When to Use

Trigger this skill **ONLY** when:
- User types `/explore [task-name]` where `[task-name]` is an exact directory name under `.claude/tasks/`
- Example: `/explore sample-feature`, `/explore auth-refactor`, `/explore api-migration`

Do NOT trigger for:
- General exploration requests ("explore the codebase", "investigate this feature")
- Codebase questions ("how does authentication work?")
- Research without the specific `/explore` command format

## Workflow

### 1. Validate the Task

First, check if the task directory exists and has a spec.md file:

```bash
# Extract task name from user's command (the argument after /explore)
TASK_NAME="[task-name from user input]"
TASK_DIR=".claude/tasks/${TASK_NAME}"

# Verify directory and spec.md exist
if [ ! -d "$TASK_DIR" ] || [ ! -f "$TASK_DIR/spec.md" ]; then
  echo "Error: Task '$TASK_NAME' not found or missing spec.md"
  exit 1
fi
```

If the task doesn't exist, inform the user and stop. Do not proceed with investigation.

### 2. Read and Understand the Spec

Read `.claude/tasks/[task-name]/spec.md` to understand:
- **やりたいこと** (What they want to do) - The goal or problem to solve
- **調べてほしいこと** (What to investigate) - Specific investigation points

Pay close attention to each investigation point. These are your research objectives.

### 3. Conduct the Investigation

For each investigation point in the spec, systematically explore the codebase:

**Search for relevant files:**
- Use `Glob` to find files by pattern (e.g., `**/*.sh`, `**/config/*`, `**/*alias*`)
- Use `Grep` to search for keywords, function names, or patterns in file contents
- Look in common locations based on the task domain (config files, source code, documentation, etc.)

**Analyze what you find:**
- Read the relevant files using `Read` tool
- Understand the current implementation, architecture, and patterns
- Identify dependencies, interactions, and potential impact areas
- Note any existing solutions or similar features

**Document insights:**
- Related files and their roles
- Current architecture and implementation patterns
- Libraries, frameworks, or tools in use
- Existing code that might need modification
- Patterns that should be followed or avoided
- Potential challenges or considerations

### 4. Generate research.md

Create `.claude/tasks/[task-name]/research.md` with your findings. Use this structure:

```markdown
# [Task Name] - Research Findings

## 概要
Brief summary of what you investigated and key discoveries.

## 既存の実装
Document what currently exists in the codebase:
- Relevant files and their purposes
- Current architecture or patterns
- Libraries/frameworks in use

## 調査結果
For each investigation point from spec.md, provide detailed findings:

### [Investigation Point 1]
- What you found
- Relevant file paths with line numbers if applicable
- Code patterns or examples
- Analysis and insights

### [Investigation Point 2]
...

## 実装への示唆
Based on your investigation, what insights are useful for implementation:
- Existing patterns to follow
- Files that will need changes
- Potential approaches or strategies
- Risks or challenges to consider
- Recommended libraries or tools

## 参考ファイル
List of all relevant files discovered:
- `path/to/file1.ext` - Brief description
- `path/to/file2.ext` - Brief description
```

### 5. Writing Quality Standards

**Be thorough but focused:**
- Cover all investigation points from spec.md
- Don't just list files - explain their relevance and what you learned
- Include specific file paths with line numbers for important code

**Be specific and actionable:**
- Provide concrete examples from the codebase
- Quote relevant code snippets when helpful
- Explain "why" not just "what" (why does this pattern exist? why might it matter for the task?)

**Be honest about gaps:**
- If you can't find something, say so
- If multiple approaches are possible, present them
- If something is unclear from the code, note it as a question to clarify

### 6. Confirm Completion

After generating research.md, inform the user:
- Where the research file was saved
- A brief summary of key findings
- Suggest next steps (e.g., "You can now use this research to plan implementation")

## Example

User input: `/explore sample-feature`

You would:
1. Read `.claude/tasks/sample-feature/spec.md`
2. Investigate the codebase based on "調べてほしいこと"
3. Generate `.claude/tasks/sample-feature/research.md` with comprehensive findings
4. Report completion to the user

## Important Notes

- Always read spec.md carefully before starting investigation
- Use parallel tool calls when searching for multiple independent things
- Don't make assumptions - if the spec is unclear, ask for clarification
- The research.md is meant to inform implementation planning, so think about what would be helpful for someone about to write code
- If you discover something important that wasn't in the investigation points, include it anyway
