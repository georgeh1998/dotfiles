# Workflow

Execute the complete workflow: explore → plan → implement.

Usage: `/workflow [task-name]`

## Steps

This command combines all three phases:

1. **Explore Phase** (`/explore [task-name]`):
   - Read `.claude/tasks/[task-name]/requirements.md`
   - Search for relevant files and patterns
   - Save findings to `.claude/tasks/[task-name]/explore.md`

2. **Plan Phase** (`/plan [task-name]`):
   - Read exploration results
   - Create detailed implementation plan
   - Save plan to `.claude/tasks/[task-name]/plan.md`

3. **Implement Phase** (`/implement [task-name]`):
   - Execute the plan
   - Track progress with todos
   - Create summary in `.claude/tasks/[task-name]/summary.md`

## Example

```
/workflow SampleScreen
```

This will:
- Complete exploration of the codebase
- Generate an implementation plan
- Execute the implementation
- Provide a summary of changes

## Prerequisites

Before running this command, ensure:
- `.claude/tasks/[task-name]/requirements.md` exists with clear requirements
- You have reviewed and approved the approach at each phase
