# Migration Audit Report

**Generated:** 2026-05-30T11:17:00.449Z  
**Migration count:** 59  
**High-risk (P0/P1):** 4  
**Non-reversible:** 4  

## Duplicate timestamps

- `20260509120000`: 20260509120000_knowledge_hub_content, 20260509120000_service_request_booking_enums_fields
- `20260523120000`: 20260523120000_animal_photo_upload_purpose, 20260523120000_phase1_fattening_batches
- `20260529120000`: 20260529120000_notification_user_created_index, 20260529120000_phase4_livestock_feed_ecosystem
- `20260601120000`: 20260601120000_ai_governance_scopes, 20260601120000_phase8_ai_ecosystem

## High-risk migrations

| Folder | Max severity | Flags |
|--------|--------------|-------|
| 20260508195220_prani_doctor_mvp_schema | P1 | DROP_COLUMN, CREATE_INDEX, ENUM_ADD |
| 20260509120000_knowledge_hub_content | P1 | DROP_COLUMN, DROP_CONSTRAINT, SET_NOT_NULL, DROP_INDEX, CREATE_INDEX |
| 20260509120000_service_request_booking_enums_fields | P1 | ALTER_TYPE |
| 20260523220000_phase6_weight_hardening | P1 | DELETE_ROWS, SET_NOT_NULL, CREATE_INDEX |

## Full inventory

| # | Folder | Severity | Reversible |
|---|--------|----------|------------|
| 1 | 20260208120000_init_mvp | P3 | yes |
| 2 | 20260508195220_prani_doctor_mvp_schema | P1 | **no** |
| 3 | 20260508200401_area_hierarchy | P3 | yes |
| 4 | 20260508204007_doctor_management_fields | P3 | yes |
| 5 | 20260508205522_ai_technician_foundation | P3 | yes |
| 6 | 20260508212430_animal_photo_pregnancy_status | P3 | yes |
| 7 | 20260509055822_billing_payment_fields_and_enums | P3 | yes |
| 8 | 20260509080348_mobile_otp_challenge | P3 | yes |
| 9 | 20260509120000_knowledge_hub_content | P1 | **no** |
| 10 | 20260509120000_service_request_booking_enums_fields | P1 | **no** |
| 11 | 20260509180000_mobile_otp_last_sent | P3 | yes |
| 12 | 20260510092800_ai_technician_foundation | P3 | yes |
| 13 | 20260510122449_bd_locations_foundation | P3 | yes |
| 14 | 20260510140000_universal_uploads_foundation | P3 | yes |
| 15 | 20260510145715_add_location_master_fields | P3 | yes |
| 16 | 20260510183000_ai_service_request_decline_reason | P3 | yes |
| 17 | 20260510210000_ai_technician_quality_tables | P3 | yes |
| 18 | 20260511121500_customer_profile_cover_photos | P3 | yes |
| 19 | 20260511133000_location_dedupe_unique_constraints | P3 | yes |
| 20 | 20260511194500_ai_technician_semen_template_system | P3 | yes |
| 21 | 20260511210000_ai_technician_cover_upload | P3 | yes |
| 22 | 20260512120000_mobile_upload_purpose_semen_template_video | P3 | yes |
| 23 | 20260512150000_enterprise_service_instances | P3 | yes |
| 24 | 20260521120000_phase1_auth_audit | P3 | yes |
| 25 | 20260521180000_phase1_refresh_session_device | P3 | yes |
| 26 | 20260521190000_phase1_device_audit_actions | P3 | yes |
| 27 | 20260521200000_phase5_treatment_workflow | P3 | yes |
| 28 | 20260521210000_phase6_ai_veterinary_core | P3 | yes |
| 29 | 20260521220000_phase7_voice_assistant | P3 | yes |
| 30 | 20260521230000_phase8_offline_architecture | P3 | yes |
| 31 | 20260522120000_phase4_milk_records | P3 | yes |
| 32 | 20260522140000_phase4_feed_records | P3 | yes |
| 33 | 20260522160000_phase4_finance_records | P3 | yes |
| 34 | 20260522170000_phase5_health_vaccine_treatment | P3 | yes |
| 35 | 20260522180000_phase6_notification_settings | P3 | yes |
| 36 | 20260522190000_phase6_support_tickets | P3 | yes |
| 37 | 20260522200000_phase8_mobile_user_settings | P3 | yes |
| 38 | 20260522210000_profile_media_thumbs | P3 | yes |
| 39 | 20260523120000_animal_photo_upload_purpose | P3 | yes |
| 40 | 20260523120000_phase1_fattening_batches | P3 | yes |
| 41 | 20260523140000_phase2_weight_records | P3 | yes |
| 42 | 20260523160000_phase3_batch_feeding | P3 | yes |
| 43 | 20260523180000_phase4_batch_roi | P3 | yes |
| 44 | 20260523200000_phase5_qurbani_mode | P3 | yes |
| 45 | 20260523220000_phase6_weight_hardening | P1 | **no** |
| 46 | 20260524120000_farm_inventory_v1 | P3 | yes |
| 47 | 20260524180000_feed_catalog_master_v1 | P3 | yes |
| 48 | 20260529120000_notification_user_created_index | P3 | yes |
| 49 | 20260529120000_phase4_livestock_feed_ecosystem | P3 | yes |
| 50 | 20260530120000_ai_usage_monitoring | P3 | yes |
| 51 | 20260530140000_ai_token_tracking | P3 | yes |
| 52 | 20260530160000_ai_governance_kill_switch | P3 | yes |
| 53 | 20260530180000_legal_consent | P3 | yes |
| 54 | 20260530190000_vet_disclaimer | P3 | yes |
| 55 | 20260601120000_ai_governance_scopes | P3 | yes |
| 56 | 20260601120000_phase8_ai_ecosystem | P3 | yes |
| 57 | 20260601180000_legal_document_registry | P3 | yes |
| 58 | 20260601200000_emergency_limitation | P3 | yes |
| 59 | 20260602120000_ai_production_platform | P3 | yes |