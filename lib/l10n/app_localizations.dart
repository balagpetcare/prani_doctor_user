import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

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

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
