// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'एग्रिवा';

  @override
  String get appTagline => 'स्मार्ट खरीद | बेहतर योजना | खुशहाल किसान';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get continueLabel => 'जारी रखें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get back => 'वापस';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get save => 'सहेजें';

  @override
  String get edit => 'संपादित करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get logoutConfirmTitle => 'लॉग आउट करें?';

  @override
  String get logoutConfirmBody =>
      'अपने खाते तक पहुंचने के लिए आपको फिर से लॉग इन करना होगा।';

  @override
  String get yes => 'हां';

  @override
  String get no => 'नहीं';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get loading => 'लोड हो रहा है…';

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get noDataYet => 'अभी तक यहां कुछ नहीं है';

  @override
  String get roleFarmer => 'किसान';

  @override
  String get roleStaff => 'कर्मचारी';

  @override
  String get roleCentreOperator => 'केंद्र संचालक';

  @override
  String get roleDistrictAdmin => 'जिला प्रशासक';

  @override
  String get roleStateAdmin => 'राज्य प्रशासक';

  @override
  String get navHome => 'होम';

  @override
  String get navBookings => 'बुकिंग';

  @override
  String get navAlerts => 'सूचनाएं';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get navDashboard => 'डैशबोर्ड';

  @override
  String get navCentres => 'केंद्र';

  @override
  String get navAnalytics => 'विश्लेषण';

  @override
  String get navQueue => 'कतार';

  @override
  String get navPayments => 'भुगतान';

  @override
  String get navGrievances => 'शिकायतें';

  @override
  String get navMore => 'अधिक';

  @override
  String get loginTitle => 'एग्रिवा लॉगिन';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get sendOtp => 'ओटीपी भेजें';

  @override
  String get enterOtp => 'ओटीपी दर्ज करें';

  @override
  String get verifyAndContinue => 'सत्यापित करें और जारी रखें';

  @override
  String resendOtpIn(int seconds) {
    return '$seconds सेकंड में ओटीपी पुनः भेजें';
  }

  @override
  String get resendOtp => 'ओटीपी पुनः भेजें';

  @override
  String get otpIncorrect => 'गलत ओटीपी। कृपया पुनः प्रयास करें।';

  @override
  String get otpExpired => 'यह ओटीपी समाप्त हो गया है। कृपया पुनः भेजें।';

  @override
  String otpTooManyAttempts(int minutes) {
    return 'बहुत अधिक गलत प्रयास। $minutes मिनट में पुनः प्रयास करें।';
  }

  @override
  String get employeeId => 'कर्मचारी आईडी';

  @override
  String get password => 'पासवर्ड';

  @override
  String get login => 'लॉगिन';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get invalidCredentials => 'गलत कर्मचारी आईडी या पासवर्ड।';

  @override
  String get wrongRoleTab =>
      'यह आईडी किसी अन्य भूमिका से संबंधित है। कृपया टैब बदलें।';

  @override
  String accountLocked(int minutes) {
    return 'खाता लॉक है। $minutes मिनट में पुनः प्रयास करें।';
  }

  @override
  String get newFarmerHint =>
      'नए किसान हैं? खाता न मिलने पर ओटीपी सत्यापन के बाद पंजीकरण स्वतः शुरू हो जाएगा।';
}
