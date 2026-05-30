import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_delegate.dart';
import 'localization_loader.dart';
import 'localization_format.dart';

// ignore_for_file: type=lint

/// Typed localization API generated from lib/l10n/app_en.arb.
abstract class AppLocalizations {
  AppLocalizations(this._localeCode)
      : localeName = intl.Intl.canonicalizedLocale(_localeCode);

  final String _localeCode;

  /// BCP-47 language code (`bn`, `en`).
  String get localeCode => _localeCode;

  final String localeName;

  @protected
  String tr(String key, [Map<String, Object?>? args]) => LocalizationFormat.format(
        LocalizationLoader.lookup(_localeCode, key),
        args,
      );

  /// Dynamic key lookup (`context.tr.translate(TranslationKeys.x)`).
  String translate(String key, [Map<String, Object?>? args]) => tr(key, args);

  /// Maps API error [code] to localized text; falls back to [code] if unknown.
  String apiError(String code) {
    final normalized = code.trim();
    if (normalized.isEmpty) return tr('errorGeneric');
    final key = 'api_error_${normalized.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')}';
    final value = tr(key);
    if (value != key) return value;
    return tr('errorGeneric');
  }

  String get errorGeneric => tr('errorGeneric');
  String get errorGenericTitle => tr('errorGenericTitle');
  String get errorSessionExpiredTitle => tr('errorSessionExpiredTitle');
  String get errorPermissionDeniedTitle => tr('errorPermissionDeniedTitle');
  String get errorNotFoundTitle => tr('errorNotFoundTitle');
  String get errorSettingsUnavailableTitle => tr('errorSettingsUnavailableTitle');
  String get errorServiceUnavailableTitle => tr('errorServiceUnavailableTitle');
  String get errorServerTitle => tr('errorServerTitle');
  String get errorNetworkTitle => tr('errorNetworkTitle');
  String get errorSettingsLoadTitle => tr('errorSettingsLoadTitle');

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      appLocalizationsDelegate;

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  String get appTitle;

  String get navHome;

  String get navServices;

  String get navInbox;

  String get navSettings;

  String get drawerTitle;

  String get drawerFarmSection;

  String get drawerFatteningSection;

  String get fatteningListTitle;

  String get fatteningCreateBatch;

  String get fatteningBatchDetail;

  String get fatteningBatchName;

  String get fatteningBatchGoal;

  String get fatteningTargetDate;

  String get fatteningTargetDateOptional;

  String get fatteningStartDate;

  String get fatteningSaveAndAddAnimals;

  String get fatteningAddAnimals;

  String get fatteningStartBatch;

  String get fatteningFilterAll;

  String get fatteningFilterDraft;

  String get fatteningFilterActive;

  String get fatteningNoAnimalsYet;

  String get fatteningNoCattleAvailable;

  String fatteningAddSelectedAnimals(int count);

  String fatteningAnimalsInBatch(int count);

  String get fatteningStartRequiresOnline;

  String get fatteningStartConfirmTitle;

  String get fatteningStartConfirmMessage;

  String get fatteningStartedSuccess;

  String get fatteningWeightEntryTitle;

  String get fatteningProgressTitle;

  String get fatteningRecordWeight;

  String get fatteningWeightKgLabel;

  String get fatteningWeightInvalid;

  String get fatteningRecordedDate;

  String get fatteningWeightNote;

  String get fatteningSaveWeight;

  String get fatteningProgressSummary;

  String get fatteningNoProgressYet;

  String get fatteningWeightHistory;

  String get fatteningWeightMethod;

  String get fatteningWeightMethodScale;

  String get fatteningWeightMethodTape;

  String get fatteningWeightMethodEstimate;

  String get fatteningWeightMethodOther;

  String get fatteningWeightSaved;

  String get fatteningWeightSavedOffline;

  String get fatteningWeightDuplicateDay;

  String get fatteningAvgCurrentWeight;

  String get fatteningTotalGain;

  String get fatteningGrowthChart;

  String get fatteningNoWeightHistory;

  String get fatteningInitialWeight;

  String get fatteningCurrentWeight;

  String get fatteningGain;

  String get fatteningFeedDashboardTitle;

  String get fatteningFeedCostSection;

  String get fatteningDailyFeedSection;

  String get fatteningTotalFeedCost;

  String get fatteningTodayFeedCost;

  String get fatteningTodayFeedAmount;

  String get fatteningAvgDailyFeed;

  String fatteningPlannedAmount(double amount);

  String get fatteningDailyCostChart;

  String get fatteningNoFeedData;

  String get fatteningLogFeed;

  String get fatteningSaveFeed;

  String get fatteningEditFeedPlan;

  String get fatteningPlanModeNormal;

  String get fatteningPlanModeFattening;

  String get fatteningPlanDailyAmount;

  String get fatteningPlanDailyCost;

  String get fatteningSavePlan;

  String get fatteningPlanSaved;

  String get fatteningRoiTitle;

  String get fatteningRoiCostSection;

  String get fatteningRoiPurchase;

  String get fatteningRoiFeed;

  String get fatteningRoiTreatment;

  String get fatteningRoiTreatmentHint;

  String get fatteningRoiTotalCost;

  String get fatteningRoiProjectedSale;

  String get fatteningRoiProfit;

  String fatteningRoiMargin(double pct);

  String fatteningRoiRecordCount(int count);

  String get fatteningEditRoi;

  String get fatteningSaveRoi;

  String get fatteningRoiSaved;

  String get fatteningBatchGoalType;

  String get fatteningGoalTypeNormal;

  String get fatteningGoalTypeQurbani;

  String get fatteningQurbaniTargetRequired;

  String get fatteningQurbaniTitle;

  String get fatteningQurbaniCountdown;

  String fatteningQurbaniDaysLabel(int days);

  String fatteningQurbaniTargetOn(String date);

  String get fatteningQurbaniSetTargetDate;

  String get fatteningQurbaniReadiness;

  String get fatteningQurbaniStatusReady;

  String get fatteningQurbaniStatusAtRisk;

  String get fatteningQurbaniStatusOverdue;

  String get fatteningQurbaniStatusNotStarted;

  String get fatteningQurbaniStatusOnTrack;

  String fatteningQurbaniWeightProgress(double pct);

  String fatteningQurbaniTimeProgress(double pct);

  String get fatteningQurbaniAnimals;

  String fatteningQurbaniAnimalProgress(String current, int target, double pct);

  String fatteningWeightRecordCount(int count);

  String get drawerMilkSection;

  String get drawerAnimalsSection;

  String get drawerRecordsSection;

  String get drawerFarmDashboard;

  String get drawerGrowthRecords;

  String get exitAppTitle;

  String get exitAppMessage;

  String get exitAppConfirm;

  String get logoutConfirmTitle;

  String get logoutConfirmMessage;

  String get loginTitle;

  String get loginWelcomeBack;

  String get loginWelcomeSubtitle;

  String loginLastLogin(String identifier);

  String get authGoogleSignIn;

  String get authGoogleComingSoon;

  String get loginDevContinue;

  String get registerTitle;

  String get registerTermsCheckbox;

  String get registerTermsRequired;

  String get authTabOtp;

  String get authTabPassword;

  String get phoneLabel;

  String get otpCodeLabel;

  String get sendOtp;

  String get verifyOtp;

  String get identifierLabel;

  String get passwordLabel;

  String get signIn;

  String get nameLabel;

  String get emailOptionalLabel;

  String get createAccount;

  String get noAccountPrompt;

  String get registerLink;

  String get hasAccountPrompt;

  String get loginLink;

  String get signOut;

  String get darkMode;

  String get otpSent;

  String get fieldRequired;

  String get editProfile;

  String get profileEditTitle;

  String get saveProfile;

  String get profileLoadError;

  String get profileEmpty;

  String get profileTitle;

  String get profileIncomplete;

  String get profileAccountInfoTitle;

  String get profileCompletionTitle;

  String get profileCompletionSubtitle;

  String get profileCompletionNameStep;

  String get profileCompletionAddressStep;

  String get profileCompletionPhotoStep;

  String get profileCompletionOptional;

  String get profileCompletionContinue;

  String get profileCompletionHint;

  String get profileChangePasswordTitle;

  String get profileChangePasswordBody;

  String get profileChangePasswordForgotLink;

  String get profileNameTooLong;

  String get profileEmailTooLong;

  String get profileAddressLineTooLong;

  String get profilePostalTooLong;

  String get addressTitle;

  String get addressLineLabel;

  String get postalCodeLabel;

  String get addressRequired;

  String get addressHierarchyRequired;

  String get areaVillageOptionalHelper;

  String get areaVillageNotFoundOptional;

  String get areaVillageManualHint;

  String get languageTitle;

  String get languageBangla;

  String get languageEnglish;

  String get areaRetry;

  String get areaOfflineHint;

  String get areaEmptyDivisions;

  String get areaEmptyDistricts;

  String get areaEmptyUpazilas;

  String get areaEmptyUnions;

  String get areaEmptyVillages;

  String get areaSearchHint;

  String get areaSearchNoResults;

  String get areaSearchVillagesTitle;

  String get areaSelectedLocation;

  String get areaSelectLevel;

  String get areaRefresh;

  String get locationSectionTitle;

  String get divisionLabel;

  String get districtLabel;

  String get upazilaLabel;

  String get unionLabel;

  String get villageLabel;

  String get findDoctors;

  String get filterEmergency;

  String get filterOnline;

  String get filterHomeVisit;

  String get filterByArea;

  String get noDoctorsFound;

  String get doctorDetails;

  String get availability;

  String get emergencyAvailable;

  String get searchEmergencySubtitle;

  String get onlineConsultation;

  String get homeVisit;

  String get aboutDoctor;

  String get experienceYears;

  String get servicesOffered;

  String get consultationFee;

  String get bookConsultation;

  String get selectAnimal;

  String get symptomsLabel;

  String get preferredTimeLabel;

  String get preferredTimeRequired;

  String get submitBooking;

  String get bookingSubmitted;

  String get addAnimalFirst;

  String get categoryMissing;

  String get appointmentsTitle;

  String get noAppointments;

  String get appointmentDetails;

  String get appointmentHistory;

  String get appointmentSummary;

  String get assignedDoctor;

  String get awaitingAssignment;

  String get trackStatus;

  String get viewHistory;

  String get noHistoryYet;

  String get segmentActive;

  String get segmentCompleted;

  String get segmentClosed;

  String get segmentAll;

  String get serviceTypeLabel;

  String get categoryLabel;

  String get providerLabel;

  String get submittedAtLabel;

  String get assignedAtLabel;

  String get startedAtLabel;

  String get completedAtLabel;

  String get cancelledAtLabel;

  String get cancelAppointment;

  String get cancelReasonLabel;

  String get keepAppointment;

  String get confirmCancel;

  String get appointmentCancelled;

  String get statusPending;

  String get statusAssigned;

  String get statusAccepted;

  String get statusInProgress;

  String get statusCompleted;

  String get statusCancelled;

  String get statusRejected;

  String get aiService;

  String get eventCreated;

  String get eventAssigned;

  String get eventReassigned;

  String get eventAccepted;

  String get eventRejected;

  String get eventStarted;

  String get eventNoteAdded;

  String get eventCaseOpened;

  String get eventCaseUpdated;

  String get eventCompleted;

  String get eventCancelled;

  String get notificationsTitle;

  String get noNotifications;

  String get markAllRead;

  String get offlineSyncTitle;

  String get offlineSyncError;

  String offlinePendingCount(int count);

  String get offlineQueueEmpty;

  String get syncNow;

  String get retryFailed;

  String get offlineDead;

  String get offlineItemServiceRequest;

  String get offlineItemLead;

  String get offlineItemProfile;

  String get savedOffline;

  String get privacyPolicy;

  String get privacyPolicySubtitle;

  String get bootSplash;

  String get bootInitializing;

  String get bootCheckingUpdate;

  String get bootRestoringSession;

  String get bootInitError;

  String get bootRetry;

  String get bootOfflineConfig;

  String get bootConfigEmpty;

  String get bootForceUpdateTitle;

  String bootForceUpdateVersion(String current, String minimum);

  String get bootUpdateNow;

  String get bootUpdateUnavailable;

  String get bootOptionalUpdateTitle;

  String bootOptionalUpdateVersion(String current, String recommended);

  String get bootUpdateLater;

  String get bootMaintenanceTitle;

  String get bootMaintenanceDefault;

  String get welcomeTitle;

  String get welcomeSubtitle;

  String get welcomeGetStarted;

  String get rememberSession;

  String get authSignInWithOtp;

  String get authUsePassword;

  String get otpResend;

  String otpResendWait(int seconds);

  String get otpChangePhone;

  String get forgotPasswordTitle;

  String get forgotPasswordLink;

  String get forgotPasswordBody;

  String get forgotPasswordCallSupport;

  String get forgotPasswordUnavailable;

  String get forgotPasswordUseOtp;

  String get authInvalidPhone;

  String get authInvalidEmail;

  String get authInvalidOtp;

  String get authPasswordTooShort;

  String get socialLoginComingSoon;

  String get socialGoogle;

  String get socialFacebook;

  String get dashboardSummaryTitle;

  String get dashboardTotalFarms;

  String get dashboardTotalAnimals;

  String get dashboardAppointments;

  String get dashboardNotifications;

  String get dashboardQuickActionsTitle;

  String get dashboardCreateFarm;

  String get dashboardAddAnimal;

  String get dashboardViewRecords;

  String get dashboardLoadError;

  String get dashboardOfflineError;

  String get dashboardOfflineHint;

  String get dashboardEmptyHint;

  String get dashboardRetry;

  String get dashboardUnauthorized;

  String get dashboardGreetingMorning;

  String get dashboardGreetingAfternoon;

  String get dashboardGreetingEvening;

  String get dashboardSectionError;

  String get dashboardSectionOffline;

  String get dashboardUpcomingAppointments;

  String get dashboardNoAppointments;

  String get dashboardAppointmentFallback;

  String get dashboardViewAllAppointments;

  String get dashboardRecentActivity;

  String get dashboardNoActivity;

  String get dashboardViewAllActivity;

  String get dashboardHealthAlerts;

  String get dashboardNoHealthAlerts;

  String get dashboardHealthOverdue;

  String get dashboardHealthUpcoming;

  String get dashboardViewHealthAlerts;

  String get dashboardSupportTitle;

  String get dashboardSupportSubtitle;

  String get dashboardSupportHelpSubtitle;

  String get dashboardSupportTickets;

  String dashboardEmergencyPhone(String phone);

  String get dashboardAiTechnicianTitle;

  String get dashboardAiTodayRequests;

  String get dashboardAiPendingRequests;

  String get dashboardAiCompletedServices;

  String get dashboardAiRating;

  String get farmListTitle;

  String get farmDetailTitle;

  String get farmCreateTitle;

  String get farmEditTitle;

  String get farmNameLabel;

  String get farmSearchHint;

  String get farmFilterAll;

  String get farmFilterHasAnimals;

  String get farmEmpty;

  String get farmNoResults;

  String get farmLoadError;

  String get farmRetry;

  String get farmOfflineHint;

  String get farmLocationRequired;

  String get farmSummaryTitle;

  String get farmActiveAnimals;

  String get farmRelatedAnimals;

  String get farmNoAnimals;

  String get farmUploadCamera;

  String get farmUploadGallery;

  String get farmUploadFailed;

  String get farmSaveDraft;

  String get farmDraftSaved;

  String get farmFilterNeedsLocation;

  String get farmSortLabel;

  String get farmSortNameAsc;

  String get farmSortNameDesc;

  String get farmSortAnimalsDesc;

  String get farmSettingsTitle;

  String get farmRefreshData;

  String get farmRefreshStarted;

  String get farmActiveFarm;

  String get farmActiveFarmHint;

  String get farmSetActive;

  String get farmSingleFarmNotice;

  String farmCardStats(int total, int active);

  String get animalListTitle;

  String get animalDetailTitle;

  String get animalAddTitle;

  String get animalFormStepBasics;

  String get animalFormStepDetails;

  String get animalFormStepMetrics;

  String get animalFormStepNotes;

  String animalFormStepOf(int current, int total);

  String get animalFormNext;

  String get animalFormBack;

  String get animalBreedSearchHint;

  String get animalHealthScore;

  String get animalHealthScorePlaceholder;

  String get animalNextReminder;

  String get animalNextReminderPlaceholder;

  String get animalQrCode;

  String get animalQrPlaceholder;

  String get animalOverviewTitle;

  String get animalDocumentsTitle;

  String get animalDocumentsEmpty;

  String get animalVaccinesTitle;

  String get animalReportsTitle;

  String get animalDoctorHistoryTitle;

  String get animalEditTitle;

  String get animalSearchHint;

  String get animalFilterAll;

  String get animalFilterActive;

  String get animalFilterLivestock;

  String get animalEmpty;

  String get animalNoResults;

  String get animalLoadError;

  String get animalRetry;

  String get animalOfflineHint;

  String get animalTypeLabel;

  String get animalTagLabel;

  String get animalBreedLabel;

  String get animalWeightLabel;

  String get animalAgeLabel;

  String get animalGenderLabel;

  String get animalGenderUnknown;

  String get animalNotesLabel;

  String get animalNameOrTagRequired;

  String get animalTimelineTitle;

  String get animalHistoryTitle;

  String get animalNoHistory;

  String get animalSaveDraft;

  String get animalDraftSaved;

  String get animalSummaryTotal;

  String get animalSummaryActive;

  String get animalSummaryLivestock;

  String get animalFilterInactive;

  String get animalFilterPets;

  String get animalSortLabel;

  String get animalSortRecent;

  String get animalSortNameAsc;

  String get animalSortNameDesc;

  String get animalSortType;

  String get animalStatusInactive;

  String get animalDeactivateTitle;

  String get animalDeactivateMessage;

  String get animalDeactivateConfirm;

  String get animalViewPhoto;

  String get animalVaccinesShortcut;

  String get animalTreatmentsShortcut;

  String get animalWeightInvalid;

  String get animalAgeInvalid;

  String get animalUploadCamera;

  String get animalUploadGallery;

  String get cancel;

  String get batchListTitle;

  String get batchDetailTitle;

  String get batchAddTitle;

  String get batchEditTitle;

  String get batchSearchHint;

  String get batchFilterAll;

  String get batchFilterActive;

  String get batchFilterEmpty;

  String get batchEmpty;

  String get batchNoResults;

  String get batchLoadError;

  String get batchRetry;

  String get batchOfflineHint;

  String get batchOfflineSaved;

  String get batchPendingSync;

  String get batchAutoGroup;

  String batchAnimalCount(int count);

  String get batchNameLabel;

  String get batchTypeLabel;

  String get batchLocationLabel;

  String get batchNotesLabel;

  String get batchNameRequired;

  String get batchAnimalsTitle;

  String get batchNoAnimals;

  String get batchMovementsTitle;

  String get batchNoMovements;

  String get batchMoveAction;

  String get batchMergeAction;

  String get batchMoveSuccess;

  String get batchMergeSuccess;

  String get batchMoveUnavailable;

  String get batchMergeUnavailable;

  String get batchMoveTarget;

  String get batchMergeTarget;

  String get batchMoveConfirm;

  String get batchMergeConfirm;

  String get batchMoveInvalid;

  String get batchMergeInvalid;

  String get batchMergeHint;

  String get batchSelectAnimals;

  String get batchAnimalsLoadError;

  String get batchSaveDraft;

  String get batchDraftSaved;

  String get batchSaveChanges;

  String get batchCreateAction;

  String get batchSummaryTotal;

  String get batchSummaryWithAnimals;

  String get batchSummaryPendingSync;

  String get batchSortLabel;

  String get batchSortRecent;

  String get batchSortNameAsc;

  String get batchSortNameDesc;

  String get batchSortAnimalsDesc;

  String get batchDeleteAction;

  String get batchDeleteConfirm;

  String get batchDeleteSuccess;

  String get batchEmptyStatus;

  String get offlineItemBatch;

  String get milkEntryTitle;

  String get milkAddTitle;

  String get milkEditTitle;

  String get milkSummaryTitle;

  String get milkChartsTitle;

  String get milkLoadError;

  String get milkRetry;

  String get milkEmpty;

  String get milkOfflineHint;

  String get milkOfflineSaved;

  String get milkPendingSync;

  String get milkFarmLabel;

  String get milkAnimalLabel;

  String get milkDateLabel;

  String get milkQuantityLabel;

  String get milkNotesLabel;

  String get milkSessionMorning;

  String get milkSessionEvening;

  String get milkAnimalRequired;

  String get milkQuantityRequired;

  String get milkDateInvalid;

  String get milkSaveDraft;

  String get milkDraftSaved;

  String get milkSaveChanges;

  String get milkCreateAction;

  String get milkDeleteTitle;

  String get milkDeleteConfirm;

  String get milkDeleteAction;

  String get milkFarmLoadError;

  String get milkAnimalLoadError;

  String get milkNoFarm;

  String get milkNoCattle;

  String get milkTodayTotal;

  String milkLiters(double liters);

  String get milkPerAnimalTitle;

  String get milkPerDayTitle;

  String get milkDailyProductionTitle;

  String get milkWeeklyTrendTitle;

  String get milkMonthlyTrendTitle;

  String get milkSessionSplitTitle;

  String get milkQuickAction;

  String get milkDetailTitle;

  String get milkSearchHint;

  String get milkNoResults;

  String get milkFromDate;

  String get milkToDate;

  String get milkFilterAllAnimals;

  String get milkFilterAllSessions;

  String get milkSummaryToday;

  String get milkSummaryEntries;

  String get milkSummaryPendingSync;

  String get milkDeleteSuccess;

  String get offlineItemMilk;

  String get dashboardRecordMilk;

  String get feedEntryTitle;

  String get feedAddTitle;

  String get feedEditTitle;

  String get feedCostTitle;

  String get feedLoadError;

  String get feedRetry;

  String get feedEmpty;

  String get feedOfflineHint;

  String get feedOfflineSaved;

  String get feedPendingSync;

  String get feedSearchHint;

  String get feedFilterAll;

  String get feedFarmLabel;

  String get feedAnimalLabel;

  String get feedGroupLabel;

  String get feedTargetAnimal;

  String get feedTargetGroup;

  String get feedTypeLabel;

  String get feedAmountLabel;

  String get feedUnitLabel;

  String get feedCostLabel;

  String get feedDateLabel;

  String get feedNotesLabel;

  String get feedTargetRequired;

  String get feedAmountRequired;

  String get feedDateInvalid;

  String get feedSaveDraft;

  String get feedDraftSaved;

  String get feedSaveChanges;

  String get feedCreateAction;

  String get feedDeleteTitle;

  String get feedDeleteConfirm;

  String get feedDeleteAction;

  String get feedFarmLoadError;

  String get feedAnimalLoadError;

  String get feedGroupLoadError;

  String get feedNoFarm;

  String get feedNoAnimals;

  String get feedNoGroups;

  String get feedTotalCost;

  String get feedTotalAmount;

  String feedCostValue(double cost);

  String get feedDailyCostTitle;

  String get feedWeeklyCostTitle;

  String get feedMonthlyCostTitle;

  String get feedPerAnimalTitle;

  String get feedAnalyticsTitle;

  String get feedAnalyticsError;

  String get feedCostBreakdownTitle;

  String get feedConsumptionTrendTitle;

  String get feedEfficiencyTitle;

  String get feedCostPerKg;

  String get feedCostPerAnimal;

  String get feedAvgCostPerRecord;

  String get feedQuickAction;

  String get feedDetailTitle;

  String get feedNoResults;

  String get feedFromDate;

  String get feedToDate;

  String get feedFilterAllAnimals;

  String get feedFilterAllGroups;

  String get feedFilterAllTargets;

  String get feedSummaryCost;

  String get feedSummaryEntries;

  String get feedSummaryPendingSync;

  String get feedDeleteSuccess;

  String get offlineItemFeed;

  String get dashboardRecordFeed;

  String get financeExpenseTitle;

  String get financeIncomeTitle;

  String get financeProfitTitle;

  String get financeExpenseAddTitle;

  String get financeExpenseEditTitle;

  String get financeIncomeAddTitle;

  String get financeIncomeEditTitle;

  String get financeLoadError;

  String get financeRetry;

  String get financeExpenseEmpty;

  String get financeIncomeEmpty;

  String get financeOfflineHint;

  String get financeOfflineSaved;

  String get financePendingSync;

  String get financeExpenseSearchHint;

  String get financeIncomeSearchHint;

  String get financeFilterAll;

  String get financeFarmLabel;

  String get financeCategoryLabel;

  String get financeSourceLabel;

  String get financeAmountLabel;

  String get financeDateLabel;

  String get financeNotesLabel;

  String get financeAmountRequired;

  String get financeDateInvalid;

  String get financeSaveDraft;

  String get financeDraftSaved;

  String get financeSaveChanges;

  String get financeCreateAction;

  String get financeDeleteTitle;

  String get financeExpenseDeleteConfirm;

  String get financeIncomeDeleteConfirm;

  String get financeDeleteAction;

  String get financeFarmLoadError;

  String get financeNoFarm;

  String financeAmountValue(double amount);

  String get financeProfitSummary;

  String get financePeriodRange;

  String get financeTotalIncome;

  String get financeTotalExpense;

  String financeProfitChange(double percent);

  String get financePreviousPeriod;

  String get financeIncomeTrendTitle;

  String get financeExpenseTrendTitle;

  String get financeProfitTrendTitle;

  String get financeChartsError;

  String get financeReportsTitle;

  String get financeReportsError;

  String get financeExpenseByCategory;

  String get financeIncomeBySource;

  String financeRecordCount(int count);

  String get financeExportTitle;

  String get financeExportCsv;

  String get financeExportPdf;

  String get financeExportCopied;

  String get financeEmpty;

  String get financeCategoryFeed;

  String get financeCategoryMedicine;

  String get financeCategoryLabor;

  String get financeCategoryEquipment;

  String get financeCategoryTransport;

  String get financeCategoryOther;

  String get financeSourceMilkSales;

  String get financeSourceAnimalSales;

  String get financeSourceSubsidy;

  String get financeSourceService;

  String get financeSourceOther;

  String get financeDashboardTitle;

  String get financeLedgerTitle;

  String get financeLedgerEmpty;

  String get financeExpenseDetailTitle;

  String get financeIncomeDetailTitle;

  String get financeNoResults;

  String get financeFromDate;

  String get financeToDate;

  String get financeSummaryEntries;

  String get financeSummaryPendingSync;

  String get financeDeleteSuccess;

  String get offlineItemFinanceExpense;

  String get offlineItemFinanceIncome;

  String get dashboardRecordFinance;

  String get healthHistoryTitle;

  String get healthTimelineTitle;

  String get healthDetailTitle;

  String get healthAddTitle;

  String get healthEditTitle;

  String get healthLoadError;

  String get healthRetry;

  String get healthEmpty;

  String get healthOfflineHint;

  String get healthOfflineSaved;

  String get healthPendingSync;

  String get healthSearchHint;

  String get healthFilterAll;

  String get healthFarmLabel;

  String get healthAnimalLabel;

  String get healthTypeLabel;

  String get healthTitleLabel;

  String get healthSymptomsLabel;

  String get healthDiagnosisLabel;

  String get healthDiseaseLabel;

  String get healthDateLabel;

  String get healthNotesLabel;

  String get healthTitleRequired;

  String get healthAnimalRequired;

  String get healthDateInvalid;

  String get healthSaveDraft;

  String get healthDraftSaved;

  String get healthSaveChanges;

  String get healthCreateAction;

  String get healthDeleteTitle;

  String get healthDeleteConfirm;

  String get healthDeleteAction;

  String get healthFarmLoadError;

  String get healthAnimalLoadError;

  String get healthNoFarm;

  String get healthNoAnimals;

  String get healthTypeSymptom;

  String get healthTypeDiagnosis;

  String get healthTypeDisease;

  String get healthTypeCheckup;

  String get healthTypeTreatmentRef;

  String get healthQuickAction;

  String get healthDashboardTitle;

  String get healthRecordsTitle;

  String get healthAnalyticsTitle;

  String get healthRecentEventsTitle;

  String get healthFromDate;

  String get healthToDate;

  String get healthSummaryTotal;

  String get healthSummaryDisease;

  String get healthSummaryCheckup;

  String get healthSummaryTreatment;

  String get healthSummaryEntries;

  String get healthSummaryPendingSync;

  String get healthNoResults;

  String get healthDeleteSuccess;

  String get healthTreatmentLinkLabel;

  String get healthVaccineRefLabel;

  String get healthAnalyticsTypeBreakdown;

  String get healthAnalyticsDiseaseFrequency;

  String get healthAnalyticsNoDiseases;

  String get healthAnalyticsMonthlyTrend;

  String get offlineItemHealth;

  String get dashboardRecordHealth;

  String get vaccineScheduleTitle;

  String get vaccineRemindersTitle;

  String get vaccineAddTitle;

  String get vaccineEditTitle;

  String get vaccineLoadError;

  String get vaccineRetry;

  String get vaccineEmpty;

  String get vaccineOfflineHint;

  String get vaccineOfflineSaved;

  String get vaccinePendingSync;

  String get vaccineFilterAll;

  String get vaccineFarmLabel;

  String get vaccineAnimalLabel;

  String get vaccineNameLabel;

  String get vaccineTypeLabel;

  String get vaccineScheduledDateLabel;

  String get vaccineAdministeredDateLabel;

  String get vaccineNotAdministered;

  String get vaccineBatchLabel;

  String get vaccineNotesLabel;

  String get vaccineNameRequired;

  String get vaccineAnimalRequired;

  String get vaccineDateInvalid;

  String get vaccineSaveDraft;

  String get vaccineDraftSaved;

  String get vaccineSaveChanges;

  String get vaccineCreateAction;

  String get vaccineDeleteTitle;

  String get vaccineDeleteConfirm;

  String get vaccineDeleteAction;

  String get vaccineFarmLoadError;

  String get vaccineAnimalLoadError;

  String get vaccineNoFarm;

  String get vaccineNoAnimals;

  String get vaccineOverdueTitle;

  String get vaccineUpcomingTitle;

  String get vaccineStatusScheduled;

  String get vaccineStatusDue;

  String get vaccineStatusOverdue;

  String get vaccineStatusCompleted;

  String get vaccineDashboardTitle;

  String get vaccineHistoryTitle;

  String get vaccineCalendarTitle;

  String get vaccineDetailTitle;

  String get vaccineSearchHint;

  String get vaccineFromDate;

  String get vaccineToDate;

  String get vaccineSummaryCompleted;

  String get vaccineSummaryUpcoming;

  String get vaccineSummaryOverdue;

  String get vaccineSummaryEntries;

  String get vaccineSummaryPendingSync;

  String get vaccineNoResults;

  String get vaccineDeleteSuccess;

  String get vaccineNextDueLabel;

  String get vaccineNextDueTitle;

  String vaccineReminderBody(Object name, Object animal);

  String get vaccineCalendarLegend;

  String get offlineItemVaccine;

  String get treatmentListTitle;

  String get treatmentDetailTitle;

  String get treatmentAddTitle;

  String get treatmentEditTitle;

  String get treatmentLoadError;

  String get treatmentRetry;

  String get treatmentEmpty;

  String get treatmentOfflineHint;

  String get treatmentOfflineSaved;

  String get treatmentPendingSync;

  String get treatmentSearchHint;

  String get treatmentFarmLabel;

  String get treatmentAnimalLabel;

  String get treatmentTitleLabel;

  String get treatmentDiagnosisLabel;

  String get treatmentPrescriptionLabel;

  String get treatmentPrescriptionTitle;

  String get treatmentMedicinesTitle;

  String get treatmentMedicineNameLabel;

  String get treatmentDosageLabel;

  String get treatmentFrequencyLabel;

  String get treatmentDurationLabel;

  String get treatmentDaysSuffix;

  String get treatmentAddMedicine;

  String get treatmentNoMedicines;

  String get treatmentStartDateLabel;

  String get treatmentEndDateLabel;

  String get treatmentNoEndDate;

  String get treatmentNotesLabel;

  String get treatmentTitleRequired;

  String get treatmentAnimalRequired;

  String get treatmentMedicineRequired;

  String get treatmentDateInvalid;

  String get treatmentSaveDraft;

  String get treatmentDraftSaved;

  String get treatmentSaveChanges;

  String get treatmentCreateAction;

  String get treatmentDeleteTitle;

  String get treatmentDeleteConfirm;

  String get treatmentDeleteAction;

  String get treatmentFarmLoadError;

  String get treatmentAnimalLoadError;

  String get treatmentNoFarm;

  String get treatmentNoAnimals;

  String get treatmentStatusActive;

  String get treatmentStatusCompleted;

  String get treatmentStatusCancelled;

  String get treatmentDashboardTitle;

  String get treatmentTimelineTitle;

  String get treatmentMedicinePlanTitle;

  String get treatmentFollowUpTitle;

  String get treatmentFollowUpAction;

  String treatmentFollowUpBody(Object title, Object animal);

  String get treatmentNoFollowUp;

  String get treatmentViewPrescription;

  String get treatmentFilterAll;

  String get treatmentFromDate;

  String get treatmentToDate;

  String get treatmentSummaryActive;

  String get treatmentSummaryCompleted;

  String get treatmentSummaryOverdue;

  String get treatmentSummaryEntries;

  String get treatmentSummaryPendingSync;

  String get treatmentNoResults;

  String get treatmentDeleteSuccess;

  String treatmentMedicineCount(int count);

  String get offlineItemTreatment;

  String get notificationLoadError;

  String get notificationRetry;

  String get notificationOfflineHint;

  String get notificationSettingsTitle;

  String get notificationSettingsSaved;

  String get notificationSaveSettings;

  String get notificationPushToggle;

  String get notificationPushToggleHint;

  String get notificationMarketingToggle;

  String get notificationTreatmentReminderToggle;

  String get notificationVaccineReminderToggle;

  String get notificationOrderServiceToggle;

  String get notificationGroupToday;

  String get notificationGroupYesterday;

  String get notificationGroupEarlier;

  String get notificationDeleteTitle;

  String get notificationDeleteConfirm;

  String get notificationDeleteAction;

  String get notificationUnreadLabel;

  String get notificationCenterTitle;

  String get notificationViewAll;

  String get notificationRecentTitle;

  String get notificationSummaryUnread;

  String get notificationSummaryRecent;

  String get notificationDetailTitle;

  String get notificationDetailNotFound;

  String get notificationMarkRead;

  String get notificationOpenAction;

  String get notificationSearchHint;

  String get notificationFilterAll;

  String get notificationFilterUnread;

  String get notificationPermissionTitle;

  String get notificationPermissionBody;

  String get notificationPermissionRequest;

  String get notificationPermissionOpenSettings;

  String get notificationPermissionGranted;

  String get notificationPermissionGrantedStatus;

  String get notificationPermissionDenied;

  String get notificationPermissionDeniedPermanent;

  String get notificationPermissionUnknown;

  String get supportTicketListTitle;

  String get supportTicketDetailTitle;

  String get supportCreateTicketTitle;

  String get supportCreateTicket;

  String get supportHelpTitle;

  String get supportHelpSubtitle;

  String get supportRetry;

  String get supportEmpty;

  String get supportOfflineHint;

  String get supportPendingSync;

  String get supportSearchHint;

  String get supportFilterAll;

  String get supportStatusOpen;

  String get supportStatusInProgress;

  String get supportStatusWaitingCustomer;

  String get supportStatusResolved;

  String get supportStatusClosed;

  String get supportCategoryAccount;

  String get supportCategoryBilling;

  String get supportCategoryTechnical;

  String get supportCategoryAnimalHealth;

  String get supportCategoryAppUsage;

  String get supportCategoryOther;

  String get supportPriorityLow;

  String get supportPriorityMedium;

  String get supportPriorityHigh;

  String get supportPriorityUrgent;

  String get supportCategoryLabel;

  String get supportPriorityLabel;

  String get supportSubjectLabel;

  String get supportDescriptionLabel;

  String get supportSubjectRequired;

  String get supportDescriptionRequired;

  String get supportSubjectTooShort;

  String get supportDescriptionTooShort;

  String get supportAttachmentsLabel;

  String get supportAddImage;

  String get supportAddDocument;

  String get supportUploadFailed;

  String get supportUploadComplete;

  String get supportSubmitTicket;

  String get supportSubmitting;

  String get supportReplyHint;

  String get supportSendReply;

  String get supportReplySent;

  String get supportCloseTicket;

  String get supportReopenTicket;

  String get supportTicketClosed;

  String get supportTicketReopened;

  String get supportTimelineTitle;

  String get supportTimelineSystem;

  String get supportQuickActionsTitle;

  String get supportContactTitle;

  String get supportCallSupport;

  String get supportWhatsappSupport;

  String get supportEmailSupport;

  String get supportFaqTitle;

  String get supportHomeTitle;

  String get supportRecentTicketsTitle;

  String get supportSummaryOpen;

  String get supportSummaryPending;

  String get supportSummaryResolved;

  String get supportSummaryClosed;

  String get supportFaqSearchHint;

  String get supportFaqEmpty;

  String get supportContactBody;

  String get supportOpenAttachment;

  String get offlineItemSupport;

  String get offlineItemAiChat;

  String get dashboardAskAi;

  String get aiAskTitle;

  String get aiVoiceTitle;

  String get aiRetry;

  String get aiEmptyState;

  String get aiOfflineHint;

  String get aiMicPermissionDenied;

  String get aiDisclaimer;

  String get aiInputHint;

  String get aiSend;

  String get aiMessageRequired;

  String get aiMessageTooLong;

  String get aiLocaleBn;

  String get aiLocaleEn;

  String get aiSuggestionFeed;

  String get aiSuggestionVaccine;

  String get aiSuggestionSymptoms;

  String get aiTriageTitle;

  String get aiSymptomsLabel;

  String get aiSymptomsHint;

  String get aiSymptomsRequired;

  String get aiRunTriage;

  String get aiPossibleConcern;

  String get aiUrgencyLabel;

  String get aiUrgencyLow;

  String get aiUrgencyMedium;

  String get aiUrgencyHigh;

  String get aiRecommendedAction;

  String get aiDoctorSuggestion;

  String get aiFindVet;

  String get aiVoiceInstructions;

  String get aiVoiceTapHint;

  String get aiVoiceStart;

  String get aiVoiceStop;

  String get aiVoiceUseText;

  String get aiEmptyTranscript;

  String get aiHomeTitle;

  String get aiHomeActiveSession;

  String get aiHistoryTitle;

  String get aiSessionLabel;

  String get aiClearHistory;

  String get aiSettingsTitle;

  String get aiSettingsLanguage;

  String get aiSettingsSuggestions;

  String get aiSettingsMemory;

  String get aiSettingsMemoryHint;

  String get aiSaveSettings;

  String get aiSettingsSaved;

  String get aiResultTitle;

  String get aiResultEmpty;

  String get aiRegenerate;

  String get aiCopied;

  String get aiPendingSync;

  String get aiEscalationHint;

  String get aiEscalateSupport;

  String get aiRequestHumanReview;

  String get aiViewResult;

  String get settingsRetry;

  String get settingsOfflineHint;

  String get settingsTermsTitle;

  String get settingsTermsSubtitle;

  String get settingsVersionLabel;

  String get settingsAccepted;

  String get settingsOpenExternal;

  String get settingsAcceptPrivacy;

  String get settingsAcceptTerms;

  String get settingsPrivacyAccepted;

  String get settingsTermsAccepted;

  String get reconsentTitle;

  String get reconsentBody;

  String get reconsentAcceptContinue;

  String get reconsentAccepted;

  String get reconsentReadPrivacy;

  String get settingsAccountTitle;

  String get settingsAccountManageTitle;

  String get settingsPreferencesTitle;

  String get settingsPreferencesSubtitle;

  String get settingsPreferencesSection;

  String get settingsAppTitle;

  String get settingsAppSubtitle;

  String get settingsAppSection;

  String get settingsThemeTitle;

  String get settingsThemeLight;

  String get settingsThemeDark;

  String get settingsThemeSystem;

  String get settingsThemeSaved;

  String get settingsLanguageSaved;

  String get settingsAboutTitle;

  String get settingsAboutSupportTitle;

  String get settingsAboutLegalTitle;

  String get settingsDataSyncTitle;

  String get settingsLastSyncTitle;

  String get settingsLastSyncNever;

  String settingsPendingSettingsCount(int count);

  String get settingsHubAccountSection;

  String get settingsHubAppSection;

  String get settingsHubLegalSection;

  String get settingsHubSupportSection;

  String get networkConnectionTitle;

  String get networkConnectionSubtitle;

  String get networkApiUrlLabel;

  String get networkApiSourceLabel;

  String get networkApiPortLabel;

  String get networkWebUrlLabel;

  String get networkTimeoutLabel;

  String get networkRunChecks;

  String get networkReconnect;

  String get networkLastChecked;

  String get networkChecksPending;

  String get networkProbeLive;

  String get networkProbeAppConfig;

  String get networkProbeAuth;

  String get networkProbeRefresh;

  String get networkProbeUpload;

  String get offlineItemSettingsSync;

  String get profileEditPersonalInfo;

  String get profileEditAddressSection;

  String get profileEditPreviewSection;

  String get profileSaving;

  String get profileUploading;

  String get profileUpdatedSuccess;

  String get profileDiscardChangesTitle;

  String get profileDiscardChangesBody;

  String get profileDiscard;

  String get profileKeepEditing;

  String get profileCoverUpload;

  String get profileAvatarChange;

  String get profileRemovePhoto;

  String get profileRemoveCover;

  String get profilePreviewTitle;

  String get profilePhoneReadonly;

  String get profileUpdatedButton;

  String get homeVaccineDue;

  String get homeTasksLabel;

  String get homeViewAll;

  String get homeNoAnimalsYet;

  String get homeHealthTasksTitle;

  String get homeNoHealthTasks;

  String get homeBookDoctor;

  String get homeNearbyServices;

  String get homeUploadReport;

  String get homeHealthHistoryAction;

  String get homeDrawerDashboard;

  String get homeDrawerOrders;

  String get homeMarketplaceTitle;

  String get homeMarketplaceSubtitle;

  String get homeCommunityTitle;

  String get homeCommunitySubtitle;

  String get homeDrawerPayments;

  String get homeNoDoctorsNearby;

  String get homePlaceholderBody;

  String get homeReportsExportHint;

  String get homeMarketplaceEmpty;

  String get homeMarketplaceCategories;

  String get homeCommunityEmpty;

  String get homeOrdersEmpty;

  String get homeOrdersPending;

  String get homeOrdersCompleted;

  String get homeOrdersCancelled;

  String get homeOrdersRecentTitle;

  String get homeSearchPlaceholder;

  String get homeSearchVoice;

  String get homeSearchListening;

  String get homeSearchStop;

  String get homeSearchRecentTitle;

  String get homeSearchRecentEmpty;

  String get homeSearchSourcesTitle;

  String get homeSearchSourceDoctors;

  String get homeSearchSourceAi;

  String get homeSearchSourceServices;

  String get homeSearchSourceAnimals;

  String get homeSearchSourceMarketplace;

  String get homeSearchSourceReports;

  String get homeSearchSourceCommunity;

  String get homeSearchSourceEmergency;

  String get homeSearchNoResults;

  String get homeGreetingMorningBn;

  String get homeGreetingAfternoonBn;

  String get homeGreetingEveningBn;

  String get homeChangeCover;

  String get homeActionAiDoctor;

  String get homeActionCallDoctor;

  String get homeActionAiTechnician;

  String get homeActionVideoCall;

  String get homeInstantCareTitle;

  String get homeInstantCareSubtitle;

  String get homeCareAiDoctor;

  String get homeCareAiDoctorEta;

  String get homeCareCallDoctor;

  String get homeCareCallDoctorEta;

  String get homeCareEmergencyVisit;

  String get homeCareEmergencyVisitEta;

  String get homeCareVideoConsultation;

  String get homeCareVideoConsultationEta;

  String get homeCareNearestService;

  String get homeCareNearestServiceEta;

  String get homeCareChat;

  String get homeCareChatEta;

  String get aiSymptomGuidanceNote;

  String get profileMemberSince;

  String get offlineModeBanner;

  String get retryLabel;

  String inventoryDaysRemaining(int days);

  String get inventoryOutOfStock;

  String get inventoryFeedLogHint;

  String get inventoryMedicineStockNote;

  String feedCatalogSelectedCount(int count);

  String get feedCatalogSearchLabel;

  String get consentWithdrawPrivacy;

  String get consentWithdrawConfirm;

  String get consentWithdrawn;

  String get animalNameLabel;

  String get animalPurposeLabel;

  String get animalQrCopy;

  String get animalQrCopied;

  String get ecosystemHubTitle;

  String get ecosystemHubSubtitle;

  String get phase4FeedHubTitle;

  String get phase4FeedOfflineHint;

  String get phase4FeedLowStockAlerts;

  String get phase4FeedCatalogTitle;

  String get phase4FeedCatalogSubtitle;

  String get phase4FeedInventoryTitle;

  String get phase4FeedInventorySubtitle;

  String get phase4FeedPurchaseTitle;

  String get phase4FeedPurchaseSubtitle;

  String get phase4FeedConsumptionTitle;

  String get phase4FeedConsumptionSubtitle;

  String get phase4FeedInventoryEmpty;

  String get phase4FeedPurchaseSaved;

  String get phase4FeedOfflineSaved;

  String get phase4FeedInventoryItemLabel;

  String get phase4FeedQuantityLabel;

  String get phase4FeedCostLabel;

  String get phase4FeedSupplierLabel;

  String get phase4FeedSavePurchase;

  String get phase4FeedConsumptionSaved;

  String get phase4FeedAmountLabel;

  String get phase4FeedDeductStock;

  String get phase4FeedSaveConsumption;

  String get phase4FeedDetailTitle;

  String get phase4FeedCategoryLabel;

  String get phase4FeedUnitLabel;

  String get phase4FeedPriceLabel;

  String get phase4FeedLoadError;

  String get analyticsDashboardTitle;

  String get analyticsActiveAnimals;

  String get analyticsFeedCost;

  String get analyticsTotalExpense;

  String get analyticsLowStock;

  String get analyticsSpeciesBreakdown;

  String get analyticsMonthlyReport;

  String get analyticsFeedEfficiency;

  String get analyticsTotalFeedKg;

  String get analyticsAvgFeedPerAnimal;

  String get analyticsCostPerAnimal;

  String get analyticsLoadError;

  String get analyticsNoFarm;

  String get recommendationTitle;

  String get recommendationDailyIntake;

  String get recommendationEstimatedCost;

  String recommendationDryMatter(String kg);

  String get recommendationWarnings;

  String get recommendationIntelligenceTitle;

  String get recommendationExplanations;

  String get recommendationAlternatives;

  String get recommendationSuggestedFeed;

  String get recommendationAccepted;

  String get recommendationAccept;

  String get recommendationScoreOverall;

  String get recommendationScoreNutrition;

  String get recommendationScoreAffordability;

  String get recommendationScoreSeasonal;

  String get recommendationScoreHealth;

}
