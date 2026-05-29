// Bangla finishing translator — meaning-first, glossary-aligned.

/// Returns curated Bangla for [key] / [english], or null to fall through.
String? lookupCuratedBn(String key, String english) {
  final direct = _curatedByKey[key];
  if (direct != null) return direct;

  final sentence = _curatedByEnglish[english.trim()];
  if (sentence != null) return sentence;

  return _translateByPattern(key, english);
}

/// Last-resort pass: word-replace entire [english] string (keeps placeholders).
String forceTranslateBn(String key, String english) {
  final curated = lookupCuratedBn(key, english);
  if (curated != null) return polishBn(curated);

  var result = english;
  final sorted = _wordMap.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final word in sorted) {
    result = result.replaceAll(word, _wordMap[word]!);
  }
  for (final e in _sentenceFragments.entries) {
    result = result.replaceAll(e.key, e.value);
  }
  for (final e in _phraseOverrides.entries) {
    result = result.replaceAll(e.key, e.value);
  }
  return polishBn(result);
}

const _phraseOverrides = <String, String>{
  'Could not load': 'লোড করা যায়নি',
  'Could not read': 'পড়া যায়নি',
  'Could not reach': 'যোগাযোগ করা যায়নি',
  'Could not connect': 'সংযোগ হয়নি',
  'Could not save': 'সংরক্ষণ করা যায়নি',
  'Could not update': 'আপডেট করা যায়নি',
  'Could not delete': 'মুছে ফেলা যায়নি',
  'Could not create': 'তৈরি করা যায়নি',
  'Please try again': 'আবার চেষ্টা করুন',
  'when online': 'অনলাইনে গেলে',
  'when available': 'পাওয়া গেলে',
  'Saved offline': 'অফলাইনে সংরক্ষিত',
  'will sync': 'যুক্ত হবে',
  'No ': 'কোনো ',
  ' yet': ' নেই',
  'not found': 'পাওয়া যায়নি',
  'not available': 'পাওয়া যায়নি',
  'Select a': 'একটি ',
  ' first': ' আগে',
  'Add a': 'একটি ',
  'Add your': 'আপনার',
  ' to ': ' ',
  ' for ': ' এর জন্য ',
  ' and ': ' এবং ',
  ' with ': ' সহ ',
};

/// Fixes broken partial replacements (e.g. "বাতিলled").
String polishBn(String value) {
  var v = value;
  for (final fix in _brokenFixes.entries) {
    v = v.replaceAll(fix.key, fix.value);
  }
  return v;
}

String? _translateByPattern(String key, String en) {
  final status = _statusWord(en);
  if (status != null) return status;

  if (key.endsWith('FilterAll') || en == 'All') return 'সব';
  if (key.endsWith('FilterDraft') || en == 'Draft') return 'খসড়া';
  if (key.endsWith('FilterActive') || en == 'Active') return 'সক্রিয়';
  if (key.endsWith('FilterPending') || en == 'Pending') return 'অপেক্ষমাণ';
  if (key.endsWith('FilterCompleted') || en == 'Completed') return 'সম্পন্ন';
  if (key.endsWith('FilterCancelled') || en == 'Cancelled') return 'বাতিল';
  if (key.endsWith('FilterInactive') || en == 'Inactive') return 'বন্ধ';
  if (key.endsWith('FilterMorning') || en == 'Morning') return 'সকাল';
  if (key.endsWith('FilterEvening') || en == 'Evening') return 'সন্ধ্যা';

  if (key.endsWith('Retry') || key == 'bootRetry' || key == 'areaRetry') {
    return 'আবার চেষ্টা করুন';
  }
  if (key.endsWith('Title') && en == 'Sign in') return 'প্রবেশ করুন';
  if (key.endsWith('Title') && en == 'Create account') return 'নতুন অ্যাকাউন্ট খুলুন';
  if (en == 'Try again') return 'আবার চেষ্টা করুন';
  if (en == 'Cancel') return 'বাতিল';
  if (en == 'Save') return 'সংরক্ষণ করুন';
  if (en == 'Delete') return 'মুছে ফেলুন';
  if (en == 'Edit') return 'সম্পাদনা';
  if (en == 'Add') return 'যোগ করুন';
  if (en == 'Continue') return 'এগিয়ে যান';
  if (en == 'Back') return 'পিছনে';
  if (en == 'Next') return 'পরের ধাপ';
  if (en == 'OK') return 'ঠিক আছে';
  if (en == 'Dismiss') return 'বন্ধ করুন';
  if (en == 'Refresh') return 'আপডেট করুন';
  if (en == 'Loading…' || en == 'Loading...' || en == 'Loading') {
    return 'লোড হচ্ছে';
  }
  if (en == 'Pending') return 'অপেক্ষমাণ';
  if (en == 'Completed') return 'সম্পন্ন';
  if (en == 'Failed') return 'কাজ সম্পন্ন হয়নি';
  if (en == 'Not set') return 'দেওয়া নেই';
  if (en == 'Optional' || en.endsWith('(optional)')) {
    return en.replaceAll('(optional)', '(ঐচ্ছিক)').replaceAll('Optional', 'ঐচ্ছিক');
  }

  final loadError = RegExp(r'^Could not load (.+)$');
  final mLoad = loadError.firstMatch(en);
  if (mLoad != null) {
    return '${_translateFragment(mLoad.group(1)!)} লোড করা যায়নি';
  }

  final couldNot = RegExp(r'^Could not (.+)$');
  final mCould = couldNot.firstMatch(en);
  if (mCould != null) {
    return '${_translateFragment(mCould.group(1)!)} করা যায়নি';
  }

  if (en.startsWith('Could not reach server')) {
    return 'সার্ভারে যোগাযোগ করা যায়নি। সংরক্ষিত তথ্য দেখানো হচ্ছে।';
  }

  if (key.endsWith('Empty') || key.contains('empty') || key.contains('Empty')) {
    if (en.contains('No ') && en.contains(' yet')) {
      return 'এখনো ${_translateFragment(en.replaceAll('No ', '').replaceAll(' yet.', '').replaceAll(' yet', ''))} নেই';
    }
    if (en == 'No results') return 'কিছু পাওয়া যায়নি';
    if (en == 'No data') return 'এখনো কোনো তথ্য নেই';
  }

  if (key.endsWith('Hint') || key.contains('hint') || key.contains('Subtitle')) {
    return _translateLongForm(en);
  }

  if (key.endsWith('Error') || key.contains('error')) {
    if (en.contains('Network')) return 'ইন্টারনেট সমস্যা। আবার চেষ্টা করুন।';
    if (en.contains('Session expired')) {
      return 'সময় শেষ। আবার প্রবেশ করুন।';
    }
  }

  return null;
}

String? _statusWord(String en) {
  return switch (en.trim()) {
    'All' => 'সব',
    'Active' => 'সক্রিয়',
    'Inactive' => 'বন্ধ',
    'Draft' => 'খসড়া',
    'Pending' => 'অপেক্ষমাণ',
    'Completed' => 'সম্পন্ন',
    'Cancelled' => 'বাতিল',
    'Failed' => 'কাজ সম্পন্ন হয়নি',
    'Success' => 'সফল',
    'Yes' => 'হ্যাঁ',
    'No' => 'না',
    'Weight' => 'ওজন',
    'Gain' => 'বৃদ্ধি',
    'Initial' => 'শুরু',
    'Current' => 'বর্তমান',
    'Scale' => 'মাপ',
    'Tape' => 'টেপ',
    'Estimate' => 'আনুমানিক',
    'Other' => 'অন্যান্য',
    'Optional' => 'ঐচ্ছিক',
    'Required' => 'প্রয়োজন',
    'Total' => 'মোট',
    'Today' => 'আজ',
    'Morning' => 'সকাল',
    'Evening' => 'সন্ধ্যা',
    'Normal' => 'সাধারণ',
    'Sections' => 'অংশ',
    _ => null,
  };
}

String _translateFragment(String fragment) {
  var f = fragment.trim();
  for (final e in _wordMap.entries) {
    f = f.replaceAll(e.key, e.value);
  }
  return f;
}

String _translateLongForm(String en) {
  var result = en;
  final sorted = _wordMap.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final word in sorted) {
    result = result.replaceAll(word, _wordMap[word]!);
  }
  for (final e in _sentenceFragments.entries) {
    result = result.replaceAll(e.key, e.value);
  }
  return result;
}

const _brokenFixes = <String, String>{
  'বাতিলled': 'বাতিল হয়েছে',
  'বাতিল appointment': 'সেবা বুকিং বাতিল',
  'সংরক্ষণ করুন profile': 'তথ্য সংরক্ষণ করুন',
  'যোগ করুন your': 'আপনার',
  'আপডেট করুন locations': 'লোকেশন আপডেট করুন',
  'আবার চেষ্টা করুন failed': 'আবার চেষ্টা করুন',
  'খামার location': 'খামারের লোকেশন',
  'লোকেশন / pen': 'লোকেশন / খামার',
};

const _wordMap = <String, String>{
  'Sign in': 'প্রবেশ করুন',
  'sign in': 'প্রবেশ করুন',
  'Sign up': 'নতুন অ্যাকাউন্ট খুলুন',
  'Log in': 'প্রবেশ করুন',
  'Log out': 'বের হন',
  'Welcome back': 'আবার স্বাগতম',
  'Try again': 'আবার চেষ্টা করুন',
  'Save': 'সংরক্ষণ করুন',
  'save': 'সংরক্ষণ',
  'Cancel': 'বাতিল',
  'Delete': 'মুছে ফেলুন',
  'Edit': 'সম্পাদনা',
  'Add': 'যোগ করুন',
  'Create': 'তৈরি করুন',
  'Update': 'আপডেট',
  'Remove': 'সরান',
  'Search': 'খুঁজুন',
  'Select': 'বেছে নিন',
  'Selected': 'নির্বাচিত',
  'Showing': 'দেখানো হচ্ছে',
  'Could not': 'যায়নি',
  'load': 'লোড',
  'your': 'আপনার',
  'farm': 'খামার',
  'Farm': 'খামার',
  'farms': 'খামার',
  'animals': 'পশু',
  'Animals': 'পশু',
  'animal': 'পশু',
  'Animal': 'পশু',
  'doctor': 'ডাক্তার',
  'Doctor': 'ডাক্তার',
  'location': 'লোকেশন',
  'Location': 'লোকেশন',
  'locations': 'লোকেশন',
  'profile': 'প্রোফাইল',
  'Profile': 'প্রোফাইল',
  'settings': 'সেটিংস',
  'Settings': 'সেটিংস',
  'offline': 'অফলাইন',
  'Offline': 'অফলাইন',
  'online': 'অনলাইন',
  'Online': 'অনলাইন',
  'network': 'ইন্টারনেট',
  'Network': 'ইন্টারনেট',
  'server': 'সার্ভার',
  'Server': 'সার্ভার',
  'batch': 'ব্যাচ',
  'Batch': 'ব্যাচ',
  'batches': 'ব্যাচ',
  'treatment': 'চিকিৎসা',
  'Treatment': 'চিকিৎসা',
  'vaccine': 'টিকা',
  'Vaccine': 'টিকা',
  'feed': 'খাদ্য',
  'Feed': 'খাদ্য',
  'milk': 'দুধ',
  'Milk': 'দুধ',
  'medicine': 'ওষুধ',
  'Medicine': 'ওষুধ',
  'inventory': 'মজুদ',
  'stock': 'মজুদ',
  'appointment': 'সেবা বুকিং',
  'Appointment': 'সেবা বুকিং',
  'optional': 'ঐচ্ছিক',
  'required': 'প্রয়োজন',
  'name': 'নাম',
  'Name': 'নাম',
  'date': 'তারিখ',
  'Date': 'তারিখ',
  'weight': 'ওজন',
  'Reason': 'কারণ',
  'reason': 'কারণ',
  'Failed': 'সম্পন্ন হয়নি',
  'failed': 'সম্পন্ন হয়নি',
  'success': 'সফল',
  'Success': 'সফল',
  'pending': 'অপেক্ষমাণ',
  'Pending': 'অপেক্ষমাণ',
  'completed': 'সম্পন্ন',
  'Completed': 'সম্পন্ন',
  'Fattening': 'মোটাতাজাকরণ',
  'fattening': 'মোটাতাজাকরণ',
  'Goal': 'লক্ষ্য',
  'goal': 'লক্ষ্য',
  'Target': 'লক্ষ্য',
  'target': 'লক্ষ্য',
  'Start': 'শুরু',
  'start': 'শুরু',
  'details': 'বিবরণ',
  'Details': 'বিবরণ',
  'history': 'তালিকা',
  'History': 'তালিকা',
  'record': 'তথ্য',
  'Record': 'তথ্য',
  'records': 'তথ্য',
  'section': 'অংশ',
  'Section': 'অংশ',
  'dashboard': 'ড্যাশবোর্ড',
  'Dashboard': 'ড্যাশবোর্ড',
  'notification': 'বার্তা',
  'Notification': 'বার্তা',
  'notifications': 'বার্তা',
  'field': 'তথ্য',
  'This field is required': 'এই তথ্য দিন',
  'Permission denied': 'এই কাজের অনুমতি নেই',
  'Something went wrong': 'সমস্যা হয়েছে',
  'Please try again': 'আবার চেষ্টা করুন',
  'Session expired': 'সময় শেষ',
  'development': 'ডেভেলপমেন্ট',
};

const _sentenceFragments = <String, String>{
  'Sign in to manage your farm, animals, and veterinary care.':
      'খামার, পশু ও ডাক্তারি সেবা দেখতে প্রবেশ করুন।',
  'Last signed in with {identifier}': 'শেষ প্রবেশ: {identifier}',
  'Add your name and location so we can personalize services for your farm.':
      'আপনার নাম ও লোকেশন দিন, যাতে খামারের সেবা ঠিকমতো মিলে।',
  'Add your name and location (union required; village optional) before using the app.':
      'অ্যাপ ব্যবহারের আগে নাম ও লোকেশন দিন (ইউনিয়ন প্রয়োজন; গ্রাম ঐচ্ছিক)।',
  'Select division, district, upazila, and union to save address':
      'ঠিকানা সংরক্ষণ করতে বিভাগ, জেলা, উপজেলা ও ইউনিয়ন বেছে নিন',
  'Showing saved locations (offline)':
      'সংরক্ষিত লোকেশন দেখানো হচ্ছে (অফলাইন)',
  'No locations match your search': 'আপনার খোঁজের সাথে কোনো লোকেশন মিলেনি',
  'Select your location': 'আপনার লোকেশন বেছে নিন',
  'Could not connect. Check your network and try again.':
      'সংযোগ হয়নি। ইন্টারনেট দেখে আবার চেষ্টা করুন।',
  'Google and Facebook sign-in coming soon.':
      'শীঘ্রই Google ও Facebook দিয়ে প্রবেশ যোগ হবে।',
  'Set up your farm location and add animals to get started.':
      'শুরু করতে খামারের লোকেশন ও পশু যোগ করুন।',
  'Could not load this section': 'এই অংশ লোড করা যায়নি',
  'Select your village to save the farm': 'খামার সংরক্ষণ করতে গ্রাম বেছে নিন',
  'Needs location': 'লোকেশন দরকার',
  'Your farm is linked to your profile location. Multiple farms and delete are not available yet.':
      'খামার আপনার প্রোফাইল লোকেশনের সাথে যুক্ত। একাধিক খামার ও মুছে ফেলা এখনো চালু নেই।',
};

const _curatedByEnglish = <String, String>{
  'This field is required': 'এই তথ্য দিন',
  'Welcome back': 'আবার স্বাগতম',
  'Sign in': 'প্রবেশ করুন',
  'Try again': 'আবার চেষ্টা করুন',
  'Cancel': 'বাতিল',
  'Save': 'সংরক্ষণ করুন',
  'Something went wrong': 'সমস্যা হয়েছে',
  'No results': 'কিছু পাওয়া যায়নি',
  'No data': 'এখনো কোনো তথ্য নেই',
};

const _curatedByKey = <String, String>{
  'loginTitle': 'প্রবেশ করুন',
  'loginWelcomeBack': 'আবার স্বাগতম',
  'loginWelcomeSubtitle':
      'খামার, পশু ও ডাক্তারি সেবা দেখতে প্রবেশ করুন।',
  'loginLastLogin': 'শেষ প্রবেশ: {identifier}',
  'loginLink': 'প্রবেশ করুন',
  'registerTitle': 'নতুন অ্যাকাউন্ট খুলুন',
  'fieldRequired': 'এই তথ্য দিন',
  'saveProfile': 'তথ্য সংরক্ষণ করুন',
  'profileLoadError': 'প্রোফাইল লোড করা যায়নি',
  'profileCompletionSubtitle':
      'আপনার নাম ও লোকেশন দিন, যাতে খামারের সেবা ঠিকমতো মিলে।',
  'profileCompletionAddressStep': 'খামারের লোকেশন',
  'profileCompletionHint':
      'অ্যাপ ব্যবহারের আগে নাম ও লোকেশন দিন (ইউনিয়ন প্রয়োজন; গ্রাম ঐচ্ছিক)।',
  'addressRequired':
      'ঠিকানা সংরক্ষণ করতে বিভাগ, জেলা, উপজেলা ও ইউনিয়ন বেছে নিন',
  'areaOfflineHint': 'সংরক্ষিত লোকেশন দেখানো হচ্ছে (অফলাইন)',
  'areaSearchNoResults': 'আপনার খোঁজের সাথে কোনো লোকেশন মিলেনি',
  'areaSelectedLocation': 'নির্বাচিত লোকেশন',
  'areaSelectLevel': 'আপনার লোকেশন বেছে নিন',
  'areaRefresh': 'লোকেশন আপডেট করুন',
  'locationSectionTitle': 'লোকেশন',
  'cancelAppointment': 'সেবা বুকিং বাতিল',
  'cancelledAtLabel': 'বাতিলের সময়',
  'cancelReasonLabel': 'কারণ (ঐচ্ছিক)',
  'retryFailed': 'আবার চেষ্টা করুন',
  'bootInitError': 'সংযোগ হয়নি। ইন্টারনেট দেখে আবার চেষ্টা করুন।',
  'bootRetry': 'আবার চেষ্টা করুন',
  'socialLoginComingSoon': 'শীঘ্রই Google ও Facebook দিয়ে প্রবেশ যোগ হবে।',
  'dashboardLoadError': 'ড্যাশবোর্ড লোড করা যায়নি',
  'dashboardOfflineError':
      'সার্ভারে যোগাযোগ করা যায়নি। সংরক্ষিত তথ্য দেখানো হচ্ছে।',
  'dashboardEmptyHint': 'শুরু করতে খামারের লোকেশন ও পশু যোগ করুন।',
  'dashboardRetry': 'আবার চেষ্টা করুন',
  'dashboardSectionError': 'এই অংশ লোড করা যায়নি',
  'farmLoadError': 'খামার লোড করা যায়নি',
  'farmRetry': 'আবার চেষ্টা করুন',
  'farmLocationRequired': 'খামার সংরক্ষণ করতে গ্রাম বেছে নিন',
  'farmFilterNeedsLocation': 'লোকেশন দরকার',
  'animalLoadError': 'পশুর তথ্য লোড করা যায়নি',
  'animalRetry': 'আবার চেষ্টা করুন',
  'batchLoadError': 'ব্যাচ লোড করা যায়নি',
  'batchRetry': 'আবার চেষ্টা করুন',
  'batchLocationLabel': 'লোকেশন / খামার',
  'drawerFatteningSection': 'মোটাতাজাকরণ',
  'fatteningListTitle': 'মোটাতাজাকরণ ব্যাচ',
  'fatteningCreateBatch': 'নতুন ব্যাচ তৈরি করুন',
  'fatteningBatchDetail': 'ব্যাচের বিবরণ',
  'fatteningBatchName': 'ব্যাচের নাম',
  'fatteningBatchGoal': 'লক্ষ্য (ঐচ্ছিক)',
  'fatteningTargetDate': 'লক্ষ্য তারিখ',
  'fatteningTargetDateOptional': 'দেওয়া নেই',
  'fatteningStartDate': 'শুরুর তারিখ',
  'fatteningSaveAndAddAnimals': 'সংরক্ষণ করে পশু যোগ করুন',
  'fatteningAddAnimals': 'পশু যোগ করুন',
  'fatteningStartBatch': 'মোটাতাজাকরণ শুরু',
  'languageTitle': 'ভাষা',
  'languageBangla': 'বাংলা',
  'languageEnglish': 'English',
  'homeGreetingMorningBn': 'সুপ্রভাত',
  'homeGreetingAfternoonBn': 'শুভ অপরাহ্ন',
  'homeGreetingEveningBn': 'শুভ সন্ধ্যা',
  'offlineModeBanner':
      'অফলাইন মোড — সর্বশেষ সংরক্ষিত তথ্য দেখানো হচ্ছে',
  'homeUniversalSearchHint': 'ডাক্তার, সেবা, এআই, চিকিৎসা খুঁজুন',
};
