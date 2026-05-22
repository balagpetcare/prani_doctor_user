# USER_APP_14 — Treatment Module Report

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_14_TREATMENT`  
**Status:** Complete  
**Date:** 2026-05-22

## Summary

Delivered treatment list, detail with prescription viewer and medicine cards, and form with offline cache and outbox sync.

## Flutter module

```
lib/features/treatment/
├── data/
│   ├── treatment_api_paths.dart
│   ├── treatment_dto.dart
│   ├── treatment_validation.dart
│   ├── treatment_repository_contract.dart
│   └── treatment_repository.dart
└── presentation/
    ├── treatment_providers.dart
    ├── treatment_list_page.dart
    ├── treatment_detail_page.dart
    ├── treatment_form_page.dart
    └── widgets/
        ├── treatment_feedback.dart
        ├── treatment_record_card.dart
        ├── treatment_labels.dart
        └── medicine_card.dart
```

## Integration

- `prescriptionProvider` for prescription/medicines on detail screen
- Outbox, sync, routes, l10n, startup cache warm
- Unit tests: `test/treatment/treatment_integration_test.dart`
