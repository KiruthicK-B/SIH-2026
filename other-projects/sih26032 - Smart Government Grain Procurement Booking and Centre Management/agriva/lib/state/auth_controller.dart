import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/admin_user.dart';
import '../models/enums.dart';
import '../models/farmer.dart';
import '../models/user.dart';
import '../repositories/repository_providers.dart';

const _sessionPrefKey = 'agriva_session'; // "roleName|id"

/// The logged-in session (README §2 — persists across restarts until
/// explicit logout). Farmer sessions resolve against [Farmer]; staff
/// sessions (centreOperator/districtAdmin/stateAdmin) resolve against
/// [AdminUser] — both collapse to the same thin [AppUser] the router and
/// UI actually consume.
final authControllerProvider = NotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

class AuthController extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    // Start at login on each app launch as requested ("each time please ask for sign in")
    return null;
  }

  Future<void> _persist(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionPrefKey, '${user.role.name}|${user.id}');
  }

  Future<void> loginAsFarmer(Farmer farmer) async {
    final user = AppUser(
      id: farmer.id,
      name: farmer.name,
      role: UserRole.farmer,
    );
    state = user;
    await _persist(user);
  }

  Future<void> loginAsAdmin(AdminUser admin) async {
    final user = AppUser(
      id: admin.id,
      name: admin.name,
      role: admin.role,
      centreId: admin.centreId,
      district: admin.district,
    );
    state = user;
    await _persist(user);
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = prefs.getString(_sessionPrefKey);
      if (session == null || !session.contains('|')) return;

      final parts = session.split('|');
      final roleName = parts[0];
      final id = parts[1];

      if (roleName == UserRole.farmer.name) {
        final farmer = await ref.read(farmerRepositoryProvider).getById(id);
        if (farmer != null) {
          state = AppUser(
            id: farmer.id,
            name: farmer.name,
            role: UserRole.farmer,
          );
        }
      } else {
        final admin = await ref.read(adminRepositoryProvider).getById(id);
        if (admin != null) {
          state = AppUser(
            id: admin.id,
            name: admin.name,
            role: admin.role,
            centreId: admin.centreId,
            district: admin.district,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionPrefKey);
  }
}

/// Farmer phone+OTP login flow state (README §2 edge cases: 30s resend
/// cooldown, wrong-OTP retry, expiry, max-attempts lockout). Ephemeral —
/// not persisted, lives only for the duration of the login screen.
class FarmerOtpState {
  final String phone;
  final String? sentOtp;
  final DateTime? sentAt;
  final int wrongAttempts;
  final DateTime? lockedUntil;
  final bool isNewFarmer;

  const FarmerOtpState({
    this.phone = '',
    this.sentOtp,
    this.sentAt,
    this.wrongAttempts = 0,
    this.lockedUntil,
    this.isNewFarmer = false,
  });

  bool get otpSent => sentOtp != null;
  bool get isLocked =>
      lockedUntil != null && lockedUntil!.isAfter(DateTime.now());
  bool get isExpired =>
      sentAt != null && DateTime.now().difference(sentAt!).inMinutes >= 5;
  int get resendCooldownSecondsRemaining {
    if (sentAt == null) return 0;
    final elapsed = DateTime.now().difference(sentAt!).inSeconds;
    return (30 - elapsed).clamp(0, 30);
  }

  FarmerOtpState copyWith({
    String? phone,
    String? sentOtp,
    DateTime? sentAt,
    int? wrongAttempts,
    DateTime? lockedUntil,
    bool clearLock = false,
    bool? isNewFarmer,
  }) => FarmerOtpState(
    phone: phone ?? this.phone,
    sentOtp: sentOtp ?? this.sentOtp,
    sentAt: sentAt ?? this.sentAt,
    wrongAttempts: wrongAttempts ?? this.wrongAttempts,
    lockedUntil: clearLock ? null : (lockedUntil ?? this.lockedUntil),
    isNewFarmer: isNewFarmer ?? this.isNewFarmer,
  );
}

enum OtpVerifyResult { success, wrong, expired, locked }

final farmerOtpControllerProvider =
    NotifierProvider<FarmerOtpController, FarmerOtpState>(
      FarmerOtpController.new,
    );

class FarmerOtpController extends Notifier<FarmerOtpState> {
  @override
  FarmerOtpState build() => const FarmerOtpState();

  /// Mock OTP generation — logged/shown on screen since there's no real SMS
  /// gateway in Phase 1 (README §2).
  Future<String> sendOtp(String phone) async {
    final otp = (100000 + Random().nextInt(900000)).toString();
    final farmer = await ref.read(farmerRepositoryProvider).findByPhone(phone);
    state = FarmerOtpState(
      phone: phone,
      sentOtp: otp,
      sentAt: DateTime.now(),
      isNewFarmer: farmer == null,
    );
    return otp;
  }

  OtpVerifyResult verifyOtp(String entered) {
    if (state.isLocked) return OtpVerifyResult.locked;
    if (state.isExpired) return OtpVerifyResult.expired;
    if (entered != state.sentOtp) {
      final attempts = state.wrongAttempts + 1;
      final locked = attempts >= 3
          ? DateTime.now().add(const Duration(minutes: 2))
          : null;
      state = state.copyWith(wrongAttempts: attempts, lockedUntil: locked);
      return locked != null ? OtpVerifyResult.locked : OtpVerifyResult.wrong;
    }
    return OtpVerifyResult.success;
  }

  void reset() => state = const FarmerOtpState();
}

/// Staff (Employee ID + password) login flow (README §2: lockout after
/// repeated failures, mocked forgot-password reset).
enum StaffLoginError { invalidCredentials, locked }

final staffLoginControllerProvider =
    NotifierProvider<StaffLoginController, StaffLoginError?>(
      StaffLoginController.new,
    );

class StaffLoginController extends Notifier<StaffLoginError?> {
  @override
  StaffLoginError? build() => null;

  Future<AdminUser?> attemptLogin(String employeeId, String password) async {
    final repo = ref.read(adminRepositoryProvider);
    final admin = await repo.findByEmployeeId(employeeId);
    if (admin == null) {
      state = StaffLoginError.invalidCredentials;
      return null;
    }
    if (admin.isLocked) {
      state = StaffLoginError.locked;
      return null;
    }
    if (admin.passwordHash != password) {
      final attempts = admin.loginAttempts + 1;
      final locked = attempts >= 5
          ? DateTime.now().add(const Duration(minutes: 10))
          : null;
      await repo.save(
        admin.copyWith(loginAttempts: attempts, lockedUntil: locked),
      );
      state = locked != null
          ? StaffLoginError.locked
          : StaffLoginError.invalidCredentials;
      return null;
    }
    await repo.save(admin.copyWith(loginAttempts: 0, clearLock: true));
    state = null;
    return admin;
  }

  /// Mocked reset (README §2): generates a temporary password shown on
  /// screen, since there's no email/SMS backend yet.
  Future<String?> resetPassword(String employeeId) async {
    final repo = ref.read(adminRepositoryProvider);
    final admin = await repo.findByEmployeeId(employeeId);
    if (admin == null) return null;
    final temp = 'Agv${100000 + Random().nextInt(900000)}';
    await repo.save(
      admin.copyWith(passwordHash: temp, loginAttempts: 0, clearLock: true),
    );
    return temp;
  }

  int lockMinutesRemaining(AdminUser admin) {
    if (admin.lockedUntil == null) return 0;
    return admin.lockedUntil!.difference(DateTime.now()).inMinutes + 1;
  }
}
