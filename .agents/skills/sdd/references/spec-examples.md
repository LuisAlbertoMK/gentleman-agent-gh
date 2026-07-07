# Spec Examples

## NEW Spec
```markdown
## Purpose
Allow users to update their profile display name.

## Requirements
- MUST validate display name is 3-50 chars
- MUST return 400 on invalid input
- MUST persist change to database
- SHOULD sanitize profanity (optional)
- MAY allow empty name (revert to username)

## Scenarios
### GIVEN a valid display name WHEN PUT /profile/name THEN 200 + DB updated
### GIVEN empty name WHEN PUT /profile/name THEN 400 + "name required"
### GIVEN name >50 chars WHEN PUT /profile/name THEN 400 + "too long"
```

## MODIFIED (delta)
```markdown
## MODIFIED | Validate display name
### Requirement | MUST validate 3-50 chars | (Previously: must not be empty)
### GIVEN a valid display name WHEN PUT /profile/name THEN 200
### GIVEN name <3 chars WHEN PUT /profile/name THEN 400 + "too short"
### GIVEN name >50 chars WHEN PUT /profile/name THEN 400 + "too long"
```
