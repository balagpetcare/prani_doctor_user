abstract final class AiDoctorApiPaths {
  AiDoctorApiPaths._();

  static const createCase = '/api/ai/doctor/cases';
  static String caseDetail(String caseId) => '/api/ai/doctor/cases/$caseId';
  static String intake(String caseId) => '/api/ai/doctor/cases/$caseId/intake';
  static String analyze(String caseId) => '/api/ai/doctor/cases/$caseId/analyze';
  static String escalate(String caseId) => '/api/ai/doctor/cases/$caseId/escalate';
  static const assistant = '/api/ai/assistants/ai-doctor';
}
