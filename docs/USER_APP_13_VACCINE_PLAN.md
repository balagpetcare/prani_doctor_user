# USER_APP_13 — Vaccine Module Plan

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_13_VACCINE`  
**Date:** 2026-05-22

## Scope

Vaccine schedule, reminders, and CRUD using `/api/mobile/vaccines/*`.

## Architecture

- `lib/features/vaccine/data/` — repository + `vaccine_reminder_service.dart` (local notification fallback)
- `lib/features/vaccine/presentation/` — schedule, reminders, form pages

## API

| Method | Path | Purpose |
|--------|------|---------|
| `GET/POST` | `/api/mobile/vaccines` | List/create |
| `GET/PATCH/DELETE` | `/api/mobile/vaccines/:id` | Detail/update/delete |
| `GET` | `/api/mobile/vaccines/reminders` | Overdue/upcoming |

## Routes

| Route | Screen |
|-------|--------|
| `/vaccines` | Schedule list |
| `/vaccines/reminders` | Reminders |
| `/vaccines/create` | Create form |
| `/vaccines/:id/edit` | Edit/delete form |

## Offline

- Cache: `vaccines_list_snapshot`, `vaccine_reminders_snapshot`, `vaccine_detail:{id}`, drafts
- Outbox: `vaccine_create`, `vaccine_patch`, `vaccine_delete`
