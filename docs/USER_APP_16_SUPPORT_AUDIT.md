# USER_APP_16 — Support Module Audit

**Project:** `pranidoctor_user` (+ backend + web BFF)  
**Date:** 2026-05-22  
**Status before work:** 🔴 Pending (no support feature)

## Existing Flutter

| Area | Finding |
|------|---------|
| `lib/features/support/` | **Missing** — greenfield |
| Routes | No `/support/*` in `app_routes.dart` |
| Upload pattern | `animal_repository.uploadPhoto` — Dio multipart + `onSendProgress` |
| File picking | `image_picker` only; **no `file_picker`** (needed for PDF/docs) |
| Offline | Mature outbox + `SyncCoordinator` + `LocalCacheService` (finance/treatment pattern) |
| Deep links | `NotificationDeepLink` routed `support\|complaint` → inbox (placeholder) |
| Config | `app-config` exposes `supportPhone` / `supportWhatsapp` via settings seed |

## Backend (before)

| Item | Status |
|------|--------|
| `SupportTicket` Prisma model | **Missing** |
| Mobile API `/api/mobile/support/*` | **Missing** |
| `Complaint` model | Admin-focused; no customer thread/attachments |
| `MobileUploadPurpose` | No `SUPPORT_ATTACHMENT` |
| Upload pipeline | `ingestMobileUpload` + customer profile image routes |

## Required API (spec)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `support/tickets` | Paginated list + filter/search |
| GET | `support/tickets/:id` | Detail + timeline + messages |
| POST | `support/tickets` | Create ticket |
| POST | `support/tickets/:id/reply` | Customer reply |
| POST | `support/upload` | Attachment upload |
| PATCH | `support/tickets/:id` | Close / reopen |
| GET | `support/help` | FAQ + contact + quick actions |

## Gaps identified

1. No ticket/message/attachment data model
2. No mobile support routes or web BFF proxies
3. No Flutter screens (Ticket list/detail/create, Help)
4. No attachment UX (preview, progress, retry, validation)
5. No offline cache for tickets/help or outbox for create/reply
6. No repository/provider tests

## Reference patterns reused

- **Backend:** `mobile-finance` service + Zod schemas + legacy routes
- **Web:** `proxyRouteToBackend` one-liner proxies
- **Flutter:** treatment/finance list `AsyncNotifier`, cache-first repository, feedback widgets
- **Offline:** `OutboxKind` + `SyncCoordinator` drain with upload-before-post for attachments

## Implementation plan

1. Prisma: `SupportTicket`, `SupportTicketMessage`, `SupportTicketAttachment`, `SUPPORT_ATTACHMENT`
2. Backend service + 7 mobile routes
3. Web BFF proxies under `src/app/api/mobile/support/**`
4. Flutter `lib/features/support/` (data + presentation)
5. Wire routes, cache keys, outbox kinds, sync, settings link, notification deep link
6. Tests + report
