import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_delegate.dart';
import 'localization_loader.dart';
import 'localization_format.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
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

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PraniDoctor'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get navServices;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @drawerTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get drawerTitle;

  /// No description provided for @drawerFarmSection.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get drawerFarmSection;

  /// No description provided for @drawerFatteningSection.
  ///
  /// In en, this message translates to:
  /// **'Fattening'**
  String get drawerFatteningSection;

  /// No description provided for @fatteningListTitle.
  ///
  /// In en, this message translates to:
  /// **'Fattening batches'**
  String get fatteningListTitle;

  /// No description provided for @fatteningCreateBatch.
  ///
  /// In en, this message translates to:
  /// **'Create fattening batch'**
  String get fatteningCreateBatch;

  /// No description provided for @fatteningBatchDetail.
  ///
  /// In en, this message translates to:
  /// **'Batch details'**
  String get fatteningBatchDetail;

  /// No description provided for @fatteningBatchName.
  ///
  /// In en, this message translates to:
  /// **'Batch name'**
  String get fatteningBatchName;

  /// No description provided for @fatteningBatchGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal (optional)'**
  String get fatteningBatchGoal;

  /// No description provided for @fatteningTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get fatteningTargetDate;

  /// No description provided for @fatteningTargetDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get fatteningTargetDateOptional;

  /// No description provided for @fatteningStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get fatteningStartDate;

  /// No description provided for @fatteningSaveAndAddAnimals.
  ///
  /// In en, this message translates to:
  /// **'Save and add animals'**
  String get fatteningSaveAndAddAnimals;

  /// No description provided for @fatteningAddAnimals.
  ///
  /// In en, this message translates to:
  /// **'Add animals'**
  String get fatteningAddAnimals;

  /// No description provided for @fatteningStartBatch.
  ///
  /// In en, this message translates to:
  /// **'Start fattening'**
  String get fatteningStartBatch;

  /// No description provided for @fatteningFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get fatteningFilterAll;

  /// No description provided for @fatteningFilterDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get fatteningFilterDraft;

  /// No description provided for @fatteningFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get fatteningFilterActive;

  /// No description provided for @fatteningNoAnimalsYet.
  ///
  /// In en, this message translates to:
  /// **'No animals in this batch yet.'**
  String get fatteningNoAnimalsYet;

  /// No description provided for @fatteningNoCattleAvailable.
  ///
  /// In en, this message translates to:
  /// **'No active cattle found. Add cattle animals first.'**
  String get fatteningNoCattleAvailable;

  /// No description provided for @fatteningAddSelectedAnimals.
  ///
  /// In en, this message translates to:
  /// **'Add {count} animals'**
  String fatteningAddSelectedAnimals(int count);

  /// No description provided for @fatteningAnimalsInBatch.
  ///
  /// In en, this message translates to:
  /// **'{count} animals in batch'**
  String fatteningAnimalsInBatch(int count);

  /// No description provided for @fatteningStartRequiresOnline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to start a batch.'**
  String get fatteningStartRequiresOnline;

  /// No description provided for @fatteningStartConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Start fattening?'**
  String get fatteningStartConfirmTitle;

  /// No description provided for @fatteningStartConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Animals will move to active fattening. Each animal can only be in one active batch.'**
  String get fatteningStartConfirmMessage;

  /// No description provided for @fatteningStartedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Fattening batch started'**
  String get fatteningStartedSuccess;

  /// No description provided for @fatteningWeightEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Record weight'**
  String get fatteningWeightEntryTitle;

  /// No description provided for @fatteningProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch progress'**
  String get fatteningProgressTitle;

  /// No description provided for @fatteningRecordWeight.
  ///
  /// In en, this message translates to:
  /// **'Record weight'**
  String get fatteningRecordWeight;

  /// No description provided for @fatteningWeightKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get fatteningWeightKgLabel;

  /// No description provided for @fatteningWeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid weight in kg'**
  String get fatteningWeightInvalid;

  /// No description provided for @fatteningRecordedDate.
  ///
  /// In en, this message translates to:
  /// **'Recorded date'**
  String get fatteningRecordedDate;

  /// No description provided for @fatteningWeightNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get fatteningWeightNote;

  /// No description provided for @fatteningSaveWeight.
  ///
  /// In en, this message translates to:
  /// **'Save weight'**
  String get fatteningSaveWeight;

  /// No description provided for @fatteningProgressSummary.
  ///
  /// In en, this message translates to:
  /// **'Growth summary'**
  String get fatteningProgressSummary;

  /// No description provided for @fatteningNoProgressYet.
  ///
  /// In en, this message translates to:
  /// **'No weight data yet. Record the first weigh-in.'**
  String get fatteningNoProgressYet;

  /// No description provided for @fatteningWeightHistory.
  ///
  /// In en, this message translates to:
  /// **'Weight history'**
  String get fatteningWeightHistory;

  /// No description provided for @fatteningWeightMethod.
  ///
  /// In en, this message translates to:
  /// **'Weighing method'**
  String get fatteningWeightMethod;

  /// No description provided for @fatteningWeightMethodScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get fatteningWeightMethodScale;

  /// No description provided for @fatteningWeightMethodTape.
  ///
  /// In en, this message translates to:
  /// **'Tape'**
  String get fatteningWeightMethodTape;

  /// No description provided for @fatteningWeightMethodEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get fatteningWeightMethodEstimate;

  /// No description provided for @fatteningWeightMethodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get fatteningWeightMethodOther;

  /// No description provided for @fatteningWeightSaved.
  ///
  /// In en, this message translates to:
  /// **'Weight recorded'**
  String get fatteningWeightSaved;

  /// No description provided for @fatteningWeightSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Weight saved offline — will sync when online'**
  String get fatteningWeightSavedOffline;

  /// No description provided for @fatteningWeightDuplicateDay.
  ///
  /// In en, this message translates to:
  /// **'This animal was already weighed today for this batch'**
  String get fatteningWeightDuplicateDay;

  /// No description provided for @fatteningAvgCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Avg current'**
  String get fatteningAvgCurrentWeight;

  /// No description provided for @fatteningTotalGain.
  ///
  /// In en, this message translates to:
  /// **'Total gain'**
  String get fatteningTotalGain;

  /// No description provided for @fatteningGrowthChart.
  ///
  /// In en, this message translates to:
  /// **'Growth trend'**
  String get fatteningGrowthChart;

  /// No description provided for @fatteningNoWeightHistory.
  ///
  /// In en, this message translates to:
  /// **'No weight records yet.'**
  String get fatteningNoWeightHistory;

  /// No description provided for @fatteningInitialWeight.
  ///
  /// In en, this message translates to:
  /// **'Initial'**
  String get fatteningInitialWeight;

  /// No description provided for @fatteningCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get fatteningCurrentWeight;

  /// No description provided for @fatteningGain.
  ///
  /// In en, this message translates to:
  /// **'Gain'**
  String get fatteningGain;

  /// No description provided for @fatteningFeedDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get fatteningFeedDashboardTitle;

  /// No description provided for @fatteningFeedCostSection.
  ///
  /// In en, this message translates to:
  /// **'Feed cost'**
  String get fatteningFeedCostSection;

  /// No description provided for @fatteningDailyFeedSection.
  ///
  /// In en, this message translates to:
  /// **'Daily feed'**
  String get fatteningDailyFeedSection;

  /// No description provided for @fatteningTotalFeedCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get fatteningTotalFeedCost;

  /// No description provided for @fatteningTodayFeedCost.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get fatteningTodayFeedCost;

  /// No description provided for @fatteningTodayFeedAmount.
  ///
  /// In en, this message translates to:
  /// **'Today fed'**
  String get fatteningTodayFeedAmount;

  /// No description provided for @fatteningAvgDailyFeed.
  ///
  /// In en, this message translates to:
  /// **'Avg daily'**
  String get fatteningAvgDailyFeed;

  /// No description provided for @fatteningPlannedAmount.
  ///
  /// In en, this message translates to:
  /// **'Plan: {amount} kg/day'**
  String fatteningPlannedAmount(double amount);

  /// No description provided for @fatteningDailyCostChart.
  ///
  /// In en, this message translates to:
  /// **'Daily feed cost'**
  String get fatteningDailyCostChart;

  /// No description provided for @fatteningNoFeedData.
  ///
  /// In en, this message translates to:
  /// **'No feed records for this batch yet.'**
  String get fatteningNoFeedData;

  /// No description provided for @fatteningLogFeed.
  ///
  /// In en, this message translates to:
  /// **'Log feed'**
  String get fatteningLogFeed;

  /// No description provided for @fatteningSaveFeed.
  ///
  /// In en, this message translates to:
  /// **'Save feed entry'**
  String get fatteningSaveFeed;

  /// No description provided for @fatteningEditFeedPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit feed plan'**
  String get fatteningEditFeedPlan;

  /// No description provided for @fatteningPlanModeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get fatteningPlanModeNormal;

  /// No description provided for @fatteningPlanModeFattening.
  ///
  /// In en, this message translates to:
  /// **'Fattening'**
  String get fatteningPlanModeFattening;

  /// No description provided for @fatteningPlanDailyAmount.
  ///
  /// In en, this message translates to:
  /// **'Daily amount'**
  String get fatteningPlanDailyAmount;

  /// No description provided for @fatteningPlanDailyCost.
  ///
  /// In en, this message translates to:
  /// **'Daily cost (BDT)'**
  String get fatteningPlanDailyCost;

  /// No description provided for @fatteningSavePlan.
  ///
  /// In en, this message translates to:
  /// **'Save plan'**
  String get fatteningSavePlan;

  /// No description provided for @fatteningPlanSaved.
  ///
  /// In en, this message translates to:
  /// **'Feed plan saved'**
  String get fatteningPlanSaved;

  /// No description provided for @fatteningRoiTitle.
  ///
  /// In en, this message translates to:
  /// **'ROI'**
  String get fatteningRoiTitle;

  /// No description provided for @fatteningRoiCostSection.
  ///
  /// In en, this message translates to:
  /// **'Cost breakdown'**
  String get fatteningRoiCostSection;

  /// No description provided for @fatteningRoiPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get fatteningRoiPurchase;

  /// No description provided for @fatteningRoiFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get fatteningRoiFeed;

  /// No description provided for @fatteningRoiTreatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get fatteningRoiTreatment;

  /// No description provided for @fatteningRoiTreatmentHint.
  ///
  /// In en, this message translates to:
  /// **'Log medicine expenses in Finance linked to this batch'**
  String get fatteningRoiTreatmentHint;

  /// No description provided for @fatteningRoiTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get fatteningRoiTotalCost;

  /// No description provided for @fatteningRoiProjectedSale.
  ///
  /// In en, this message translates to:
  /// **'Projected sale'**
  String get fatteningRoiProjectedSale;

  /// No description provided for @fatteningRoiProfit.
  ///
  /// In en, this message translates to:
  /// **'Estimated profit'**
  String get fatteningRoiProfit;

  /// No description provided for @fatteningRoiMargin.
  ///
  /// In en, this message translates to:
  /// **'{pct}% margin'**
  String fatteningRoiMargin(double pct);

  /// No description provided for @fatteningRoiRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String fatteningRoiRecordCount(int count);

  /// No description provided for @fatteningEditRoi.
  ///
  /// In en, this message translates to:
  /// **'Edit ROI'**
  String get fatteningEditRoi;

  /// No description provided for @fatteningSaveRoi.
  ///
  /// In en, this message translates to:
  /// **'Save ROI'**
  String get fatteningSaveRoi;

  /// No description provided for @fatteningRoiSaved.
  ///
  /// In en, this message translates to:
  /// **'ROI updated'**
  String get fatteningRoiSaved;

  /// No description provided for @fatteningBatchGoalType.
  ///
  /// In en, this message translates to:
  /// **'Batch goal'**
  String get fatteningBatchGoalType;

  /// No description provided for @fatteningGoalTypeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get fatteningGoalTypeNormal;

  /// No description provided for @fatteningGoalTypeQurbani.
  ///
  /// In en, this message translates to:
  /// **'Qurbani'**
  String get fatteningGoalTypeQurbani;

  /// No description provided for @fatteningQurbaniTargetRequired.
  ///
  /// In en, this message translates to:
  /// **'Set a target date for Qurbani batches'**
  String get fatteningQurbaniTargetRequired;

  /// No description provided for @fatteningQurbaniTitle.
  ///
  /// In en, this message translates to:
  /// **'Qurbani'**
  String get fatteningQurbaniTitle;

  /// No description provided for @fatteningQurbaniCountdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get fatteningQurbaniCountdown;

  /// No description provided for @fatteningQurbaniDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String fatteningQurbaniDaysLabel(int days);

  /// No description provided for @fatteningQurbaniTargetOn.
  ///
  /// In en, this message translates to:
  /// **'Target: {date}'**
  String fatteningQurbaniTargetOn(String date);

  /// No description provided for @fatteningQurbaniSetTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Set a target date on the batch to see the countdown.'**
  String get fatteningQurbaniSetTargetDate;

  /// No description provided for @fatteningQurbaniReadiness.
  ///
  /// In en, this message translates to:
  /// **'Readiness'**
  String get fatteningQurbaniReadiness;

  /// No description provided for @fatteningQurbaniStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get fatteningQurbaniStatusReady;

  /// No description provided for @fatteningQurbaniStatusAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get fatteningQurbaniStatusAtRisk;

  /// No description provided for @fatteningQurbaniStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get fatteningQurbaniStatusOverdue;

  /// No description provided for @fatteningQurbaniStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get fatteningQurbaniStatusNotStarted;

  /// No description provided for @fatteningQurbaniStatusOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get fatteningQurbaniStatusOnTrack;

  /// No description provided for @fatteningQurbaniWeightProgress.
  ///
  /// In en, this message translates to:
  /// **'Weight: {pct}% of target'**
  String fatteningQurbaniWeightProgress(double pct);

  /// No description provided for @fatteningQurbaniTimeProgress.
  ///
  /// In en, this message translates to:
  /// **'Timeline: {pct}%'**
  String fatteningQurbaniTimeProgress(double pct);

  /// No description provided for @fatteningQurbaniAnimals.
  ///
  /// In en, this message translates to:
  /// **'Cattle readiness'**
  String get fatteningQurbaniAnimals;

  /// No description provided for @fatteningQurbaniAnimalProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} kg / {target} kg ({pct}%)'**
  String fatteningQurbaniAnimalProgress(String current, int target, double pct);

  /// No description provided for @fatteningWeightRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} weigh-ins'**
  String fatteningWeightRecordCount(int count);

  /// No description provided for @drawerMilkSection.
  ///
  /// In en, this message translates to:
  /// **'Milk production'**
  String get drawerMilkSection;

  /// No description provided for @drawerAnimalsSection.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get drawerAnimalsSection;

  /// No description provided for @drawerRecordsSection.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get drawerRecordsSection;

  /// No description provided for @drawerFarmDashboard.
  ///
  /// In en, this message translates to:
  /// **'Farm dashboard'**
  String get drawerFarmDashboard;

  /// No description provided for @drawerGrowthRecords.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get drawerGrowthRecords;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit app?'**
  String get exitAppTitle;

  /// No description provided for @exitAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to close PraniDoctor?'**
  String get exitAppMessage;

  /// No description provided for @exitAppConfirm.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitAppConfirm;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to access your account.'**
  String get logoutConfirmMessage;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your farm, animals, and veterinary care.'**
  String get loginWelcomeSubtitle;

  /// No description provided for @loginLastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last signed in with {identifier}'**
  String loginLastLogin(String identifier);

  /// No description provided for @authGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogleSignIn;

  /// No description provided for @authGoogleComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in coming soon'**
  String get authGoogleComingSoon;

  /// No description provided for @loginDevContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue (development)'**
  String get loginDevContinue;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @authTabOtp.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get authTabOtp;

  /// No description provided for @authTabPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authTabPassword;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneLabel;

  /// No description provided for @otpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otpCodeLabel;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify & sign in'**
  String get verifyOtp;

  /// No description provided for @identifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile or email'**
  String get identifierLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get nameLabel;

  /// No description provided for @emailOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptionalLabel;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLink;

  /// No description provided for @hasAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get hasAccountPrompt;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginLink;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent'**
  String get otpSent;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTitle;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get profileLoadError;

  /// No description provided for @profileEmpty.
  ///
  /// In en, this message translates to:
  /// **'No profile information yet.'**
  String get profileEmpty;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Profile incomplete'**
  String get profileIncomplete;

  /// No description provided for @profileAccountInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Account information'**
  String get profileAccountInfoTitle;

  /// No description provided for @profileCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profileCompletionTitle;

  /// No description provided for @profileCompletionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your name and location so we can personalize services for your farm.'**
  String get profileCompletionSubtitle;

  /// No description provided for @profileCompletionNameStep.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get profileCompletionNameStep;

  /// No description provided for @profileCompletionAddressStep.
  ///
  /// In en, this message translates to:
  /// **'Farm location'**
  String get profileCompletionAddressStep;

  /// No description provided for @profileCompletionPhotoStep.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profileCompletionPhotoStep;

  /// No description provided for @profileCompletionOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get profileCompletionOptional;

  /// No description provided for @profileCompletionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to home'**
  String get profileCompletionContinue;

  /// No description provided for @profileCompletionHint.
  ///
  /// In en, this message translates to:
  /// **'Add your name and location (union required; village optional) before using the app.'**
  String get profileCompletionHint;

  /// No description provided for @profileChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePasswordTitle;

  /// No description provided for @profileChangePasswordBody.
  ///
  /// In en, this message translates to:
  /// **'In-app password change is not available yet. Reset your password or contact support for help.'**
  String get profileChangePasswordBody;

  /// No description provided for @profileChangePasswordForgotLink.
  ///
  /// In en, this message translates to:
  /// **'Reset via forgot password'**
  String get profileChangePasswordForgotLink;

  /// No description provided for @profileNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name must be 120 characters or fewer.'**
  String get profileNameTooLong;

  /// No description provided for @profileEmailTooLong.
  ///
  /// In en, this message translates to:
  /// **'Email must be 200 characters or fewer.'**
  String get profileEmailTooLong;

  /// No description provided for @profileAddressLineTooLong.
  ///
  /// In en, this message translates to:
  /// **'Address line must be 500 characters or fewer.'**
  String get profileAddressLineTooLong;

  /// No description provided for @profilePostalTooLong.
  ///
  /// In en, this message translates to:
  /// **'Postal code must be 20 characters or fewer.'**
  String get profilePostalTooLong;

  /// No description provided for @addressTitle.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressTitle;

  /// No description provided for @addressLineLabel.
  ///
  /// In en, this message translates to:
  /// **'Street / house (optional)'**
  String get addressLineLabel;

  /// No description provided for @postalCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Postal code (optional)'**
  String get postalCodeLabel;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Select division, district, upazila, and union to save address'**
  String get addressRequired;

  /// No description provided for @addressHierarchyRequired.
  ///
  /// In en, this message translates to:
  /// **'Division, district, upazila, and union are required'**
  String get addressHierarchyRequired;

  /// No description provided for @areaVillageOptionalHelper.
  ///
  /// In en, this message translates to:
  /// **'Village is optional — type a name if yours is not listed'**
  String get areaVillageOptionalHelper;

  /// No description provided for @areaVillageNotFoundOptional.
  ///
  /// In en, this message translates to:
  /// **'Village not found (optional)'**
  String get areaVillageNotFoundOptional;

  /// No description provided for @areaVillageManualHint.
  ///
  /// In en, this message translates to:
  /// **'Enter village (optional)'**
  String get areaVillageManualHint;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageBangla.
  ///
  /// In en, this message translates to:
  /// **'Bangla'**
  String get languageBangla;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @areaRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get areaRetry;

  /// No description provided for @areaOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved locations (offline)'**
  String get areaOfflineHint;

  /// No description provided for @areaEmptyDivisions.
  ///
  /// In en, this message translates to:
  /// **'No divisions available'**
  String get areaEmptyDivisions;

  /// No description provided for @areaEmptyDistricts.
  ///
  /// In en, this message translates to:
  /// **'No districts for this division'**
  String get areaEmptyDistricts;

  /// No description provided for @areaEmptyUpazilas.
  ///
  /// In en, this message translates to:
  /// **'No upazilas for this district'**
  String get areaEmptyUpazilas;

  /// No description provided for @areaEmptyUnions.
  ///
  /// In en, this message translates to:
  /// **'No unions for this upazila'**
  String get areaEmptyUnions;

  /// No description provided for @areaEmptyVillages.
  ///
  /// In en, this message translates to:
  /// **'No villages for this union'**
  String get areaEmptyVillages;

  /// No description provided for @areaSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name…'**
  String get areaSearchHint;

  /// No description provided for @areaSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No locations match your search'**
  String get areaSearchNoResults;

  /// No description provided for @areaSearchVillagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Search villages'**
  String get areaSearchVillagesTitle;

  /// No description provided for @areaSelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get areaSelectedLocation;

  /// No description provided for @areaSelectLevel.
  ///
  /// In en, this message translates to:
  /// **'Select your location'**
  String get areaSelectLevel;

  /// No description provided for @areaRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh locations'**
  String get areaRefresh;

  /// No description provided for @locationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSectionTitle;

  /// No description provided for @divisionLabel.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get divisionLabel;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @upazilaLabel.
  ///
  /// In en, this message translates to:
  /// **'Upazila'**
  String get upazilaLabel;

  /// No description provided for @unionLabel.
  ///
  /// In en, this message translates to:
  /// **'Union'**
  String get unionLabel;

  /// No description provided for @villageLabel.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get villageLabel;

  /// No description provided for @findDoctors.
  ///
  /// In en, this message translates to:
  /// **'Find a doctor'**
  String get findDoctors;

  /// No description provided for @filterEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get filterEmergency;

  /// No description provided for @filterOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get filterOnline;

  /// No description provided for @filterHomeVisit.
  ///
  /// In en, this message translates to:
  /// **'Home visit'**
  String get filterHomeVisit;

  /// No description provided for @filterByArea.
  ///
  /// In en, this message translates to:
  /// **'Filter by area'**
  String get filterByArea;

  /// No description provided for @noDoctorsFound.
  ///
  /// In en, this message translates to:
  /// **'No doctors found for these filters'**
  String get noDoctorsFound;

  /// No description provided for @doctorDetails.
  ///
  /// In en, this message translates to:
  /// **'Doctor details'**
  String get doctorDetails;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @emergencyAvailable.
  ///
  /// In en, this message translates to:
  /// **'Emergency available'**
  String get emergencyAvailable;

  /// No description provided for @onlineConsultation.
  ///
  /// In en, this message translates to:
  /// **'Online consultation'**
  String get onlineConsultation;

  /// No description provided for @homeVisit.
  ///
  /// In en, this message translates to:
  /// **'Home visit'**
  String get homeVisit;

  /// No description provided for @aboutDoctor.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutDoctor;

  /// No description provided for @experienceYears.
  ///
  /// In en, this message translates to:
  /// **'Experience (years)'**
  String get experienceYears;

  /// No description provided for @servicesOffered.
  ///
  /// In en, this message translates to:
  /// **'Services offered'**
  String get servicesOffered;

  /// No description provided for @consultationFee.
  ///
  /// In en, this message translates to:
  /// **'Consultation fee'**
  String get consultationFee;

  /// No description provided for @bookConsultation.
  ///
  /// In en, this message translates to:
  /// **'Book consultation'**
  String get bookConsultation;

  /// No description provided for @selectAnimal.
  ///
  /// In en, this message translates to:
  /// **'Select animal'**
  String get selectAnimal;

  /// No description provided for @symptomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Symptoms or problem'**
  String get symptomsLabel;

  /// No description provided for @preferredTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred time'**
  String get preferredTimeLabel;

  /// No description provided for @preferredTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Preferred time is required for online consultation'**
  String get preferredTimeRequired;

  /// No description provided for @submitBooking.
  ///
  /// In en, this message translates to:
  /// **'Submit booking'**
  String get submitBooking;

  /// No description provided for @bookingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Consultation request submitted'**
  String get bookingSubmitted;

  /// No description provided for @addAnimalFirst.
  ///
  /// In en, this message translates to:
  /// **'Add an animal to your profile before booking'**
  String get addAnimalFirst;

  /// No description provided for @categoryMissing.
  ///
  /// In en, this message translates to:
  /// **'Service category not available'**
  String get categoryMissing;

  /// No description provided for @appointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointmentsTitle;

  /// No description provided for @noAppointments.
  ///
  /// In en, this message translates to:
  /// **'No appointments yet'**
  String get noAppointments;

  /// No description provided for @appointmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Appointment details'**
  String get appointmentDetails;

  /// No description provided for @appointmentHistory.
  ///
  /// In en, this message translates to:
  /// **'Appointment history'**
  String get appointmentHistory;

  /// No description provided for @appointmentSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get appointmentSummary;

  /// No description provided for @assignedDoctor.
  ///
  /// In en, this message translates to:
  /// **'Assigned doctor'**
  String get assignedDoctor;

  /// No description provided for @awaitingAssignment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for doctor assignment'**
  String get awaitingAssignment;

  /// No description provided for @trackStatus.
  ///
  /// In en, this message translates to:
  /// **'Track status'**
  String get trackStatus;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get viewHistory;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history events yet'**
  String get noHistoryYet;

  /// No description provided for @segmentActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get segmentActive;

  /// No description provided for @segmentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get segmentCompleted;

  /// No description provided for @segmentClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get segmentClosed;

  /// No description provided for @segmentAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get segmentAll;

  /// No description provided for @serviceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Service type'**
  String get serviceTypeLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @providerLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get providerLabel;

  /// No description provided for @submittedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submittedAtLabel;

  /// No description provided for @assignedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assignedAtLabel;

  /// No description provided for @startedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get startedAtLabel;

  /// No description provided for @completedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedAtLabel;

  /// No description provided for @cancelledAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledAtLabel;

  /// No description provided for @cancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel appointment'**
  String get cancelAppointment;

  /// No description provided for @cancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get cancelReasonLabel;

  /// No description provided for @keepAppointment.
  ///
  /// In en, this message translates to:
  /// **'Keep appointment'**
  String get keepAppointment;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancel'**
  String get confirmCancel;

  /// No description provided for @appointmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled'**
  String get appointmentCancelled;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @aiService.
  ///
  /// In en, this message translates to:
  /// **'AI service'**
  String get aiService;

  /// No description provided for @eventCreated.
  ///
  /// In en, this message translates to:
  /// **'Request created'**
  String get eventCreated;

  /// No description provided for @eventAssigned.
  ///
  /// In en, this message translates to:
  /// **'Doctor assigned'**
  String get eventAssigned;

  /// No description provided for @eventReassigned.
  ///
  /// In en, this message translates to:
  /// **'Doctor reassigned'**
  String get eventReassigned;

  /// No description provided for @eventAccepted.
  ///
  /// In en, this message translates to:
  /// **'Doctor accepted'**
  String get eventAccepted;

  /// No description provided for @eventRejected.
  ///
  /// In en, this message translates to:
  /// **'Doctor rejected'**
  String get eventRejected;

  /// No description provided for @eventStarted.
  ///
  /// In en, this message translates to:
  /// **'Treatment started'**
  String get eventStarted;

  /// No description provided for @eventNoteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get eventNoteAdded;

  /// No description provided for @eventCaseOpened.
  ///
  /// In en, this message translates to:
  /// **'Case opened'**
  String get eventCaseOpened;

  /// No description provided for @eventCaseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Case updated'**
  String get eventCaseUpdated;

  /// No description provided for @eventCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get eventCompleted;

  /// No description provided for @eventCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get eventCancelled;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @offlineSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline sync'**
  String get offlineSyncTitle;

  /// No description provided for @offlineSyncError.
  ///
  /// In en, this message translates to:
  /// **'Could not read sync queue'**
  String get offlineSyncError;

  /// No description provided for @offlinePendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items waiting to sync'**
  String offlinePendingCount(int count);

  /// No description provided for @offlineQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'All changes are synced'**
  String get offlineQueueEmpty;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @retryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed'**
  String get retryFailed;

  /// No description provided for @offlineDead.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get offlineDead;

  /// No description provided for @offlineItemServiceRequest.
  ///
  /// In en, this message translates to:
  /// **'Appointment booking'**
  String get offlineItemServiceRequest;

  /// No description provided for @offlineItemLead.
  ///
  /// In en, this message translates to:
  /// **'Offline lead'**
  String get offlineItemLead;

  /// No description provided for @offlineItemProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile update'**
  String get offlineItemProfile;

  /// No description provided for @savedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved offline — will sync when online'**
  String get savedOffline;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get privacyPolicySubtitle;

  /// No description provided for @bootSplash.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get bootSplash;

  /// No description provided for @bootInitializing.
  ///
  /// In en, this message translates to:
  /// **'Loading app settings…'**
  String get bootInitializing;

  /// No description provided for @bootCheckingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get bootCheckingUpdate;

  /// No description provided for @bootRestoringSession.
  ///
  /// In en, this message translates to:
  /// **'Restoring your session…'**
  String get bootRestoringSession;

  /// No description provided for @bootInitError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check your network and try again.'**
  String get bootInitError;

  /// No description provided for @bootRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get bootRetry;

  /// No description provided for @bootOfflineConfig.
  ///
  /// In en, this message translates to:
  /// **'Using saved settings (offline)'**
  String get bootOfflineConfig;

  /// No description provided for @bootConfigEmpty.
  ///
  /// In en, this message translates to:
  /// **'Support contacts will appear when online.'**
  String get bootConfigEmpty;

  /// No description provided for @bootForceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get bootForceUpdateTitle;

  /// No description provided for @bootForceUpdateVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed: {current} · Required: {minimum}'**
  String bootForceUpdateVersion(String current, String minimum);

  /// No description provided for @bootUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get bootUpdateNow;

  /// No description provided for @bootUpdateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Please update PraniDoctor from your app store.'**
  String get bootUpdateUnavailable;

  /// No description provided for @bootOptionalUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get bootOptionalUpdateTitle;

  /// No description provided for @bootOptionalUpdateVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed: {current} · Latest: {recommended}'**
  String bootOptionalUpdateVersion(String current, String recommended);

  /// No description provided for @bootUpdateLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get bootUpdateLater;

  /// No description provided for @bootMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Under maintenance'**
  String get bootMaintenanceTitle;

  /// No description provided for @bootMaintenanceDefault.
  ///
  /// In en, this message translates to:
  /// **'PraniDoctor is temporarily unavailable. Please try again shortly.'**
  String get bootMaintenanceDefault;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to PraniDoctor'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Veterinary care for your animals — book doctors, track appointments, and get help when you need it.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeGetStarted;

  /// No description provided for @rememberSession.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in'**
  String get rememberSession;

  /// No description provided for @authSignInWithOtp.
  ///
  /// In en, this message translates to:
  /// **'Sign in with OTP'**
  String get authSignInWithOtp;

  /// No description provided for @authUsePassword.
  ///
  /// In en, this message translates to:
  /// **'Use password instead'**
  String get authUsePassword;

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpResendWait.
  ///
  /// In en, this message translates to:
  /// **'Resend available in {seconds}s'**
  String otpResendWait(int seconds);

  /// No description provided for @otpChangePhone.
  ///
  /// In en, this message translates to:
  /// **'Change mobile number'**
  String get otpChangePhone;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Password reset is not available in the app yet. Please contact support to recover your account.'**
  String get forgotPasswordBody;

  /// No description provided for @forgotPasswordCallSupport.
  ///
  /// In en, this message translates to:
  /// **'Call support'**
  String get forgotPasswordCallSupport;

  /// No description provided for @forgotPasswordUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Support phone is unavailable offline. Try again when connected.'**
  String get forgotPasswordUnavailable;

  /// No description provided for @forgotPasswordUseOtp.
  ///
  /// In en, this message translates to:
  /// **'Sign in with OTP instead'**
  String get forgotPasswordUseOtp;

  /// No description provided for @authInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Bangladesh mobile number (01XXXXXXXXX).'**
  String get authInvalidPhone;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 4–6 digit code from SMS.'**
  String get authInvalidOtp;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authPasswordTooShort;

  /// No description provided for @socialLoginComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Google and Facebook sign-in coming soon.'**
  String get socialLoginComingSoon;

  /// No description provided for @socialGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get socialGoogle;

  /// No description provided for @socialFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get socialFacebook;

  /// No description provided for @dashboardSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get dashboardSummaryTitle;

  /// No description provided for @dashboardTotalFarms.
  ///
  /// In en, this message translates to:
  /// **'Farms'**
  String get dashboardTotalFarms;

  /// No description provided for @dashboardTotalAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get dashboardTotalAnimals;

  /// No description provided for @dashboardAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get dashboardAppointments;

  /// No description provided for @dashboardNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get dashboardNotifications;

  /// No description provided for @dashboardQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardQuickActionsTitle;

  /// No description provided for @dashboardCreateFarm.
  ///
  /// In en, this message translates to:
  /// **'Create farm'**
  String get dashboardCreateFarm;

  /// No description provided for @dashboardAddAnimal.
  ///
  /// In en, this message translates to:
  /// **'Add animal'**
  String get dashboardAddAnimal;

  /// No description provided for @dashboardViewRecords.
  ///
  /// In en, this message translates to:
  /// **'View records'**
  String get dashboardViewRecords;

  /// No description provided for @dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load dashboard'**
  String get dashboardLoadError;

  /// No description provided for @dashboardOfflineError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach server. Showing saved data when available.'**
  String get dashboardOfflineError;

  /// No description provided for @dashboardOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved dashboard (offline)'**
  String get dashboardOfflineHint;

  /// No description provided for @dashboardEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Set up your farm location and add animals to get started.'**
  String get dashboardEmptyHint;

  /// No description provided for @dashboardRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get dashboardRetry;

  /// No description provided for @dashboardUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get dashboardUnauthorized;

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashboardGreetingMorning;

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashboardGreetingAfternoon;

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get dashboardGreetingEvening;

  /// No description provided for @dashboardSectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this section'**
  String get dashboardSectionError;

  /// No description provided for @dashboardSectionOffline.
  ///
  /// In en, this message translates to:
  /// **'This section is unavailable offline'**
  String get dashboardSectionOffline;

  /// No description provided for @dashboardUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming appointments'**
  String get dashboardUpcomingAppointments;

  /// No description provided for @dashboardNoAppointments.
  ///
  /// In en, this message translates to:
  /// **'No active appointments'**
  String get dashboardNoAppointments;

  /// No description provided for @dashboardAppointmentFallback.
  ///
  /// In en, this message translates to:
  /// **'Service request'**
  String get dashboardAppointmentFallback;

  /// No description provided for @dashboardViewAllAppointments.
  ///
  /// In en, this message translates to:
  /// **'View all appointments'**
  String get dashboardViewAllAppointments;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent notifications'**
  String get dashboardNoActivity;

  /// No description provided for @dashboardViewAllActivity.
  ///
  /// In en, this message translates to:
  /// **'View all notifications'**
  String get dashboardViewAllActivity;

  /// No description provided for @dashboardHealthAlerts.
  ///
  /// In en, this message translates to:
  /// **'Health alerts'**
  String get dashboardHealthAlerts;

  /// No description provided for @dashboardNoHealthAlerts.
  ///
  /// In en, this message translates to:
  /// **'No vaccine reminders right now'**
  String get dashboardNoHealthAlerts;

  /// No description provided for @dashboardHealthOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue vaccines'**
  String get dashboardHealthOverdue;

  /// No description provided for @dashboardHealthUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get dashboardHealthUpcoming;

  /// No description provided for @dashboardViewHealthAlerts.
  ///
  /// In en, this message translates to:
  /// **'View vaccine reminders'**
  String get dashboardViewHealthAlerts;

  /// No description provided for @dashboardSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get dashboardSupportTitle;

  /// No description provided for @dashboardSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us or open a support ticket'**
  String get dashboardSupportSubtitle;

  /// No description provided for @dashboardSupportHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse help articles and FAQs'**
  String get dashboardSupportHelpSubtitle;

  /// No description provided for @dashboardSupportTickets.
  ///
  /// In en, this message translates to:
  /// **'My support tickets'**
  String get dashboardSupportTickets;

  /// No description provided for @dashboardEmergencyPhone.
  ///
  /// In en, this message translates to:
  /// **'Emergency: {phone}'**
  String dashboardEmergencyPhone(String phone);

  /// No description provided for @dashboardAiTechnicianTitle.
  ///
  /// In en, this message translates to:
  /// **'Technician dashboard'**
  String get dashboardAiTechnicianTitle;

  /// No description provided for @dashboardAiTodayRequests.
  ///
  /// In en, this message translates to:
  /// **'Today\'s requests'**
  String get dashboardAiTodayRequests;

  /// No description provided for @dashboardAiPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get dashboardAiPendingRequests;

  /// No description provided for @dashboardAiCompletedServices.
  ///
  /// In en, this message translates to:
  /// **'Completed services'**
  String get dashboardAiCompletedServices;

  /// No description provided for @dashboardAiRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get dashboardAiRating;

  /// No description provided for @farmListTitle.
  ///
  /// In en, this message translates to:
  /// **'My farms'**
  String get farmListTitle;

  /// No description provided for @farmDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm details'**
  String get farmDetailTitle;

  /// No description provided for @farmCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create farm'**
  String get farmCreateTitle;

  /// No description provided for @farmEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit farm'**
  String get farmEditTitle;

  /// No description provided for @farmNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm name'**
  String get farmNameLabel;

  /// No description provided for @farmSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search farms'**
  String get farmSearchHint;

  /// No description provided for @farmFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get farmFilterAll;

  /// No description provided for @farmFilterHasAnimals.
  ///
  /// In en, this message translates to:
  /// **'With animals'**
  String get farmFilterHasAnimals;

  /// No description provided for @farmEmpty.
  ///
  /// In en, this message translates to:
  /// **'No farm registered yet. Create your first farm to get started.'**
  String get farmEmpty;

  /// No description provided for @farmNoResults.
  ///
  /// In en, this message translates to:
  /// **'No farms match your search'**
  String get farmNoResults;

  /// No description provided for @farmLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load farms'**
  String get farmLoadError;

  /// No description provided for @farmRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get farmRetry;

  /// No description provided for @farmOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved farms (offline)'**
  String get farmOfflineHint;

  /// No description provided for @farmLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your village to save the farm'**
  String get farmLocationRequired;

  /// No description provided for @farmSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get farmSummaryTitle;

  /// No description provided for @farmActiveAnimals.
  ///
  /// In en, this message translates to:
  /// **'Active animals'**
  String get farmActiveAnimals;

  /// No description provided for @farmRelatedAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals on this farm'**
  String get farmRelatedAnimals;

  /// No description provided for @farmNoAnimals.
  ///
  /// In en, this message translates to:
  /// **'No animals registered yet'**
  String get farmNoAnimals;

  /// No description provided for @farmUploadCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get farmUploadCamera;

  /// No description provided for @farmUploadGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get farmUploadGallery;

  /// No description provided for @farmUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get farmUploadFailed;

  /// No description provided for @farmSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get farmSaveDraft;

  /// No description provided for @farmDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get farmDraftSaved;

  /// No description provided for @farmFilterNeedsLocation.
  ///
  /// In en, this message translates to:
  /// **'Needs location'**
  String get farmFilterNeedsLocation;

  /// No description provided for @farmSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get farmSortLabel;

  /// No description provided for @farmSortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get farmSortNameAsc;

  /// No description provided for @farmSortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name (Z–A)'**
  String get farmSortNameDesc;

  /// No description provided for @farmSortAnimalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Most animals'**
  String get farmSortAnimalsDesc;

  /// No description provided for @farmSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm settings'**
  String get farmSettingsTitle;

  /// No description provided for @farmRefreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh farm data'**
  String get farmRefreshData;

  /// No description provided for @farmRefreshStarted.
  ///
  /// In en, this message translates to:
  /// **'Refreshing farm data…'**
  String get farmRefreshStarted;

  /// No description provided for @farmActiveFarm.
  ///
  /// In en, this message translates to:
  /// **'Active farm'**
  String get farmActiveFarm;

  /// No description provided for @farmActiveFarmHint.
  ///
  /// In en, this message translates to:
  /// **'Used as default for records and dashboard'**
  String get farmActiveFarmHint;

  /// No description provided for @farmSetActive.
  ///
  /// In en, this message translates to:
  /// **'Set as active farm'**
  String get farmSetActive;

  /// No description provided for @farmSingleFarmNotice.
  ///
  /// In en, this message translates to:
  /// **'Your farm is linked to your profile location. Multiple farms and delete are not available yet.'**
  String get farmSingleFarmNotice;

  /// No description provided for @farmCardStats.
  ///
  /// In en, this message translates to:
  /// **'{total} animals · {active} active'**
  String farmCardStats(int total, int active);

  /// No description provided for @animalListTitle.
  ///
  /// In en, this message translates to:
  /// **'My animals'**
  String get animalListTitle;

  /// No description provided for @animalDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Animal details'**
  String get animalDetailTitle;

  /// No description provided for @animalAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add animal'**
  String get animalAddTitle;

  /// No description provided for @animalFormStepBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get animalFormStepBasics;

  /// No description provided for @animalFormStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get animalFormStepDetails;

  /// No description provided for @animalFormStepMetrics.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get animalFormStepMetrics;

  /// No description provided for @animalFormStepNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get animalFormStepNotes;

  /// No description provided for @animalFormStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String animalFormStepOf(int current, int total);

  /// No description provided for @animalFormNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get animalFormNext;

  /// No description provided for @animalFormBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get animalFormBack;

  /// No description provided for @animalBreedSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search breed'**
  String get animalBreedSearchHint;

  /// No description provided for @animalHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Health score'**
  String get animalHealthScore;

  /// No description provided for @animalHealthScorePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get animalHealthScorePlaceholder;

  /// No description provided for @animalNextReminder.
  ///
  /// In en, this message translates to:
  /// **'Next reminder'**
  String get animalNextReminder;

  /// No description provided for @animalNextReminderPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'No upcoming reminders'**
  String get animalNextReminderPlaceholder;

  /// No description provided for @animalQrCode.
  ///
  /// In en, this message translates to:
  /// **'Animal QR'**
  String get animalQrCode;

  /// No description provided for @animalQrPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'QR code coming soon'**
  String get animalQrPlaceholder;

  /// No description provided for @animalOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get animalOverviewTitle;

  /// No description provided for @animalDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get animalDocumentsTitle;

  /// No description provided for @animalDocumentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded'**
  String get animalDocumentsEmpty;

  /// No description provided for @animalVaccinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Vaccines'**
  String get animalVaccinesTitle;

  /// No description provided for @animalReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get animalReportsTitle;

  /// No description provided for @animalDoctorHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor visits'**
  String get animalDoctorHistoryTitle;

  /// No description provided for @animalEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit animal'**
  String get animalEditTitle;

  /// No description provided for @animalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search animals'**
  String get animalSearchHint;

  /// No description provided for @animalFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get animalFilterAll;

  /// No description provided for @animalFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get animalFilterActive;

  /// No description provided for @animalFilterLivestock.
  ///
  /// In en, this message translates to:
  /// **'Livestock'**
  String get animalFilterLivestock;

  /// No description provided for @animalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No animals registered yet.'**
  String get animalEmpty;

  /// No description provided for @animalNoResults.
  ///
  /// In en, this message translates to:
  /// **'No animals match your search'**
  String get animalNoResults;

  /// No description provided for @animalLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load animals'**
  String get animalLoadError;

  /// No description provided for @animalRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get animalRetry;

  /// No description provided for @animalOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved animals (offline)'**
  String get animalOfflineHint;

  /// No description provided for @animalTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Animal type'**
  String get animalTypeLabel;

  /// No description provided for @animalTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag / ID'**
  String get animalTagLabel;

  /// No description provided for @animalBreedLabel.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get animalBreedLabel;

  /// No description provided for @animalWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get animalWeightLabel;

  /// No description provided for @animalAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age (years)'**
  String get animalAgeLabel;

  /// No description provided for @animalGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get animalGenderLabel;

  /// No description provided for @animalGenderUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get animalGenderUnknown;

  /// No description provided for @animalNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get animalNotesLabel;

  /// No description provided for @animalNameOrTagRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name or tag'**
  String get animalNameOrTagRequired;

  /// No description provided for @animalTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get animalTimelineTitle;

  /// No description provided for @animalHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Care history'**
  String get animalHistoryTitle;

  /// No description provided for @animalNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No appointments for this animal yet'**
  String get animalNoHistory;

  /// No description provided for @animalSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get animalSaveDraft;

  /// No description provided for @animalDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get animalDraftSaved;

  /// No description provided for @animalSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get animalSummaryTotal;

  /// No description provided for @animalSummaryActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get animalSummaryActive;

  /// No description provided for @animalSummaryLivestock.
  ///
  /// In en, this message translates to:
  /// **'Livestock'**
  String get animalSummaryLivestock;

  /// No description provided for @animalFilterInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get animalFilterInactive;

  /// No description provided for @animalFilterPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get animalFilterPets;

  /// No description provided for @animalSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get animalSortLabel;

  /// No description provided for @animalSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get animalSortRecent;

  /// No description provided for @animalSortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get animalSortNameAsc;

  /// No description provided for @animalSortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name (Z–A)'**
  String get animalSortNameDesc;

  /// No description provided for @animalSortType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get animalSortType;

  /// No description provided for @animalStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get animalStatusInactive;

  /// No description provided for @animalDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate animal'**
  String get animalDeactivateTitle;

  /// No description provided for @animalDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'This animal will be marked inactive. You can still view it using the Inactive filter.'**
  String get animalDeactivateMessage;

  /// No description provided for @animalDeactivateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get animalDeactivateConfirm;

  /// No description provided for @animalViewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View full photo'**
  String get animalViewPhoto;

  /// No description provided for @animalVaccinesShortcut.
  ///
  /// In en, this message translates to:
  /// **'Vaccines'**
  String get animalVaccinesShortcut;

  /// No description provided for @animalTreatmentsShortcut.
  ///
  /// In en, this message translates to:
  /// **'Treatments'**
  String get animalTreatmentsShortcut;

  /// No description provided for @animalWeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid weight in kg'**
  String get animalWeightInvalid;

  /// No description provided for @animalAgeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid age in years'**
  String get animalAgeInvalid;

  /// No description provided for @animalUploadCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get animalUploadCamera;

  /// No description provided for @animalUploadGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get animalUploadGallery;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @batchListTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups & batches'**
  String get batchListTitle;

  /// No description provided for @batchDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch details'**
  String get batchDetailTitle;

  /// No description provided for @batchAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Create batch'**
  String get batchAddTitle;

  /// No description provided for @batchEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit batch'**
  String get batchEditTitle;

  /// No description provided for @batchSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search groups'**
  String get batchSearchHint;

  /// No description provided for @batchFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get batchFilterAll;

  /// No description provided for @batchFilterActive.
  ///
  /// In en, this message translates to:
  /// **'With animals'**
  String get batchFilterActive;

  /// No description provided for @batchFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get batchFilterEmpty;

  /// No description provided for @batchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No batches yet. Create a group to organize your animals.'**
  String get batchEmpty;

  /// No description provided for @batchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No batches match your search'**
  String get batchNoResults;

  /// No description provided for @batchLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load batches'**
  String get batchLoadError;

  /// No description provided for @batchRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get batchRetry;

  /// No description provided for @batchOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved batches (offline or pending API)'**
  String get batchOfflineHint;

  /// No description provided for @batchOfflineSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved locally — will sync when the batches API is available'**
  String get batchOfflineSaved;

  /// No description provided for @batchPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get batchPendingSync;

  /// No description provided for @batchAutoGroup.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get batchAutoGroup;

  /// No description provided for @batchAnimalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} animals'**
  String batchAnimalCount(int count);

  /// No description provided for @batchNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Batch name'**
  String get batchNameLabel;

  /// No description provided for @batchTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Animal type'**
  String get batchTypeLabel;

  /// No description provided for @batchLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location / pen'**
  String get batchLocationLabel;

  /// No description provided for @batchNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get batchNotesLabel;

  /// No description provided for @batchNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a batch name (at least 2 characters)'**
  String get batchNameRequired;

  /// No description provided for @batchAnimalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Animals in batch'**
  String get batchAnimalsTitle;

  /// No description provided for @batchNoAnimals.
  ///
  /// In en, this message translates to:
  /// **'No animals in this batch'**
  String get batchNoAnimals;

  /// No description provided for @batchMovementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Movement history'**
  String get batchMovementsTitle;

  /// No description provided for @batchNoMovements.
  ///
  /// In en, this message translates to:
  /// **'No movements recorded yet'**
  String get batchNoMovements;

  /// No description provided for @batchMoveAction.
  ///
  /// In en, this message translates to:
  /// **'Move animals'**
  String get batchMoveAction;

  /// No description provided for @batchMergeAction.
  ///
  /// In en, this message translates to:
  /// **'Merge batch'**
  String get batchMergeAction;

  /// No description provided for @batchMoveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Animals moved'**
  String get batchMoveSuccess;

  /// No description provided for @batchMergeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Batches merged'**
  String get batchMergeSuccess;

  /// No description provided for @batchMoveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Add another batch and animals before moving'**
  String get batchMoveUnavailable;

  /// No description provided for @batchMergeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Create another batch to merge into'**
  String get batchMergeUnavailable;

  /// No description provided for @batchMoveTarget.
  ///
  /// In en, this message translates to:
  /// **'Move to batch'**
  String get batchMoveTarget;

  /// No description provided for @batchMergeTarget.
  ///
  /// In en, this message translates to:
  /// **'Merge into batch'**
  String get batchMergeTarget;

  /// No description provided for @batchMoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get batchMoveConfirm;

  /// No description provided for @batchMergeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get batchMergeConfirm;

  /// No description provided for @batchMoveInvalid.
  ///
  /// In en, this message translates to:
  /// **'Select a target batch and at least one animal'**
  String get batchMoveInvalid;

  /// No description provided for @batchMergeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Select a different target batch'**
  String get batchMergeInvalid;

  /// No description provided for @batchMergeHint.
  ///
  /// In en, this message translates to:
  /// **'All animals from this batch will join the selected batch. This batch will be removed.'**
  String get batchMergeHint;

  /// No description provided for @batchSelectAnimals.
  ///
  /// In en, this message translates to:
  /// **'Assign animals'**
  String get batchSelectAnimals;

  /// No description provided for @batchAnimalsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load animals for assignment'**
  String get batchAnimalsLoadError;

  /// No description provided for @batchSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get batchSaveDraft;

  /// No description provided for @batchDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get batchDraftSaved;

  /// No description provided for @batchSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get batchSaveChanges;

  /// No description provided for @batchCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create batch'**
  String get batchCreateAction;

  /// No description provided for @batchSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total batches'**
  String get batchSummaryTotal;

  /// No description provided for @batchSummaryWithAnimals.
  ///
  /// In en, this message translates to:
  /// **'With animals'**
  String get batchSummaryWithAnimals;

  /// No description provided for @batchSummaryPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get batchSummaryPendingSync;

  /// No description provided for @batchSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get batchSortLabel;

  /// No description provided for @batchSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get batchSortRecent;

  /// No description provided for @batchSortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get batchSortNameAsc;

  /// No description provided for @batchSortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name (Z–A)'**
  String get batchSortNameDesc;

  /// No description provided for @batchSortAnimalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Most animals'**
  String get batchSortAnimalsDesc;

  /// No description provided for @batchDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete batch'**
  String get batchDeleteAction;

  /// No description provided for @batchDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this batch? Animals will not be deleted.'**
  String get batchDeleteConfirm;

  /// No description provided for @batchDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Batch deleted'**
  String get batchDeleteSuccess;

  /// No description provided for @batchEmptyStatus.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get batchEmptyStatus;

  /// No description provided for @offlineItemBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch change'**
  String get offlineItemBatch;

  /// No description provided for @milkEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Milk records'**
  String get milkEntryTitle;

  /// No description provided for @milkAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Record milk'**
  String get milkAddTitle;

  /// No description provided for @milkEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit milk record'**
  String get milkEditTitle;

  /// No description provided for @milkSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily summary'**
  String get milkSummaryTitle;

  /// No description provided for @milkChartsTitle.
  ///
  /// In en, this message translates to:
  /// **'Production charts'**
  String get milkChartsTitle;

  /// No description provided for @milkLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load milk records'**
  String get milkLoadError;

  /// No description provided for @milkRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get milkRetry;

  /// No description provided for @milkEmpty.
  ///
  /// In en, this message translates to:
  /// **'No milk records yet.'**
  String get milkEmpty;

  /// No description provided for @milkOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved milk data (offline)'**
  String get milkOfflineHint;

  /// No description provided for @milkOfflineSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved offline — will sync when online'**
  String get milkOfflineSaved;

  /// No description provided for @milkPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get milkPendingSync;

  /// No description provided for @milkFarmLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get milkFarmLabel;

  /// No description provided for @milkAnimalLabel.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get milkAnimalLabel;

  /// No description provided for @milkDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get milkDateLabel;

  /// No description provided for @milkQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity (liters)'**
  String get milkQuantityLabel;

  /// No description provided for @milkNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get milkNotesLabel;

  /// No description provided for @milkSessionMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get milkSessionMorning;

  /// No description provided for @milkSessionEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get milkSessionEvening;

  /// No description provided for @milkAnimalRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an animal'**
  String get milkAnimalRequired;

  /// No description provided for @milkQuantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity in liters'**
  String get milkQuantityRequired;

  /// No description provided for @milkDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Date cannot be in the future'**
  String get milkDateInvalid;

  /// No description provided for @milkSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get milkSaveDraft;

  /// No description provided for @milkDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get milkDraftSaved;

  /// No description provided for @milkSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get milkSaveChanges;

  /// No description provided for @milkCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Save record'**
  String get milkCreateAction;

  /// No description provided for @milkDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get milkDeleteTitle;

  /// No description provided for @milkDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this milk entry?'**
  String get milkDeleteConfirm;

  /// No description provided for @milkDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get milkDeleteAction;

  /// No description provided for @milkFarmLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load farms'**
  String get milkFarmLoadError;

  /// No description provided for @milkAnimalLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load animals'**
  String get milkAnimalLoadError;

  /// No description provided for @milkNoFarm.
  ///
  /// In en, this message translates to:
  /// **'Set up your farm location first'**
  String get milkNoFarm;

  /// No description provided for @milkNoCattle.
  ///
  /// In en, this message translates to:
  /// **'Add cattle to record milk production'**
  String get milkNoCattle;

  /// No description provided for @milkTodayTotal.
  ///
  /// In en, this message translates to:
  /// **'Total production'**
  String get milkTodayTotal;

  /// No description provided for @milkLiters.
  ///
  /// In en, this message translates to:
  /// **'{liters} L'**
  String milkLiters(double liters);

  /// No description provided for @milkPerAnimalTitle.
  ///
  /// In en, this message translates to:
  /// **'Per animal'**
  String get milkPerAnimalTitle;

  /// No description provided for @milkPerDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get milkPerDayTitle;

  /// No description provided for @milkDailyProductionTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily production'**
  String get milkDailyProductionTitle;

  /// No description provided for @milkWeeklyTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly trend'**
  String get milkWeeklyTrendTitle;

  /// No description provided for @milkMonthlyTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly trend'**
  String get milkMonthlyTrendTitle;

  /// No description provided for @milkSessionSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning vs evening'**
  String get milkSessionSplitTitle;

  /// No description provided for @milkQuickAction.
  ///
  /// In en, this message translates to:
  /// **'Record milk'**
  String get milkQuickAction;

  /// No description provided for @milkDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Milk record details'**
  String get milkDetailTitle;

  /// No description provided for @milkSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search records'**
  String get milkSearchHint;

  /// No description provided for @milkNoResults.
  ///
  /// In en, this message translates to:
  /// **'No records match your filters'**
  String get milkNoResults;

  /// No description provided for @milkFromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get milkFromDate;

  /// No description provided for @milkToDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get milkToDate;

  /// No description provided for @milkFilterAllAnimals.
  ///
  /// In en, this message translates to:
  /// **'All animals'**
  String get milkFilterAllAnimals;

  /// No description provided for @milkFilterAllSessions.
  ///
  /// In en, this message translates to:
  /// **'All sessions'**
  String get milkFilterAllSessions;

  /// No description provided for @milkSummaryToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get milkSummaryToday;

  /// No description provided for @milkSummaryEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get milkSummaryEntries;

  /// No description provided for @milkSummaryPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get milkSummaryPendingSync;

  /// No description provided for @milkDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get milkDeleteSuccess;

  /// No description provided for @offlineItemMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk record'**
  String get offlineItemMilk;

  /// No description provided for @dashboardRecordMilk.
  ///
  /// In en, this message translates to:
  /// **'Record milk'**
  String get dashboardRecordMilk;

  /// No description provided for @feedEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed records'**
  String get feedEntryTitle;

  /// No description provided for @feedAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Record feed'**
  String get feedAddTitle;

  /// No description provided for @feedEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit feed record'**
  String get feedEditTitle;

  /// No description provided for @feedCostTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed cost'**
  String get feedCostTitle;

  /// No description provided for @feedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load feed records'**
  String get feedLoadError;

  /// No description provided for @feedRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get feedRetry;

  /// No description provided for @feedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No feed records yet.'**
  String get feedEmpty;

  /// No description provided for @feedOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved feed data (offline)'**
  String get feedOfflineHint;

  /// No description provided for @feedOfflineSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved offline — will sync when online'**
  String get feedOfflineSaved;

  /// No description provided for @feedPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get feedPendingSync;

  /// No description provided for @feedSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search feed history'**
  String get feedSearchHint;

  /// No description provided for @feedFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get feedFilterAll;

  /// No description provided for @feedFarmLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get feedFarmLabel;

  /// No description provided for @feedAnimalLabel.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get feedAnimalLabel;

  /// No description provided for @feedGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group / batch'**
  String get feedGroupLabel;

  /// No description provided for @feedTargetAnimal.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get feedTargetAnimal;

  /// No description provided for @feedTargetGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get feedTargetGroup;

  /// No description provided for @feedTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Feed type'**
  String get feedTypeLabel;

  /// No description provided for @feedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get feedAmountLabel;

  /// No description provided for @feedUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get feedUnitLabel;

  /// No description provided for @feedCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost (BDT)'**
  String get feedCostLabel;

  /// No description provided for @feedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get feedDateLabel;

  /// No description provided for @feedNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get feedNotesLabel;

  /// No description provided for @feedTargetRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an animal or group'**
  String get feedTargetRequired;

  /// No description provided for @feedAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get feedAmountRequired;

  /// No description provided for @feedDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Date cannot be in the future'**
  String get feedDateInvalid;

  /// No description provided for @feedSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get feedSaveDraft;

  /// No description provided for @feedDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get feedDraftSaved;

  /// No description provided for @feedSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get feedSaveChanges;

  /// No description provided for @feedCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Save record'**
  String get feedCreateAction;

  /// No description provided for @feedDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get feedDeleteTitle;

  /// No description provided for @feedDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this feed entry?'**
  String get feedDeleteConfirm;

  /// No description provided for @feedDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get feedDeleteAction;

  /// No description provided for @feedFarmLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load farms'**
  String get feedFarmLoadError;

  /// No description provided for @feedAnimalLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load animals'**
  String get feedAnimalLoadError;

  /// No description provided for @feedGroupLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load groups'**
  String get feedGroupLoadError;

  /// No description provided for @feedNoFarm.
  ///
  /// In en, this message translates to:
  /// **'Set up your farm location first'**
  String get feedNoFarm;

  /// No description provided for @feedNoAnimals.
  ///
  /// In en, this message translates to:
  /// **'Add animals to record feed'**
  String get feedNoAnimals;

  /// No description provided for @feedNoGroups.
  ///
  /// In en, this message translates to:
  /// **'Create a group to assign feed'**
  String get feedNoGroups;

  /// No description provided for @feedTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total feed cost'**
  String get feedTotalCost;

  /// No description provided for @feedTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get feedTotalAmount;

  /// No description provided for @feedCostValue.
  ///
  /// In en, this message translates to:
  /// **'৳{cost}'**
  String feedCostValue(double cost);

  /// No description provided for @feedDailyCostTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily cost'**
  String get feedDailyCostTitle;

  /// No description provided for @feedWeeklyCostTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly cost'**
  String get feedWeeklyCostTitle;

  /// No description provided for @feedMonthlyCostTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly cost'**
  String get feedMonthlyCostTitle;

  /// No description provided for @feedPerAnimalTitle.
  ///
  /// In en, this message translates to:
  /// **'Cost per animal'**
  String get feedPerAnimalTitle;

  /// No description provided for @feedAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get feedAnalyticsTitle;

  /// No description provided for @feedAnalyticsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load analytics'**
  String get feedAnalyticsError;

  /// No description provided for @feedCostBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Cost breakdown by type'**
  String get feedCostBreakdownTitle;

  /// No description provided for @feedConsumptionTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Consumption trend'**
  String get feedConsumptionTrendTitle;

  /// No description provided for @feedEfficiencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Efficiency metrics'**
  String get feedEfficiencyTitle;

  /// No description provided for @feedCostPerKg.
  ///
  /// In en, this message translates to:
  /// **'Cost per kg equivalent'**
  String get feedCostPerKg;

  /// No description provided for @feedCostPerAnimal.
  ///
  /// In en, this message translates to:
  /// **'Cost per active animal'**
  String get feedCostPerAnimal;

  /// No description provided for @feedAvgCostPerRecord.
  ///
  /// In en, this message translates to:
  /// **'Average cost per record'**
  String get feedAvgCostPerRecord;

  /// No description provided for @feedQuickAction.
  ///
  /// In en, this message translates to:
  /// **'Record feed'**
  String get feedQuickAction;

  /// No description provided for @feedDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed record details'**
  String get feedDetailTitle;

  /// No description provided for @feedNoResults.
  ///
  /// In en, this message translates to:
  /// **'No records match your filters'**
  String get feedNoResults;

  /// No description provided for @feedFromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get feedFromDate;

  /// No description provided for @feedToDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get feedToDate;

  /// No description provided for @feedFilterAllAnimals.
  ///
  /// In en, this message translates to:
  /// **'All animals'**
  String get feedFilterAllAnimals;

  /// No description provided for @feedFilterAllGroups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get feedFilterAllGroups;

  /// No description provided for @feedFilterAllTargets.
  ///
  /// In en, this message translates to:
  /// **'All targets'**
  String get feedFilterAllTargets;

  /// No description provided for @feedSummaryCost.
  ///
  /// In en, this message translates to:
  /// **'Period cost'**
  String get feedSummaryCost;

  /// No description provided for @feedSummaryEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get feedSummaryEntries;

  /// No description provided for @feedSummaryPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get feedSummaryPendingSync;

  /// No description provided for @feedDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get feedDeleteSuccess;

  /// No description provided for @offlineItemFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed record'**
  String get offlineItemFeed;

  /// No description provided for @dashboardRecordFeed.
  ///
  /// In en, this message translates to:
  /// **'Record feed'**
  String get dashboardRecordFeed;

  /// No description provided for @financeExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get financeExpenseTitle;

  /// No description provided for @financeIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get financeIncomeTitle;

  /// No description provided for @financeProfitTitle.
  ///
  /// In en, this message translates to:
  /// **'Profit & reports'**
  String get financeProfitTitle;

  /// No description provided for @financeExpenseAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get financeExpenseAddTitle;

  /// No description provided for @financeExpenseEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get financeExpenseEditTitle;

  /// No description provided for @financeIncomeAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get financeIncomeAddTitle;

  /// No description provided for @financeIncomeEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit income'**
  String get financeIncomeEditTitle;

  /// No description provided for @financeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load finance data'**
  String get financeLoadError;

  /// No description provided for @financeRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get financeRetry;

  /// No description provided for @financeExpenseEmpty.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded yet'**
  String get financeExpenseEmpty;

  /// No description provided for @financeIncomeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No income recorded yet'**
  String get financeIncomeEmpty;

  /// No description provided for @financeOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing cached data — will refresh when online'**
  String get financeOfflineHint;

  /// No description provided for @financeOfflineSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved offline — will sync when online'**
  String get financeOfflineSaved;

  /// No description provided for @financePendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get financePendingSync;

  /// No description provided for @financeExpenseSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search expense notes'**
  String get financeExpenseSearchHint;

  /// No description provided for @financeIncomeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search income history'**
  String get financeIncomeSearchHint;

  /// No description provided for @financeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get financeFilterAll;

  /// No description provided for @financeFarmLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get financeFarmLabel;

  /// No description provided for @financeCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get financeCategoryLabel;

  /// No description provided for @financeSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get financeSourceLabel;

  /// No description provided for @financeAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (BDT)'**
  String get financeAmountLabel;

  /// No description provided for @financeDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get financeDateLabel;

  /// No description provided for @financeNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get financeNotesLabel;

  /// No description provided for @financeAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get financeAmountRequired;

  /// No description provided for @financeDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Date cannot be in the future'**
  String get financeDateInvalid;

  /// No description provided for @financeSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get financeSaveDraft;

  /// No description provided for @financeDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get financeDraftSaved;

  /// No description provided for @financeSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get financeSaveChanges;

  /// No description provided for @financeCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Save record'**
  String get financeCreateAction;

  /// No description provided for @financeDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get financeDeleteTitle;

  /// No description provided for @financeExpenseDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this expense?'**
  String get financeExpenseDeleteConfirm;

  /// No description provided for @financeIncomeDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this income record?'**
  String get financeIncomeDeleteConfirm;

  /// No description provided for @financeDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get financeDeleteAction;

  /// No description provided for @financeFarmLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load farms'**
  String get financeFarmLoadError;

  /// No description provided for @financeNoFarm.
  ///
  /// In en, this message translates to:
  /// **'Set up your farm location first'**
  String get financeNoFarm;

  /// No description provided for @financeAmountValue.
  ///
  /// In en, this message translates to:
  /// **'৳{amount}'**
  String financeAmountValue(double amount);

  /// No description provided for @financeProfitSummary.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get financeProfitSummary;

  /// No description provided for @financePeriodRange.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get financePeriodRange;

  /// No description provided for @financeTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get financeTotalIncome;

  /// No description provided for @financeTotalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total expense'**
  String get financeTotalExpense;

  /// No description provided for @financeProfitChange.
  ///
  /// In en, this message translates to:
  /// **'Change vs previous period: {percent}%'**
  String financeProfitChange(double percent);

  /// No description provided for @financePreviousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get financePreviousPeriod;

  /// No description provided for @financeIncomeTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Income trend'**
  String get financeIncomeTrendTitle;

  /// No description provided for @financeExpenseTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense trend'**
  String get financeExpenseTrendTitle;

  /// No description provided for @financeProfitTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Profit trend'**
  String get financeProfitTrendTitle;

  /// No description provided for @financeChartsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load charts'**
  String get financeChartsError;

  /// No description provided for @financeReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get financeReportsTitle;

  /// No description provided for @financeReportsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load reports'**
  String get financeReportsError;

  /// No description provided for @financeExpenseByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category'**
  String get financeExpenseByCategory;

  /// No description provided for @financeIncomeBySource.
  ///
  /// In en, this message translates to:
  /// **'Income by source'**
  String get financeIncomeBySource;

  /// No description provided for @financeRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String financeRecordCount(int count);

  /// No description provided for @financeExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get financeExportTitle;

  /// No description provided for @financeExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Copy CSV export path'**
  String get financeExportCsv;

  /// No description provided for @financeExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Copy PDF export path'**
  String get financeExportPdf;

  /// No description provided for @financeExportCopied.
  ///
  /// In en, this message translates to:
  /// **'Export path copied'**
  String get financeExportCopied;

  /// No description provided for @financeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get financeEmpty;

  /// No description provided for @financeCategoryFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get financeCategoryFeed;

  /// No description provided for @financeCategoryMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get financeCategoryMedicine;

  /// No description provided for @financeCategoryLabor.
  ///
  /// In en, this message translates to:
  /// **'Labor'**
  String get financeCategoryLabor;

  /// No description provided for @financeCategoryEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get financeCategoryEquipment;

  /// No description provided for @financeCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get financeCategoryTransport;

  /// No description provided for @financeCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get financeCategoryOther;

  /// No description provided for @financeSourceMilkSales.
  ///
  /// In en, this message translates to:
  /// **'Milk sales'**
  String get financeSourceMilkSales;

  /// No description provided for @financeSourceAnimalSales.
  ///
  /// In en, this message translates to:
  /// **'Animal sales'**
  String get financeSourceAnimalSales;

  /// No description provided for @financeSourceSubsidy.
  ///
  /// In en, this message translates to:
  /// **'Subsidy'**
  String get financeSourceSubsidy;

  /// No description provided for @financeSourceService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get financeSourceService;

  /// No description provided for @financeSourceOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get financeSourceOther;

  /// No description provided for @financeDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get financeDashboardTitle;

  /// No description provided for @financeLedgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get financeLedgerTitle;

  /// No description provided for @financeLedgerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet. Add income or expenses to build your ledger.'**
  String get financeLedgerEmpty;

  /// No description provided for @financeExpenseDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense details'**
  String get financeExpenseDetailTitle;

  /// No description provided for @financeIncomeDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Income details'**
  String get financeIncomeDetailTitle;

  /// No description provided for @financeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No records match your filters'**
  String get financeNoResults;

  /// No description provided for @financeFromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get financeFromDate;

  /// No description provided for @financeToDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get financeToDate;

  /// No description provided for @financeSummaryEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get financeSummaryEntries;

  /// No description provided for @financeSummaryPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get financeSummaryPendingSync;

  /// No description provided for @financeDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get financeDeleteSuccess;

  /// No description provided for @offlineItemFinanceExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense record'**
  String get offlineItemFinanceExpense;

  /// No description provided for @offlineItemFinanceIncome.
  ///
  /// In en, this message translates to:
  /// **'Income record'**
  String get offlineItemFinanceIncome;

  /// No description provided for @dashboardRecordFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get dashboardRecordFinance;

  /// No description provided for @healthHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Health history'**
  String get healthHistoryTitle;

  /// No description provided for @healthTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Health timeline'**
  String get healthTimelineTitle;

  /// No description provided for @healthDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Health record'**
  String get healthDetailTitle;

  /// No description provided for @healthAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Record health event'**
  String get healthAddTitle;

  /// No description provided for @healthEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit health record'**
  String get healthEditTitle;

  /// No description provided for @healthLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load health records'**
  String get healthLoadError;

  /// No description provided for @healthRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get healthRetry;

  /// No description provided for @healthEmpty.
  ///
  /// In en, this message translates to:
  /// **'No health records yet.'**
  String get healthEmpty;

  /// No description provided for @healthOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved health data (offline)'**
  String get healthOfflineHint;

  /// No description provided for @healthOfflineSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved offline — will sync when online'**
  String get healthOfflineSaved;

  /// No description provided for @healthPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get healthPendingSync;

  /// No description provided for @healthSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search health history'**
  String get healthSearchHint;

  /// No description provided for @healthFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get healthFilterAll;

  /// No description provided for @healthFarmLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get healthFarmLabel;

  /// No description provided for @healthAnimalLabel.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get healthAnimalLabel;

  /// No description provided for @healthTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get healthTypeLabel;

  /// No description provided for @healthTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get healthTitleLabel;

  /// No description provided for @healthSymptomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get healthSymptomsLabel;

  /// No description provided for @healthDiagnosisLabel.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get healthDiagnosisLabel;

  /// No description provided for @healthDiseaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Disease'**
  String get healthDiseaseLabel;

  /// No description provided for @healthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get healthDateLabel;

  /// No description provided for @healthNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get healthNotesLabel;

  /// No description provided for @healthTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get healthTitleRequired;

  /// No description provided for @healthAnimalRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an animal'**
  String get healthAnimalRequired;

  /// No description provided for @healthDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Date cannot be in the future'**
  String get healthDateInvalid;

  /// No description provided for @healthSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get healthSaveDraft;

  /// No description provided for @healthDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get healthDraftSaved;

  /// No description provided for @healthSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get healthSaveChanges;

  /// No description provided for @healthCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Save record'**
  String get healthCreateAction;

  /// No description provided for @healthDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get healthDeleteTitle;

  /// No description provided for @healthDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this health record?'**
  String get healthDeleteConfirm;

  /// No description provided for @healthDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get healthDeleteAction;

  /// No description provided for @healthFarmLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load farms'**
  String get healthFarmLoadError;

  /// No description provided for @healthAnimalLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load animals'**
  String get healthAnimalLoadError;

  /// No description provided for @healthNoFarm.
  ///
  /// In en, this message translates to:
  /// **'Set up your farm location first'**
  String get healthNoFarm;

  /// No description provided for @healthNoAnimals.
  ///
  /// In en, this message translates to:
  /// **'Add animals to record health events'**
  String get healthNoAnimals;

  /// No description provided for @healthTypeSymptom.
  ///
  /// In en, this message translates to:
  /// **'Symptom'**
  String get healthTypeSymptom;

  /// No description provided for @healthTypeDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get healthTypeDiagnosis;

  /// No description provided for @healthTypeDisease.
  ///
  /// In en, this message translates to:
  /// **'Disease'**
  String get healthTypeDisease;

  /// No description provided for @healthTypeCheckup.
  ///
  /// In en, this message translates to:
  /// **'Checkup'**
  String get healthTypeCheckup;

  /// No description provided for @healthTypeTreatmentRef.
  ///
  /// In en, this message translates to:
  /// **'Treatment reference'**
  String get healthTypeTreatmentRef;

  /// No description provided for @healthQuickAction.
  ///
  /// In en, this message translates to:
  /// **'Record health'**
  String get healthQuickAction;

  /// No description provided for @healthDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthDashboardTitle;

  /// No description provided for @healthRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical records'**
  String get healthRecordsTitle;

  /// No description provided for @healthAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Health analytics'**
  String get healthAnalyticsTitle;

  /// No description provided for @healthRecentEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent events'**
  String get healthRecentEventsTitle;

  /// No description provided for @healthFromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get healthFromDate;

  /// No description provided for @healthToDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get healthToDate;

  /// No description provided for @healthSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total events'**
  String get healthSummaryTotal;

  /// No description provided for @healthSummaryDisease.
  ///
  /// In en, this message translates to:
  /// **'Disease / diagnosis'**
  String get healthSummaryDisease;

  /// No description provided for @healthSummaryCheckup.
  ///
  /// In en, this message translates to:
  /// **'Checkups'**
  String get healthSummaryCheckup;

  /// No description provided for @healthSummaryTreatment.
  ///
  /// In en, this message translates to:
  /// **'Treatments'**
  String get healthSummaryTreatment;

  /// No description provided for @healthSummaryEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get healthSummaryEntries;

  /// No description provided for @healthSummaryPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get healthSummaryPendingSync;

  /// No description provided for @healthNoResults.
  ///
  /// In en, this message translates to:
  /// **'No records match your filters'**
  String get healthNoResults;

  /// No description provided for @healthDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Health record deleted'**
  String get healthDeleteSuccess;

  /// No description provided for @healthTreatmentLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked treatment'**
  String get healthTreatmentLinkLabel;

  /// No description provided for @healthVaccineRefLabel.
  ///
  /// In en, this message translates to:
  /// **'Vaccine reference'**
  String get healthVaccineRefLabel;

  /// No description provided for @healthAnalyticsTypeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Event type breakdown'**
  String get healthAnalyticsTypeBreakdown;

  /// No description provided for @healthAnalyticsDiseaseFrequency.
  ///
  /// In en, this message translates to:
  /// **'Disease frequency'**
  String get healthAnalyticsDiseaseFrequency;

  /// No description provided for @healthAnalyticsNoDiseases.
  ///
  /// In en, this message translates to:
  /// **'No disease names recorded in this period'**
  String get healthAnalyticsNoDiseases;

  /// No description provided for @healthAnalyticsMonthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly event trend'**
  String get healthAnalyticsMonthlyTrend;

  /// No description provided for @offlineItemHealth.
  ///
  /// In en, this message translates to:
  /// **'Health record'**
  String get offlineItemHealth;

  /// No description provided for @dashboardRecordHealth.
  ///
  /// In en, this message translates to:
  /// **'Health records'**
  String get dashboardRecordHealth;

  /// No description provided for @vaccineScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Vaccine schedule'**
  String get vaccineScheduleTitle;

  /// No description provided for @vaccineRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Vaccine reminders'**
  String get vaccineRemindersTitle;

  /// No description provided for @vaccineAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule vaccine'**
  String get vaccineAddTitle;

  /// No description provided for @vaccineEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit vaccine'**
  String get vaccineEditTitle;

  /// No description provided for @vaccineLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load vaccines'**
  String get vaccineLoadError;

  /// No description provided for @vaccineRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get vaccineRetry;

  /// No description provided for @vaccineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No vaccines scheduled yet.'**
  String get vaccineEmpty;

  /// No description provided for @vaccineOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved vaccine data (offline)'**
  String get vaccineOfflineHint;

  /// No description provided for @vaccineOfflineSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved offline — will sync when online'**
  String get vaccineOfflineSaved;

  /// No description provided for @vaccinePendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get vaccinePendingSync;

  /// No description provided for @vaccineFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get vaccineFilterAll;

  /// No description provided for @vaccineFarmLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get vaccineFarmLabel;

  /// No description provided for @vaccineAnimalLabel.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get vaccineAnimalLabel;

  /// No description provided for @vaccineNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Vaccine name'**
  String get vaccineNameLabel;

  /// No description provided for @vaccineTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Vaccine type'**
  String get vaccineTypeLabel;

  /// No description provided for @vaccineScheduledDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Scheduled date'**
  String get vaccineScheduledDateLabel;

  /// No description provided for @vaccineAdministeredDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Administered date'**
  String get vaccineAdministeredDateLabel;

  /// No description provided for @vaccineNotAdministered.
  ///
  /// In en, this message translates to:
  /// **'Not yet administered'**
  String get vaccineNotAdministered;

  /// No description provided for @vaccineBatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Batch number'**
  String get vaccineBatchLabel;

  /// No description provided for @vaccineNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get vaccineNotesLabel;

  /// No description provided for @vaccineNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter vaccine name'**
  String get vaccineNameRequired;

  /// No description provided for @vaccineAnimalRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an animal'**
  String get vaccineAnimalRequired;

  /// No description provided for @vaccineDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid scheduled date'**
  String get vaccineDateInvalid;

  /// No description provided for @vaccineSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get vaccineSaveDraft;

  /// No description provided for @vaccineDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get vaccineDraftSaved;

  /// No description provided for @vaccineSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get vaccineSaveChanges;

  /// No description provided for @vaccineCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Save record'**
  String get vaccineCreateAction;

  /// No description provided for @vaccineDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get vaccineDeleteTitle;

  /// No description provided for @vaccineDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this vaccine record?'**
  String get vaccineDeleteConfirm;

  /// No description provided for @vaccineDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get vaccineDeleteAction;

  /// No description provided for @vaccineFarmLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load farms'**
  String get vaccineFarmLoadError;

  /// No description provided for @vaccineAnimalLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load animals'**
  String get vaccineAnimalLoadError;

  /// No description provided for @vaccineNoFarm.
  ///
  /// In en, this message translates to:
  /// **'Set up your farm location first'**
  String get vaccineNoFarm;

  /// No description provided for @vaccineNoAnimals.
  ///
  /// In en, this message translates to:
  /// **'Add animals to schedule vaccines'**
  String get vaccineNoAnimals;

  /// No description provided for @vaccineOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get vaccineOverdueTitle;

  /// No description provided for @vaccineUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get vaccineUpcomingTitle;

  /// No description provided for @vaccineStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get vaccineStatusScheduled;

  /// No description provided for @vaccineStatusDue.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get vaccineStatusDue;

  /// No description provided for @vaccineStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get vaccineStatusOverdue;

  /// No description provided for @vaccineStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get vaccineStatusCompleted;

  /// No description provided for @vaccineDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Vaccines'**
  String get vaccineDashboardTitle;

  /// No description provided for @vaccineHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Vaccine history'**
  String get vaccineHistoryTitle;

  /// No description provided for @vaccineCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Vaccine calendar'**
  String get vaccineCalendarTitle;

  /// No description provided for @vaccineDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Vaccine record'**
  String get vaccineDetailTitle;

  /// No description provided for @vaccineSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search vaccines'**
  String get vaccineSearchHint;

  /// No description provided for @vaccineFromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get vaccineFromDate;

  /// No description provided for @vaccineToDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get vaccineToDate;

  /// No description provided for @vaccineSummaryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get vaccineSummaryCompleted;

  /// No description provided for @vaccineSummaryUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get vaccineSummaryUpcoming;

  /// No description provided for @vaccineSummaryOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get vaccineSummaryOverdue;

  /// No description provided for @vaccineSummaryEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get vaccineSummaryEntries;

  /// No description provided for @vaccineSummaryPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get vaccineSummaryPendingSync;

  /// No description provided for @vaccineNoResults.
  ///
  /// In en, this message translates to:
  /// **'No vaccines match your filters'**
  String get vaccineNoResults;

  /// No description provided for @vaccineDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vaccine record deleted'**
  String get vaccineDeleteSuccess;

  /// No description provided for @vaccineNextDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Next due date'**
  String get vaccineNextDueLabel;

  /// No description provided for @vaccineNextDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get vaccineNextDueTitle;

  /// No description provided for @vaccineReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{name} for {animal}'**
  String vaccineReminderBody(Object animal, Object name);

  /// No description provided for @vaccineCalendarLegend.
  ///
  /// In en, this message translates to:
  /// **'Scheduled this month'**
  String get vaccineCalendarLegend;

  /// No description provided for @offlineItemVaccine.
  ///
  /// In en, this message translates to:
  /// **'Vaccine record'**
  String get offlineItemVaccine;

  /// No description provided for @treatmentListTitle.
  ///
  /// In en, this message translates to:
  /// **'Treatments'**
  String get treatmentListTitle;

  /// No description provided for @treatmentDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Treatment detail'**
  String get treatmentDetailTitle;

  /// No description provided for @treatmentAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add treatment'**
  String get treatmentAddTitle;

  /// No description provided for @treatmentEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit treatment'**
  String get treatmentEditTitle;

  /// No description provided for @treatmentLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load treatments'**
  String get treatmentLoadError;

  /// No description provided for @treatmentRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get treatmentRetry;

  /// No description provided for @treatmentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No treatments recorded yet.'**
  String get treatmentEmpty;

  /// No description provided for @treatmentOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved treatment data (offline)'**
  String get treatmentOfflineHint;

  /// No description provided for @treatmentOfflineSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved offline — will sync when online'**
  String get treatmentOfflineSaved;

  /// No description provided for @treatmentPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get treatmentPendingSync;

  /// No description provided for @treatmentSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search treatments'**
  String get treatmentSearchHint;

  /// No description provided for @treatmentFarmLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get treatmentFarmLabel;

  /// No description provided for @treatmentAnimalLabel.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get treatmentAnimalLabel;

  /// No description provided for @treatmentTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get treatmentTitleLabel;

  /// No description provided for @treatmentDiagnosisLabel.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get treatmentDiagnosisLabel;

  /// No description provided for @treatmentPrescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Prescription notes'**
  String get treatmentPrescriptionLabel;

  /// No description provided for @treatmentPrescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get treatmentPrescriptionTitle;

  /// No description provided for @treatmentMedicinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get treatmentMedicinesTitle;

  /// No description provided for @treatmentMedicineNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Medicine name'**
  String get treatmentMedicineNameLabel;

  /// No description provided for @treatmentDosageLabel.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get treatmentDosageLabel;

  /// No description provided for @treatmentFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get treatmentFrequencyLabel;

  /// No description provided for @treatmentDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (days)'**
  String get treatmentDurationLabel;

  /// No description provided for @treatmentDaysSuffix.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get treatmentDaysSuffix;

  /// No description provided for @treatmentAddMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add medicine'**
  String get treatmentAddMedicine;

  /// No description provided for @treatmentNoMedicines.
  ///
  /// In en, this message translates to:
  /// **'No medicines listed'**
  String get treatmentNoMedicines;

  /// No description provided for @treatmentStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get treatmentStartDateLabel;

  /// No description provided for @treatmentEndDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get treatmentEndDateLabel;

  /// No description provided for @treatmentNoEndDate.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get treatmentNoEndDate;

  /// No description provided for @treatmentNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get treatmentNotesLabel;

  /// No description provided for @treatmentTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get treatmentTitleRequired;

  /// No description provided for @treatmentAnimalRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an animal'**
  String get treatmentAnimalRequired;

  /// No description provided for @treatmentMedicineRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter medicine name and dosage'**
  String get treatmentMedicineRequired;

  /// No description provided for @treatmentDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid start date'**
  String get treatmentDateInvalid;

  /// No description provided for @treatmentSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get treatmentSaveDraft;

  /// No description provided for @treatmentDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get treatmentDraftSaved;

  /// No description provided for @treatmentSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get treatmentSaveChanges;

  /// No description provided for @treatmentCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Save treatment'**
  String get treatmentCreateAction;

  /// No description provided for @treatmentDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete treatment'**
  String get treatmentDeleteTitle;

  /// No description provided for @treatmentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this treatment?'**
  String get treatmentDeleteConfirm;

  /// No description provided for @treatmentDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get treatmentDeleteAction;

  /// No description provided for @treatmentFarmLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load farms'**
  String get treatmentFarmLoadError;

  /// No description provided for @treatmentAnimalLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load animals'**
  String get treatmentAnimalLoadError;

  /// No description provided for @treatmentNoFarm.
  ///
  /// In en, this message translates to:
  /// **'Set up your farm location first'**
  String get treatmentNoFarm;

  /// No description provided for @treatmentNoAnimals.
  ///
  /// In en, this message translates to:
  /// **'Add animals to record treatments'**
  String get treatmentNoAnimals;

  /// No description provided for @treatmentStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get treatmentStatusActive;

  /// No description provided for @treatmentStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get treatmentStatusCompleted;

  /// No description provided for @treatmentStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get treatmentStatusCancelled;

  /// No description provided for @treatmentDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Treatments'**
  String get treatmentDashboardTitle;

  /// No description provided for @treatmentTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Treatment timeline'**
  String get treatmentTimelineTitle;

  /// No description provided for @treatmentMedicinePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Medicine plan'**
  String get treatmentMedicinePlanTitle;

  /// No description provided for @treatmentFollowUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get treatmentFollowUpTitle;

  /// No description provided for @treatmentFollowUpAction.
  ///
  /// In en, this message translates to:
  /// **'Update follow-up'**
  String get treatmentFollowUpAction;

  /// No description provided for @treatmentFollowUpBody.
  ///
  /// In en, this message translates to:
  /// **'{title} for {animal}'**
  String treatmentFollowUpBody(Object title, Object animal);

  /// No description provided for @treatmentNoFollowUp.
  ///
  /// In en, this message translates to:
  /// **'No follow-ups due soon'**
  String get treatmentNoFollowUp;

  /// No description provided for @treatmentViewPrescription.
  ///
  /// In en, this message translates to:
  /// **'View full prescription'**
  String get treatmentViewPrescription;

  /// No description provided for @treatmentFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get treatmentFilterAll;

  /// No description provided for @treatmentFromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get treatmentFromDate;

  /// No description provided for @treatmentToDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get treatmentToDate;

  /// No description provided for @treatmentSummaryActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get treatmentSummaryActive;

  /// No description provided for @treatmentSummaryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get treatmentSummaryCompleted;

  /// No description provided for @treatmentSummaryOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue follow-up'**
  String get treatmentSummaryOverdue;

  /// No description provided for @treatmentSummaryEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get treatmentSummaryEntries;

  /// No description provided for @treatmentSummaryPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get treatmentSummaryPendingSync;

  /// No description provided for @treatmentNoResults.
  ///
  /// In en, this message translates to:
  /// **'No treatments match your filters'**
  String get treatmentNoResults;

  /// No description provided for @treatmentDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Treatment deleted'**
  String get treatmentDeleteSuccess;

  /// No description provided for @treatmentMedicineCount.
  ///
  /// In en, this message translates to:
  /// **'{count} medicines'**
  String treatmentMedicineCount(int count);

  /// No description provided for @offlineItemTreatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment record'**
  String get offlineItemTreatment;

  /// No description provided for @notificationLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get notificationLoadError;

  /// No description provided for @notificationRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get notificationRetry;

  /// No description provided for @notificationOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing cached notifications — will refresh when online'**
  String get notificationOfflineHint;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get notificationSettingsSaved;

  /// No description provided for @notificationSaveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get notificationSaveSettings;

  /// No description provided for @notificationPushToggle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get notificationPushToggle;

  /// No description provided for @notificationPushToggleHint.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts on this device'**
  String get notificationPushToggleHint;

  /// No description provided for @notificationMarketingToggle.
  ///
  /// In en, this message translates to:
  /// **'Marketing updates'**
  String get notificationMarketingToggle;

  /// No description provided for @notificationTreatmentReminderToggle.
  ///
  /// In en, this message translates to:
  /// **'Treatment reminders'**
  String get notificationTreatmentReminderToggle;

  /// No description provided for @notificationVaccineReminderToggle.
  ///
  /// In en, this message translates to:
  /// **'Vaccine reminders'**
  String get notificationVaccineReminderToggle;

  /// No description provided for @notificationOrderServiceToggle.
  ///
  /// In en, this message translates to:
  /// **'Orders & service updates'**
  String get notificationOrderServiceToggle;

  /// No description provided for @notificationGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationGroupToday;

  /// No description provided for @notificationGroupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notificationGroupYesterday;

  /// No description provided for @notificationGroupEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notificationGroupEarlier;

  /// No description provided for @notificationDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get notificationDeleteTitle;

  /// No description provided for @notificationDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this notification?'**
  String get notificationDeleteConfirm;

  /// No description provided for @notificationDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get notificationDeleteAction;

  /// No description provided for @notificationUnreadLabel.
  ///
  /// In en, this message translates to:
  /// **'Unread notification'**
  String get notificationUnreadLabel;

  /// No description provided for @notificationCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification center'**
  String get notificationCenterTitle;

  /// No description provided for @notificationViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get notificationViewAll;

  /// No description provided for @notificationRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent notifications'**
  String get notificationRecentTitle;

  /// No description provided for @notificationSummaryUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationSummaryUnread;

  /// No description provided for @notificationSummaryRecent.
  ///
  /// In en, this message translates to:
  /// **'Loaded'**
  String get notificationSummaryRecent;

  /// No description provided for @notificationDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationDetailTitle;

  /// No description provided for @notificationDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Notification not found'**
  String get notificationDetailNotFound;

  /// No description provided for @notificationMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get notificationMarkRead;

  /// No description provided for @notificationOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notificationOpenAction;

  /// No description provided for @notificationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notifications'**
  String get notificationSearchHint;

  /// No description provided for @notificationFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationFilterAll;

  /// No description provided for @notificationFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationFilterUnread;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification permission'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to receive appointment updates, reminders, and service alerts on this device.'**
  String get notificationPermissionBody;

  /// No description provided for @notificationPermissionRequest.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notificationPermissionRequest;

  /// No description provided for @notificationPermissionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get notificationPermissionOpenSettings;

  /// No description provided for @notificationPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationPermissionGranted;

  /// No description provided for @notificationPermissionGrantedStatus.
  ///
  /// In en, this message translates to:
  /// **'Notifications are enabled'**
  String get notificationPermissionGrantedStatus;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled'**
  String get notificationPermissionDenied;

  /// No description provided for @notificationPermissionDeniedPermanent.
  ///
  /// In en, this message translates to:
  /// **'Notifications blocked — enable in system settings'**
  String get notificationPermissionDeniedPermanent;

  /// No description provided for @notificationPermissionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Notification permission status unknown'**
  String get notificationPermissionUnknown;

  /// No description provided for @supportTicketListTitle.
  ///
  /// In en, this message translates to:
  /// **'Support tickets'**
  String get supportTicketListTitle;

  /// No description provided for @supportTicketDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket details'**
  String get supportTicketDetailTitle;

  /// No description provided for @supportCreateTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Create ticket'**
  String get supportCreateTicketTitle;

  /// No description provided for @supportCreateTicket.
  ///
  /// In en, this message translates to:
  /// **'New ticket'**
  String get supportCreateTicket;

  /// No description provided for @supportHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get supportHelpTitle;

  /// No description provided for @supportHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ, contact, and tickets'**
  String get supportHelpSubtitle;

  /// No description provided for @supportRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get supportRetry;

  /// No description provided for @supportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No support tickets yet.'**
  String get supportEmpty;

  /// No description provided for @supportOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved support data (offline)'**
  String get supportOfflineHint;

  /// No description provided for @supportPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get supportPendingSync;

  /// No description provided for @supportSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tickets'**
  String get supportSearchHint;

  /// No description provided for @supportFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get supportFilterAll;

  /// No description provided for @supportStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get supportStatusOpen;

  /// No description provided for @supportStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get supportStatusInProgress;

  /// No description provided for @supportStatusWaitingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get supportStatusWaitingCustomer;

  /// No description provided for @supportStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get supportStatusResolved;

  /// No description provided for @supportStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get supportStatusClosed;

  /// No description provided for @supportCategoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get supportCategoryAccount;

  /// No description provided for @supportCategoryBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get supportCategoryBilling;

  /// No description provided for @supportCategoryTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get supportCategoryTechnical;

  /// No description provided for @supportCategoryAnimalHealth.
  ///
  /// In en, this message translates to:
  /// **'Animal health'**
  String get supportCategoryAnimalHealth;

  /// No description provided for @supportCategoryAppUsage.
  ///
  /// In en, this message translates to:
  /// **'App usage'**
  String get supportCategoryAppUsage;

  /// No description provided for @supportCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportCategoryOther;

  /// No description provided for @supportPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get supportPriorityLow;

  /// No description provided for @supportPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get supportPriorityMedium;

  /// No description provided for @supportPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get supportPriorityHigh;

  /// No description provided for @supportPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get supportPriorityUrgent;

  /// No description provided for @supportCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get supportCategoryLabel;

  /// No description provided for @supportPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get supportPriorityLabel;

  /// No description provided for @supportSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get supportSubjectLabel;

  /// No description provided for @supportDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get supportDescriptionLabel;

  /// No description provided for @supportSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Subject is required'**
  String get supportSubjectRequired;

  /// No description provided for @supportDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get supportDescriptionRequired;

  /// No description provided for @supportSubjectTooShort.
  ///
  /// In en, this message translates to:
  /// **'Subject must be at least 3 characters'**
  String get supportSubjectTooShort;

  /// No description provided for @supportDescriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 10 characters'**
  String get supportDescriptionTooShort;

  /// No description provided for @supportAttachmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get supportAttachmentsLabel;

  /// No description provided for @supportAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get supportAddImage;

  /// No description provided for @supportAddDocument.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get supportAddDocument;

  /// No description provided for @supportUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed — check connection and retry'**
  String get supportUploadFailed;

  /// No description provided for @supportUploadComplete.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get supportUploadComplete;

  /// No description provided for @supportSubmitTicket.
  ///
  /// In en, this message translates to:
  /// **'Submit ticket'**
  String get supportSubmitTicket;

  /// No description provided for @supportSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get supportSubmitting;

  /// No description provided for @supportReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write your reply'**
  String get supportReplyHint;

  /// No description provided for @supportSendReply.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get supportSendReply;

  /// No description provided for @supportReplySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent'**
  String get supportReplySent;

  /// No description provided for @supportCloseTicket.
  ///
  /// In en, this message translates to:
  /// **'Close ticket'**
  String get supportCloseTicket;

  /// No description provided for @supportReopenTicket.
  ///
  /// In en, this message translates to:
  /// **'Reopen ticket'**
  String get supportReopenTicket;

  /// No description provided for @supportTicketClosed.
  ///
  /// In en, this message translates to:
  /// **'Ticket closed'**
  String get supportTicketClosed;

  /// No description provided for @supportTicketReopened.
  ///
  /// In en, this message translates to:
  /// **'Ticket reopened'**
  String get supportTicketReopened;

  /// No description provided for @supportTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get supportTimelineTitle;

  /// No description provided for @supportTimelineSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get supportTimelineSystem;

  /// No description provided for @supportQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get supportQuickActionsTitle;

  /// No description provided for @supportContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get supportContactTitle;

  /// No description provided for @supportCallSupport.
  ///
  /// In en, this message translates to:
  /// **'Call support'**
  String get supportCallSupport;

  /// No description provided for @supportWhatsappSupport.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp support'**
  String get supportWhatsappSupport;

  /// No description provided for @supportEmailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get supportEmailSupport;

  /// No description provided for @supportFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get supportFaqTitle;

  /// No description provided for @supportHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportHomeTitle;

  /// No description provided for @supportRecentTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent tickets'**
  String get supportRecentTicketsTitle;

  /// No description provided for @supportSummaryOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get supportSummaryOpen;

  /// No description provided for @supportSummaryPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get supportSummaryPending;

  /// No description provided for @supportSummaryResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get supportSummaryResolved;

  /// No description provided for @supportSummaryClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get supportSummaryClosed;

  /// No description provided for @supportFaqSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search FAQ'**
  String get supportFaqSearchHint;

  /// No description provided for @supportFaqEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching questions'**
  String get supportFaqEmpty;

  /// No description provided for @supportContactBody.
  ///
  /// In en, this message translates to:
  /// **'Reach our team by phone, WhatsApp, email, or open a support ticket.'**
  String get supportContactBody;

  /// No description provided for @supportOpenAttachment.
  ///
  /// In en, this message translates to:
  /// **'Open attachment'**
  String get supportOpenAttachment;

  /// No description provided for @offlineItemSupport.
  ///
  /// In en, this message translates to:
  /// **'Support ticket'**
  String get offlineItemSupport;

  /// No description provided for @offlineItemAiChat.
  ///
  /// In en, this message translates to:
  /// **'AI message'**
  String get offlineItemAiChat;

  /// No description provided for @dashboardAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get dashboardAskAi;

  /// No description provided for @aiAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get aiAskTitle;

  /// No description provided for @aiVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get aiVoiceTitle;

  /// No description provided for @aiRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get aiRetry;

  /// No description provided for @aiEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Ask a question about your farm or animals.'**
  String get aiEmptyState;

  /// No description provided for @aiOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved conversation — will sync when online'**
  String get aiOfflineHint;

  /// No description provided for @aiMicPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for voice input.'**
  String get aiMicPermissionDenied;

  /// No description provided for @aiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI guidance is informational only — not a substitute for a veterinarian.'**
  String get aiDisclaimer;

  /// No description provided for @aiInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type your question'**
  String get aiInputHint;

  /// No description provided for @aiSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get aiSend;

  /// No description provided for @aiMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a message'**
  String get aiMessageRequired;

  /// No description provided for @aiMessageTooLong.
  ///
  /// In en, this message translates to:
  /// **'Message is too long'**
  String get aiMessageTooLong;

  /// No description provided for @aiLocaleBn.
  ///
  /// In en, this message translates to:
  /// **'Bangla'**
  String get aiLocaleBn;

  /// No description provided for @aiLocaleEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get aiLocaleEn;

  /// No description provided for @aiSuggestionFeed.
  ///
  /// In en, this message translates to:
  /// **'How much feed for a cow?'**
  String get aiSuggestionFeed;

  /// No description provided for @aiSuggestionVaccine.
  ///
  /// In en, this message translates to:
  /// **'When is the next vaccine due?'**
  String get aiSuggestionVaccine;

  /// No description provided for @aiSuggestionSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Check symptoms (triage)'**
  String get aiSuggestionSymptoms;

  /// No description provided for @aiTriageTitle.
  ///
  /// In en, this message translates to:
  /// **'Symptom check'**
  String get aiTriageTitle;

  /// No description provided for @aiSymptomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get aiSymptomsLabel;

  /// No description provided for @aiSymptomsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. fever, low milk, not eating'**
  String get aiSymptomsHint;

  /// No description provided for @aiSymptomsRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one symptom'**
  String get aiSymptomsRequired;

  /// No description provided for @aiRunTriage.
  ///
  /// In en, this message translates to:
  /// **'Check urgency'**
  String get aiRunTriage;

  /// No description provided for @aiPossibleConcern.
  ///
  /// In en, this message translates to:
  /// **'Possible concern'**
  String get aiPossibleConcern;

  /// No description provided for @aiUrgencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get aiUrgencyLabel;

  /// No description provided for @aiUrgencyLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get aiUrgencyLow;

  /// No description provided for @aiUrgencyMedium.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get aiUrgencyMedium;

  /// No description provided for @aiUrgencyHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get aiUrgencyHigh;

  /// No description provided for @aiRecommendedAction.
  ///
  /// In en, this message translates to:
  /// **'Recommended action'**
  String get aiRecommendedAction;

  /// No description provided for @aiDoctorSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Doctor suggestion'**
  String get aiDoctorSuggestion;

  /// No description provided for @aiFindVet.
  ///
  /// In en, this message translates to:
  /// **'Find a veterinarian'**
  String get aiFindVet;

  /// No description provided for @aiVoiceInstructions.
  ///
  /// In en, this message translates to:
  /// **'Tap to speak. Stop when finished, then review the text before sending.'**
  String get aiVoiceInstructions;

  /// No description provided for @aiVoiceTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone to start'**
  String get aiVoiceTapHint;

  /// No description provided for @aiVoiceStart.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get aiVoiceStart;

  /// No description provided for @aiVoiceStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get aiVoiceStop;

  /// No description provided for @aiVoiceUseText.
  ///
  /// In en, this message translates to:
  /// **'Use text in chat'**
  String get aiVoiceUseText;

  /// No description provided for @aiEmptyTranscript.
  ///
  /// In en, this message translates to:
  /// **'No speech detected — try again'**
  String get aiEmptyTranscript;

  /// No description provided for @aiHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiHomeTitle;

  /// No description provided for @aiHomeActiveSession.
  ///
  /// In en, this message translates to:
  /// **'You have an active conversation.'**
  String get aiHomeActiveSession;

  /// No description provided for @aiHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation history'**
  String get aiHistoryTitle;

  /// No description provided for @aiSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get aiSessionLabel;

  /// No description provided for @aiClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear and start new chat'**
  String get aiClearHistory;

  /// No description provided for @aiSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI settings'**
  String get aiSettingsTitle;

  /// No description provided for @aiSettingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get aiSettingsLanguage;

  /// No description provided for @aiSettingsSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Show suggested prompts'**
  String get aiSettingsSuggestions;

  /// No description provided for @aiSettingsMemory.
  ///
  /// In en, this message translates to:
  /// **'Remember conversations'**
  String get aiSettingsMemory;

  /// No description provided for @aiSettingsMemoryHint.
  ///
  /// In en, this message translates to:
  /// **'Keep recent chats on this device'**
  String get aiSettingsMemoryHint;

  /// No description provided for @aiSaveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get aiSaveSettings;

  /// No description provided for @aiSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get aiSettingsSaved;

  /// No description provided for @aiResultTitle.
  ///
  /// In en, this message translates to:
  /// **'AI result'**
  String get aiResultTitle;

  /// No description provided for @aiResultEmpty.
  ///
  /// In en, this message translates to:
  /// **'No result to display'**
  String get aiResultEmpty;

  /// No description provided for @aiRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get aiRegenerate;

  /// No description provided for @aiCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get aiCopied;

  /// No description provided for @aiPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get aiPendingSync;

  /// No description provided for @aiEscalationHint.
  ///
  /// In en, this message translates to:
  /// **'Human help may be needed'**
  String get aiEscalationHint;

  /// No description provided for @aiEscalateSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get aiEscalateSupport;

  /// No description provided for @aiViewResult.
  ///
  /// In en, this message translates to:
  /// **'View full result'**
  String get aiViewResult;

  /// No description provided for @settingsRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get settingsRetry;

  /// No description provided for @settingsOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Showing saved settings (offline)'**
  String get settingsOfflineHint;

  /// No description provided for @settingsTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsTitle;

  /// No description provided for @settingsTermsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read and accept the terms'**
  String get settingsTermsSubtitle;

  /// No description provided for @settingsVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersionLabel;

  /// No description provided for @settingsAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get settingsAccepted;

  /// No description provided for @settingsOpenExternal.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get settingsOpenExternal;

  /// No description provided for @settingsAcceptPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Accept privacy policy'**
  String get settingsAcceptPrivacy;

  /// No description provided for @settingsAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Accept terms'**
  String get settingsAcceptTerms;

  /// No description provided for @settingsPrivacyAccepted.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy accepted'**
  String get settingsPrivacyAccepted;

  /// No description provided for @settingsTermsAccepted.
  ///
  /// In en, this message translates to:
  /// **'Terms accepted'**
  String get settingsTermsAccepted;

  /// No description provided for @settingsAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get settingsAccountTitle;

  /// No description provided for @settingsAccountManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage account'**
  String get settingsAccountManageTitle;

  /// No description provided for @settingsPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferencesTitle;

  /// No description provided for @settingsPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language, theme, and notifications'**
  String get settingsPreferencesSubtitle;

  /// No description provided for @settingsPreferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Your preferences'**
  String get settingsPreferencesSection;

  /// No description provided for @settingsAppTitle.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get settingsAppTitle;

  /// No description provided for @settingsAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App behavior and sync'**
  String get settingsAppSubtitle;

  /// No description provided for @settingsAppSection.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get settingsAppSection;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeSaved.
  ///
  /// In en, this message translates to:
  /// **'Theme saved'**
  String get settingsThemeSaved;

  /// No description provided for @settingsLanguageSaved.
  ///
  /// In en, this message translates to:
  /// **'Language saved'**
  String get settingsLanguageSaved;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsAboutSupportTitle;

  /// No description provided for @settingsAboutLegalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsAboutLegalTitle;

  /// No description provided for @settingsDataSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Data & sync'**
  String get settingsDataSyncTitle;

  /// No description provided for @settingsLastSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Last settings sync'**
  String get settingsLastSyncTitle;

  /// No description provided for @settingsLastSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get settingsLastSyncNever;

  /// No description provided for @settingsPendingSettingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 settings change pending} other{{count} settings changes pending}}'**
  String settingsPendingSettingsCount(int count);

  /// No description provided for @settingsHubAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsHubAccountSection;

  /// No description provided for @settingsHubAppSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsHubAppSection;

  /// No description provided for @settingsHubLegalSection.
  ///
  /// In en, this message translates to:
  /// **'Legal & privacy'**
  String get settingsHubLegalSection;

  /// No description provided for @settingsHubSupportSection.
  ///
  /// In en, this message translates to:
  /// **'Support & about'**
  String get settingsHubSupportSection;

  /// No description provided for @networkConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection check'**
  String get networkConnectionTitle;

  /// No description provided for @networkConnectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify phone can reach the PC backend over WiFi'**
  String get networkConnectionSubtitle;

  /// No description provided for @networkApiUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'API URL'**
  String get networkApiUrlLabel;

  /// No description provided for @networkApiSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'URL source'**
  String get networkApiSourceLabel;

  /// No description provided for @networkApiPortLabel.
  ///
  /// In en, this message translates to:
  /// **'API port'**
  String get networkApiPortLabel;

  /// No description provided for @networkWebUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Web URL'**
  String get networkWebUrlLabel;

  /// No description provided for @networkTimeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Timeouts'**
  String get networkTimeoutLabel;

  /// No description provided for @networkRunChecks.
  ///
  /// In en, this message translates to:
  /// **'Run checks'**
  String get networkRunChecks;

  /// No description provided for @networkReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect & sync'**
  String get networkReconnect;

  /// No description provided for @networkLastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked'**
  String get networkLastChecked;

  /// No description provided for @networkChecksPending.
  ///
  /// In en, this message translates to:
  /// **'Tap Run checks to test the connection'**
  String get networkChecksPending;

  /// No description provided for @networkProbeLive.
  ///
  /// In en, this message translates to:
  /// **'API health (/live)'**
  String get networkProbeLive;

  /// No description provided for @networkProbeAppConfig.
  ///
  /// In en, this message translates to:
  /// **'Mobile app-config'**
  String get networkProbeAppConfig;

  /// No description provided for @networkProbeAuth.
  ///
  /// In en, this message translates to:
  /// **'Auth profile (/me)'**
  String get networkProbeAuth;

  /// No description provided for @networkProbeRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh token'**
  String get networkProbeRefresh;

  /// No description provided for @networkProbeUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload / storage'**
  String get networkProbeUpload;

  /// No description provided for @offlineItemSettingsSync.
  ///
  /// In en, this message translates to:
  /// **'Settings sync'**
  String get offlineItemSettingsSync;

  /// No description provided for @profileEditPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get profileEditPersonalInfo;

  /// No description provided for @profileEditAddressSection.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get profileEditAddressSection;

  /// No description provided for @profileEditPreviewSection.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get profileEditPreviewSection;

  /// No description provided for @profileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving profile…'**
  String get profileSaving;

  /// No description provided for @profileUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get profileUploading;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileDiscardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get profileDiscardChangesTitle;

  /// No description provided for @profileDiscardChangesBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Leave without saving?'**
  String get profileDiscardChangesBody;

  /// No description provided for @profileDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get profileDiscard;

  /// No description provided for @profileKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get profileKeepEditing;

  /// No description provided for @profileCoverUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload cover'**
  String get profileCoverUpload;

  /// No description provided for @profileAvatarChange.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileAvatarChange;

  /// No description provided for @profileRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profileRemovePhoto;

  /// No description provided for @profileRemoveCover.
  ///
  /// In en, this message translates to:
  /// **'Remove cover'**
  String get profileRemoveCover;

  /// No description provided for @profilePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get profilePreviewTitle;

  /// No description provided for @profilePhoneReadonly.
  ///
  /// In en, this message translates to:
  /// **'Phone number cannot be changed here'**
  String get profilePhoneReadonly;

  /// No description provided for @profileUpdatedButton.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdatedButton;

  /// No description provided for @homeVaccineDue.
  ///
  /// In en, this message translates to:
  /// **'Vaccine due'**
  String get homeVaccineDue;

  /// No description provided for @homeTasksLabel.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get homeTasksLabel;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeViewAll;

  /// No description provided for @homeNoAnimalsYet.
  ///
  /// In en, this message translates to:
  /// **'No animals yet. Add your first animal to get started.'**
  String get homeNoAnimalsYet;

  /// No description provided for @homeHealthTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming health tasks'**
  String get homeHealthTasksTitle;

  /// No description provided for @homeNoHealthTasks.
  ///
  /// In en, this message translates to:
  /// **'No upcoming health tasks right now.'**
  String get homeNoHealthTasks;

  /// No description provided for @homeBookDoctor.
  ///
  /// In en, this message translates to:
  /// **'Book doctor'**
  String get homeBookDoctor;

  /// No description provided for @homeNearbyServices.
  ///
  /// In en, this message translates to:
  /// **'Nearby services'**
  String get homeNearbyServices;

  /// No description provided for @homeUploadReport.
  ///
  /// In en, this message translates to:
  /// **'Upload report'**
  String get homeUploadReport;

  /// No description provided for @homeHealthHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Health history'**
  String get homeHealthHistoryAction;

  /// No description provided for @homeDrawerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get homeDrawerDashboard;

  /// No description provided for @homeDrawerOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get homeDrawerOrders;

  /// No description provided for @homeMarketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get homeMarketplaceTitle;

  /// No description provided for @homeMarketplaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse farm supplies and services from trusted sellers.'**
  String get homeMarketplaceSubtitle;

  /// No description provided for @homeCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get homeCommunityTitle;

  /// No description provided for @homeCommunitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect with farmers and share knowledge.'**
  String get homeCommunitySubtitle;

  /// No description provided for @homeDrawerPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get homeDrawerPayments;

  /// No description provided for @homeNoDoctorsNearby.
  ///
  /// In en, this message translates to:
  /// **'No doctors found nearby. Try adjusting your location filters.'**
  String get homeNoDoctorsNearby;

  /// No description provided for @homePlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'This section is coming soon. Check back in a future update.'**
  String get homePlaceholderBody;

  /// No description provided for @homeReportsExportHint.
  ///
  /// In en, this message translates to:
  /// **'Export CSV or PDF from the full reports screen.'**
  String get homeReportsExportHint;

  /// No description provided for @homeMarketplaceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No services available in your area yet.'**
  String get homeMarketplaceEmpty;

  /// No description provided for @homeMarketplaceCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get homeMarketplaceCategories;

  /// No description provided for @homeCommunityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No community tips yet. Visit help for guides.'**
  String get homeCommunityEmpty;

  /// No description provided for @homeOrdersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No orders yet. Book a service to get started.'**
  String get homeOrdersEmpty;

  /// No description provided for @homeOrdersPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get homeOrdersPending;

  /// No description provided for @homeOrdersCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get homeOrdersCompleted;

  /// No description provided for @homeOrdersCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get homeOrdersCancelled;

  /// No description provided for @homeOrdersRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent orders'**
  String get homeOrdersRecentTitle;

  /// No description provided for @homeSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'ডাক্তার, সার্ভিস, AI, চিকিৎসা সার্চ করুন'**
  String get homeSearchPlaceholder;

  /// No description provided for @homeSearchVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice search'**
  String get homeSearchVoice;

  /// No description provided for @homeSearchListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get homeSearchListening;

  /// No description provided for @homeSearchStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get homeSearchStop;

  /// No description provided for @homeSearchRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get homeSearchRecentTitle;

  /// No description provided for @homeSearchRecentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent searches yet.'**
  String get homeSearchRecentEmpty;

  /// No description provided for @homeSearchSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Search in'**
  String get homeSearchSourcesTitle;

  /// No description provided for @homeSearchSourceDoctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get homeSearchSourceDoctors;

  /// No description provided for @homeSearchSourceAi.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get homeSearchSourceAi;

  /// No description provided for @homeSearchSourceServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get homeSearchSourceServices;

  /// No description provided for @homeSearchSourceAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get homeSearchSourceAnimals;

  /// No description provided for @homeSearchSourceMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get homeSearchSourceMarketplace;

  /// No description provided for @homeSearchSourceReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get homeSearchSourceReports;

  /// No description provided for @homeSearchSourceCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get homeSearchSourceCommunity;

  /// No description provided for @homeSearchSourceEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get homeSearchSourceEmergency;

  /// No description provided for @homeSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get homeSearchNoResults;

  /// No description provided for @homeGreetingMorningBn.
  ///
  /// In en, this message translates to:
  /// **'সুপ্রভাত'**
  String get homeGreetingMorningBn;

  /// No description provided for @homeGreetingAfternoonBn.
  ///
  /// In en, this message translates to:
  /// **'শুভ অপরাহ্ন'**
  String get homeGreetingAfternoonBn;

  /// No description provided for @homeGreetingEveningBn.
  ///
  /// In en, this message translates to:
  /// **'শুভ সন্ধ্যা'**
  String get homeGreetingEveningBn;

  /// No description provided for @homeChangeCover.
  ///
  /// In en, this message translates to:
  /// **'Change cover'**
  String get homeChangeCover;

  /// No description provided for @homeActionAiDoctor.
  ///
  /// In en, this message translates to:
  /// **'AI Doctor'**
  String get homeActionAiDoctor;

  /// No description provided for @homeActionCallDoctor.
  ///
  /// In en, this message translates to:
  /// **'Call doctor'**
  String get homeActionCallDoctor;

  /// No description provided for @homeActionAiTechnician.
  ///
  /// In en, this message translates to:
  /// **'AI Technician'**
  String get homeActionAiTechnician;

  /// No description provided for @homeActionVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get homeActionVideoCall;

  /// No description provided for @homeInstantCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Instant care'**
  String get homeInstantCareTitle;

  /// No description provided for @homeInstantCareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the fastest way to get help.'**
  String get homeInstantCareSubtitle;

  /// No description provided for @homeCareAiDoctor.
  ///
  /// In en, this message translates to:
  /// **'AI Doctor'**
  String get homeCareAiDoctor;

  /// No description provided for @homeCareAiDoctorEta.
  ///
  /// In en, this message translates to:
  /// **'Typical response: under 1 min'**
  String get homeCareAiDoctorEta;

  /// No description provided for @homeCareCallDoctor.
  ///
  /// In en, this message translates to:
  /// **'Call doctor'**
  String get homeCareCallDoctor;

  /// No description provided for @homeCareCallDoctorEta.
  ///
  /// In en, this message translates to:
  /// **'Typical response: 5–15 min'**
  String get homeCareCallDoctorEta;

  /// No description provided for @homeCareEmergencyVisit.
  ///
  /// In en, this message translates to:
  /// **'Emergency visit'**
  String get homeCareEmergencyVisit;

  /// No description provided for @homeCareEmergencyVisitEta.
  ///
  /// In en, this message translates to:
  /// **'Typical response: 15–30 min'**
  String get homeCareEmergencyVisitEta;

  /// No description provided for @homeCareVideoConsultation.
  ///
  /// In en, this message translates to:
  /// **'Video consultation'**
  String get homeCareVideoConsultation;

  /// No description provided for @homeCareVideoConsultationEta.
  ///
  /// In en, this message translates to:
  /// **'Typical response: 10–20 min'**
  String get homeCareVideoConsultationEta;

  /// No description provided for @homeCareNearestService.
  ///
  /// In en, this message translates to:
  /// **'Nearest service'**
  String get homeCareNearestService;

  /// No description provided for @homeCareNearestServiceEta.
  ///
  /// In en, this message translates to:
  /// **'Based on your location'**
  String get homeCareNearestServiceEta;

  /// No description provided for @homeCareChat.
  ///
  /// In en, this message translates to:
  /// **'Chat support'**
  String get homeCareChat;

  /// No description provided for @homeCareChatEta.
  ///
  /// In en, this message translates to:
  /// **'Typical response: under 5 min'**
  String get homeCareChatEta;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'PraniDoctor member'**
  String get profileMemberSince;

  /// No description provided for @offlineModeBanner.
  ///
  /// In en, this message translates to:
  /// **'অফলাইন মোড — সর্বশেষ সংরক্ষিত তথ্য দেখানো হচ্ছে'**
  String get offlineModeBanner;
}

