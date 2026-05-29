/// Typed route paths for go_router.
abstract final class AppRoutes {
  AppRoutes._();

  static const boot = '/boot';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const farms = '/farms';
  static const farmCreate = '/farms/create';
  static String farmDetail(String id) => '/farms/$id';
  static String farmEdit(String id) => '/farms/$id/edit';
  static String farmSettings(String id) => '/farms/$id/settings';
  static String farmFattening(String farmId) => '/farms/$farmId/fattening';
  static String fatteningCreate(String farmId) =>
      '/farms/$farmId/fattening/create';
  static String fatteningBatchDetail(String farmId, String batchId) =>
      '/farms/$farmId/fattening/$batchId';
  static String fatteningAddAnimals(String farmId, String batchId) =>
      '/farms/$farmId/fattening/$batchId/animals';
  static String fatteningBatchProgress(String farmId, String batchId) =>
      '/farms/$farmId/fattening/$batchId/progress';
  static String fatteningBatchFeed(String farmId, String batchId) =>
      '/farms/$farmId/fattening/$batchId/feed-dashboard';
  static String fatteningLogFeed(String farmId, String batchId) =>
      '/farms/$farmId/fattening/$batchId/log-feed';
  static String fatteningBatchRoi(String farmId, String batchId) =>
      '/farms/$farmId/fattening/$batchId/roi';
  static String fatteningBatchQurbani(String farmId, String batchId) =>
      '/farms/$farmId/fattening/$batchId/qurbani';
  static String fatteningWeightEntry(
    String farmId,
    String batchId, {
    String? animalId,
  }) {
    final base = '/farms/$farmId/fattening/$batchId/weight';
    if (animalId == null || animalId.isEmpty) return base;
    return '$base?animalId=$animalId';
  }

  static String fatteningWeightHistory(String farmId, String batchId) =>
      '/farms/$farmId/fattening/$batchId/weight/history';
  static const animals = '/animals';
  static const animalCreate = '/animals/create';
  static String animalDetail(String id) => '/animals/$id';
  static String animalEdit(String id) => '/animals/$id/edit';
  static const ecosystemHub = '/ecosystem';
  static const livestock = '/livestock';
  static const livestockCreate = '/livestock/create';
  static String livestockDetail(String id) => '/livestock/$id';
  static String livestockEdit(String id) => '/livestock/$id/edit';
  static String livestockTimeline(String id) => '/livestock/$id/timeline';
  static String livestockQr(String id) => '/livestock/$id/qr';
  static const phase4FeedHub = '/feed-ecosystem';
  static const phase4FeedItems = '/feed-ecosystem/items';
  static String phase4FeedItemDetail(String id) => '/feed-ecosystem/items/$id';
  static const phase4FeedInventory = '/feed-ecosystem/inventory';
  static const phase4FeedPurchase = '/feed-ecosystem/purchase';
  static const phase4FeedConsumption = '/feed-ecosystem/consumption';
  static String dailyRation(String livestockId) =>
      '/recommendations/$livestockId';
  static const livestockAnalytics = '/analytics/livestock';
  static const feedEfficiency = '/analytics/livestock/feed-efficiency';
  static const batches = '/batches';
  static const batchCreate = '/batches/create';
  static String batchDetail(String id) => '/batches/$id';
  static String batchEdit(String id) => '/batches/$id/edit';
  static const milk = '/milk';
  static const milkCreate = '/milk/create';
  static String milkDetail(String id) => '/milk/$id';
  static String milkEdit(String id) => '/milk/$id/edit';
  static const milkSummary = '/milk/summary';
  static const milkCharts = '/milk/charts';
  static const feeds = '/feeds';
  static const feedCreate = '/feeds/create';
  static String feedDetail(String id) => '/feeds/$id';
  static String feedEdit(String id) => '/feeds/$id/edit';
  static const feedCost = '/feeds/cost';
  static const feedAnalytics = '/feeds/analytics';
  static const inventory = '/inventory';
  static const inventoryFeed = '/inventory/feed';
  static const inventoryFeedCreate = '/inventory/feed/create';
  static String inventoryFeedDetail(String id) => '/inventory/feed/$id';
  static String inventoryFeedReceipt(String id) =>
      '/inventory/feed/$id/receipt';
  static const inventoryMedicine = '/inventory/medicine';
  static const inventoryMedicineCreate = '/inventory/medicine/create';
  static String inventoryMedicineDetail(String id) => '/inventory/medicine/$id';
  static String inventoryMedicineReceipt(String id) =>
      '/inventory/medicine/$id/receipt';
  static const inventoryConsumptionHistory = '/inventory/consumption-history';
  static const finance = '/finance';
  static const financeReports = '/finance/reports';
  static const financeExpenses = '/finance/expenses';
  static const financeExpenseCreate = '/finance/expenses/create';
  static String financeExpenseDetail(String id) => '/finance/expenses/$id';
  static String financeExpenseEdit(String id) => '/finance/expenses/$id/edit';
  static const financeIncome = '/finance/income';
  static const financeIncomeCreate = '/finance/income/create';
  static String financeIncomeDetail(String id) => '/finance/income/$id';
  static String financeIncomeEdit(String id) => '/finance/income/$id/edit';
  static const financeProfit = '/finance/profit';
  static const health = '/health';
  static const healthHistory = '/health/history';
  static const healthRecords = '/health/records';
  static const healthTimeline = '/health/timeline';
  static const healthAnalytics = '/health/analytics';
  static const healthCreate = '/health/create';
  static String healthDetail(String id) => '/health/$id';
  static String healthEdit(String id) => '/health/$id/edit';
  static const vaccines = '/vaccines';
  static const vaccineSchedule = '/vaccines/schedule';
  static const vaccineHistory = '/vaccines/history';
  static const vaccineCalendar = '/vaccines/calendar';
  static const vaccineReminders = '/vaccines/reminders';
  static const vaccineCreate = '/vaccines/create';
  static String vaccineDetail(String id) => '/vaccines/$id';
  static String vaccineEdit(String id) => '/vaccines/$id/edit';
  static const treatments = '/treatments';
  static const treatmentList = '/treatments/list';
  static const treatmentTimeline = '/treatments/timeline';
  static const treatmentMedicinePlan = '/treatments/medicine-plan';
  static const treatmentFollowUp = '/treatments/follow-up';
  static const treatmentCreate = '/treatments/create';
  static String treatmentDetail(String id) => '/treatments/$id';
  static String treatmentEdit(String id) => '/treatments/$id/edit';
  static String treatmentPrescription(String id) =>
      '/treatments/$id/prescription';
  static const support = '/support';
  static const supportTickets = '/support/tickets';
  static const supportTicketCreate = '/support/tickets/create';
  static String supportTicketDetail(String id) => '/support/tickets/$id';
  static const supportHelp = '/support/help';
  static const supportFaq = '/support/faq';
  static const supportContact = '/support/contact';
  static const supportAttachmentView = '/support/attachment';
  static const ai = '/ai';
  static const aiChat = '/home/ai-chat';
  static const aiVoiceInput = '/home/ai-chat/voice';
  static const aiHistory = '/ai/history';
  static const aiSettings = '/ai/settings';
  static const aiResult = '/ai/result';
  static const aiSymptomChecker = '/ai/symptom-check';
  static const aiSmartRecommendations = '/ai/recommendations';
  static const aiFarmHealth = '/ai/farm-health';
  static const aiSmartAlerts = '/ai/alerts';
  static const aiKnowledgeSearch = '/ai/knowledge';
  static const aiFollowUps = '/ai/follow-ups';
  static const services = '/services';
  static const inbox = '/inbox';
  static const notifications = '/notifications';
  static const notificationPermission = '/notifications/permission';
  static const notificationDeepLink = '/notifications/open';
  static String notificationDetail(String id) => '/notifications/$id';
  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';
  static const settingsProfileEdit = '/settings/profile/edit';
  static const settingsProfileAppearance = '/settings/profile/edit';
  static const settingsPersonalInfo = '/settings/account/personal-info';
  static const settingsProfileAddress = '/settings/profile/address';
  static const settingsProfileLanguage = '/settings/profile/language';
  static const settingsProfileComplete = '/settings/profile/complete';
  static const settingsProfileChangePassword =
      '/settings/profile/change-password';
  static const settingsNotifications = '/settings/notifications';
  static const reconsent = '/reconsent';
  static const settingsPrivacy = '/settings/privacy';
  static const settingsAiConsent = '/settings/ai-consent';
  static const settingsTerms = '/settings/terms';
  static const settingsAccount = '/settings/account';
  static const settingsPreferences = '/settings/preferences';
  static const settingsApp = '/settings/app';
  static const settingsLanguage = '/settings/language';
  static const settingsTheme = '/settings/theme';
  static const settingsAbout = '/settings/about';
  static const settingsDataSync = '/settings/data-sync';
  static const settingsConnection = '/settings/connection';
  static String doctorDetail(String id) => '/services/doctor/$id';
  static String bookConsultation(String doctorId) =>
      '/services/doctor/$doctorId/book';
  static String serviceRequestDetail(String id) => '/inbox/request/$id';
  static String serviceRequestHistory(String id) =>
      '/inbox/request/$id/history';
  static const marketplace = '/marketplace';
  static const community = '/community';
  static const orders = '/orders';
  static const search = '/search';
}
