# USER_APP_16 — Support Module Report

**Project:** Prani Doctor User App  
**Module:** Support (Phase 6 — Communication)  
**Date:** 2026-05-22  
**Status:** ✅ Complete

## Audit summary

See [USER_APP_16_SUPPORT_AUDIT.md](./USER_APP_16_SUPPORT_AUDIT.md). Support was fully greenfield: no models, APIs, or Flutter feature existed.

## Implementation

### Backend (`pranidoctor-backend`)

- **Prisma:** `SupportTicket`, `SupportTicketMessage`, `SupportTicketAttachment` enums/models; `MobileUploadPurpose.SUPPORT_ATTACHMENT`
- **Migration:** `20260522190000_phase6_support_tickets`
- **Service:** `src/legacy/web/lib/mobile-support/` — schemas, mapper, service (list, detail, create, reply, patch, help)
- **Routes:** `src/legacy/web/routes/mobile/support/` — tickets, `[id]`, `[id]/reply`, upload, help
- **Upload:** `POST support/upload` uses `ingestMobileUpload` with document+image mimes (8 MB default)

### Web BFF (`pranidoctor-web`)

Proxies under `src/app/api/mobile/support/` mirroring backend paths.

### Flutter (`pranidoctor_user`)

```
lib/features/support/
├── data/
│   support_api_paths.dart
│   support_dto.dart
│   support_validation.dart
│   support_repository_contract.dart
│   support_repository.dart
│   support_attachment_service.dart
└── presentation/
    support_providers.dart
    support_ticket_list_page.dart
    support_ticket_detail_page.dart
    support_ticket_create_page.dart
    support_help_page.dart
    widgets/ (feedback, card, badge, attachment picker, messages/timeline)
```

**Screens**

| Screen | Features |
|--------|----------|
| Ticket list | Pagination, search, status filter, status badge, offline cache |
| Ticket detail | Timeline/conversation, reply, attachments, close/reopen |
| Create ticket | Category, subject, description, priority, attachments |
| Help | FAQ, contact (phone/WhatsApp/email), quick actions |

**Attachments:** image (gallery), PDF/doc via `file_picker`; preview, upload progress, retry, remove; 8 MB + mime validation.

**Offline:** Cache tickets + help; outbox `supportTicketCreate`, `supportTicketReply`, `supportTicketPatch`; sync uploads local files then POST/PATCH.

## API mapping

| Flutter `SupportApiPaths` | Backend route |
|---------------------------|---------------|
| `GET /api/mobile/support/tickets` | List with page/limit/status/category/search |
| `GET /api/mobile/support/tickets/:id` | Detail + messages + timeline |
| `POST /api/mobile/support/tickets` | Create |
| `POST /api/mobile/support/tickets/:id/reply` | Reply |
| `POST /api/mobile/support/upload` | Multipart `file` |
| `PATCH /api/mobile/support/tickets/:id` | `{ status: OPEN \| CLOSED }` |
| `GET /api/mobile/support/help` | FAQ + contact + quickActions |

## Changed / added files

### Backend
- `prisma/schema.prisma`
- `prisma/migrations/20260522190000_phase6_support_tickets/migration.sql`
- `src/legacy/web/lib/mobile-support/*`
- `src/legacy/web/routes/mobile/support/**`
- `src/legacy/web/lib/storage/upload-service.ts`

### Web
- `src/app/api/mobile/support/**`

### Flutter
- `lib/features/support/**`
- `lib/core/offline/local_cache_contract.dart`
- `lib/features/offline/data/outbox_item.dart`
- `lib/features/offline/data/sync_coordinator.dart`
- `lib/features/offline/presentation/offline_queue_panel.dart`
- `lib/features/notifications/notification_deeplink.dart`
- `lib/features/settings/settings_page.dart`
- `lib/routing/app_routes.dart`, `app_router.dart`
- `lib/l10n/app_en.arb`
- `pubspec.yaml` (`file_picker`)
- `test/support/support_integration_test.dart`
- `docs/USER_APP_16_SUPPORT_AUDIT.md`, `docs/USER_APP_16_SUPPORT_REPORT.md`

## Known limits

- FAQ content is static in backend service (not CMS-driven)
- Staff replies require admin/support tooling (customer app shows `SUPPORT` author type when added server-side)
- Attachment upload requires connectivity; local paths queued in outbox sync on reconnect
- No push notification when support team replies (future: notification type + deep link)

## Testing

- `test/support/support_integration_test.dart` — DTO parsing, validation, help data, attachment state
- Run: `flutter test test/support/`
- Run: `dart analyze lib/features/support`

## Follow-up

1. Admin panel to view/respond to customer tickets
2. Push notification on new support reply with `metadata.ticketId`
3. Optional: link Help FAQ to knowledge-hub tutorials API
4. E2E test against staging backend with real S3 upload
