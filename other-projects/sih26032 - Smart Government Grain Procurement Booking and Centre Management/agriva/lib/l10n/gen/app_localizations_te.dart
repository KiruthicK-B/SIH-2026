// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appName => 'అగ్రివా';

  @override
  String get appTagline =>
      'స్మార్ట్ సేకరణ | మెరుగైన ప్రణాళిక | సంతోషకరమైన రైతులు';

  @override
  String get chooseLanguage => 'మీ భాషను ఎంచుకోండి';

  @override
  String get continueLabel => 'కొనసాగించు';

  @override
  String get cancel => 'రద్దు చేయి';

  @override
  String get confirm => 'నిర్ధారించు';

  @override
  String get back => 'వెనుకకు';

  @override
  String get retry => 'మళ్లీ ప్రయత్నించండి';

  @override
  String get save => 'సేవ్ చేయి';

  @override
  String get edit => 'సవరించు';

  @override
  String get delete => 'తొలగించు';

  @override
  String get logout => 'లాగ్ అవుట్';

  @override
  String get logoutConfirmTitle => 'లాగ్ అవుట్ చేయాలా?';

  @override
  String get logoutConfirmBody =>
      'మీ ఖాతాను యాక్సెస్ చేయడానికి మీరు మళ్లీ లాగిన్ చేయాలి.';

  @override
  String get yes => 'అవును';

  @override
  String get no => 'కాదు';

  @override
  String get seeAll => 'అన్నీ చూడండి';

  @override
  String get loading => 'లోడ్ అవుతోంది…';

  @override
  String get somethingWentWrong => 'ఏదో తప్పు జరిగింది';

  @override
  String get noDataYet => 'ఇక్కడ ఇంకా ఏమీ లేదు';

  @override
  String get roleFarmer => 'రైతు';

  @override
  String get roleStaff => 'సిబ్బంది';

  @override
  String get roleCentreOperator => 'కేంద్ర నిర్వాహకుడు';

  @override
  String get roleDistrictAdmin => 'జిల్లా అడ్మిన్';

  @override
  String get roleStateAdmin => 'రాష్ట్ర అడ్మిన్';

  @override
  String get navHome => 'హోమ్';

  @override
  String get navBookings => 'బుకింగ్‌లు';

  @override
  String get navAlerts => 'హెచ్చరికలు';

  @override
  String get navProfile => 'ప్రొఫైల్';

  @override
  String get navDashboard => 'డాష్‌బోర్డ్';

  @override
  String get navCentres => 'కేంద్రాలు';

  @override
  String get navAnalytics => 'విశ్లేషణలు';

  @override
  String get navQueue => 'క్యూ';

  @override
  String get navPayments => 'చెల్లింపులు';

  @override
  String get navGrievances => 'ఫిర్యాదులు';

  @override
  String get navMore => 'మరిన్ని';

  @override
  String get loginTitle => 'అగ్రివా లాగిన్';

  @override
  String get mobileNumber => 'మొబైల్ నంబర్';

  @override
  String get sendOtp => 'OTP పంపండి';

  @override
  String get enterOtp => 'OTP నమోదు చేయండి';

  @override
  String get verifyAndContinue => 'ధృవీకరించి కొనసాగించండి';

  @override
  String resendOtpIn(int seconds) {
    return '$seconds సెకన్లలో OTP మళ్లీ పంపండి';
  }

  @override
  String get resendOtp => 'OTP మళ్లీ పంపండి';

  @override
  String get otpIncorrect => 'తప్పు OTP. మళ్లీ ప్రయత్నించండి.';

  @override
  String get otpExpired => 'ఈ OTP గడువు ముగిసింది. దయచేసి మళ్లీ పంపండి.';

  @override
  String otpTooManyAttempts(int minutes) {
    return 'చాలా తప్పు ప్రయత్నాలు. $minutes నిమిషాల్లో మళ్లీ ప్రయత్నించండి.';
  }

  @override
  String get employeeId => 'ఉద్యోగి ID';

  @override
  String get password => 'పాస్‌వర్డ్';

  @override
  String get login => 'లాగిన్';

  @override
  String get forgotPassword => 'పాస్‌వర్డ్ మర్చిపోయారా?';

  @override
  String get invalidCredentials => 'తప్పు ఉద్యోగి ID లేదా పాస్‌వర్డ్.';

  @override
  String get wrongRoleTab =>
      'ఈ ID వేరే పాత్రకు చెందినది. దయచేసి ట్యాబ్ మార్చండి.';

  @override
  String accountLocked(int minutes) {
    return 'ఖాతా లాక్ చేయబడింది. $minutes నిమిషాల్లో మళ్లీ ప్రయత్నించండి.';
  }

  @override
  String get newFarmerHint =>
      'కొత్త రైతా? ఖాతా కనుగొనబడకపోతే OTP ధృవీకరణ తర్వాత నమోదు స్వయంచాలకంగా ప్రారంభమవుతుంది.';
}
