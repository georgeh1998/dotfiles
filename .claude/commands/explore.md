# Explore

Explore the codebase and save findings for planning.

Usage: `/explore [task-name]`

## Steps

1. Read `.claude/tasks/[task-name]/requirements.md` to understand requirements
2. Search for relevant files using Glob and Grep
3. Read existing implementations to understand patterns
4. Identify:
   - Files to modify
   - Files to create
   - Relevant patterns and conventions
   - Dependencies and related code
5. Write findings to `.claude/tasks/[task-name]/explore.md`

The exploration should include:
- **Requirements Summary**: Key points from requirements.md
- **Relevant Files**: List of files found and their purpose
- **Existing Patterns**: Code patterns to follow
- **Dependencies**: Related code and imports
- **Notes**: Any important observations

Example:
```
/explore add-expense-screen
```

This will:
- Read `.claude/tasks/add-expense-screen/requirements.md`
- Search the codebase for relevant files
- Document findings in `.claude/tasks/add-expense-screen/explore.md`
- Prepare information for the planning phase
