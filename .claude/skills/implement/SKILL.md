---
name: implement
description: Execute implementation tasks step-by-step from .claude/tasks/[task-name]/plan.md. Presents each task to the user for confirmation before executing, then records what was changed. Supports resuming from specific tasks. Trigger when the user types `/implement [task-name]` or `/implement [task-name] [number]` to start from a specific task. Use this skill to systematically work through implementation plans with human oversight at each step.
---

# Implement Skill

This skill executes implementation plans step-by-step with human confirmation at each stage.

## When to Use

Trigger this skill **ONLY** when:
- User types `/implement [task-name]` where `[task-name]` is an exact directory name under `.claude/tasks/`
- User types `/implement [task-name] [number]` to start from a specific task number
- Examples:
  - `/implement sample-feature` - start from beginning (or resume)
  - `/implement sample-feature 2` - start from task 2
  - `/implement sample-feature 3` - start from task 3

Do NOT trigger for:
- General implementation requests without the `/implement` command
- Direct "implement this feature" instructions (handle those normally)

## Workflow

### 1. Parse Input and Validate

Parse the command to extract task name and optional starting task number:

- `/implement sample-feature` → task_name="sample-feature", start_from=null
- `/implement sample-feature 2` → task_name="sample-feature", start_from=2

Check if the task directory exists and has plan.md:

```bash
TASK_NAME="[task-name from user input]"
START_FROM="[task number from user input, or null]"
TASK_DIR=".claude/tasks/${TASK_NAME}"

if [ ! -f "$TASK_DIR/plan.md" ]; then
  echo "Error: plan.md not found for task '$TASK_NAME'"
  echo "Run /plan ${TASK_NAME} first to create an implementation plan."
  exit 1
fi
```

### 2. Read and Parse the Plan

Read `plan.md` and identify all implementation tasks. Tasks are typically structured as:

```markdown
### 1. [Task Name]
Description

**変更するファイル:**
- file paths

**実装内容:**
- implementation details
```

Extract:
- Task number and name
- Files to be changed
- Implementation details
- Any special notes or warnings

### 3. Check for Existing Progress

Check if `implementation.md` already exists:

**If it exists and START_FROM is null:**
- Read the progress tracker section
- Determine the last completed task
- Ask the user: "Previous implementation found. Last completed: Task [N]. Resume from Task [N+1], or start over? (resume/restart/[task-number])"
- If user says "resume", continue from Task [N+1]
- If user says "restart", archive the old log and start fresh
- If user gives a number, start from that task

**If it exists and START_FROM is provided:**
- Start from the specified task number immediately (no confirmation needed)
- Update the log with "Resumed from Task [START_FROM]" timestamp

**If it doesn't exist:**
- Create a new implementation.md with initial structure

### 4. Initialize or Update Implementation Log

If creating new:

```markdown
# [Task Name] - Implementation Log

Started: [timestamp]

## Progress

[ ] Task 1: [Task Name]
[ ] Task 2: [Task Name]
[ ] Task 3: [Task Name]
...

---
```

If resuming, add a resume marker:

```markdown
Last updated: [timestamp]
Resumed from Task [N]: [timestamp]
```

### 5. Execute Tasks Sequentially

For each task in plan.md:

#### Step A: Present the Task

Show the user what you're about to do:

```
─────────────────────────────────────
Task [N]: [Task Name]
─────────────────────────────────────

[Brief summary of what this task does]

Files to modify:
• path/to/file1.ext
• path/to/file2.ext

Changes:
• [Key change 1]
• [Key change 2]

Ready to proceed? (yes/no)
```

Wait for user confirmation. If the user says no or wants modifications, discuss and adjust before proceeding.

#### Step B: Implement the Task

Once confirmed, execute the changes:
- Read the relevant files
- Make the specified modifications using Edit or Write tools
- Follow the implementation details from plan.md exactly
- If you encounter issues or ambiguities, stop and ask the user

#### Step C: Record the Changes

Update the progress tracker in `implementation.md`:

```markdown
## Progress

[✓] Task 1: [Task Name]
[✓] Task 2: [Task Name]
[ ] Task 3: [Task Name]
...
```

Then append the detailed entry:

```markdown
### Task [N]: [Task Name] ✓

Completed: [timestamp]

**Changes made:**
- Modified `path/to/file1.ext`: [brief description of what changed]
- Modified `path/to/file2.ext`: [brief description of what changed]

**Details:**
[Natural language explanation of what was done and why]

**Notes:**
[Any issues encountered, decisions made, or things to watch out for]

---
```

If a task fails or needs manual intervention, mark it accordingly:

```markdown
[!] Task 3: [Task Name] (needs manual fix)
```

And log the issue:

```markdown
### Task 3: [Task Name] [NEEDS ATTENTION]

Attempted: [timestamp]

**Issue:**
[Description of what went wrong or why it needs manual work]

**Suggested fix:**
[What the user should do to resolve it]

**To resume:**
After fixing manually, run `/implement [task-name] 4` to continue from the next task.

---
```

#### Step D: Confirm and Continue

Tell the user:
```
✓ Task [N] completed: [Task Name]

[Brief summary of changes]

Moving to Task [N+1]...
```

Then proceed to the next task.

### 6. Handle Completion

After all tasks are complete, update the progress tracker to show all tasks completed:

```markdown
## Progress

[✓] Task 1: [Task Name]
[✓] Task 2: [Task Name]
[✓] Task 3: [Task Name]
```

Then append a summary to `implementation.md`:

```markdown
## Summary

All tasks completed: [timestamp]

**Total changes:**
- [N] files modified
- [Brief overview of what was accomplished]

**Next steps:**
[Any recommendations from plan.md's "補足事項" section, like testing or documentation updates]
```

Then inform the user:

```
════════════════════════════════════════
Implementation Complete!
════════════════════════════════════════

✓ All [N] tasks completed
✓ Changes logged to .claude/tasks/[task-name]/implementation.md

Summary:
[High-level summary of what was done]

Recommended next steps:
[Testing, documentation, or follow-up items]
```

## Important Guidelines

### Be Methodical

- Always wait for user confirmation before starting each task
- Don't rush ahead or combine multiple tasks without asking
- If a task is ambiguous, clarify before implementing

### Record Everything

- The implementation log should be readable by a human who didn't watch you work
- Explain what changed and why, not just which files were touched
- Note any deviations from the plan

### Handle Issues Gracefully

If you encounter problems:
- **Missing files**: Ask the user if the plan needs updating
- **Unexpected code**: Stop and show the user what you found
- **Ambiguous instructions**: Request clarification before guessing
- **Errors during implementation**: Record them in the log with [NEEDS ATTENTION] marker and tell the user how to resume

When logging a failed task, provide clear guidance:
- What went wrong
- What needs to be fixed manually
- How to resume (e.g., "After fixing, run `/implement task-name 3`")

### Stay Focused

- Don't make changes beyond what the plan specifies
- Don't refactor or "improve" unrelated code
- Follow the plan's structure and order
- If you think the plan needs adjustment, discuss with the user first

## Example Interactions

### Example 1: Fresh start

User: `/implement sample-feature`

You:
1. Read `.claude/tasks/sample-feature/plan.md`
2. Find 3 tasks in the plan
3. No `implementation.md` exists, so create it with progress tracker
4. Present Task 1 for confirmation
5. User confirms
6. Execute Task 1 (e.g., modify `bin/nk` to add directory check)
7. Mark Task 1 as [✓] and record detailed changes
8. Present Task 2 for confirmation
9. Continue until all tasks complete
10. Show completion summary

### Example 2: Resume from previous session

User: `/implement sample-feature`

You:
1. Read `plan.md` and existing `implementation.md`
2. See that Task 1 and 2 are marked [✓], Task 3 is [ ]
3. Ask: "Previous implementation found. Last completed: Task 2. Resume from Task 3? (yes/no/[number])"
4. User says "yes"
5. Update log with resume timestamp
6. Present Task 3 for confirmation
7. Continue from there

### Example 3: Start from specific task

User: `/implement sample-feature 2`

You:
1. Read `plan.md` and existing `implementation.md` (if it exists)
2. Skip directly to Task 2 (no confirmation about resume point)
3. Update log: "Resumed from Task 2: [timestamp]"
4. Present Task 2 for confirmation
5. Continue from there

### Example 4: Handle failure and manual fix

During Task 3, something goes wrong:

You:
1. Attempt Task 3
2. Encounter an error (e.g., can't find the right code pattern)
3. Mark Task 3 as [!] in progress tracker
4. Log the issue with [NEEDS ATTENTION]
5. Tell user: "Task 3 needs manual attention. After fixing, run `/implement sample-feature 4` to continue."
6. Stop execution

Later, after user fixes manually:

User: `/implement sample-feature 4`

You:
1. Resume from Task 4
2. Continue normally

## Implementation Log Format

The `implementation.md` file serves as a permanent record and should be:

**Clear**: Someone reading it later should understand what was done
**Concise**: Don't copy entire file contents, just describe changes
**Structured**: Use consistent formatting for each task entry
**Helpful**: Include context that explains decisions or gotchas

Good entry example:
```markdown
### Task 2: ファイル名とメッセージの変更 ✓

Completed: 2026-03-18 14:32

**Changes made:**
- Modified `bin/nk`: Replaced all occurrences of `requirements.md` with `spec.md`

**Details:**
Updated 4 locations where the script referenced requirements.md:
- Line 21: heredoc output filename
- Line 41: echo message after file creation
- Line 44-50: editor command paths
- Line 51: fallback instruction message

This ensures the script now creates and references spec.md consistently throughout.

**Notes:**
No issues encountered. All references were straightforward string replacements.

---
```

## Additional Notes

- This skill works with plans generated by the `/plan` skill
- Plans should use the numbered task format (### 1, ### 2, etc.)
- The user can interrupt at any time to adjust course
- Implementation logs are saved in the task directory and persist across sessions
