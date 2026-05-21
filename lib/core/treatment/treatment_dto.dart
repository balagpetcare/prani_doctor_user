/// Treatment workflow DTOs — mirrors GET/POST /api/cases/* foundation responses.
class TreatmentConsultationDto {
  const TreatmentConsultationDto({
    required this.id,
    this.observations,
    this.diagnosisSummary,
    this.attachmentRefs,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? observations;
  final String? diagnosisSummary;
  final List<dynamic>? attachmentRefs;
  final String createdAt;
  final String updatedAt;

  factory TreatmentConsultationDto.fromJson(Map<String, dynamic> json) {
    return TreatmentConsultationDto(
      id: json['id'] as String,
      observations: json['observations'] as String?,
      diagnosisSummary: json['diagnosisSummary'] as String?,
      attachmentRefs: json['attachmentRefs'] as List<dynamic>?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class TreatmentDiagnosisDto {
  const TreatmentDiagnosisDto({
    required this.treatmentCaseId,
    required this.status,
    this.chiefComplaint,
    this.symptoms,
    this.diagnosis,
    this.procedures,
    this.treatmentNotes,
    required this.recordedAt,
    required this.updatedAt,
  });

  final String treatmentCaseId;
  final String status;
  final String? chiefComplaint;
  final String? symptoms;
  final String? diagnosis;
  final String? procedures;
  final String? treatmentNotes;
  final String recordedAt;
  final String updatedAt;

  factory TreatmentDiagnosisDto.fromJson(Map<String, dynamic> json) {
    return TreatmentDiagnosisDto(
      treatmentCaseId: json['treatmentCaseId'] as String,
      status: json['status'] as String,
      chiefComplaint: json['chiefComplaint'] as String?,
      symptoms: json['symptoms'] as String?,
      diagnosis: json['diagnosis'] as String?,
      procedures: json['procedures'] as String?,
      treatmentNotes: json['treatmentNotes'] as String?,
      recordedAt: json['recordedAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class TreatmentPrescriptionItemDto {
  const TreatmentPrescriptionItemDto({
    required this.id,
    required this.medicineName,
    this.dosage,
    this.duration,
    this.instruction,
    this.quantity,
  });

  final String id;
  final String medicineName;
  final String? dosage;
  final String? duration;
  final String? instruction;
  final String? quantity;

  factory TreatmentPrescriptionItemDto.fromJson(Map<String, dynamic> json) {
    return TreatmentPrescriptionItemDto(
      id: json['id'] as String,
      medicineName: json['medicineName'] as String,
      dosage: json['dosage'] as String?,
      duration: json['duration'] as String?,
      instruction: json['instruction'] as String?,
      quantity: json['quantity'] as String?,
    );
  }
}

class TreatmentPrescriptionDto {
  const TreatmentPrescriptionDto({
    required this.id,
    required this.status,
    this.instructions,
    this.warnings,
    this.validUntil,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String status;
  final String? instructions;
  final String? warnings;
  final String? validUntil;
  final String createdAt;
  final List<TreatmentPrescriptionItemDto> items;

  factory TreatmentPrescriptionDto.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return TreatmentPrescriptionDto(
      id: json['id'] as String,
      status: json['status'] as String,
      instructions: json['instructions'] as String?,
      warnings: json['warnings'] as String?,
      validUntil: json['validUntil'] as String?,
      createdAt: json['createdAt'] as String,
      items: itemsJson
          .map((e) => TreatmentPrescriptionItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TreatmentFollowupDto {
  const TreatmentFollowupDto({
    required this.id,
    required this.scheduledAt,
    this.reminderNote,
    required this.status,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String scheduledAt;
  final String? reminderNote;
  final String status;
  final String? completedAt;
  final String createdAt;

  factory TreatmentFollowupDto.fromJson(Map<String, dynamic> json) {
    return TreatmentFollowupDto(
      id: json['id'] as String,
      scheduledAt: json['scheduledAt'] as String,
      reminderNote: json['reminderNote'] as String?,
      status: json['status'] as String,
      completedAt: json['completedAt'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}

class TreatmentAggregateDto {
  const TreatmentAggregateDto({
    required this.caseId,
    required this.workflowId,
    required this.workflowStatus,
    this.closedAt,
    required this.consultations,
    this.diagnosis,
    required this.prescriptions,
    required this.followups,
  });

  final String caseId;
  final String workflowId;
  final String workflowStatus;
  final String? closedAt;
  final List<TreatmentConsultationDto> consultations;
  final TreatmentDiagnosisDto? diagnosis;
  final List<TreatmentPrescriptionDto> prescriptions;
  final List<TreatmentFollowupDto> followups;

  factory TreatmentAggregateDto.fromJson(Map<String, dynamic> json) {
    return TreatmentAggregateDto(
      caseId: json['caseId'] as String,
      workflowId: json['workflowId'] as String,
      workflowStatus: json['workflowStatus'] as String,
      closedAt: json['closedAt'] as String?,
      consultations: (json['consultations'] as List<dynamic>? ?? [])
          .map((e) => TreatmentConsultationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      diagnosis: json['diagnosis'] == null
          ? null
          : TreatmentDiagnosisDto.fromJson(json['diagnosis'] as Map<String, dynamic>),
      prescriptions: (json['prescriptions'] as List<dynamic>? ?? [])
          .map((e) => TreatmentPrescriptionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      followups: (json['followups'] as List<dynamic>? ?? [])
          .map((e) => TreatmentFollowupDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TreatmentNoteDto {
  const TreatmentNoteDto({
    required this.id,
    required this.noteType,
    required this.content,
    required this.authorDoctorId,
    required this.createdAt,
  });

  final String id;
  final String noteType;
  final String content;
  final String authorDoctorId;
  final String createdAt;

  factory TreatmentNoteDto.fromJson(Map<String, dynamic> json) {
    return TreatmentNoteDto(
      id: json['id'] as String,
      noteType: json['noteType'] as String,
      content: json['content'] as String,
      authorDoctorId: json['authorDoctorId'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}
