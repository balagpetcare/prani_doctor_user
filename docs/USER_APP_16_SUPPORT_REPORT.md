# USER_APP_16 — Support Module Report

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_16_SUPPORT`  
**Date:** 2026-05-22  
**Status:** Complete

## 1. Current audit

| Area | Pre-work |
|------|----------|
| Ticket list/create/detail/reply | Done |
| Repository + cache + outbox sync | Done |
| Help page (FAQ + contact inline) | Done |
| Attachment upload/picker | Done |
| Search + status filters | Done |
| **Support home dashboard** | Missing |
| **Cache-first providers** | Missing |
| **Dedicated FAQ / Contact / Attachment viewer** | Missing |
| **Draft recovery** | Missing |
| **Summary counts** | Missing |
| **SupportNavigation** | Missing |

## 2. Plan

See `docs/user_app/USER_APP_16_SUPPORT.md`.

## 3. Implementation

- Support home at `/support` with summary + recent tickets + quick actions
- Cache-first list, help, and ticket detail providers
- FAQ page (`/support/faq`) with search
- Contact page (`/support/contact`)
- Attachment viewer (`/support/attachment?url=&name=&mime=`)
- Create-ticket draft persistence + recovery
- `SupportNavigation` with notification badge invalidation
- Double-submit guard via `supportSubmissionProvider`
- App startup cache warm for tickets/help

## 4. Changed files

**New:** `support_home_page.dart`, `support_faq_page.dart`, `support_contact_page.dart`, `support_attachment_viewer_page.dart`, `support_navigation.dart`, `support_summary_section.dart`, plan doc

**Updated:** `support_providers.dart`, `support_repository*.dart`, create/detail/help pages, `support_message_bubble.dart`, routes, l10n, app_startup, home/settings links, notification deeplink, tests

## 5. API mapping

| Method | Path | Use |
|--------|------|-----|
| GET | `/api/mobile/support/tickets` | List (page, search, filters) |
| GET | `/api/mobile/support/tickets/:id` | Detail + messages |
| POST | `/api/mobile/support/tickets` | Create |
| POST | `/api/mobile/support/tickets/:id/reply` | Reply |
| PATCH | `/api/mobile/support/tickets/:id` | Close/reopen |
| POST | `/api/mobile/support/upload` | Attachment upload |
| GET | `/api/mobile/support/help` | FAQ + contact + quick actions |

## 6. Validation

```
flutter test test/support/  → 10/10 passed
dart analyze lib/features/support  → 0 errors
```

## 7. Remaining blockers

- Summary counts derived from loaded/cached list (no dedicated stats API)
- Ticket export not implemented
- Push on support reply depends on backend notification dispatch

## 8. Manual QA checklist

- [ ] `/support` — summary chips, recent tickets, pull refresh
- [ ] Create ticket — draft survives app restart; attachments upload; submit once
- [ ] Ticket detail — conversation, reply, close/reopen
- [ ] Attachment tap — image viewer / external open for PDF
- [ ] FAQ search; contact phone/WhatsApp/email
- [ ] Offline — cached list/help; pending sync badges
- [ ] Notification deep link → ticket detail

**USER_APP_16_COMPLETE**
