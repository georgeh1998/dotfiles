# Review

Comprehensive PR review using multiple specialized subagents.

Usage: `/review <PR-URL>`

## Instructions for Claude

When this command is invoked:

1. Parse the PR URL to extract owner, repo, and PR number
2. Use Bash commands (to minimize tokens) to:
   - Get current branch: `git branch --show-current`
   - Checkout PR: `gh pr checkout <PR-number>`
   - Get changed files: `gh pr diff --name-only`
   - Get PR details: `gh pr view <PR-number> --json title,body,additions,deletions`
3. Launch 4 parallel Task subagents (in a single message) with subagent_type="general-purpose":
   - Code Quality Reviewer
   - Security Reviewer
   - Performance Reviewer
   - Testing Reviewer
4. Each agent should receive:
   - List of changed files
   - PR context (title, description)
   - Their specific review focus
5. Aggregate findings and create `.claude/reviews/<PR-number>/review.md`
6. Switch back to original branch: `git checkout <original-branch>`

## Overview

This command performs a multi-perspective review of a GitHub Pull Request:
1. Fetches PR information and checks out the branch
2. Spawns specialized review subagents for different perspectives
3. Aggregates findings into a comprehensive review report

## Review Perspectives

The following subagents review the PR in parallel:

- **Code Quality Agent**: Readability, maintainability, design patterns, best practices
- **Security Agent**: Vulnerabilities, authentication/authorization, input validation, secrets
- **Performance Agent**: Algorithm efficiency, memory usage, N+1 queries, optimizations
- **Testing Agent**: Test coverage, test quality, edge cases

## Steps

1. **Extract PR information from URL**:
   - Parse owner, repo, and PR number from URL
   - Use `gh pr view` to get PR details

2. **Checkout PR branch** (using Bash to minimize token usage):
   ```bash
   gh pr checkout <PR-number>
   ```

3. **Get changed files**:
   ```bash
   gh pr diff --name-only
   ```

4. **Spawn parallel review subagents**:
   - Launch 4 specialized agents using Task tool
   - Each agent reviews from their specific perspective
   - Agents run concurrently for efficiency

5. **Aggregate results**:
   - Collect findings from all agents
   - Create `.claude/reviews/<PR-number>/review.md`
   - Summarize critical issues and recommendations

## Output

Creates `.claude/reviews/<PR-number>/review.md` with:

```markdown
# PR Review: <PR-title>

## Summary
- PR: #<number>
- Branch: <branch-name>
- Files changed: <count>

## Critical Issues
[High-priority issues that must be addressed]

## Code Quality
[Findings from code quality agent]

## Security
[Findings from security agent]

## Performance
[Findings from performance agent]

## Testing
[Findings from testing agent]

## Recommendations
[Prioritized list of improvements]
```

## Example

```
/review https://github.com/owner/repo/pull/123
```

This will:
- Checkout PR #123
- Review from 4 different perspectives in parallel
- Generate comprehensive review report
- Save to `.claude/reviews/123/review.md`

## Notes

- Requires `gh` CLI to be authenticated
- Will switch branches locally (saves current branch first)
- Uses subagents to minimize main context token usage
- Agents run in parallel for faster review
