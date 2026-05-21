import 'treatment_dto.dart';

/// Client contract for treatment workflow (`/api/cases/*`).
abstract class TreatmentRepositoryContract {
  Future<TreatmentAggregateDto> getTreatment(String caseId);

  Future<Map<String, dynamic>> startConsultation(
    String caseId, {
    String? observations,
    String? diagnosisSummary,
    List<Map<String, String>>? attachmentRefs,
  });

  Future<Map<String, dynamic>> recordDiagnosis(
    String caseId, {
    required String diagnosis,
    String? chiefComplaint,
    String? symptoms,
    String? procedures,
    String? treatmentNotes,
  });

  Future<Map<String, dynamic>> createPrescription(
    String caseId, {
    String? instructions,
    String? warnings,
    String? validUntil,
    required List<Map<String, String?>> items,
  });

  Future<Map<String, dynamic>> scheduleFollowup(
    String caseId, {
    required String scheduledAt,
    String? reminderNote,
  });

  Future<Map<String, dynamic>> closeTreatment(String caseId, {String? closingNote});

  Future<List<TreatmentNoteDto>> listNotes(String caseId);

  Future<TreatmentNoteDto> createNote(
    String caseId, {
    required String noteType,
    required String content,
  });
}

abstract class TreatmentApiPaths {
  static String treatment(String caseId) => '/api/cases/$caseId/treatment';
  static String consultation(String caseId) => '/api/cases/$caseId/consultation';
  static String diagnosis(String caseId) => '/api/cases/$caseId/diagnosis';
  static String prescription(String caseId) => '/api/cases/$caseId/prescription';
  static String followup(String caseId) => '/api/cases/$caseId/followup';
  static String close(String caseId) => '/api/cases/$caseId/close';
  static String notes(String caseId) => '/api/cases/$caseId/notes';
}
