# USER_APP_17 — AI Module Report

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_17_AI`  
**Date:** 2026-05-22  
**Status:** Complete

## 1. Current audit

| Area | Pre-work |
|------|----------|
| Chat + voice pages | Done |
| Repository (chat/triage/history/STT/offline) | Done |
| Triage card, suggestions, disclaimer | Done |
| Bangla speech (`bn_BD`) | Done |
| **AI home dashboard** | Missing |
| **Cache-first chat load** | Missing |
| **Draft persistence** | Missing |
| **Settings / history / result screens** | Missing |
| **Escalate API** | Missing |
| **Copy/regenerate** | Missing |

## 2. Plan

See `docs/user_app/USER_APP_17_AI.md`.

## 3. Implementation

- `/ai` home dashboard
- Cache-first chat provider + settings provider
- Draft message save/restore
- `/ai/history`, `/ai/settings`, `/ai/result` screens
- Escalate API + support ticket CTA
- Copy on long-press, regenerate, duplicate-submit guard
- `AiNavigation`, app startup cache warm

## 4. Changed files

**New:** `ai_home_page.dart`, `ai_history_page.dart`, `ai_settings_page.dart`, `ai_result_page.dart`, `ai_navigation.dart`, plan + report

**Updated:** `ai_providers.dart`, `ai_repository*.dart`, `ai_dto.dart`, `ai_chat_page.dart`, `ai_message_bubble.dart`, `triage_card.dart`, routes, l10n, app_startup, home quick actions, tests

## 5. API mapping

| Method | Path | Use |
|--------|------|-----|
| POST | `/api/ai/chat` | Send message |
| POST | `/api/ai/triage` | Symptom check |
| GET | `/api/ai/history` | Conversation |
| POST | `/api/ai/escalate` | Human handoff |
| DELETE | `/api/ai/memory` | Clear history |
| POST | `/api/voice/stt` | Normalize transcript |

## 6. Validation

```
flutter test test/ai/  → 8/8 passed
dart analyze lib/features/ai  → 0 errors
```

## 7. Remaining blockers

- No streaming responses (full response wait)
- Voice STT falls back to raw transcript if API fails
- Settings stored locally (memory API not synced for preferences)
- Single active session in history API (no multi-session list)

## 8. Manual QA checklist

- [ ] `/ai` → chat, voice, history links
- [ ] Send message → assistant reply; offline queue
- [ ] Draft survives leaving chat
- [ ] Bangla voice input → normalized text → chat
- [ ] Triage → result page → support ticket
- [ ] Settings locale/suggestions persist
- [ ] Long-press copy; regenerate last turn
- [ ] Clear history starts fresh session

**USER_APP_17_COMPLETE**
