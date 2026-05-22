# USER_APP_17 — AI Module Report

**Project:** Prani Doctor User App  
**Module:** AI (Phase 7 — final)  
**Date:** 2026-05-22  
**Status:** ✅ Complete

## Completed scope

| Screen | Status |
|--------|--------|
| Ask AI (chat) | ✅ |
| Voice Input | ✅ |
| AI Triage (symptom check card) | ✅ |

## API connected

| Flutter path | Backend | Auth |
|--------------|---------|------|
| `POST /api/ai/chat` | Foundation AI module | Bearer mobile JWT |
| `GET /api/ai/history?sessionId=` | ➕ Added for mobile history sync | Bearer |
| `POST /api/ai/triage` | Foundation AI module | Bearer |
| `DELETE /api/ai/memory` | Clear conversation memory | Bearer |
| `POST /api/voice/stt` | Voice normalize (Bangla-first) | Bearer |

**Note:** Flutter calls backend origin via `API_BASE_URL` (no web BFF proxy), consistent with `/api/area` and foundation modules.

## Architecture notes

- Pattern: `lib/features/ai/data/` + `presentation/` (matches support/treatment)
- `AiRepository` — cache-first history, outbox for offline messages
- `SpeechService` interface + `PlatformSpeechService` (`speech_to_text`) — provider swappable
- `AiChatNotifier` — Riverpod `AsyncNotifier` with idle/loading/success/error/empty/offline states
- Triage UI uses **Possible concern / Urgency / Recommended action** — no diagnosis language

## Offline

- Cache keys: `ai_active_session`, `ai_conversation:{sessionId}`, `ai_draft_input`
- Outbox: `OutboxKind.aiChatMessage` → sync on reconnect via `SyncCoordinator`
- `AiRepository.syncPending()` for explicit drain

## Created files

### Backend
- `src/modules/ai-veterinary-core/repository/ai-veterinary.repository.ts` (history helpers)
- `src/modules/ai-veterinary-core/ai-veterinary-core.types.ts` (history DTOs)
- `src/modules/ai-veterinary-core/ai-veterinary-core.service.ts` (`getHistory`)
- `src/modules/ai-veterinary-core/ai-veterinary-core.controller.ts` (`GET /history`)
- `src/modules/ai-veterinary-core/ai-veterinary-core.routes.ts`

### Flutter
- `lib/features/ai/data/*` (paths, dto, validation, repository, speech service)
- `lib/features/ai/presentation/*` (providers, chat page, voice page, widgets)
- `test/ai/ai_integration_test.dart`
- `docs/plans/USER_APP_17_AI_PLAN.md`

## Modified files

- `lib/core/offline/local_cache_contract.dart`
- `lib/features/offline/data/outbox_item.dart`
- `lib/features/offline/data/sync_coordinator.dart`
- `lib/features/offline/presentation/offline_queue_panel.dart`
- `lib/routing/app_routes.dart`, `app_router.dart`
- `lib/features/home/presentation/widgets/home_quick_actions.dart`
- `lib/l10n/app_en.arb`
- `pubspec.yaml` (`speech_to_text`)

## Pending / limitations

- **Streaming responses** — architecture ready (async send); backend is non-streaming rules provider
- **Raw audio upload STT** — client sends transcript to `/api/voice/stt` for Bangla normalize; no on-server audio decode
- **Web BFF proxies** for `/api/ai/*` — not added (mobile uses backend URL directly)
- **Push on escalation** — not wired
- **Case-linked chat (`caseId`)** — API supported; UI not exposed in v1

## Test summary

- `test/ai/ai_integration_test.dart` — DTO, validation, triage mapping, voice STT parse
- Run: `flutter test test/ai/`
- Run: `dart analyze lib/features/ai`

## Blockers

None for module completion. Requires backend running at `API_BASE_URL` with Phase 6/7 modules enabled and valid mobile auth token.
