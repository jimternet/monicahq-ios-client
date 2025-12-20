# Task: Work and Career History

## Spec Reference
- **Spec Location**: `specs/013-work-occupation/`
- **Feature Branch**: `001-013-work-occupation` (to be created)
- **Status**: pending

## Description
Track employment and career information for contacts - company, job title, salary range, work history.

This feature enables users to:
- Record current employment (job title, company)
- Track full career history with multiple positions
- Manage company information with reuse across contacts
- Track employment dates and calculate tenure
- Optionally record sensitive career information (salary)

## Priority Stories
1. **P1**: Record Current Employment - Capture job title and company
2. **P1**: Track Full Career History - Record multiple positions across career
3. **P2**: Manage Company Information - Reuse companies across contacts
4. **P2**: Track Employment Dates and Tenure - Date tracking with duration calculation
5. **P3**: Manage Sensitive Career Information - Optional salary tracking

## Key Entities
- **Occupation/Position**: Employment record for a contact
- **Company**: Organization entity reusable across contacts
- **Work History**: Chronological collection of positions

## Action Required
1. Create feature branch: `git checkout -b feature/013-work-occupation`
2. Review spec at `specs/013-work-occupation/spec.md`
3. Create implementation plan
4. Implement according to spec requirements

## Notes
- Requires Monica backend API endpoints at `/api/occupations` and `/api/contacts/{contact}/work`
- Company API at `/api/companies`
- Salary information should be treated as private/sensitive
