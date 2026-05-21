/// Offline draft + sync contract for treatment workflow mutations.
abstract class TreatmentDraftContract {
  static const boxName = 'treatment_draft_v1';

  static String consultationDraftKey(String caseId) => 'consultation:$caseId';
  static String diagnosisDraftKey(String caseId) => 'diagnosis:$caseId';
  static String prescriptionDraftKey(String caseId) => 'prescription:$caseId';
  static String noteDraftKey(String caseId) => 'note:$caseId';

  Future<void> saveDraft(String key, Map<String, dynamic> payload);

  Future<Map<String, dynamic>?> readDraft(String key);

  Future<void> clearDraft(String key);

  Future<List<String>> listPendingSyncKeys();

  Future<void> markSynced(String key);
}

abstract class TreatmentSyncContract {
  /// Push queued offline drafts to `/api/cases/*` in workflow order.
  Future<void> syncPendingDrafts();

  /// Pull latest aggregate after successful sync.
  Future<void> refreshTreatment(String caseId);
}
