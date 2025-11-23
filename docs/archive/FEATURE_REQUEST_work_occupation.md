# Feature Request: Work & Occupation Information

## Overview
Track employment and career information for contacts - company, job title, salary range, work history.

## API Endpoints Available
From Monica v4.x `/routes/api.php`:
- `PUT /api/contacts/{contact}/work` - Update work information
- `GET /api/companies` - List companies
- `POST /api/companies` - Create company
- `PUT /api/companies/{id}` - Update company
- `DELETE /api/companies/{id}` - Delete company
- `GET /api/occupations` - List occupations
- `POST /api/occupations` - Create occupation
- `PUT /api/occupations/{id}` - Update occupation
- `DELETE /api/occupations/{id}` - Delete occupation

## Proposed Models

```swift
struct Company: Codable, Identifiable {
    let id: Int
    let name: String
    let website: String?
    let numberOfEmployees: Int?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case website
        case numberOfEmployees = "number_of_employees"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Occupation: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let companyId: Int?
    let title: String
    let description: String?
    let salary: Int?
    let salaryCurrency: String?
    let currentlyWorksHere: Bool
    let startDate: Date?
    let endDate: Date?
    let company: Company?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case companyId = "company_id"
        case title
        case description
        case salary
        case salaryCurrency = "salary_currency"
        case currentlyWorksHere = "currently_works_here"
        case startDate = "start_date"
        case endDate = "end_date"
        case company
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var formattedSalary: String? {
        guard let salary = salary, let currency = salaryCurrency else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: salary))
    }

    var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        var result = ""
        if let start = startDate {
            result = formatter.string(from: start)
        }
        result += " - "
        if currentlyWorksHere {
            result += "Present"
        } else if let end = endDate {
            result += formatter.string(from: end)
        }
        return result
    }
}

struct WorkUpdatePayload: Codable {
    let job: String?
    let company: String?

    enum CodingKeys: String, CodingKey {
        case job
        case company
    }
}

struct OccupationCreatePayload: Codable {
    let contactId: Int
    let companyId: Int?
    let title: String
    let description: String?
    let salary: Int?
    let salaryCurrency: String?
    let currentlyWorksHere: Bool
    let startDate: String?
    let endDate: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case companyId = "company_id"
        case title
        case description
        case salary
        case salaryCurrency = "salary_currency"
        case currentlyWorksHere = "currently_works_here"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}
```

## UI Components Needed

### 1. ContactWorkSection
- Show on contact detail page
- Current job and company prominently
- Work history timeline
- Add occupation button
- Quick update current job

### 2. CurrentJobCard
- Company name/logo
- Job title
- Duration at current position
- Tap to edit

### 3. AddEditOccupationView
- Job title field
- Company selector (or create new)
- Description/responsibilities
- Salary (optional, private)
- Start date picker
- End date picker (or "Currently working here")
- Save/Cancel buttons

### 4. WorkHistoryTimeline
- Chronological list of occupations
- Company names and titles
- Date ranges
- Current position highlighted
- Past positions with duration

### 5. CompanyPickerView
- Search existing companies
- Create new company option
- Company details (website, size)
- Recently used companies

## Implementation Priority
**MEDIUM** - Useful professional context but basic info already storable in contact fields

## Key Features
1. Current job and company
2. Work history timeline
3. Company database (reusable across contacts)
4. Optional salary tracking
5. Employment date ranges
6. Job descriptions/responsibilities

## Visual Design
- Current job card at top
- Timeline view for history
- Company logos (if available)
- Clear date ranges
- Professional icons (briefcase, building)
- Compact list for history

## Use Cases
- Remember what someone does for work
- Track career progression
- Know company connections
- Networking context
- Professional gift giving
- Conversation topics

## Advanced Features (Future)
- LinkedIn profile linking
- Company logo fetching
- Industry categorization
- Skills tracking
- Professional certifications
- Networking graph (who works where)

## Contact Integration
Currently, Contact model has:
- `job: String?`
- `company: String?`

These are basic fields. The Occupation model provides much richer data:
- Full work history
- Company as separate entity
- Date tracking
- Salary information

## Data Migration
```swift
// When adding occupations, migrate existing job/company
if let job = contact.job, !job.isEmpty {
    let occupation = OccupationCreatePayload(
        contactId: contact.id,
        companyId: nil,
        title: job,
        description: nil,
        salary: nil,
        salaryCurrency: nil,
        currentlyWorksHere: true,
        startDate: nil,
        endDate: nil
    )
    // Create occupation from basic job info
}
```

## Related Files
- Contact.swift - Already has `job` and `company` fields
- MonicaAPIClient.swift - Add occupation/company CRUD methods
- ContactDetailView.swift - Add work section
- New models for Company, Occupation

## Notes
- Salary is sensitive - mark as private
- Company reuse across contacts is valuable
- Consider importing from LinkedIn
- Keep simple job/company fields for quick view
- Full history in expanded section
