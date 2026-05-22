# USER_APP_12 — Health Module Plan

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_12_HEALTH`  
**Date:** 2026-05-22

## Scope

Health history, timeline, and CRUD for animal health events using existing backend `/api/mobile/health/*`.

## Architecture

- `lib/features/health/data/` — paths, DTO, validation, repository (offline cache + outbox)
- `lib/features/health/presentation/` — providers with `HealthLoading/Loaded/Empty/Error`, pages, widgets
- Mirror `lib/features/feed/` and `lib/features/finance/` patterns

## API

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/mobile/health/history` | List with filters/pagination |
| `POST` | `/api/mobile/health/history` | Create |
| `GET` | `/api/mobile/health/history/:id` | Detail |
| `PATCH` | `/api/mobile/health/history/:id` | Update |
| `DELETE` | `/api/mobile/health/history/:id` | Delete |
| `GET` | `/api/mobile/health/timeline` | Date-grouped timeline |

## Routes

| Route | Screen |
|-------|--------|
| `/health/history` | History list |
| `/health/timeline` | Timeline view |
| `/health/create` | Create form |
| `/health/:id` | Detail |
| `/health/:id/edit` | Edit/delete form |

## Offline

- Cache: `health_history_list_snapshot`, `health_timeline_snapshot`, `health_detail:{id}`, drafts
- Outbox: `health_create`, `health_patch`, `health_delete`
