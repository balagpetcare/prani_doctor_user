# USER_APP_17 — AI Assistant

**Project:** `pranidoctor_user`  
**Phase:** 7 — AI (Final)  
**Status:** Complete

## Audit (pre-implementation)

| Area | State |
|------|--------|
| Chat page + voice input | Done |
| Repository (chat/triage/history/STT/offline) | Done |
| Triage inline card | Done |
| Suggestion chips (l10n) | Done |
| Bangla speech locale | Done |
| **Ask AI home dashboard** | Missing |
| **Cache-first chat provider** | Missing |
| **Draft message persistence** | Partial (key exists, unused) |
| **AI settings screen** | Missing (locale in app bar only) |
| **History screen** | Missing |
| **Result view screen** | Missing (inline triage only) |
| **Escalate API** | Missing in Flutter |
| **Copy/share, regenerate** | Missing |
| **AiNavigation helper** | Missing |
| **App startup cache warm** | Missing |

Backend: `/api/ai/*` (ai-veterinary-core), `/api/voice/stt` (voice-assistant). No streaming.

## Plan

1. Cache-first `aiChatProvider`; draft + settings in local cache.
2. Screens: `/ai` home, `/ai/history`, `/ai/settings`, `/ai/result`.
3. Repository: escalate; settings/draft cache helpers.
4. Chat UX: copy long-press, regenerate last user turn, escalate → support.
5. `AiNavigation`; app startup warm.
6. Tests + validation.

## API mapping

| Flutter | Method | Path |
|---------|--------|------|
| `sendMessage` | POST | `/api/ai/chat` |
| `runTriage` | POST | `/api/ai/triage` |
| `getHistory` | GET | `/api/ai/history` |
| `escalate` | POST | `/api/ai/escalate` |
| `clearHistory` | DELETE | `/api/ai/memory` |
| `normalizeVoiceTranscript` | POST | `/api/voice/stt` |

**USER_APP_17_COMPLETE**
