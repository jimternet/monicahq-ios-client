# Migration Strategy: FEATURE_REQUEST to SpecKit Format

## Overview

You have 13 FEATURE_REQUEST documents in [docs/](../docs/) that need to be converted to SpecKit format. The SpecKit workflow provides structured feature specification, planning, and task management.

## SpecKit Workflow

The SpecKit system uses this sequence:

1. **`/speckit.specify`** - Create/update feature specification (generates `spec.md`)
2. **`/speckit.clarify`** - Identify underspecified areas and ask clarifying questions
3. **`/speckit.plan`** - Generate implementation plan (generates `plan.md`)
4. **`/speckit.tasks`** - Generate actionable task list (generates `tasks.md`)
5. **`/speckit.implement`** - Execute the implementation
6. **`/speckit.analyze`** - Quality and consistency analysis

## Current FEATURE_REQUEST Documents

Located in `docs/`:

1. FEATURE_REQUEST_avatar_images.md
2. FEATURE_REQUEST_day_mood_entries.md
3. FEATURE_REQUEST_reminders.md
4. FEATURE_REQUEST_debts.md
5. FEATURE_REQUEST_relationships.md
6. FEATURE_REQUEST_calls.md
7. FEATURE_REQUEST_conversations.md
8. FEATURE_REQUEST_life_events.md
9. FEATURE_REQUEST_photos.md
10. FEATURE_REQUEST_documents.md
11. FEATURE_REQUEST_pets.md
12. FEATURE_REQUEST_addresses.md
13. FEATURE_REQUEST_work_occupation.md

## Recommended Migration Approach

### Option 1: One-by-One Conversion (Recommended)

Process each feature systematically:

```bash
# For each feature, run:
/speckit.specify <paste feature description from FEATURE_REQUEST doc>
/speckit.clarify  # Answer any clarification questions
/speckit.plan     # Generate implementation plan
/speckit.tasks    # Generate task list
```

**Advantages:**
- Claude can ask clarifying questions for each feature
- Results in high-quality, well-structured specs
- Ensures each feature gets proper attention

**Time Estimate:** ~5-10 minutes per feature = ~1-2 hours total

### Option 2: Manual Conversion

Create spec directories manually by adapting the existing FEATURE_REQUEST content:

```bash
# For each feature:
mkdir -p specs/002-avatar-images
cp docs/FEATURE_REQUEST_avatar_images.md specs/002-avatar-images/spec.md
# Edit spec.md to follow SpecKit template format
```

Then use `/speckit.plan` and `/speckit.tasks` to generate the remaining artifacts.

**Advantages:**
- Faster initial conversion
- Still generates plans and tasks automatically

### Option 3: Prioritize Features

Focus on the most important features first:

**High Priority** (implement first):
- reminders (already partially implemented)
- avatar_images (critical UX issue)
- relationships (core Monica feature)
- calls & conversations (core interaction tracking)

**Medium Priority:**
- day_mood_entries
- life_events
- photos & documents

**Lower Priority:**
- debts
- pets
- addresses
- work_occupation

## Naming Convention

SpecKit specs should follow this pattern:
```
specs/###-feature-name/
├── spec.md
├── plan.md
└── tasks.md
```

Suggested mapping:

| FEATURE_REQUEST | Spec Directory |
|----------------|---------------|
| avatar_images | 002-avatar-images |
| reminders | 003-reminders-enhancement |
| relationships | 004-relationships |
| calls | 005-call-tracking |
| conversations | 006-conversations |
| day_mood_entries | 007-mood-tracking |
| life_events | 008-life-events |
| photos | 009-photo-gallery |
| documents | 010-document-management |
| debts | 011-debt-tracking |
| pets | 012-pet-profiles |
| addresses | 013-address-management |
| work_occupation | 014-work-occupation |

## Step-by-Step Example

Let's convert `FEATURE_REQUEST_avatar_images.md`:

### 1. Initiate Specification

```bash
/speckit.specify

Contact avatar images are not loading in the iOS app due to authentication issues with the Monica server's static file serving. The server uses session-based authentication for files in the `/store/` directory, but the iOS app uses Bearer token authentication.

**Current Behavior:**
- App shows fallback initials instead of actual contact photos
- AuthenticatedImageLoader sends Bearer token but gets HTTP 302 redirects
- Custom uploaded photos don't display

**Desired Behavior:**
- Contact avatar images load successfully
- Support for both Gravatar and custom uploaded photos
- Fallback to initials only when no photo exists

**Solution Options:**
1. Server-side: Configure nginx to accept Bearer tokens for `/store/`
2. API proxy: Create `/api/storage/photos/{filename}` endpoint
3. Client workaround: Session cookie handling in iOS app

**Priority:** Medium-High (affects user experience)
```

### 2. Answer Clarifications

Claude will ask questions like:
- "Which solution approach do you prefer?"
- "Are there any server configuration constraints?"
- "Should we implement fallback strategies?"

Answer these to refine the spec.

### 3. Generate Plan

```bash
/speckit.plan
```

This creates the implementation plan with design decisions and architecture.

### 4. Generate Tasks

```bash
/speckit.tasks
```

This creates a dependency-ordered task list ready for implementation.

### 5. Implement

```bash
/speckit.implement
```

Claude executes all tasks in the task list.

## After Migration

1. Archive original FEATURE_REQUEST documents:
   ```bash
   mkdir docs/archive
   mv docs/FEATURE_REQUEST_*.md docs/archive/
   ```

2. Update project documentation to reference new specs:
   ```bash
   # Update README.md to link to specs/ directory
   ```

3. Use SpecKit workflow for all new features going forward

## Benefits of SpecKit Format

- **Consistency:** Standard structure across all features
- **Clarity:** Separates specification from implementation planning
- **Task Management:** Automatic task generation with dependencies
- **Quality:** Built-in analysis tools to catch inconsistencies
- **Documentation:** Auto-generates comprehensive feature docs

## Getting Help

- Read SpecKit templates in `.claude/templates/`
- View SpecKit command definitions in `.claude/commands/speckit.*.md`
- Look at existing spec in `specs/001-monica-ios-mvp/` as example

## Next Steps

1. Choose which approach to use (Option 1 recommended)
2. Select first feature to convert (suggest: avatar_images or reminders)
3. Run `/speckit.specify` with feature description
4. Work through the workflow for that feature
5. Repeat for remaining features
