# USER_APP_16 — Support

**Project:** `pranidoctor_user`  
**Phase:** 6 — Communication  
**Status:** Complete

## Audit (pre-implementation)

| Area | State |
|------|--------|
| Ticket list/create/detail/reply | Done |
| Repository + cache + outbox | Done |
| Help page (FAQ + contact inline) | Done |
| Attachment upload + picker | Done |
| Search + status filters | Done |
| Routes `/support/tickets`, `/support/help` | Done |
| **Support home dashboard** | Missing |
| **Cache-first providers** | Missing — list/help/detail hit network in `build()` |
| **Dedicated FAQ / Contact screens** | Missing — embedded in help only |
| **Attachment viewer** | Missing — external URL only |
| **Draft recovery (create)** | Missing |
| **Summary counts (open/resolved/…)** | Missing |
| **SupportNavigation helper** | Missing |
| **App startup cache warm** | Missing |
| **Double-submit guard (global)** | Partial |

Backend supports list filters, search, create, reply, close/reopen, upload, help/FAQ.

## Plan

1. **Providers** — cache-first list/help/ticket; summary from cached list; draft save/load; `SupportNavigation`.
2. **Screens** — `/support` home; `/support/faq`; `/support/contact`; `/support/attachment` viewer.
3. **UX** — attachment tap → viewer; submission guard; startup cache warm.
4. **Tests + validation** — extend integration tests; analyze.

## API mapping

| Flutter | Method | Path |
|---------|--------|------|
| `listTickets` | GET | `/api/mobile/support/tickets` |
| `getTicket` | GET | `/api/mobile/support/tickets/:id` |
| `createTicket` | POST | `/api/mobile/support/tickets` |
| `reply` | POST | `/api/mobile/support/tickets/:id/reply` |
| `closeTicket` / `reopenTicket` | PATCH | `/api/mobile/support/tickets/:id` |
| `uploadAttachment` | POST | `/api/mobile/support/upload` |
| `getHelp` | GET | `/api/mobile/support/help` |

## State flow

```
AppStartup → warm tickets/help cache
supportTicketListProvider → cache → paint → silent refresh
supportHelpProvider → cache-first AsyncNotifier
supportTicketProvider(id) → detail cache → silent refresh
supportSummaryProvider → derived from list cache
supportCreateDraftProvider → local draft read/write
```

## Ticket flow

Create → validate → upload attachments → POST → list cache update → detail  
Reply → validate → upload → POST reply → invalidate detail + list  
Close/reopen → PATCH → optimistic cache

## Attachment flow

Pick file → validate → pending list → upload with progress → retry on error → fileIds on submit  
View → `/support/attachment?url=&name=&mime=` (image inline, PDF/doc external)

## Remaining blockers

- No dedicated ticket summary API (client-side counts from list)
- Export not implemented (export readiness = structured data only)
- Admin reply notifications depend on backend push (notification module)

**USER_APP_16_COMPLETE**
