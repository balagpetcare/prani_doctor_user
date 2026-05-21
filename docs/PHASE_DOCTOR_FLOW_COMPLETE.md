# Phase Doctor Discovery — Complete

**Repository:** `pranidoctor_user`  
**Completed:** 2026-05-22

## Summary

| Feature | API | UI |
|---------|-----|-----|
| Doctor list + filters | `GET /api/mobile/providers/doctors` | Services tab |
| Area filter (client-side label match) | Reuses `AreaPicker` + foundation `/api/area/*` | Services tab expansion |
| Doctor details | `GET /api/mobile/providers/doctors/:id` | `/services/doctor/:id` |
| Availability / emergency / online / home visit | Detail response fields | Detail chips + list icons |
| Book consultation | `POST /api/mobile/service-requests` | `/services/doctor/:id/book` |
| Service categories | `GET /api/mobile/service-categories` | Booking form |
| Animals | `GET /api/mobile/animals` | Booking form |

## Files

- `lib/features/doctors/data/` — `provider_api_paths.dart`, `provider_dto.dart`, `doctor_repository.dart`
- `lib/features/doctors/presentation/` — `doctor_detail_page.dart`, `book_consultation_page.dart`
- Updated: `services_page.dart`, `area_picker.dart` (`selectedLabel` in callback), routing, l10n

## Routes

- `/services` — doctor discovery list
- `/services/doctor/:id` — doctor profile
- `/services/doctor/:id/book` — book consultation (auth required)

## Reuse

- **Dio + session** — shared `dioProvider` with Bearer + refresh
- **AreaPicker** — same hierarchy picker from profile phase
- **ApiEnvelope / getJson** — same network layer
- **Tab shell** — Services branch; detail/book use root navigator for full-screen

## Notes

- Server `areaId`/`areaSlug` filters use admin `Area` model; foundation village picker applies a **client-side** filter on `areaText` until backend aligns area IDs.
- Booking stores preferred doctor in `description`; assignment is handled server-side on the service request.

*Doctor discovery phase complete.*
