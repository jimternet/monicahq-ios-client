# Feature Request: Pets Management

## Overview
Track pets for contacts - their names, types, and important information. Remember someone's beloved dog or cat.

## API Endpoints Available
From Monica v4.x `/routes/api.php`:
- `GET /api/pets` - List all pets
- `GET /api/pets/{id}` - Get single pet
- `POST /api/pets` - Create pet
- `PUT /api/pets/{id}` - Update pet
- `DELETE /api/pets/{id}` - Delete pet
- `GET /api/contacts/{contact}/pets` - Get pets for specific contact

## Proposed Models

```swift
struct Pet: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let petCategoryId: Int?
    let name: String?
    let petCategory: PetCategory?
    let contact: Contact?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case petCategoryId = "pet_category_id"
        case name
        case petCategory = "pet_category"
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        return petCategory?.name ?? "Pet"
    }

    var icon: String {
        guard let category = petCategory?.name.lowercased() else { return "pawprint" }
        switch category {
        case "dog": return "dog"
        case "cat": return "cat"
        case "bird": return "bird"
        case "fish": return "fish"
        case "rabbit": return "rabbit"
        case "hamster": return "hare"
        default: return "pawprint"
        }
    }
}

struct PetCategory: Codable, Identifiable {
    let id: Int
    let name: String // "Dog", "Cat", "Bird", "Fish", etc.
    let isComon: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isComon = "is_common"
    }
}

struct PetCreatePayload: Codable {
    let contactId: Int
    let petCategoryId: Int
    let name: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case petCategoryId = "pet_category_id"
        case name
    }
}
```

## UI Components Needed

### 1. ContactPetsSection
- Show on contact detail page
- List of pets with icons and names
- Add pet button
- Edit/delete actions
- Pet type icons

### 2. AddPetView
- Pet type selector (Dog, Cat, Bird, etc.)
- Name field (optional)
- Save button
- Cancel option

### 3. PetListItem
- Pet type icon
- Pet name (or just type if no name)
- Swipe to delete
- Tap to edit

### 4. EditPetView
- Change name
- Change type
- Delete option

## Implementation Priority
**LOW** - Nice personal touch but not critical for relationship management

## Key Features
1. Track pet type (Dog, Cat, Bird, etc.)
2. Optional pet names
3. Multiple pets per contact
4. Pet type icons
5. Quick add/remove

## Pet Categories (from Monica)
- Dog
- Cat
- Bird
- Fish
- Small pet (hamster, gerbil, etc.)
- Rabbit
- Reptile
- Horse
- Other

## Visual Design
- Cute pet type icons
- Simple list layout
- Quick edit inline
- Compact display in contact info
- Optional: pet photo support

## Use Cases
- Remember pet names for conversation
- Know someone has allergies (no pets)
- Gift ideas (pet-related gifts)
- Conversation starters ("How's Max doing?")
- Understand lifestyle (outdoor person with dog)

## UI Mockup
```
Pets
├─ 🐕 Max (Dog)
├─ 🐈 Whiskers (Cat)
└─ ➕ Add Pet
```

## Integration Points
- Show in contact summary
- Gift suggestions related to pets
- Conversation topic suggestions
- Quick facts about contact

## Related Files
- MonicaAPIClient.swift - Add pet CRUD methods
- ContactDetailView.swift - Add pets section
- New models for Pet, PetCategory
- Cache pet categories locally

## Notes
- Simple feature with good personal value
- Cache pet categories (rarely change)
- Consider pet birthday tracking
- Potential for pet photos
- Low complexity, high empathy value
