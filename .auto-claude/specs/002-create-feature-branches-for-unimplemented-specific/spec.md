# Quick Spec: Create Tasks for Unimplemented Specs

## Overview
This specification defines an automation task to scan the repository for specification documents that lack corresponding feature branches and generate task files for each unmapped spec. This ensures all planned work has proper tracking and branch management.

## Workflow Type
**simple** - Single-phase automation task focused on discovery and file generation.

## Task Scope
- **Discovery**: Scan `.auto-claude/specs/` directory for all specification directories
- **Branch Analysis**: List all feature branches in the repository
- **Gap Identification**: Cross-reference specs against branches to identify unmapped specs
- **Task Generation**: Create task files in `.auto-claude/tasks/` for each spec without a branch

## Success Criteria
- All specifications in `.auto-claude/specs/` have been scanned
- Task files created for every spec that lacks a corresponding feature branch
- No duplicate tasks created for specs with existing branches
- Each task file contains sufficient detail (spec reference, description, status, action)
- Current spec (002) is excluded from task generation

## Task
Scan repository specifications and create tasks for any specs that don't have corresponding feature branches.

## Files to Modify
- Create new task files in `.auto-claude/tasks/` directory (one per unmapped spec)

## Change Details
1. List all specification directories in `.auto-claude/specs/`
2. List all feature branches in the repository
3. Compare specs against branches to find specs without branches
4. For each unmapped spec, create a task file with:
   - Spec name and reference
   - Description from the spec
   - Status: pending
   - Action: create feature branch and implement

## Verification
- [ ] All specs in `.auto-claude/specs/` have been checked
- [ ] Task files created for specs without feature branches
- [ ] No duplicate tasks created for specs that already have branches
- [ ] Task files contain sufficient detail for implementation

## Expected Pattern
- Spec directories: `.auto-claude/specs/[number]-[name]/`
- Feature branches: `feature/[number]-[name]` or `feat/[name]`
- Task files: `.auto-claude/tasks/[spec-name].md`

## Notes
- Focus on specs that have `implementation_plan.json` but no active branch
- Skip the current spec (002) since we're working on it
