abstract final class AiPhase8ApiPaths {
  AiPhase8ApiPaths._();

  static const symptomTaxonomy = '/api/ai/symptom-taxonomy';
  static const symptomCheck = '/api/ai/symptom-check';
  static const knowledgeSearch = '/api/ai/knowledge/search';
  static String knowledgeDetail(String slug) => '/api/ai/knowledge/$slug';
  static const smartRecommendations = '/api/ai/smart-recommendations';
  static String dismissRecommendation(String id) =>
      '/api/ai/smart-recommendations/$id/dismiss';
  static String completeRecommendation(String id) =>
      '/api/ai/smart-recommendations/$id/complete';
  static const smartAlerts = '/api/ai/smart-alerts';
  static String dismissAlert(String id) => '/api/ai/smart-alerts/$id/dismiss';
  static const farmHealth = '/api/ai/farm-health';
  static const farmBriefing = '/api/ai/briefing/daily';
  static const farmQuery = '/api/ai/farm-query';
  static const followUps = '/api/ai/follow-ups';
  static String dismissFollowUp(String id) => '/api/ai/follow-ups/$id/dismiss';
  static const farmRisk = '/api/ai/analytics/farm-risk';
  static const chatV2 = '/api/ai/chat/v2';
}
