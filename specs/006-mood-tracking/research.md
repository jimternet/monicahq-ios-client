# Research: Day and Mood Tracking API

**Feature**: 006-mood-tracking
**Date**: 2025-01-27
**Status**: Complete

## Research Questions

### Q1: What API endpoint serves day/mood entries?

**Finding**: Monica v4.x does NOT have a dedicated `/api/days` endpoint.

**Evidence**:
- Searched Monica GitHub repository routes/api.php - no `/days` route exists
- ApiJournalController only handles standard journal entries with `title` and `post` fields
- Day model implements `IsJournalableInterface` suggesting it's part of journal feed

**Decision**: Day entries are likely returned via `/api/journal` mixed with other journal items, distinguished by a `type` field in the response.

**Sources**:
- [Monica API routes](https://github.com/monicahq/monica/blob/4.x/routes/api.php)
- [Monica features changelog](https://www.monicahq.com/changelog)

---

### Q2: What is the Day model structure?

**Finding**: Day model in Monica v4.x has the following structure:

```php
class Day extends Model implements IsJournalableInterface
{
    protected $guarded = ['id'];
    protected $dates = ['date'];

    // Relationships
    public function account()

    // Methods
    public function getInfoForJournalEntry() returns:
    - type: 'day'
    - id
    - rate (mood rating)
    - comment (optional text)
    - date
    - day, day_name, month, month_name, year
    - happens_today (boolean)
}
```

**Decision**: Map to Swift struct with `id`, `rate`, `comment`, `date`, `createdAt`, `updatedAt`

**Source**: [Day.php model](https://github.com/monicahq/monica/blob/4.x/app/Models/Journal/Day.php)

---

### Q3: What are the mood rating values?

**Finding**: Based on Monica source code and web UI:
- Rate 1 = Bad day (😞)
- Rate 2 = Okay day (😐)
- Rate 3 = Great day (😊)

**Decision**: Use 3-point scale with emoji mapping. Include fallback for unexpected values.

**Source**: Monica web UI inspection and GitHub issues mentioning "great, ok or bad" ratings

---

### Q4: How does the web UI create day entries?

**Finding**: The web UI uses a Journal page with "Rate Your Day" functionality. Day entries appear in the same timeline as journal entries and activities.

**Decision**: Follow same pattern - unified journal feed with distinct visual styling for day entries.

**Source**: [Monica features page](https://www.monicahq.com/features)

---

### Q5: Is there offline support for day entries?

**Finding**: The spec mentions offline support (FR-017) but this conflicts with our backend-only architecture decision for this MVP.

**Decision**: Defer offline support to future enhancement. Follow pattern from 005-conversation-tracking which is also backend-only.

**Rationale**:
- Mood logging is less time-critical than call logging
- Reduces implementation complexity
- User can wait for connectivity to rate their day

---

## API Endpoint Strategy

### Option A: Dedicated `/api/days` endpoint (Preferred if exists)
```
GET    /api/days              - List all day entries
GET    /api/days/{id}         - Get single day entry
POST   /api/days              - Create day entry
PUT    /api/days/{id}         - Update day entry
DELETE /api/days/{id}         - Delete day entry
```

### Option B: Mixed journal endpoint (Fallback)
```
GET    /api/journal           - Returns mixed items with type field
POST   /api/journal           - May support day creation with type parameter
```

**Implementation Plan**:
1. First attempt Option A at runtime
2. If 404, fall back to Option B
3. Document actual endpoint in OpenAPI spec after discovery

---

## Unknowns Requiring Runtime Verification

1. **Exact endpoint path**: `/api/days` vs mixed `/api/journal`
2. **Create payload format**: Whether `type` field is required
3. **Date format in API**: ISO 8601 date vs datetime
4. **Account scoping**: Whether day entries automatically scoped to authenticated user

---

## References

- [Monica API Documentation](https://www.monicahq.com/api)
- [Monica GitHub Repository](https://github.com/monicahq/monica)
- [Monica Changelog](https://www.monicahq.com/changelog) - Day rating feature mentioned in 2017 updates
- [GitHub Issue #725](https://github.com/monicahq/monica/issues/725) - Add statistics about moods
