# USER_APP_14 — Treatment Module Plan

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_14_TREATMENT`  
**Date:** 2026-05-22

## Scope

Farm treatment list, prescription viewer, and CRUD using `/api/mobile/treatments/*`.

## Architecture

- `lib/features/treatment/data/` — repository with medicines JSON
- `lib/features/treatment/presentation/` — list, detail (prescription + medicine cards), form

## API

| Method | Path | Purpose |
|--------|------|---------|
| `GET/POST` | `/api/mobile/treatments` | List/create |
| `GET/PATCH/DELETE` | `/api/mobile/treatments/:id` | Detail/update/delete |

## Routes

| Route | Screen |
|-------|--------|
| `/treatments` | List |
| `/treatments/create` | Create form |
| `/treatments/:id` | Detail + prescription |
| `/treatments/:id/edit` | Edit/delete form |

## Offline

- Cache: `treatments_list_snapshot`, `treatment_detail:{id}`, drafts
- Outbox: `treatment_create`, `treatment_patch`, `treatment_delete`
