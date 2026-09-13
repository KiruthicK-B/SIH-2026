// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Agriva';

  @override
  String get appTagline =>
      'Smart Procurement | Better Planning | Happier Farmers';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get continueLabel => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmBody =>
      'You\'ll need to log in again to access your account.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get seeAll => 'See all';

  @override
  String get loading => 'Loading…';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get noDataYet => 'Nothing here yet';

  @override
  String get roleFarmer => 'Farmer';

  @override
  String get roleStaff => 'Staff';

  @override
  String get roleCentreOperator => 'Centre Operator';

  @override
  String get roleDistrictAdmin => 'District Admin';

  @override
  String get roleStateAdmin => 'State Admin';

  @override
  String get navHome => 'Home';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navProfile => 'Profile';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCentres => 'Centres';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navQueue => 'Queue';

  @override
  String get navPayments => 'Payments';

  @override
  String get navGrievances => 'Grievances';

  @override
  String get navMore => 'More';

  @override
  String get loginTitle => 'Agriva Login';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String get verifyAndContinue => 'Verify & Continue';

  @override
  String resendOtpIn(int seconds) {
    return 'Resend OTP in ${seconds}s';
  }

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get otpIncorrect => 'Incorrect OTP. Please try again.';

  @override
  String get otpExpired => 'This OTP has expired. Please resend.';

  @override
  String otpTooManyAttempts(int minutes) {
    return 'Too many incorrect attempts. Try again in $minutes min.';
  }

  @override
  String get employeeId => 'Employee ID';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get invalidCredentials => 'Incorrect Employee ID or password.';

  @override
  String get wrongRoleTab =>
      'This ID belongs to a different role. Please switch tabs.';

  @override
  String accountLocked(int minutes) {
    return 'Account locked. Try again in $minutes min.';
  }

  @override
  String get newFarmerHint =>
      'New farmer? Registration starts automatically after OTP verification if no account is found.';
}
