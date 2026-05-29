# Farm Inventory V1 — Risk Report

**Date:** 2026-05-24

---

## Risk matrix

| ID | Risk | Severity | Likelihood | Mitigation | Status |
|----|------|----------|------------|------------|--------|
| R1 | Feed deduct + feed create not in single DB transaction | Medium | Medium | Roll back feed row if stock fails; idempotent stock via `feed:{feedRecordId}` | Mitigated |
| R2 | Medicine consumed without real clinical event | High | Low | `consume` requires clinical `sourceType`; treatment id validated for `FARM_TREATMENT` | Mitigated |
| R3 | Farmer creates duplicate catalog names | Low | Medium | Unique constraint per farm+type+name | Mitigated |
| R4 | Double-count opening stock | Medium | Low | CREATE_ITEM starts balance at 0 then RECEIPT movement | Mitigated |
| R5 | `farmRef` mismatch across features | Medium | Medium | All APIs require `farmRef`; feed deduct requires `farmRef` when `deductStock` | Partial |
| R6 | Idempotency key collision across ops | Low | Low | Unique per customer on transactions | Mitigated |
| R7 | Negative stock with `allowNegativeStock` | Low | Low | Explicit flag per item | Accepted |
| R8 | `FarmTreatment` still allows farmer-entered medicines (clinical) | Medium | High | Inventory separated; consumption needs `sourceId` | Accepted (product) |
| R9 | PRESCRIPTION_ITEM consumption without doctor RBAC | High | Medium | Mobile customer can call consume with `PRESCRIPTION_ITEM` if they know id | **Open** |
| R10 | Legacy route import path depth | Low | Low | Test routes after deploy | Verify on deploy |

---

## BLOCKER / follow-up

### R9 — Medicine consumption authorization (V1.2)

`POST /inventory/consume` with `sourceType: PRESCRIPTION_ITEM` is accepted for any authenticated mobile customer if they supply a valid `sourceId`. Planning doc required doctor/service RBAC before clinical consumption.

**Recommendation:** Gate `PRESCRIPTION_ITEM`, `TREATMENT_CASE`, `AI_PLAN` behind service token or doctor session in Phase 4.

---

## SAFE ✅

- Existing feed APIs without new fields
- Additive schema
- No prescription generation endpoints
- Medicine create rejects obvious prescription/diagnosis keywords in notes/name

---

## WARNING ⚠️

- Feed/stock not atomic — brief window if crash between create and consume
- Opening balance for existing farms is manual
- Flutter not implemented — APIs unused until client ships

---

## Monitoring suggestions

- Log `INSUFFICIENT_STOCK` rate on feed create
- Alert on failed feed rollback (feed deleted after stock error)
- Track `InventoryAuditLog` volume growth
