// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'அக்ரிவா';

  @override
  String get appTagline =>
      'ஸ்மார்ட் கொள்முதல் | சிறந்த திட்டமிடல் | மகிழ்ச்சியான விவசாயிகள்';

  @override
  String get chooseLanguage => 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get continueLabel => 'தொடரவும்';

  @override
  String get cancel => 'ரத்துசெய்';

  @override
  String get confirm => 'உறுதிப்படுத்து';

  @override
  String get back => 'பின்செல்';

  @override
  String get retry => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get save => 'சேமி';

  @override
  String get edit => 'திருத்து';

  @override
  String get delete => 'நீக்கு';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get logoutConfirmTitle => 'வெளியேறவா?';

  @override
  String get logoutConfirmBody =>
      'உங்கள் கணக்கை அணுக மீண்டும் உள்நுழைய வேண்டும்.';

  @override
  String get yes => 'ஆம்';

  @override
  String get no => 'இல்லை';

  @override
  String get seeAll => 'அனைத்தையும் காண்க';

  @override
  String get loading => 'ஏற்றுகிறது…';

  @override
  String get somethingWentWrong => 'ஏதோ தவறு நடந்தது';

  @override
  String get noDataYet => 'இதுவரை இங்கு எதுவும் இல்லை';

  @override
  String get roleFarmer => 'விவசாயி';

  @override
  String get roleStaff => 'பணியாளர்';

  @override
  String get roleCentreOperator => 'மைய இயக்குநர்';

  @override
  String get roleDistrictAdmin => 'மாவட்ட நிர்வாகி';

  @override
  String get roleStateAdmin => 'மாநில நிர்வாகி';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navBookings => 'முன்பதிவுகள்';

  @override
  String get navAlerts => 'அறிவிப்புகள்';

  @override
  String get navProfile => 'சுயவிவரம்';

  @override
  String get navDashboard => 'டாஷ்போர்டு';

  @override
  String get navCentres => 'மையங்கள்';

  @override
  String get navAnalytics => 'பகுப்பாய்வு';

  @override
  String get navQueue => 'வரிசை';

  @override
  String get navPayments => 'பணம் செலுத்துதல்';

  @override
  String get navGrievances => 'புகார்கள்';

  @override
  String get navMore => 'மேலும்';

  @override
  String get loginTitle => 'அக்ரிவா உள்நுழைவு';

  @override
  String get mobileNumber => 'மொபைல் எண்';

  @override
  String get sendOtp => 'ஓடிபி அனுப்பு';

  @override
  String get enterOtp => 'ஓடிபி உள்ளிடவும்';

  @override
  String get verifyAndContinue => 'சரிபார்த்து தொடரவும்';

  @override
  String resendOtpIn(int seconds) {
    return '$seconds வினாடிகளில் ஓடிபியை மீண்டும் அனுப்பு';
  }

  @override
  String get resendOtp => 'ஓடிபியை மீண்டும் அனுப்பு';

  @override
  String get otpIncorrect => 'தவறான ஓடிபி. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get otpExpired =>
      'இந்த ஓடிபியின் காலம் முடிந்தது. மீண்டும் அனுப்பவும்.';

  @override
  String otpTooManyAttempts(int minutes) {
    return 'பல தவறான முயற்சிகள். $minutes நிமிடத்தில் மீண்டும் முயற்சிக்கவும்.';
  }

  @override
  String get employeeId => 'பணியாளர் ஐடி';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get login => 'உள்நுழை';

  @override
  String get forgotPassword => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get invalidCredentials => 'தவறான பணியாளர் ஐடி அல்லது கடவுச்சொல்.';

  @override
  String get wrongRoleTab =>
      'இந்த ஐடி வேறு பாத்திரத்திற்கு சொந்தமானது. தாவலை மாற்றவும்.';

  @override
  String accountLocked(int minutes) {
    return 'கணக்கு பூட்டப்பட்டது. $minutes நிமிடத்தில் முயற்சிக்கவும்.';
  }

  @override
  String get newFarmerHint =>
      'புதிய விவசாயியா? கணக்கு இல்லையெனில் ஓடிபி சரிபார்ப்புக்குப் பிறகு பதிவு தானாகத் தொடங்கும்.';
}
