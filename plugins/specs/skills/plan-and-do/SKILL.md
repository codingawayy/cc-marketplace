---
name: plan-and-do
description: Create, iterate, and update markdown-based plans. Use this skill when you need to plan multi-step work, track progress through tasks, and maintain a persistent record of completed work.
---

# Plan Management

Use markdown-based plans to manage multi-step tasks. Plans provide:

- **Persistence** - Progress survives session interruptions
- **Visibility** - Clear view of what's done and what remains
- **Adaptability** - Easy to update as you learn more
- **Accountability** - Changelog tracks all modifications

## Plan Structure

A plan has five sections:

```markdown
# Plan: [Brief Title]

Created: [timestamp]

## Objective

[What this plan aims to achieve and why]

## Approach

- [Phase 1 summary]
- [Phase 2 summary]
- [Phase 3 summary]

## Detailed Plan

### Phase 1: [Name]

- [ ] Action item 1
- [ ] Action item 2

### Phase 2: [Name]

- [ ] Action item 3
- [ ] Action item 4

## Notes

- [Important context or decisions]

## Changelog

- [timestamp] Initial plan created
```

## Section Guidelines

**Objective** - What the plan aims to achieve and why it matters. Provides context for all decisions.

**High Level Overview** - 2-6 bullet points summarizing the key phases. Gives a quick understanding without reading details.

**Detailed Plan** - Phases containing checkbox action items. Each phase should complete a logically distinct unit of work. Items should be specific but not overly granular.

**Notes** - Bullet point list of important context, decisions, or discoveries. Keep concise.

**Changelog** - Records all modifications to the plan with timestamps and reasons.

## Creating a Plan

1. Create the plan file FIRST, before doing any work
2. Save to a project directory (e.g., `.claude/plans/` or a task-specified location)
3. Use a descriptive filename that identifies the work
4. Fill in all sections, even if Notes is initially empty
5. Add the initial changelog entry

## Executing the Plan

Work through the plan systematically:

1. Re-read the plan file before starting work
2. For each unchecked item (`- [ ]`):
   - Perform the work described
   - Mark complete by changing `[ ]` to `[x]`
   - Save the plan file immediately
3. Continue until all items are complete

```markdown
- [x] Set up project structure
- [x] Create database schema
- [ ] Implement API endpoints  <-- current item
```

## Updating the Plan

As you work, you may discover the plan needs changes:

- **Add items** - Insert new checkboxes when you discover additional work
- **Remove items** - Delete items that are unnecessary
- **Modify items** - Update descriptions if scope changes
- **Add notes** - Document important discoveries

**Always update the Changelog** when modifying the plan:

```markdown
## Changelog

- [timestamp] Initial plan created
- [timestamp] Added migration scripts to Phase 1 - discovered dependency
- [timestamp] Removed caching layer - not needed for MVP
```

## Completing the Plan

When all items are checked:

1. Review that all work is actually complete
2. Add any final notes
3. Add completion entry to changelog:

```markdown
## Changelog

- ...
- [timestamp] Plan completed
```

## TodoWrite Integration

Use TodoWrite for real-time in-session visibility. However, the plan file is the persistent record - TodoWrite is supplementary, not primary. Always update the plan file.
