# Phase Appointment Workflow — Complete

**Repository:** `pranidoctor_user`  
**Completed:** 2026-05-22

## Summary

| Flow step | Mobile API | UI |
|-----------|------------|-----|
| Create lead | `POST /api/mobile/service-requests` | Book consultation (doctor flow) |
| Assign doctor | Admin-side; customer reads `assignedDoctor` | Appointment detail |
| Track | `GET /api/mobile/service-requests` | Inbox segments (Active / Completed / Closed / All) |
| History | `GET /api/mobile/service-requests/:id/timeline` | History screen |
| Status | `status` on request + timeline events | Status chip + detail timestamps |

## Files

- `lib/features/service_requests/data/` — `service_request_api_paths.dart`, `service_request_dto.dart`, `service_request_repository.dart`
- `lib/features/service_requests/presentation/` — `service_request_status_chip.dart`, `service_request_detail_page.dart`, `service_request_history_page.dart`
- Updated: `inbox_page.dart`, `book_consultation_page.dart`, `doctor_repository.dart`, routing, l10n

## Routes

- `/inbox` — appointment list with segment filters
- `/inbox/request/:id` — detail, status, assigned doctor, cancel
- `/inbox/request/:id/history` — timeline events

## Workflow

1. Customer books via Services → doctor → book → creates service request (`PENDING`).
2. Admin assigns doctor server-side → status `ASSIGNED`; customer sees assignee on detail.
3. Doctor accepts → `ACCEPTED`; treatment → `IN_PROGRESS`; complete → `COMPLETED`.
4. Customer tracks in Inbox; opens detail for status; views full history timeline.
5. Customer can cancel while `PENDING`, `ASSIGNED`, or `ACCEPTED`.

## Reuse

- Shared `dioProvider`, `ApiEnvelope`, `getJson` / `postJson`
- Doctor booking reuses `ServiceRequestRepository.createRequest`
- `AreaPicker` unchanged from profile/doctor phases

*Appointment workflow complete.*
