# Today — Project Context

A daily task manager, tasks are scoped to the current day, and are cleared at the end of the day. Tasks can be added, removed, and marked as completed.

## Technical Requirements
- iOS 16 minimum deployment target
- Fully offline, no network requests, persist tasks locally
- Persistence: UserDefaults + Codable

## Security & Privacy
- Do not log private data, such as task titles or other user-generated data.
- No force unwraps on anything read from UserDefaults
- Conduct input validation in ViewModels

## Code Quality
- Maintain reliable, secure code.
- Keep the architecture simple and avoid unnecessary complexity.
- Code should stay clear, readable, and maintainable, without over-engineering or excessive abstraction.
- Avoid tightly coupled or tangled logic that makes changes difficult.
- Refactors should be intentional and only done when there is a clear benefit.


