---
name: spec-writer
description: Guide users through interactive requirements gathering and generate standardized spec.md files for the /explore command. Use this skill whe users say "/spec-write".
---

# Spec Writer

A skill for guiding users through structured requirements gathering and generating spec.md files in the standard format used by the `/explore` command.

## When to Use This Skill

Trigger this skill when users:
- Type `/spec-write` command

## Workflow

### Step 1: Understand the Context

First, gather context about whether this is a new or existing project:

1. **Check for existing project information**: Read `CLAUDE.md` or other documentation files to understand:
   - Project type (CLI tool, web app, mobile app, etc.)
   - Technology stack
   - Existing architecture and patterns
   - Project constraints

2. **For new projects**: Ask about the project type and core technology choices, as these will be included in the Technical Context section.

### Step 2: Gather Requirements Through Conversation

Use a use-case and scenario-based approach to elicit requirements. Start by understanding what the user wants to accomplish, then drill down into specifics.

**Effective questioning pattern**:

1. **Start with the big picture**:
   - "What problem are you trying to solve?"
   - "Who will use this feature/project?"
   - "What's the main workflow or user journey?"

2. **Get a feature list**:
   - "What are the key features or capabilities you need?"
   - List them out for confirmation

3. **Drill into each feature**:
   - "Walk me through how a user would [do X]"
   - "What should happen when [scenario Y]?"
   - "What edge cases or error conditions should we handle?"

4. **Clarify success criteria**:
   - "How will you know this is working correctly?"
   - "What behavior are you expecting?"
   - **Adapt testing strategy to the task type**:
     - For CLI tools or libraries: suggest unit tests for specific functions/outputs
     - For UI/frontend work: suggest behavior-based validation ("user can do X", "page displays Y")
     - For APIs: suggest endpoint testing and response validation
     - For mobile apps or complex UIs: focus on user-visible behavior and workflows

5. **Define boundaries**:
   - "What's explicitly NOT in scope for this task?"
   - "Are there any features we should save for later?"

Throughout the conversation, confirm understanding by summarizing what you've heard.

### Step 3: Generate the spec.md

Create a spec.md file with the following structure:

```markdown
# Overview

[1-2 sentence summary of what this task accomplishes and why it matters]

# Functional Requirements

[Bulleted list of specific capabilities and features, organized by category if appropriate]

- Feature/capability 1
- Feature/capability 2
- ...

# Success Criteria

## Expected Behavior

[Describe what success looks like - what should happen when this is working correctly]

## Testing Strategy

[Describe how to verify the implementation works. Adapt to the task type:
- For testable code (CLI, libraries): specific test cases and assertions
- For UI work: user workflows and expected visual/behavioral outcomes
- For APIs: endpoint behavior and response validation
- For mobile/complex UIs: user-facing capabilities and workflows]

# Technical Context

[Relevant technical background, constraints, dependencies, or architectural considerations. For new projects, include project type and core technology choices.]

# Out of Scope

[Explicitly list what is NOT included in this task to prevent scope creep]
```

**Guidelines for spec.md content**:

- **Overview**: Be concise but clear about the purpose and value
- **Functional Requirements**: Be specific and actionable, not vague
- **Expected Behavior**: Focus on observable outcomes
- **Testing Strategy**: Match the testing approach to what's practical for the task type:
  - Don't force unit tests onto UI-heavy work
  - Don't force manual testing onto algorithmic code
  - Consider the trade-offs: testability vs. implementation speed vs. task complexity
- **Technical Context**: Include technology stack for new projects; for existing projects, note relevant patterns, libraries, or architectural decisions
- **Out of Scope**: Be explicit to manage expectations

### Step 4: Save and Confirm

The spec.md should be saved to `.claude/tasks/[task-name]/spec.md`.

After generating the spec, present it to the user for review and ask:
- "Does this capture what you need?"
- "Should we adjust any requirements or success criteria?"
- "Is anything missing or unclear?"

Iterate based on feedback until the user is satisfied.

## Tips for Effective Requirements Gathering

- **Ask open-ended questions** to let users explain in their own words
- **Reflect back** what you hear to confirm understanding
- **Look for gaps** - if something seems underspecified, probe deeper
- **Be pragmatic about testing** - match the testing strategy to the task's nature
- **Keep it focused** - help users resist scope creep by clearly defining what's out of scope
- **Think about the future reader** - the spec should make sense to someone (or an AI agent) who wasn't part of this conversation

## Example Interaction Pattern

User: "I want to add a feature to export data"

You: "Great! Let me understand the use case. What kind of data needs to be exported, and who will be using this export feature?"

User: "Users should be able to export their task list to a CSV file"

You: "Got it. Walk me through the workflow - where would a user trigger this export? What columns should the CSV include?"

[Continue drilling down until you have enough detail to write a complete spec]
