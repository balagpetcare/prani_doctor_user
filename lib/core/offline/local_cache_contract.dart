/// Local cache keys + TTL for offline-first reads.
abstract class LocalCacheContract {
  static const boxName = 'local_cache_v1';

  static const authSnapshotKey = 'auth_snapshot';
  static const authOtpPendingPrefix = 'auth_otp_pending:';
  static const appConfigKey = 'app_config_snapshot';
  static const profileKey = 'profile_snapshot';
  static const profileAddressKey = 'profile_address_snapshot';
  static const dashboardKey = 'dashboard_snapshot';
  static const farmsListKey = 'farms_list_snapshot';
  static String farmDetailKey(String id) => 'farm_detail:$id';
  static const farmDraftKey = 'farm_draft_new';
  static String farmEditDraftKey(String id) => 'farm_draft:$id';
  static const activeFarmIdKey = 'active_farm_id';
  static const animalsListKey = 'animals_list_snapshot';
  static String animalDetailKey(String id) => 'animal_detail:$id';
  static String profileImageCacheKey(String userId) => 'profile_image:$userId';
  static String animalImageCacheKey(String animalId) => 'animal_image:$animalId';
  static const animalDraftKey = 'animal_draft_new';
  static String animalEditDraftKey(String id) => 'animal_draft:$id';
  static String fatteningBatchesListKey(String farmId) =>
      'fattening_batches_list:$farmId';
  static String fatteningBatchDetailKey(String id) => 'fattening_batch_detail:$id';
  static String fatteningWeightHistoryKey(String batchId) =>
      'fattening_weight_history:$batchId';
  static String fatteningBatchProgressKey(String batchId) =>
      'fattening_batch_progress:$batchId';
  static String fatteningFeedDashboardKey(String batchId) =>
      'fattening_feed_dashboard:$batchId';
  static String fatteningRoiKey(String batchId) => 'fattening_roi:$batchId';
  static String fatteningQurbaniKey(String batchId) =>
      'fattening_qurbani:$batchId';
  static const fatteningBatchDraftKey = 'fattening_batch_draft_new';
  static const batchesListKey = 'batches_list_snapshot';
  static String batchDetailKey(String id) => 'batch_detail:$id';
  static const batchDraftKey = 'batch_draft_new';
  static String batchEditDraftKey(String id) => 'batch_draft:$id';
  static const milkListKey = 'milk_list_snapshot';
  static String milkDetailKey(String id) => 'milk_detail:$id';
  static const milkDraftKey = 'milk_draft_new';
  static String milkEditDraftKey(String id) => 'milk_draft:$id';
  static String milkSummaryKey(String key) => 'milk_summary:$key';
  static const milkChartsKey = 'milk_charts_snapshot';
  static const feedsListKey = 'feeds_list_snapshot';
  static String feedDetailKey(String id) => 'feed_detail:$id';
  static const feedDraftKey = 'feed_draft_new';
  static String feedEditDraftKey(String id) => 'feed_draft:$id';
  static const feedCostKey = 'feed_cost_snapshot';
  static const feedAnalyticsKey = 'feed_analytics_snapshot';
  static String inventorySummaryKey(String farmRef) =>
      'inventory_summary:$farmRef';
  static const inventoryFeedCreateDraftKey = 'inventory_feed_create_draft';
  static String inventoryFeedListKey(String farmRef) =>
      'inventory_feed_list:$farmRef';
  static String inventoryMedicineListKey(String farmRef) =>
      'inventory_medicine_list:$farmRef';
  static const financeExpensesListKey = 'finance_expenses_list_snapshot';
  static const financeIncomeListKey = 'finance_income_list_snapshot';
  static String financeExpenseDetailKey(String id) =>
      'finance_expense_detail:$id';
  static String financeIncomeDetailKey(String id) =>
      'finance_income_detail:$id';
  static const financeExpenseDraftKey = 'finance_expense_draft_new';
  static String financeExpenseEditDraftKey(String id) =>
      'finance_expense_draft:$id';
  static const financeIncomeDraftKey = 'finance_income_draft_new';
  static String financeIncomeEditDraftKey(String id) =>
      'finance_income_draft:$id';
  static const financeProfitKey = 'finance_profit_snapshot';
  static const financeChartsKey = 'finance_charts_snapshot';
  static const financeReportsKey = 'finance_reports_snapshot';
  static const healthHistoryListKey = 'health_history_list_snapshot';
  static const healthTimelineKey = 'health_timeline_snapshot';
  static String healthDetailKey(String id) => 'health_detail:$id';
  static const healthDraftKey = 'health_draft_new';
  static String healthEditDraftKey(String id) => 'health_draft:$id';
  static const vaccinesListKey = 'vaccines_list_snapshot';
  static const vaccineRemindersKey = 'vaccine_reminders_snapshot';
  static String vaccineDetailKey(String id) => 'vaccine_detail:$id';
  static const vaccineDraftKey = 'vaccine_draft_new';
  static String vaccineEditDraftKey(String id) => 'vaccine_draft:$id';
  static const treatmentsListKey = 'treatments_list_snapshot';
  static String treatmentDetailKey(String id) => 'treatment_detail:$id';
  static const treatmentDraftKey = 'treatment_draft_new';
  static String treatmentEditDraftKey(String id) => 'treatment_draft:$id';
  static const supportTicketsListKey = 'support_tickets_list_snapshot';
  static String supportTicketDetailKey(String id) =>
      'support_ticket_detail:$id';
  static const supportHelpKey = 'support_help_snapshot';
  static const supportCreateDraftKey = 'support_create_draft';
  static const aiActiveSessionKey = 'ai_active_session';
  static String aiConversationKey(String sessionId) =>
      'ai_conversation:$sessionId';
  static const aiDraftKey = 'ai_draft_input';
  static const aiSettingsKey = 'ai_settings';
  static const userSettingsKey = 'user_settings_snapshot';
  static const privacyDocumentKey = 'privacy_document_snapshot';
  static const termsDocumentKey = 'terms_document_snapshot';
  static const aiConsentDocumentKey = 'ai_consent_document_snapshot';
  static const aiDisclaimerKey = 'ai_disclaimer_snapshot';
  static const aiEscalationDisclosureKey = 'ai_escalation_disclosure_snapshot';
  static const vetDisclaimerKey = 'vet_disclaimer_snapshot';
  static const emergencyLimitationKey = 'emergency_limitation_snapshot';
  static const serviceRequestsListKey = 'service_requests:list';
  static const notificationsListKey = 'notifications_list_snapshot';
  static const notificationsUnreadCountKey =
      'notifications_unread_count_snapshot';
  static const notificationSettingsKey = 'notification_settings_snapshot';
  static String areaSeedKey(String locale) => 'area_seed:$locale';
  static String caseDraftKey(String caseId) => 'case_draft:$caseId';
  static String voiceDraftKey(String sessionId) => 'voice_draft:$sessionId';

  // Phase 4 livestock / feed ecosystem
  static String livestockListKey(String farmRef) => 'livestock_list:$farmRef';
  static String livestockDetailKey(String id) => 'livestock_detail:$id';
  static const livestockDraftKey = 'livestock_draft_new';
  static String livestockEditDraftKey(String id) => 'livestock_draft:$id';
  static String livestockTimelineKey(String id) => 'livestock_timeline:$id';
  static String phase4FeedItemsKey(String farmRef) => 'phase4_feed_items:$farmRef';
  static String phase4FeedItemDetailKey(String id) => 'phase4_feed_item:$id';
  static String phase4FeedInventoryKey(String farmRef) =>
      'phase4_feed_inventory:$farmRef';
  static String phase4FeedConsumptionKey(String farmRef) =>
      'phase4_feed_consumption:$farmRef';
  static String phase4RecommendationKey(String livestockId, String date) =>
      'phase4_recommendation:$livestockId:$date';
  static String phase4AnalyticsDashboardKey(String farmRef, String range) =>
      'phase4_analytics_dashboard:$farmRef:$range';
  static const phase4FeedPurchaseDraftKey = 'phase4_feed_purchase_draft';
  static const phase4FeedConsumptionDraftKey = 'phase4_feed_consumption_draft';

  static const authTtl = Duration(hours: 24);
  static const appConfigTtl = Duration(hours: 12);
  static const areaTtl = Duration(days: 7);
  static const caseDraftTtl = Duration(days: 30);
  static const voiceDraftTtl = Duration(days: 7);
  static const profileTtl = Duration(minutes: 30);
  static const dashboardTtl = Duration(minutes: 30);
  static const dataTtl = Duration(minutes: 30);

  Future<void> write(String key, Map<String, dynamic> payload, Duration ttl);

  Future<Map<String, dynamic>?> read(String key);

  Future<void> evictExpired();

  /// Never evict keys listed in pending sync queue.
  Future<void> evictLru({
    required Set<String> protectedKeys,
    required int quotaBytes,
  });
}
