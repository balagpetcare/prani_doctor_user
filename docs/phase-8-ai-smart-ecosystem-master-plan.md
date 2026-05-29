# Phase 8 — AI & Smart Ecosystem Master Plan

**Document version:** 1.0.0  
**Date:** 2026-05-29  
**Status:** Planning only — **no implementation in this phase**  
**Prerequisites:** [phase-7-preparation.md](./phase-7-preparation.md) (production launch readiness), [phase-6-devops-security-master-plan.md](./phase-6-devops-security-master-plan.md)  
**Authority:** AI safety principles in `pranidoctor-web/docs/PHASE6_AI.md` and `pranidoctor-web/docs/ai/AI_ORCHESTRATOR.md` override convenience features.

**Repositories in scope:**

| Role | Repository | Local path |
|------|------------|------------|
| Mobile (farmer) | `pranidoctor_user` | `pranidoctor_user` |
| API | `pranidoctor-backend` | `pranidoctor-backend` |
| Admin / BFF | `pranidoctor-web` | `pranidoctor-web` |
| Database | PostgreSQL (shared schema via Prisma) | `pranidoctor-backend/prisma/schema.prisma` |

**Core principle (non-negotiable):** AI is an **assistant layer**. AI **never** diagnoses independently, **never** replaces licensed veterinarians, and **never** autonomously prescribes. Human escalation has priority over automation.

---

## Table of contents

1. [Executive summary](#1-executive-summary)
2. [Current state audit](#2-current-state-audit)
3. [Veterinary AI Assistant](#3-veterinary-ai-assistant)
4. [Smart Symptom Checker](#4-smart-symptom-checker)
5. [AI Knowledge Base](#5-ai-knowledge-base)
6. [Smart Recommendation Engine](#6-smart-recommendation-engine)
7. [AI Doctor Copilot](#7-ai-doctor-copilot)
8. [Predictive Analytics](#8-predictive-analytics)
9. [Smart Notification System](#9-smart-notification-system)
10. [AI Marketplace Recommendation](#10-ai-marketplace-recommendation)
11. [AI Farm Assistant](#11-ai-farm-assistant)
12. [AI Governance & Safety](#12-ai-governance--safety)
13. [Architecture Design](#13-architecture-design)
14. [Database Changes](#14-database-changes)
15. [API Changes](#15-api-changes)
16. [Flutter Changes](#16-flutter-changes)
17. [Admin Panel Changes](#17-admin-panel-changes)
18. [AI Cost Optimization Strategy](#18-ai-cost-optimization-strategy)
19. [Implementation Priority Matrix](#19-implementation-priority-matrix)
20. [Risks, dependencies & exit criteria](#20-risks-dependencies--exit-criteria)
21. [Appendix — evidence index](#21-appendix--evidence-index)

---

## 1. Executive summary

Phase 8 transforms Prani Doctor from a **feature-complete livestock + doctor marketplace platform** into an **intelligent ecosystem** where AI augments farmers, technicians, and doctors at every touchpoint — while preserving clinical safety, Bangladesh-first localization (Bangla + English), and offline resilience on mobile.

### What exists today (Phase 6–7 foundations)

| Capability | Maturity | Location |
|------------|----------|----------|
| Farmer AI chat + triage (rules stub) | **Implemented (stub provider)** | `pranidoctor-backend/src/modules/ai-veterinary-core/` |
| AI safety guardrails + audit | **Implemented** | `ai-safety.guardrails.ts`, `AiSafetyAuditLog` |
| Voice assistant (Bangla TTS path) | **Implemented (Phase 7)** | `voice-assistant` module, `VoiceSession` |
| Feed intelligence engine (rules, not LLM) | **Production-ready** | `feed-recommendation/intelligence.engine.ts` |
| Vaccine reminders (rule-based) | **Implemented** | Mobile + `mobile-vaccines` legacy |
| Livestock registry + health records | **Phase 4 implemented** | `Livestock`, `LivestockHealthRecord`, etc. |
| Admin analytics + feed ecosystem | **Phase 5 implemented** | Admin panel routes |
| LLM provider integration | **Not implemented** | `RulesBasedAiProvider` placeholder |
| Knowledge base (structured) | **Not implemented** | Referenced in `PROMPT_SYSTEM.md` only |
| Doctor copilot | **Not implemented** | Phase 3 doctor workflow exists without AI |
| Push/SMS smart notifications | **Stub** | `notifications.service.ts` TODOs |
| Predictive analytics | **Not implemented** | Admin analytics is descriptive only |

### Phase 8 north-star outcomes

1. **Farmer-facing:** Conversational veterinary assistant with structured symptom flows, emergency triage, breed-aware guidance, and farm-level daily briefings — available in Bangla and English, voice + text.
2. **Clinical-facing:** Doctor copilot that summarizes cases, suggests differential lists (not diagnoses), drafts follow-up plans — always requiring doctor confirmation.
3. **Operational:** Unified recommendation engine spanning vaccines, deworming, feed, pregnancy care, and farm management — with explainable scores.
4. **Platform:** RAG-backed knowledge base, cost-controlled LLM orchestration, governance dashboards, and predictive risk scores at herd/farm level.

### Strategic sequencing

```
Phase 7 (launch) → Phase 8.1 (LLM + KB + symptom checker)
                 → Phase 8.2 (recommendations + notifications)
                 → Phase 8.3 (doctor copilot + predictive)
                 → Phase 8.4 (marketplace AI + farm assistant pro)
```

Estimated calendar (1 senior full-stack + 0.5 ML/AI engineer + part-time vet content reviewer): **16–24 weeks** for full scope; **8–10 weeks** for MVP subset (sections marked P0 in §19).

---

## 2. Current state audit

### 2.1 Backend modules map (AI-relevant)

```
pranidoctor-backend/src/modules/
├── ai-veterinary-core/     ← P6 farmer AI (chat, triage, memory, escalate)
├── ai/                     ← Legacy stub (superseded by ai-veterinary-core)
├── voice-assistant/        ← P7 voice → ai-veterinary-core bridge
├── feed-recommendation/    ← Rules intelligence engine (non-LLM)
├── notifications/          ← In-app OK; SMS/push not wired
├── treatment-workflow/     ← P5 doctor treatment (no AI hooks)
├── feed-inventory/         ← Stock alerts (rule-based)
├── feed-consumption/       ← Consumption logging
├── admin-analytics/        ← Descriptive KPIs
└── livestock (legacy routes) ← Health, weight, vaccinations
```

### 2.2 Mobile features map

```
pranidoctor_user/lib/features/
├── ai/                     ← Chat, triage UI, voice input, history, settings
├── feed_recommendations/   ← Daily ration, accept flow
├── vaccine/                ← Dashboard, reminders (local notifications)
├── livestock/              ← Registry, health, weight
├── fattening/              ← Batch ROI, feed dashboard
├── ecosystem/              ← Hub linking livestock/feed/inventory/analytics
├── home/                   ← Health tasks, marketplace preview
└── notifications/          ← Local notification service
```

### 2.3 Admin panel map

```
pranidoctor-web/src/app/admin/
├── feed-ecosystem/         ← Items, vendors, nutrition, recommendation rules
├── analytics/              ← Doctors, farmers, livestock, revenue, geography
├── feed-catalog/           ← Bangladesh feed master catalog
└── (no AI admin yet)       ← Phase 8 adds governance + KB curation
```

### 2.4 Gaps driving Phase 8

| Gap | Impact | Phase 8 resolution |
|-----|--------|------------------|
| Rules-only AI responses | Low user value | LLM provider + RAG knowledge base |
| Unstructured symptom input | Poor triage accuracy | Smart Symptom Checker wizard |
| Siloed recommendations | Missed care opportunities | Unified Smart Recommendation Engine |
| No doctor AI assist | Doctor panel friction | AI Doctor Copilot (assist-only) |
| Notification delivery stub | Reminders don't reach users | Smart Notification System + FCM |
| No predictive layer | Reactive-only platform | Herd/farm risk scores |
| No AI ops visibility | Cost/safety blind spots | Admin governance dashboard |

---

## 3. Veterinary AI Assistant

### 3.1 Purpose

Primary farmer-facing conversational agent for livestock health education, symptom clarification, next-step guidance, and escalation to human veterinarians — integrated with existing `ServiceRequest` (case) workflow.

### 3.2 User journeys

#### 3.2.1 Chat-based consultation assistant

| Step | Actor | Action |
|------|-------|--------|
| 1 | Farmer | Opens AI from home, livestock detail, or emergency shortcut |
| 2 | System | Loads session context: locale, active farm, selected animal (optional), recent health events |
| 3 | Farmer | Describes concern in text or voice |
| 4 | AI | Responds with educational guidance, clarifying questions, care steps |
| 5 | System | Persists messages; applies safety layer; logs audit |
| 6 | Farmer | Can escalate → creates/flags `ServiceRequest` or calls emergency flow |

**Enhancements over current `AiVeterinaryCoreService.chat`:**

- Multi-turn structured state machine (INTAKE → CLARIFY → GUIDANCE → ESCALATE)
- Animal context injection from `Livestock` profile (species, breed, age, pregnancy, recent vaccines)
- Image attachment support (Phase 8.2) — stored as media metadata, not sent to LLM without consent flag
- Conversation summaries for doctor handoff
- Bangla-first prompts with English parity

#### 3.2.2 Symptom collection flow

Structured wizard embedded in chat (not separate app):

```
Select animal → Select body system → Pick symptoms (checkbox + free text)
→ Duration / severity → Recent treatments → Environmental factors (feed change, weather)
→ Submit to triage pipeline
```

Output feeds both chat context and `AiTriageRecord`.

#### 3.2.3 Emergency triage flow

Leverage existing `assessSymptomRisk()` and `pranidoctor-web/docs/ai/EMERGENCY_ENGINE.md` spec:

| Urgency | UX | Backend |
|---------|-----|---------|
| CRITICAL (emergency) | Full-screen red banner, one-tap "Call vet / Request emergency visit" | Auto `AiEscalationRecord`, optional admin alert |
| HIGH | Prominent escalation card, pre-filled service request | Escalation queue |
| MEDIUM | Suggest booking within 24–48h | Standard chat continues |
| LOW | Self-care checklist + monitoring reminders | Schedule optional follow-up notification |

**Integration points:**

- Existing Flutter `TriageCard` widget — extend with CRITICAL tier
- `AppRoutes.emergency` / service request creation
- Voice path: `VoiceAssistantService` already routes to `ai-veterinary-core`

#### 3.2.4 Breed-specific guidance

| Input | Source |
|-------|--------|
| Species + breed | `Livestock.breedId` → `LivestockBreed` or `breedName` |
| Breed profile | New `AiKnowledgeBreedProfile` (see §5, §14) |
| Regional norms | Bangladesh heat/humidity, monsoon disease patterns |

Example guidance types (educational, not diagnostic):

- Sahiwal dairy: heat stress mitigation in April–June
- Black Bengal goat: common kid mortality prevention checklist
- Sonali poultry: Newcastle vaccination timing reminder

#### 3.2.5 Disease risk estimation

**Assistive risk score (0–100), not diagnosis:**

```
RiskScore = f(symptoms, species, season, regional outbreak signals, herd history)
```

- Uses symptom checker output + `LivestockHealthRecord` history + optional regional outbreak data (admin-seeded)
- Display: "Elevated concern for respiratory issues — consult a vet"
- Never: "Your cow has pneumonia"

### 3.3 Module ownership

| Layer | Owner module | New? |
|-------|--------------|------|
| Orchestration | `ai-veterinary-core` (extend) | Extend |
| LLM calls | `ai-orchestrator` (new) | **New** |
| Context assembly | `ai-context-builder` (new) | **New** |
| Prompt templates | `ai-prompts` (new, mirrors web docs) | **New** |

### 3.4 Acceptance criteria

- [ ] Bangla + English chat with `<3s` p95 for rules-only fallback; `<8s` p95 with LLM
- [ ] 100% responses include disclaimer + human-redirect on clinical topics
- [ ] HIGH/CRITICAL triage creates escalation record within 500ms
- [ ] Animal-linked sessions show breed-aware context in audit log
- [ ] Offline: queue messages (existing mobile pattern) sync on reconnect

---

## 4. Smart Symptom Checker

### 4.1 Purpose

Guided, species-specific symptom intake producing structured output for triage, chat context, and doctor pre-consultation summaries.

### 4.2 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter SymptomCheckerFlow (stepper UI)                     │
└───────────────────────────┬─────────────────────────────────┘
                            │ POST /api/ai/symptom-check
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  SymptomCheckerService                                       │
│  1. Validate species + symptom IDs                           │
│  2. Rule engine: red flags, confidence, differentials        │
│  3. Optional LLM: rank differentials (assistive labels only) │
│  4. Persist AiSymptomCheckSession                            │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Outputs: confidence, redFlags[], differentials[], triage    │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 Species-specific symptoms

Master taxonomy stored in knowledge base (§5):

| Species | Body systems | Example symptom nodes |
|---------|--------------|----------------------|
| CATTLE | Digestive, Respiratory, Reproductive, Locomotion, Skin, General | Bloat, mastitis signs, milk drop, lameness |
| BUFFALO | Same as cattle + heat stress emphasis | |
| GOAT | Digestive, Respiratory, Reproductive | Kid scours, enterotoxemia signs |
| SHEEP | + Foot rot cluster | |
| POULTRY | Respiratory, Digestive, Production | Drop in egg production, respiratory rattling |
| DUCK | + Duck plague red flags | |

Each symptom node:

```typescript
{
  id: "cattle_bloat",
  species: ["CATTLE", "BUFFALO"],
  labels: { bn: "...", en: "..." },
  redFlag: true,
  weight: 0.9,
  relatedDiseaseIds: ["ruminal_acidosis", "frothy_bloat"],
  followUpQuestions: ["..."],
}
```

### 4.4 Confidence scoring

| Factor | Weight |
|--------|--------|
| Symptom coverage (how many relevant nodes matched) | 30% |
| Red flag presence | 40% (forces high urgency) |
| Duration/severity inputs | 15% |
| Consistency (contradictory symptoms reduce score) | 15% |

Thresholds:

- `< 0.55` → mandatory escalation flag (existing `AI_CONFIDENCE_ESCALATION_THRESHOLD`)
- `0.55–0.75` → guidance + suggest vet visit
- `> 0.75` → still no diagnosis language; stronger educational content only

### 4.5 Differential diagnosis suggestions

**Format (always assistive):**

> "Based on the symptoms described, conditions that veterinarians often consider include: A, B, C. Only a veterinarian can confirm."

- Rule-based: symptom → disease edges in KB graph
- LLM enhancement: re-rank and generate farmer-friendly explanations (Bangla)
- Cap at 3–5 differentials; hide low-confidence (<0.3 edge weight)

### 4.6 Red flag detection

Extend `EMERGENCY_SYMPTOMS` in `ai-safety.guardrails.ts` with structured KB-driven list:

- Immediate UI lock to emergency flow
- Skip LLM for latency — pure rule match
- Audit: `TRIAGE_RED_FLAG` action

### 4.7 Flutter UX

New feature module: `lib/features/symptom_checker/`

- Entry: AI home, livestock health tab, emergency shortcut
- Reuse `AiChatPage` handoff: "Continue in chat with these details"
- Offline: cache symptom taxonomy locally (seed asset + API sync)

---

## 5. AI Knowledge Base

### 5.1 Purpose

Curated, versioned, bilingual veterinary reference content powering RAG, symptom checker, recommendations, and doctor copilot — admin-maintainable.

### 5.2 Content domains

| Domain | Contents | Primary consumers |
|--------|----------|-------------------|
| **Diseases** | Name, species, symptoms, prevention, NOT treatment prescriptions | Symptom checker, chat RAG, copilot |
| **Medicines** | Generic name, species applicability, **info only** — no dosing in farmer AI | Doctor copilot (reference), admin |
| **Vaccines** | Schedule templates by species/age, Bangladesh program alignment | Recommendation engine, vaccine reminders |
| **Feed** | Links to `FeedItem` / `FeedCatalog` + nutritional notes | Feed engine, farm assistant |
| **Farm Management** | Seasonal checklists, biosecurity, housing | Farm assistant, notifications |
| **Emergency Protocols** | Step-by-step first aid (stabilization only) | Emergency triage, voice assistant |

### 5.3 Storage strategy (hybrid)

| Tier | Technology | Use |
|------|------------|-----|
| Structured records | PostgreSQL (`AiKnowledgeEntry`, relations) | Admin CRUD, versioning, audit |
| Embeddings | pgvector extension OR external vector DB (Qdrant/Pinecone) | Semantic RAG retrieval |
| Static seeds | JSON in repo for bootstrap | Initial Bangladesh content pack |
| Media | MinIO / S3 | Diagrams, reference images |

### 5.4 RAG pipeline

```
Query → embed → retrieve top-k chunks (filtered by species, locale)
     → rerank → inject into system prompt → LLM → safety sanitize → response
```

**Retrieval filters:**

- `species`, `locale`, `contentType`, `published=true`, `effectiveDate <= now`
- Exclude `audience=DOCTOR_ONLY` from farmer-facing paths

### 5.5 Content governance

| Role | Capability |
|------|------------|
| Super admin | Publish, deprecate, bulk import |
| Vet reviewer | Draft, review queue, approve |
| AI ops | Embedding refresh, retrieval eval metrics |

Workflow: DRAFT → IN_REVIEW → PUBLISHED → DEPRECATED

### 5.6 Initial content pack (MVP)

Target **80 disease entries**, **30 vaccine schedule templates**, **20 emergency protocols** covering:

- Cattle: FMD, mastitis, tick fever, bloat, heat stress
- Goat: PPR, enterotoxemia, scours
- Poultry: Newcastle, infectious bronchitis, coccidiosis
- Cross-cutting: anthrax (regional alert), rabies (public health)

Content authored in Bangla with English parallel fields.

---

## 6. Smart Recommendation Engine

### 6.1 Purpose

Unified proactive care scheduler extending the existing feed intelligence engine to vaccines, deworming, pregnancy, and farm management — single API surface for mobile home screen and notifications.

### 6.2 Current foundation

`feed-recommendation` module already implements:

- Pipeline modules: dm-base, lactation, pregnancy, health, seasonal, item-selection
- Admin-editable rules via `RecommendationRulesEditor`
- `FeedRecommendationLog` with accept flow

### 6.3 Unified engine architecture

```
┌──────────────────────────────────────────────────────────────┐
│  SmartRecommendationOrchestrator                              │
├──────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │ FeedModule  │ │ VaccineMod  │ │ DewormMod   │  ...       │
│  │ (existing)  │ │ (new)       │ │ (new)       │            │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘            │
│         └───────────────┴───────────────┘                    │
│                         ▼                                     │
│              Merged RecommendationPlan                          │
│              (prioritized, deduplicated, explainable)           │
└──────────────────────────────────────────────────────────────┘
```

### 6.4 Recommendation types

#### 6.4.1 Vaccine reminders

| Input | Rule source |
|-------|-------------|
| `LivestockVaccination` history | Last administered + vaccine type |
| Species + age | KB schedule templates |
| Regional calendar | Admin config (e.g., FMD campaign months) |

Output: `{ livestockId, vaccineName, dueDate, urgency, explanationBn }`

Integrate with existing mobile `vaccineReminderProvider` — backend becomes source of truth.

#### 6.4.2 Deworming schedules

| Species | Default interval | Adjustments |
|---------|------------------|-------------|
| Cattle | 90 days | Monsoon +15 days, young animals 60 days |
| Goat | 60 days | High pasture exposure flag |
| Poultry | 45 days (if applicable product) | |

New model: `DewormingRecord` (parallel to vaccination).

#### 6.4.3 Feed recommendations

Keep existing `GET /api/mobile/recommendations/daily` — wrap as `FeedModule` output in unified plan.

#### 6.4.4 Pregnancy recommendations

Leverage `Livestock.pregnancyStatus`, `lastCalvingDate`, `lactationNumber`:

- Nutrition adjustments (existing pregnancy module)
- Pre-calving checklist (7 days before estimated calving)
- Post-calving care reminders

#### 6.4.5 Farm management suggestions

Farm-level (not per-animal):

- Inventory low-stock from `feed-inventory` alerts
- Seasonal: "Prepare shade for heat wave"
- Batch-level: fattening ROI review triggers from `fattening` module

### 6.5 Explainability contract

Every recommendation includes:

```typescript
{
  id: string;
  type: 'VACCINE' | 'DEWORM' | 'FEED' | 'PREGNANCY' | 'FARM';
  priority: 1 | 2 | 3;
  titleBn: string;
  titleEn: string;
  explanationBn: string;
  ruleVersion: string;
  confidence: number;
  actions: [{ label, deepLink }];
}
```

### 6.6 API surface

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/mobile/smart-recommendations` | Unified plan for user/farm |
| GET | `/api/mobile/smart-recommendations/livestock/:id` | Per-animal plan |
| POST | `/api/mobile/smart-recommendations/:id/dismiss` | User dismissed |
| POST | `/api/mobile/smart-recommendations/:id/complete` | Mark done (links to vaccine/deworm log) |

---

## 7. AI Doctor Copilot

### 7.1 Purpose

Assist licensed veterinarians during consultations — summarization, differential suggestions, protocol references, follow-up drafting. **Doctor always confirms; AI never auto-writes to medical record.**

### 7.2 Prerequisites

- Phase 3 doctor workflow stable: `TreatmentCase`, `TreatmentWorkflow`, `TreatmentConsultation`
- Doctor panel auth: `panel-doctor-auth.service.ts`
- Phase 7 production monitoring for audit

### 7.3 Capabilities

#### 7.3.1 Consultation assistance

| Feature | Description |
|---------|-------------|
| Case summary | Aggregates `ServiceRequest`, farmer AI chat, symptom check, livestock profile |
| Timeline view | Chronological health events |
| Question prompts | Suggested clarifying questions for doctor to ask |

#### 7.3.2 Prescription suggestions

**Strict boundary:** Suggest medicine **categories** and reference formulary entries — doctor selects and edits.

```
Input: confirmed diagnosis (by doctor), species, weight, allergies
Output: "Consider: Oxytetracycline class — see formulary #123" (not auto-Rx)
```

Requires `audience=DOCTOR_ONLY` KB content with dosing references.

#### 7.3.3 Treatment protocol suggestions

Link to published protocols in KB:

- Mastitis protocol (step 1–5)
- Post-surgical care
- Vaccination certificate generation hints

#### 7.3.4 Follow-up suggestions

Based on treatment workflow state:

- Suggested follow-up date
- Parameters to monitor
- Draft follow-up message for farmer (doctor approves before send)

### 7.4 Architecture

New module: `ai-doctor-copilot` (backend)

- Auth: doctor panel JWT, separate rate limits
- No access to other doctors' cases
- All suggestions logged in `AiCopilotSuggestionLog` with `accepted: boolean`

### 7.5 UI placement

**Not in current admin panel** — requires doctor-facing UI:

| Option | Recommendation |
|--------|----------------|
| A — Flutter doctor app | Future Phase 9 |
| B — Web doctor panel in `pranidoctor-web` | **Phase 8.3** — sidebar copilot drawer |
| C — API-only for external EMR | Defer |

**Plan:** Option B — new `/doctor/consultation/:caseId` copilot panel.

---

## 8. Predictive Analytics

### 8.1 Purpose

Move from descriptive admin analytics to farm-level predictive signals — assistive risk scores for proactive intervention.

### 8.2 Models (Phase 8 scope)

| Model | Output | Inputs | Update cadence |
|-------|--------|--------|----------------|
| **Disease outbreak prediction** | Regional risk index 0–100 | Admin outbreak reports, symptom check aggregates (anonymized), season | Daily |
| **Herd health score** | 0–100 per farmRef | Vaccination compliance, health records, mortality events | Weekly |
| **Farm risk score** | 0–100 composite | Herd score + inventory + financial anomalies | Weekly |
| **Livestock mortality risk** | Per-animal 0–100 | Age, breed, health history, weight trend | On-demand |

### 8.3 Implementation approach

**Phase 8:** Rule-based + statistical baselines (no custom ML training required for MVP)

```
mortalityRisk = weighted_sum(age_factor, recent_illness, weight_loss, missed_vaccines)
```

**Phase 8.4+:** Optional ML models trained on aggregated anonymized data — separate privacy review.

### 8.4 Data pipeline

```
PostgreSQL (Livestock, HealthRecord, Vaccination, SymptomCheck aggregates)
    → nightly BullMQ job: compute_scores
    → store in FarmRiskSnapshot, HerdHealthSnapshot
    → expose via /api/mobile/analytics/risk and /api/admin/analytics/predictive
```

Leverage existing `admin-analytics` module patterns and mobile `livestock/analytics` routes.

### 8.5 UX

| Surface | Display |
|---------|---------|
| Farmer app | Farm dashboard card: "Herd health: 78/100 — 2 actions suggested" |
| Admin | Geography heatmap of outbreak risk |
| Doctor | Optional regional alert banner |

### 8.6 Privacy

- Outbreak aggregation: k-anonymity minimum 5 farms per cell
- No individual farmer data in admin outbreak view
- Opt-out flag on `CustomerProfile` for analytics contribution

---

## 9. Smart Notification System

### 9.1 Purpose

Deliver the right message at the right time through the right channel — powering recommendations, triage escalations, and farm alerts.

### 9.2 Current state

- Backend `notifications` module: in-app storage works; SMS/PUSH throw `NotImplementedError`
- Mobile: `LocalNotificationService` for vaccine fallback only
- No FCM/APNs integration

### 9.3 Target architecture

```
┌─────────────────────────────────────────────────────────────┐
│  NotificationOrchestrator                                    │
│  Triggers: recommendations, triage, inventory, admin campaigns│
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Channel router (user preferences + urgency override)        │
│  IN_APP │ PUSH (FCM) │ SMS (GP/SSL) │ EMAIL (defer)         │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  BullMQ workers: deliver, retry, DLQ                         │
└─────────────────────────────────────────────────────────────┘
```

### 9.4 Smart behaviors

| Behavior | Logic |
|----------|-------|
| **Priority routing** | CRITICAL triage → PUSH + SMS even if user muted marketing |
| **Quiet hours** | 22:00–06:00 BDT — queue non-urgent until morning |
| **Digest mode** | Batch LOW priority into daily 08:00 summary |
| **Fatigue cap** | Max 3 marketing/promo pushes per week |
| **Deep links** | Every notification maps to Flutter route |
| **Locale** | Bangla default; respect user locale |

### 9.5 AI-generated notification copy

- Template-first (deterministic)
- LLM optional for personalization with strict token budget
- All AI copy passes safety sanitizer (no diagnosis in push text)

### 9.6 Device registration

New: `DevicePushToken` model, `POST /api/mobile/devices/register`

---

## 10. AI Marketplace Recommendation

### 10.1 Purpose

Help farmers find the right service provider, product category, or technician based on context — extending home marketplace preview.

### 10.2 Current state

- `MarketplacePage` shows service categories + doctor list preview
- `homeMarketplaceCatalogProvider` — static/catalog-driven
- No personalization

### 10.3 Recommendation signals

| Signal | Source |
|--------|--------|
| Recent AI triage outcome | Escalation → prioritize vets over technicians |
| Livestock profile | Dairy farmer → dairy-specialist doctors |
| Location | Existing area/doctor proximity |
| Service history | Repeat booking bias |
| Seasonal demand | Qurbani season → fattening services |

### 10.4 Architecture

```
MarketplaceRecommendationService
  → rule engine (Phase 8.1)
  → optional LLM re-ranking (Phase 8.4)
  → output: ranked HomeMarketplacePreviewItem[]
```

### 10.5 API

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/mobile/marketplace/recommendations` | Personalized catalog |
| GET | `/api/mobile/marketplace/recommendations/explain/:id` | Why shown (transparency) |

### 10.6 Guardrails

- No paid placement without `sponsored: true` label
- Doctor rankings must include distance and availability factors
- AI must not guarantee outcomes

---

## 11. AI Farm Assistant

### 11.1 Purpose

Daily operational copilot for farm managers — briefings, task lists, and natural-language queries over farm data.

### 11.2 Capabilities

| Capability | Example query (BN) |
|------------|-------------------|
| Daily briefing | "আজ আমার খামারে কী কী করতে হবে?" |
| Inventory query | "ঘাসের গুঁড়া কত দিন চলবে?" |
| Livestock query | "কতগুলো গরু টিকা বাকি?" |
| Financial snapshot | "এ মাসে খাদ্য খরচ কত?" |
| Action execution | "গরু #১২-এর ওজন লগ করো" → deep link to weight entry |

### 11.3 Architecture

Extends `ai-veterinary-core` with `contextType: FARM_OPS`:

- Tool-calling layer (function calls) against read-only farm APIs
- Write actions require explicit user confirmation (never autonomous mutations)
- Integrates with `EcosystemHubPage` as primary entry

### 11.4 Data access scope

| Data | Access |
|------|--------|
| Own farms/livestock | Read |
| Feed inventory | Read |
| Recommendations | Read |
| Create health record | Confirm → hand off to form |
| Purchase / financial write | **Blocked** |

### 11.5 Voice integration

Route farm queries through existing `VoiceAssistantService` with expanded intent classification.

---

## 12. AI Governance & Safety

### 12.1 Policy framework

Extend Phase 6 rules:

| Rule | Enforcement layer |
|------|-------------------|
| No autonomous diagnosis | Input + output guardrails, prompt design |
| No prescription to farmers | Refusal layer + KB audience tags |
| Human escalation priority | Triage + confidence thresholds |
| Doctor confirmation for clinical actions | Copilot accept/reject logging |
| Bangla/English parity | Content + prompt QA |
| Audit everything clinical-adjacent | `AiSafetyAuditLog`, extended types |

### 12.2 New governance capabilities

| Capability | Description |
|------------|-------------|
| **Prompt versioning** | Git-tracked prompts with admin override registry |
| **Model allowlist** | Per-environment approved models |
| **Usage budgets** | Per-user/day token caps |
| **Content moderation** | Farmer-uploaded images — separate moderation pipeline |
| **Incident response** | Kill switch: disable LLM → rules fallback globally |
| **Eval harness** | Golden test cases for triage + safety (CI gate) |

### 12.3 Admin governance dashboard

New admin section: `/admin/ai-governance`

- Usage by feature/model/day
- Escalation queue (existing `AiEscalationRecord` + review UI)
- Safety audit search
- KB publish queue
- Prompt A/B experiment results (Phase 8.4)

### 12.4 Regulatory alignment (Bangladesh context)

- Position as **livestock information assistant**, not telemedicine prescriber
- Terms of service acknowledgment in AI settings (existing `ai_settings_page.dart`)
- Vet reviewer sign-off on KB clinical content
- Data residency: prefer LLM providers with APAC endpoints or self-hosted option for sensitive deployments

---

## 13. Architecture Design

### 13.1 Target system diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CLIENTS                                            │
│  Flutter (farmer)  │  Flutter/Web (doctor)  │  Admin Next.js                │
└─────────┬──────────────────┬─────────────────────────┬──────────────────────┘
          │                  │                         │
          ▼                  ▼                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     API GATEWAY (Express / hybrid BFF)                       │
│  /api/ai/*  /api/mobile/smart-*  /api/doctor/copilot/*  /api/admin/ai/*     │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          ▼                       ▼                       ▼
┌──────────────────┐  ┌──────────────────────┐  ┌─────────────────────┐
│ ai-veterinary-   │  │ ai-orchestrator      │  │ smart-recommendation│
│ core             │  │ (router, budget,     │  │ -orchestrator       │
│ symptom-checker  │  │  fallback chain)     │  │                     │
│ ai-doctor-copilot│  └──────────┬───────────┘  └─────────────────────┘
│ ai-farm-assistant│             │
└────────┬─────────┘             ▼
         │            ┌──────────────────────┐
         │            │ Provider layer        │
         │            │ OpenAI / Anthropic /  │
         │            │ rules-fallback        │
         │            └──────────┬───────────┘
         │                       │
         ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  ai-knowledge-base (PostgreSQL + pgvector)  │  Redis (cache, rate limits)   │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  BullMQ workers: embeddings, notifications, score computation, moderation    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 13.2 New backend modules

| Module | Responsibility |
|--------|----------------|
| `ai-orchestrator` | Provider abstraction, routing, budgets — implement `AI_ORCHESTRATOR.md` |
| `ai-knowledge-base` | CRUD, RAG retrieval, embedding jobs |
| `ai-symptom-checker` | Structured intake + scoring |
| `smart-recommendation-orchestrator` | Unified care recommendations |
| `ai-doctor-copilot` | Doctor-facing suggestions |
| `ai-farm-assistant` | Tool-calling farm queries |
| `ai-governance` | Usage, eval, kill switch |
| `marketplace-recommendation` | Personalized marketplace ranking |

### 13.3 Event-driven integration

Extend existing event patterns (`aiEvents`, `notificationsEvents`):

| Event | Consumers |
|-------|-----------|
| `ai.triage.completed` | Notifications, escalation queue, analytics |
| `ai.escalation.created` | Admin alert, doctor queue |
| `recommendation.generated` | Notification scheduler |
| `knowledge.published` | Embedding worker |
| `farm.risk.updated` | Mobile dashboard cache invalidation |

### 13.4 Caching strategy

| Cache | TTL | Key |
|-------|-----|-----|
| Symptom taxonomy | 24h | `symptom-taxonomy:{species}:{locale}` |
| KB retrieval chunks | 1h | query hash + filters |
| Daily recommendations | Until midnight BDT | `recs:{customerId}:{farmRef}:{date}` |
| LLM response (educational FAQ) | 7d | normalized query hash (opt-in) |

### 13.5 Mobile offline strategy

| Feature | Offline behavior |
|---------|------------------|
| Chat | Queue messages (existing) |
| Symptom checker | Cached taxonomy; triage requires network |
| Recommendations | Last-synced plan + stale badge |
| Farm assistant queries | Read-only cached briefing |

---

## 14. Database Changes

**Rule:** Additive migrations only (consistent with Phase 6 freeze policy). All new tables prefixed or namespaced to avoid collision with legacy.

### 14.1 Knowledge base

```prisma
model AiKnowledgeEntry {
  id            String   @id @default(cuid())
  contentType   AiKnowledgeContentType  // DISEASE, MEDICINE, VACCINE, FEED, FARM_MGMT, EMERGENCY
  slug          String   @unique
  audience      AiKnowledgeAudience      // FARMER, DOCTOR, BOTH
  titleBn       String
  titleEn       String
  bodyBn        String   @db.Text
  bodyEn        String   @db.Text
  species       LivestockSpecies[]
  status        AiKnowledgeStatus        // DRAFT, IN_REVIEW, PUBLISHED, DEPRECATED
  version       Int      @default(1)
  publishedAt   DateTime?
  createdById   String?
  reviewedById  String?
  metadataJson  Json?
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
  chunks        AiKnowledgeChunk[]
  symptomLinks  AiSymptomDiseaseLink[]
}

model AiKnowledgeChunk {
  id          String   @id @default(cuid())
  entryId     String
  chunkIndex  Int
  contentBn   String   @db.Text
  contentEn   String   @db.Text
  embedding   Unsupported("vector(1536)")?  // pgvector
  entry       AiKnowledgeEntry @relation(...)
  @@index([entryId])
}

model AiSymptomNode {
  id          String   @id @default(cuid())
  code        String   @unique
  species     LivestockSpecies[]
  bodySystem  String
  labelBn     String
  labelEn     String
  redFlag     Boolean  @default(false)
  weight      Float    @default(0.5)
  parentId    String?
}

model AiSymptomDiseaseLink {
  symptomNodeId  String
  knowledgeEntryId String
  edgeWeight     Float
  @@id([symptomNodeId, knowledgeEntryId])
}

model AiKnowledgeBreedProfile {
  id          String   @id @default(cuid())
  breedId     String?
  species     LivestockSpecies
  titleBn     String
  guidanceBn  String   @db.Text
  guidanceEn  String   @db.Text
}
```

### 14.2 Symptom checker sessions

```prisma
model AiSymptomCheckSession {
  id              String   @id @default(cuid())
  userId          String
  livestockId     String?
  species         LivestockSpecies
  symptomsJson    Json
  confidence      Float
  redFlagsJson    Json
  differentialsJson Json
  triageBucket    AiRiskBucket
  aiSessionId     String?
  createdAt       DateTime @default(now())
  @@index([userId, createdAt])
}
```

### 14.3 Smart recommendations

```prisma
model SmartRecommendation {
  id            String   @id @default(cuid())
  customerId    String
  farmRef       String?
  livestockId   String?
  type          SmartRecommendationType
  priority      Int
  titleBn       String
  explanationBn String
  ruleVersion   String
  confidence    Float
  dueDate       DateTime? @db.Date
  status        SmartRecommendationStatus  // PENDING, DISMISSED, COMPLETED
  deepLink      String?
  createdAt     DateTime @default(now())
  @@index([customerId, status, dueDate])
}

model DewormingRecord {
  id              String   @id @default(cuid())
  customerId      String
  livestockId     String
  productName     String?
  administeredDate DateTime @db.Date
  nextDueDate     DateTime? @db.Date
  notes           String?
  @@index([livestockId])
}
```

### 14.4 Doctor copilot

```prisma
model AiCopilotSuggestionLog {
  id            String   @id @default(cuid())
  doctorUserId  String
  caseId        String
  suggestionType String  // SUMMARY, DIFFERENTIAL, PROTOCOL, FOLLOWUP
  contentJson   Json
  accepted      Boolean?
  createdAt     DateTime @default(now())
  @@index([caseId])
}
```

### 14.5 Predictive analytics

```prisma
model FarmRiskSnapshot {
  id              String   @id @default(cuid())
  customerId      String
  farmRef         String
  herdHealthScore Int
  farmRiskScore   Int
  mortalityRiskAvg Float?
  computedAt      DateTime @default(now())
  factorsJson     Json
  @@index([customerId, farmRef, computedAt])
}

model RegionalOutbreakSignal {
  id          String   @id @default(cuid())
  diseaseSlug String
  divisionId  String?
  districtId  String?
  riskIndex   Int
  effectiveDate DateTime @db.Date
  source      String
  @@index([effectiveDate])
}
```

### 14.6 AI operations

```prisma
model AiUsageRecord {
  id            String   @id @default(cuid())
  userId        String?
  feature       String   // CHAT, TRIAGE, COPILOT, FARM_ASSISTANT
  provider      String
  model         String
  inputTokens   Int
  outputTokens  Int
  costUsd       Decimal? @db.Decimal(10, 6)
  latencyMs     Int
  createdAt     DateTime @default(now())
  @@index([createdAt, feature])
}

model DevicePushToken {
  id        String   @id @default(cuid())
  userId    String
  platform  String   // ANDROID, IOS
  token     String   @unique
  locale    String   @default("bn")
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

### 14.7 Migration plan

| Migration | Phase | Notes |
|-----------|-------|-------|
| `20260601120000_ai_knowledge_base_v1` | 8.1 | pgvector extension + KB tables |
| `20260602120000_ai_symptom_checker_v1` | 8.1 | Symptom nodes + sessions |
| `20260603120000_smart_recommendations_v1` | 8.2 | Unified recs + deworming |
| `20260604120000_ai_copilot_v1` | 8.3 | Copilot audit log |
| `20260605120000_predictive_analytics_v1` | 8.3 | Risk snapshots |
| `20260606120000_ai_usage_devices_v1` | 8.1 | Usage + push tokens |

Seed scripts: `prisma/seeds/ai_knowledge_bd_v1.seed.ts`, `prisma/seeds/ai_symptom_taxonomy.seed.ts`

---

## 15. API Changes

### 15.1 Farmer AI (`/api/ai` — extend existing)

| Method | Path | Status | Description |
|--------|------|--------|-------------|
| POST | `/chat` | **Extend** | Add `livestockId`, `contextType`, tool results |
| POST | `/triage` | **Extend** | Accept structured symptom IDs |
| POST | `/symptom-check` | **New** | Full symptom checker pipeline |
| GET | `/symptom-taxonomy` | **New** | Species → body systems → symptoms |
| POST | `/symptom-check/:id/to-chat` | **New** | Hand off to chat session |
| GET | `/briefing/daily` | **New** | Farm assistant daily briefing |
| POST | `/farm-query` | **New** | Natural language farm data query |
| GET | `/history` | Exists | Extend with symptom check sessions |

### 15.2 Smart recommendations (`/api/mobile/smart-recommendations`)

See §6.6 — new module mount.

### 15.3 Doctor copilot (`/api/doctor/copilot`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/cases/:caseId/summary` | Doctor JWT | AI case summary |
| POST | `/cases/:caseId/suggest/differentials` | Doctor JWT | Differential list |
| POST | `/cases/:caseId/suggest/protocol` | Doctor JWT | Protocol reference |
| POST | `/cases/:caseId/suggest/followup` | Doctor JWT | Follow-up draft |
| POST | `/suggestions/:id/feedback` | Doctor JWT | Accept/reject log |

### 15.4 Knowledge base admin (`/api/admin/ai-knowledge`)

| Method | Path | Description |
|--------|------|-------------|
| GET/POST | `/entries` | List/create |
| GET/PATCH | `/entries/:id` | Read/update |
| POST | `/entries/:id/publish` | Publish workflow |
| POST | `/entries/:id/reembed` | Trigger embedding job |
| GET/POST | `/symptom-nodes` | Symptom taxonomy CRUD |

### 15.5 AI governance admin (`/api/admin/ai-governance`)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/usage` | Token/cost dashboard |
| GET | `/escalations` | Review queue |
| GET | `/audit` | Safety audit search |
| POST | `/kill-switch` | Disable LLM globally |

### 15.6 Marketplace (`/api/mobile/marketplace`)

See §10.5.

### 15.7 Notifications (`/api/mobile/devices`)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/register` | FCM token registration |
| DELETE | `/register/:token` | Unregister |
| GET/PATCH | `/notification-preferences` | Channel preferences |

### 15.8 Predictive analytics

| Method | Path | Audience |
|--------|------|----------|
| GET | `/api/mobile/analytics/farm-risk` | Farmer |
| GET | `/api/admin/analytics/predictive` | Admin |
| GET | `/api/admin/analytics/outbreak-risk` | Admin |

### 15.9 Rate limits (extend existing)

| Endpoint group | Limit |
|----------------|-------|
| `/api/ai/chat` | Existing `rateLimitAiChat` — 30/hour/user |
| `/api/ai/symptom-check` | 20/hour/user |
| `/api/ai/farm-query` | 40/hour/user |
| `/api/doctor/copilot/*` | 100/hour/doctor |
| `/api/admin/ai/*` | Admin role + 200/hour |

---

## 16. Flutter Changes

### 16.1 Existing modules to extend

| Module | Changes |
|--------|---------|
| `lib/features/ai/` | Structured symptom handoff, daily briefing entry, farm query mode, image attach (8.2) |
| `lib/features/home/` | Smart recommendation cards on dashboard; risk score chip |
| `lib/features/vaccine/` | Backend-driven reminders; dismiss/complete actions |
| `lib/features/ecosystem/` | Add AI Farm Assistant + Symptom Checker tiles |
| `lib/features/livestock/` | "Ask AI about this animal" shortcut |
| `lib/features/notifications/` | FCM registration, preference screen |

### 16.2 New feature modules

```
lib/features/
├── symptom_checker/
│   ├── data/          # taxonomy repository, session DTOs
│   └── presentation/  # stepper flow, result screen
├── smart_recommendations/
│   ├── data/
│   └── presentation/  # unified rec list, home widgets
├── farm_assistant/
│   └── presentation/  # briefing page, query bar
└── farm_risk/
    └── presentation/  # risk dashboard cards
```

### 16.3 Routing additions (`app_routes.dart`)

| Route | Page |
|-------|------|
| `/ai/symptom-check` | SymptomCheckerFlowPage |
| `/ai/briefing` | FarmBriefingPage |
| `/smart-recommendations` | SmartRecommendationsPage |
| `/farm-risk` | FarmRiskDashboardPage |

### 16.4 Localization

Add keys to `assets/i18n/en.json`, `assets/i18n/bn.json`:

- Symptom checker steps, body systems, red flag messages
- Risk score explanations
- Smart recommendation type labels
- Farm assistant query hints

Follow [LOCALIZATION_MASTER_PLAN.md](./localization/LOCALIZATION_MASTER_PLAN.md) — Bangla primary.

### 16.5 Offline / sync

- Cache symptom taxonomy in Hive/SQLite via existing offline patterns
- Queue symptom check sessions if offline → sync when online (or block with message)
- Smart recommendations: stale-while-revalidate with `lastSyncedAt` badge

---

## 17. Admin Panel Changes

### 17.1 New admin sections

| Path | Purpose |
|------|---------|
| `/admin/ai-governance` | Usage, escalations, audit, kill switch |
| `/admin/ai-knowledge` | KB entry list + editor |
| `/admin/ai-knowledge/symptoms` | Symptom taxonomy editor |
| `/admin/ai-knowledge/review-queue` | Vet content review |
| `/admin/ai-analytics` | Predictive/outbreak dashboards |
| `/admin/smart-recommendations/rules` | Extend recommendation rules (deworm/vaccine) |

### 17.2 Extend existing sections

| Section | Extension |
|---------|-----------|
| `/admin/feed-ecosystem/recommendations` | Link to unified smart recommendation rules |
| `/admin/analytics/livestock` | Herd health score aggregates |
| `/admin/analytics/geography` | Outbreak risk heatmap layer |

### 17.3 New components (Next.js)

```
src/components/admin/ai/
├── AiGovernanceDashboard.tsx
├── AiUsageChart.tsx
├── EscalationReviewQueue.tsx
├── KnowledgeEntryForm.tsx
├── KnowledgeEntryList.tsx
├── SymptomTaxonomyEditor.tsx
├── ContentReviewQueue.tsx
└── OutbreakRiskMap.tsx
```

### 17.4 Doctor panel (new route group)

```
src/app/doctor/(consultation)/
├── layout.tsx
└── cases/[caseId]/page.tsx   # Copilot drawer
```

Separate auth layout using doctor panel JWT — not mixed with admin RBAC.

### 17.5 BFF proxy routes

Mirror all `/api/admin/ai-*` and `/api/doctor/copilot/*` in `pranidoctor-web/src/app/api/` per existing pattern.

---

## 18. AI Cost Optimization Strategy

### 18.1 Cost drivers (estimated monthly at 10k MAU)

| Feature | Est. tokens/request | Requests/day | Monthly cost (GPT-4o-mini) |
|---------|---------------------|--------------|----------------------------|
| Chat | 2,000 | 3,000 | ~$270 |
| Symptom check + LLM rank | 1,500 | 500 | ~$45 |
| Farm assistant | 1,000 | 1,000 | ~$60 |
| Doctor copilot | 3,000 | 200 | ~$36 |
| Embeddings (KB refresh) | batch | weekly | ~$20 |
| **Total estimate** | | | **~$430/month** |

*Scale linearly with MAU; use budgets below to cap.*

### 18.2 Optimization tactics

| Tactic | Savings | Implementation |
|--------|---------|----------------|
| **Rules-first routing** | 40–60% | Try symptom rules before LLM; FAQ cache hits |
| **Model tiering** | 50%+ | GPT-4o-mini for chat; GPT-4o only for copilot |
| **Prompt compression** | 20% | Trim context; summarize old turns |
| **RAG chunk limit** | 15% | top-k=4, max 800 tokens retrieved |
| **Response caching** | 30% FAQ | Redis cache normalized educational queries |
| **Batch embeddings** | 10% | Weekly KB refresh, not per-edit |
| **Token budgets** | Hard cap | Per-user daily limit with graceful degradation |
| **Bangla fine-tuned small model (future)** | 70%+ | Evaluate Bangla-Llama for chat only |

### 18.3 Fallback chain (from AI_ORCHESTRATOR.md)

```
Primary (OpenAI) → Secondary (Anthropic) → Rules-based provider → Static FAQ
```

Emergency triage **never waits** for fallback delay — rules-only path.

### 18.4 Monitoring

- `AiUsageRecord` aggregated in admin dashboard
- Alert if daily spend > 120% of budget
- Per-feature cost attribution for prioritization decisions

---

## 19. Implementation Priority Matrix

### 19.1 Priority definitions

| Priority | Meaning | Target |
|----------|---------|--------|
| **P0** | MVP — launch Phase 8 value | Weeks 1–10 |
| **P1** | High value, post-MVP | Weeks 11–16 |
| **P2** | Enhancement | Weeks 17–24 |
| **P3** | Future / research | Phase 9+ |

### 19.2 Feature matrix

| # | Feature | Priority | Effort | Dependencies | Success metric |
|---|---------|----------|--------|--------------|----------------|
| 1 | LLM provider integration (`ai-orchestrator`) | **P0** | L | Phase 7 launch, API keys | Chat uses real LLM with fallback |
| 2 | AI Knowledge Base + RAG | **P0** | L | pgvector, content seed | 80+ published entries |
| 3 | Smart Symptom Checker | **P0** | M | KB symptom taxonomy | 70% triage uses structured flow |
| 4 | Veterinary AI Assistant enhancements | **P0** | M | #1, #2 | Session context with livestock |
| 5 | Emergency triage upgrade | **P0** | S | Symptom checker | CRITICAL path <2s |
| 6 | Smart Recommendation Engine (vaccine + deworm) | **P1** | M | KB vaccine templates | Unified rec API live |
| 7 | Push notifications (FCM) | **P1** | M | Device tokens | 50% push delivery rate |
| 8 | Smart Notification orchestration | **P1** | M | #7, #6 | Recommendations reach users |
| 9 | AI Governance admin dashboard | **P1** | M | AiUsageRecord | Ops visibility day 1 of LLM |
| 10 | AI Farm Assistant (briefing + queries) | **P1** | M | #1, farm APIs | Daily briefing active |
| 11 | Breed-specific guidance | **P1** | S | KB breed profiles | Breed context in 90% sessions |
| 12 | Disease risk estimation | **P1** | M | Symptom checker + health history | Risk score on result screen |
| 13 | AI Doctor Copilot | **P2** | L | Doctor panel UI, DOCTOR KB | 20% doctor adoption |
| 14 | Predictive analytics (rule-based) | **P2** | M | Health/vaccine data quality | Farm risk on dashboard |
| 15 | AI Marketplace Recommendation | **P2** | S | Triage + location signals | CTR +10% vs static |
| 16 | Image analysis (symptom photos) | **P2** | L | Moderation pipeline | Optional attach flow |
| 17 | Voice farm assistant intents | **P2** | M | Voice assistant | 5 farm intents supported |
| 18 | ML-based predictive models | **P3** | XL | Data volume, privacy review | Defer to Phase 9 |
| 19 | Doctor mobile copilot | **P3** | L | Doctor app | Defer |
| 20 | Local Llama self-hosted | **P3** | XL | Infra budget | Evaluate at 50k MAU |

**Effort:** S = 1–2 weeks, M = 2–4 weeks, L = 4–8 weeks, XL = 8+ weeks

### 19.3 Recommended sprint plan

| Sprint | Weeks | Deliverables |
|--------|-------|--------------|
| 8.1a | 1–2 | `ai-orchestrator`, OpenAI adapter, usage logging, kill switch |
| 8.1b | 3–4 | KB schema, admin CRUD, embedding worker, BD seed content |
| 8.1c | 5–6 | Symptom taxonomy, checker API + Flutter flow |
| 8.1d | 7–8 | Chat RAG integration, triage upgrade, governance dashboard |
| 8.2a | 9–10 | Smart recommendation orchestrator, deworming, vaccine sync |
| 8.2b | 11–12 | FCM push, notification orchestrator, smart notif copy |
| 8.2c | 13–14 | Farm assistant briefing + queries, ecosystem hub updates |
| 8.3a | 15–18 | Doctor copilot backend + web panel |
| 8.3b | 19–20 | Predictive scores, farm risk dashboard |
| 8.4 | 21–24 | Marketplace AI, voice intents, image attach, eval harness hardening |

### 19.4 MVP scope (P0 only — ~8–10 weeks)

If resources are constrained, ship:

1. LLM orchestrator with safety layer
2. Knowledge base (80 entries) + RAG chat
3. Symptom checker + emergency triage
4. AI governance dashboard
5. Enhanced chat with livestock context

Defer: doctor copilot, predictive analytics, marketplace AI, push notifications (keep local notifications).

---

## 20. Risks, dependencies & exit criteria

### 20.1 Dependencies

| Dependency | Blocking |
|------------|----------|
| Phase 7 production launch | Real user traffic, FCM credentials, monitoring |
| pgvector on PostgreSQL | RAG |
| Vet content reviewer | KB quality |
| LLM provider account + APAC routing | Chat quality |
| Doctor panel route ownership | Copilot UI |
| BullMQ workers in production | Embeddings, notifications, scores |

### 20.2 Risks

| Risk | Mitigation |
|------|------------|
| LLM hallucination in Bangla | RAG grounding + output sanitizer + eval harness |
| Regulatory telemedicine concern | Disclaimers, no Rx to farmers, vet-reviewed KB |
| Cost overrun | Token budgets, rules-first, caching |
| Low doctor adoption | Copilot as optional drawer; measure accept rate |
| Content staleness | Review queue + version expiry alerts |
| Privacy on symptom aggregates | k-anonymity, opt-out, no PII in embeddings |

### 20.3 Phase 8 exit criteria

- [ ] P0 features live in staging with LLM provider
- [ ] 100% clinical AI responses pass safety eval harness
- [ ] KB: ≥80 published entries, Bangla + English
- [ ] Symptom checker integrated with triage and chat
- [ ] Admin governance dashboard operational
- [ ] AI usage cost within budget for 30-day staging soak
- [ ] Documentation updated: API contracts, runbooks, content style guide
- [ ] Phase 8 QA report signed off

---

## 21. Appendix — evidence index

| Topic | Reference |
|-------|-----------|
| Phase 6 AI architecture | `pranidoctor-web/docs/PHASE6_AI.md` |
| AI orchestrator design | `pranidoctor-web/docs/ai/AI_ORCHESTRATOR.md` |
| Emergency engine spec | `pranidoctor-web/docs/ai/EMERGENCY_ENGINE.md` |
| Prompt system | `pranidoctor-web/docs/ai/PROMPT_SYSTEM.md` |
| AI veterinary core (backend) | `pranidoctor-backend/src/modules/ai-veterinary-core/` |
| Safety guardrails | `pranidoctor-backend/src/modules/ai-veterinary-core/safety/` |
| Rules-based provider (current) | `pranidoctor-backend/src/modules/ai-veterinary-core/provider/rules-based.provider.ts` |
| Flutter AI feature | `pranidoctor_user/lib/features/ai/` |
| Feed intelligence engine | `pranidoctor-backend/src/modules/feed-recommendation/` |
| Feed engine plan | `pranidoctor-backend/docs/plans/phase-4-livestock-feed-ecosystem/FEED_INTELLIGENCE_ENGINE_V1.md` |
| Livestock health plan | `pranidoctor-web/docs/plans/phase-4-livestock-feed-ecosystem/livestock-health-plan.md` |
| Phase 7 preparation | `pranidoctor_user/docs/phase-7-preparation.md` |
| Prisma AI models (P6) | `pranidoctor-backend/prisma/schema.prisma` — `AiAssistantSession`, etc. |
| Voice assistant (P7) | `pranidoctor-backend/src/modules/voice-assistant/` |
| Notifications stub | `pranidoctor-backend/src/modules/notifications/notifications.service.ts` |
| Admin recommendation rules | `pranidoctor-web/src/components/admin/feed-ecosystem/RecommendationRulesEditor.tsx` |

---

**Document owner:** Platform architecture  
**Next review:** After Phase 7 launch sign-off  
**Related plans:** Phase 9 (Doctor Mobile App + ML scale) — to be drafted after Phase 8 MVP
