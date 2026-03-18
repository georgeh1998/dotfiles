---
name: plan
description: Create an implementation plan based on research findings in .claude/tasks/[task-name]/research.md. Breaks down the work into ordered, actionable tasks ready for step-by-step implementation. Trigger ONLY when the user types `/plan [task-name]` with an exact task name argument. Do not trigger for general planning requests or project planning discussions unless the exact command format is used.
---

# Plan Skill

This skill helps you create a structured implementation plan based on codebase research findings.

## When to Use

Trigger this skill **ONLY** when:
- User types `/plan [task-name]` where `[task-name]` is an exact directory name under `.claude/tasks/`
- Example: `/plan sample-feature`, `/plan auth-refactor`, `/plan api-migration`

Do NOT trigger for:
- General planning requests ("plan the implementation", "how should we approach this?")
- Architecture discussions
- Planning without the specific `/plan` command format

## Workflow

### 1. Validate the Task

Check if the task directory exists and has both spec.md and research.md:

```bash
TASK_NAME="[task-name from user input]"
TASK_DIR=".claude/tasks/${TASK_NAME}"

# Verify required files exist
if [ ! -f "$TASK_DIR/spec.md" ]; then
  echo "Error: spec.md not found for task '$TASK_NAME'"
  exit 1
fi

if [ ! -f "$TASK_DIR/research.md" ]; then
  echo "Error: research.md not found. Run /explore first."
  exit 1
fi
```

If either file is missing, inform the user and stop.

### 2. Read and Understand Context

Read both files to understand the full context:

**From spec.md:**
- What the user wants to accomplish (やりたいこと)
- The goals and requirements

**From research.md:**
- Current codebase state (既存の実装)
- Investigation findings (調査結果)
- Implementation insights (実装への示唆)
- Relevant files and patterns

Understanding both the goal and the current state is crucial for creating a practical plan.

### 3. Break Down into Tasks

Decompose the work into discrete, actionable tasks. Each task should:

**Be self-contained:**
- Can be implemented independently (or with clear dependencies)
- Has a clear definition of "done"
- Focuses on one specific thing

**Be appropriately sized:**
- Not too big (avoid "refactor everything")
- Not too granular (avoid "add semicolon to line 42")
- Roughly 15-60 minutes of implementation work

**Follow logical order:**
- Dependencies come first (create a file before modifying it)
- Core functionality before polish
- Critical path before nice-to-haves

**Common task patterns:**
- Creating new files or components
- Modifying existing files
- Moving or refactoring code
- Adding tests
- Updating configuration
- Documentation updates

### 4. Consider Implementation Strategy

Think about:

**Dependencies between tasks:**
- What must be done before what?
- Can any tasks be done in parallel?
- Are there natural checkpoints?

**Risk and complexity:**
- Which tasks are straightforward vs. complex?
- Are there any high-risk changes?
- Should complex tasks be broken down further?

**Incremental progress:**
- Can the work be done in a way that keeps things working?
- Are there natural milestones where functionality can be tested?

### 5. Generate plan.md

Create `.claude/tasks/[task-name]/plan.md` with the implementation plan:

```markdown
# [Task Name] - Implementation Plan

## 目標
Brief restatement of what we're trying to accomplish (from spec.md).

## 前提
Key findings from research that inform this plan:
- Relevant files and their current state
- Patterns or conventions to follow
- Constraints or considerations

## 実装タスク

### 1. [Task Name]
Brief description of what this task involves and why it's first.

**変更するファイル:**
- `path/to/file1.ext` - what changes
- `path/to/file2.ext` - what changes

**実装内容:**
- Specific step or change 1
- Specific step or change 2
- Any important details or gotchas

### 2. [Task Name]
Description of the second task.

**変更するファイル:**
- `path/to/file.ext` - what changes

**実装内容:**
- What to do
- Important considerations

### 3. [Task Name]
...

## 補足事項
Any additional notes:
- Optional enhancements that can be done later
- Known limitations or trade-offs
- Things to watch out for during implementation
```

### 6. Writing Quality Standards

**Be specific and actionable:**
- Don't say "update the config" — say "add SOURCE_ALIASES=true to .zshrc line 10"
- Include actual file paths from the codebase
- Reference patterns from research.md

**Be realistic:**
- Don't assume things that weren't confirmed in research
- Note uncertainties or decisions that need to be made
- If research was incomplete, call it out

**Think about the implementer:**
- The AI (or human) implementing this will read each task in order
- Each task description should contain enough context to be actionable
- Don't make them re-read research.md constantly — surface key info in the task

**Explain the why, not just the what:**
- Why this order?
- Why this approach?
- Why is this task necessary?

This helps the implementer make good decisions if they encounter unexpected issues.

### 7. Confirm Completion

After generating plan.md, inform the user:
- Where the plan file was saved
- A brief summary (e.g., "Created a 5-step implementation plan")
- Suggest next steps (e.g., "You can now review the plan and start implementation task by task")

## Example

User input: `/plan sample-feature`

You would:
1. Read `.claude/tasks/sample-feature/spec.md` and `research.md`
2. Understand the goal and current codebase state
3. Break the work into logical, ordered tasks
4. Generate `.claude/tasks/sample-feature/plan.md` with detailed implementation steps
5. Report completion to the user

## Important Notes

- Always read both spec.md AND research.md before planning
- The plan should reflect what research actually found, not idealized assumptions
- Tasks should be ordered by dependency and logical flow
- Each task should be clear enough that it can be implemented without extensive back-and-forth
- If research.md suggests multiple approaches, either pick one (with rationale) or note the decision point in the plan
- The plan is meant to be followed sequentially, one task at a time, with human review between tasks
