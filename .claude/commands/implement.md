# Implement

Execute the implementation based on the plan.

Usage: `/implement [task-name]`

## Steps

1. Read `.claude/tasks/[task-name]/plan.md`
2. Create TodoWrite with implementation steps from the plan
3. Execute each step:
   - Write clean, well-structured code
   - Follow project patterns (CLAUDE.md, docs/)
   - Update todos as you complete each step
4. Verify the implementation works correctly
5. Run tests if applicable
6. Create `summary.md` with implementation results

## Summary File

After completing the implementation, create `.claude/tasks/[task-name]/summary.md` with:

- **実装完了**: Brief description of what was implemented
- **変更内容**: List of modified/created files with before/after code snippets
- **期待される動作**: Expected behavior after changes
- **ビルド確認**: Build verification results (e.g., which variants were built successfully)
- **次のステップ**: Manual testing steps or next actions required
- **テスト方法**: Specific commands or procedures to test the implementation

Example:
```
/implement add-expense-screen
```

This will:
- Read `.claude/tasks/add-expense-screen/plan.md`
- Implement the features according to the plan
- Update todos to track progress
- Create `.claude/tasks/add-expense-screen/summary.md` with implementation results
