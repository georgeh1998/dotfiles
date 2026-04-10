#!/bin/bash
# Workaround for https://github.com/anthropics/claude-code/issues/17321
# Bash commands in the allow list for filesystem writes (e.g. mkdir) still
# prompt for permission. This PreToolUse hook auto-approves safe write commands.

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$COMMAND" ] && exit 0

BASE=$(echo "$COMMAND" | sed 's/^\s*//' | awk '{print $1}')
case "$BASE" in
    mkdir|touch|ln|cp)
        jq -n '{
            hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "allow",
                permissionDecisionReason: "Safe write command auto-approved (issue #17321 workaround)"
            }
        }'
        ;;
esac
exit 0
