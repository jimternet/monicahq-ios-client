# Monica v4.x API Bug: Journal Entry Creation Missing Polymorphic Link

## The Problem

When creating journal entries via the REST API (`POST /api/journal`), the entries are created in the `entries` table but NOT linked in the `journal_entries` polymorphic table. This causes entries created via the API to not appear in the web journal view.

## Root Cause

In `/app/Http/Controllers/Api/ApiJournalController.php`, the `store()` method is missing the `JournalEntry::add($entry)` call that exists in the web controller.

**Current API code (line 57-73):**
```php
public function store(Request $request)
{
    $isvalid = $this->validateUpdate($request);
    if ($isvalid !== true) {
        return $isvalid;
    }

    try {
        $entry = Entry::create(
            $request->except(['account_id'])
            + ['account_id' => auth()->user()->account_id]
        );
    } catch (QueryException $e) {
        return $this->respondNotTheRightParameters();
    }

    return new JournalResource($entry);  // MISSING JournalEntry::add($entry) call!
}
```

**Web controller code (for comparison):**
```php
$entry->save();

$entry->date = $request->input('date');
// This line creates the polymorphic link - MISSING from API controller!
JournalEntry::add($entry);
```

## The Fix

Add the `JournalEntry::add()` call after creating the entry:

```php
public function store(Request $request)
{
    $isvalid = $this->validateUpdate($request);
    if ($isvalid !== true) {
        return $isvalid;
    }

    try {
        $entry = Entry::create(
            $request->except(['account_id'])
            + ['account_id' => auth()->user()->account_id]
        );
    } catch (QueryException $e) {
        return $this->respondNotTheRightParameters();
    }

    // ADD THIS: Create the polymorphic journal entry link
    $entry->date = now(\App\Helpers\DateHelper::getTimezone());
    \App\Models\Journal\JournalEntry::add($entry);

    return new JournalResource($entry);
}
```

## How to Apply This Fix to Your Synology Docker Instance

### Option 1: Direct Container Patch (Quick Fix)

1. Connect to the container:
```bash
sudo docker exec -it monica_app bash
```

2. Edit the file:
```bash
apt-get update && apt-get install -y nano
nano /var/www/html/app/Http/Controllers/Api/ApiJournalController.php
```

3. Find the `store()` method (around line 57) and add the two lines after `Entry::create()`:
```php
$entry->date = now(\App\Helpers\DateHelper::getTimezone());
\App\Models\Journal\JournalEntry::add($entry);
```

4. Save and exit (Ctrl+O, Enter, Ctrl+X)

5. Clear Laravel cache:
```bash
php artisan cache:clear
php artisan config:clear
php artisan route:clear
```

6. Restart the container:
```bash
exit
sudo docker restart monica_app
```

### Option 2: Volume Mount (Persistent Fix)

Create a custom file and mount it over the original:

1. Copy the patched file to your Synology:
```bash
sudo docker cp monica_app:/var/www/html/app/Http/Controllers/Api/ApiJournalController.php /volume1/docker/monica/patches/
```

2. Edit `/volume1/docker/monica/patches/ApiJournalController.php` with the fix

3. Add a volume mount in your `compose.yaml`:
```yaml
volumes:
  - /volume1/docker/monica/patches/ApiJournalController.php:/var/www/html/app/Http/Controllers/Api/ApiJournalController.php
```

4. Recreate the container:
```bash
sudo docker compose up -d
```

### Option 3: Fork and Build Custom Image (Best Long-Term)

1. Fork the Monica repository on GitHub
2. Apply the fix in your fork
3. Build a custom Docker image
4. Use your custom image in `compose.yaml`

## Fixing Orphaned Entries

After applying the fix, entries created via the API will work correctly. For existing orphaned entries, you can manually create the links:

```sql
-- Connect to your database
sudo docker exec -it monica_mariadb mariadb -u monica_user -p'YourSecureDBPassword456!' monica

-- Check for orphaned entries (entries without journal_entries links)
SELECT e.id, e.title, e.created_at
FROM entries e
LEFT JOIN journal_entries je ON je.journalable_id = e.id AND je.journalable_type = 'App\\Models\\Journal\\Entry'
WHERE je.id IS NULL;

-- Create missing links for orphaned entries (adjust IDs as needed)
INSERT INTO journal_entries (account_id, date, journalable_id, journalable_type, created_at, updated_at)
SELECT
    e.account_id,
    e.created_at,
    e.id,
    'App\\Models\\Journal\\Entry',
    NOW(),
    NOW()
FROM entries e
LEFT JOIN journal_entries je ON je.journalable_id = e.id AND je.journalable_type = 'App\\Models\\Journal\\Entry'
WHERE je.id IS NULL;
```

## Reporting This Bug

This is a confirmed bug in Monica v4.x. Consider reporting it:

1. Go to https://github.com/monicahq/monica/issues
2. Create a new issue with:
   - Title: "API: Journal entry creation doesn't create polymorphic journal_entries link"
   - Include the code comparison shown above
   - Mention it affects Monica v4.x REST API
   - Link to this file for the fix

## Files Involved

- `/app/Http/Controllers/Api/ApiJournalController.php` - The buggy API controller
- `/app/Http/Controllers/JournalController.php` - The working web controller (for reference)
- `/app/Models/Journal/JournalEntry.php` - The model with the `add()` method that creates the link
- `/app/Models/Journal/Entry.php` - The journal entry content model
