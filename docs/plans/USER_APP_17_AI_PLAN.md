# USER_APP_17 — AI Module Implementation Plan

**Date:** 2026-05-22  
**Phase:** 7 — AI (final)

## Current state

| Layer | Status |
|-------|--------|
| Backend `/api/ai/*` | ✅ chat, triage, memory, escalate |
| Backend `/api/voice/*` | ✅ stt, chat, navigation, session |
| Web BFF | ❌ No proxy (Flutter uses `API_BASE_URL` → backend) |
| Flutter `lib/features/ai/` | ❌ Missing (removed stubs) |
| Voice packages | ❌ None in pubspec |
| Offline keys | Partial (`voiceDraftKey`, no AI outbox) |

## Missing screens

1. **Ask AI** — chat UI with history, send, retry, disclaimer
2. **Voice Input** — tap-to-speak → text → fill chat input
3. **Triage** — symptom flow → structured card (no diagnosis wording)

## API mapping

| Flutter | Backend | Notes |
|---------|---------|-------|
| `POST /api/ai/chat` | ✅ | Returns `sessionId`, assistant reply |
| `GET /api/ai/history?sessionId=` | ➕ Add | List session messages |
| `POST /api/ai/triage` | ✅ | Risk bucket + recommendation |
| `POST /api/voice/stt` | ✅ | Normalize Bangla transcript |
| `GET /api/voice/session` | ✅ | Restore voice session |
| `DELETE /api/ai/memory` | ✅ | Clear conversation memory on clearHistory |

Auth: `authMobile` Bearer token (same as existing Dio interceptor).

## Risks

- No streaming endpoint yet — UI streaming-ready via async send + placeholder
- On-device STT quality for Bangla varies by device — fallback to `/api/voice/stt` normalize
- Foundation API error shape differs from legacy mobile — `ApiEnvelope` already handles `{ success, data }`

## Files to modify

- `pranidoctor-backend`: ai-veterinary-core (history route)
- `pranidoctor_user`: new `lib/features/ai/**`, routes, cache, outbox, sync, l10n, pubspec, home quick action

## Execution order

1. Backend `GET /api/ai/history`
2. Flutter data layer (DTOs, repository, speech service)
3. Presentation (chat, voice, triage widgets)
4. Offline (cache + outbox + sync)
5. Routes + home entry + l10n
6. Tests + report

## Architecture note

Follow **support/treatment pattern**: `data/` + `presentation/` only (no domain/usecases layer).
