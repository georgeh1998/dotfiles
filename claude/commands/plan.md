# Plan

Create a detailed implementation plan based on exploration results.

Usage: `/plan [task-name]`

## Steps

1. Read `.claude/tasks/[task-name]/explore.md`
2. Analyze the findings and requirements
3. Think through:
   - Architecture and design decisions
   - Files to create or modify
   - Implementation steps in order
   - Potential issues and edge cases
   - Testing strategy
4. Create a detailed plan
5. Write plan to `.claude/tasks/[task-name]/plan.md`

The plan should include:
- **Overview**: High-level approach
- **Files to Create**: New files with descriptions
- **Files to Modify**: Existing files to update
- **Implementation Steps**: Ordered list of tasks
- **Considerations**: Edge cases, testing, etc.

Example:
```
/plan add-expense-screen
```

This will:
- Read `.claude/tasks/add-expense-screen/explore.md`
- Create a detailed implementation plan
- Save plan to `.claude/tasks/add-expense-screen/plan.md`
- Prepare for the implementation phase
