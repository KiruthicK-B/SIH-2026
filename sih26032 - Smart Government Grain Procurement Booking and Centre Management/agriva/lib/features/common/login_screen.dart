import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/enums.dart';
import '../../repositories/repository_providers.dart';
import '../../state/auth_controller.dart';
import '../../state/locale_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/max_width_body.dart';

enum _LoginRole { farmer, operator, districtAdmin, stateAdmin }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  _LoginRole _role = _LoginRole.farmer;
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _staffError;
  String? _farmerError;
  String? _tempPasswordMessage;
  bool _sending = false;
  bool _staffBusy = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchRole(_LoginRole role) {
    setState(() {
      _role = role;
      _staffError = null;
      _farmerError = null;
      _tempPasswordMessage = null;
      switch (role) {
        case _LoginRole.farmer:
          break;
        case _LoginRole.operator:
          _employeeIdController.text = 'OP-Erode-01';
          _passwordController.text = 'agriva123';
          break;
        case _LoginRole.districtAdmin:
          _employeeIdController.text = 'DT-Erode';
          _passwordController.text = 'agriva123';
          break;
        case _LoginRole.stateAdmin:
          _employeeIdController.text = 'ST-Admin';
          _passwordController.text = 'agriva123';
          break;
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(() => _farmerError = 'Please enter a valid 10-digit mobile number (e.g. 9876543210)');
      return;
    }
    setState(() => _farmerError = null);
    setState(() => _sending = true);
    await ref.read(farmerOtpControllerProvider.notifier).sendOtp(phone);
    setState(() => _sending = false);
    if (mounted) context.push('/login/otp');
  }

  Future<void> _staffLogin() async {
    setState(() => _staffError = null);
    final employeeId = _employeeIdController.text.trim();
    final password = _passwordController.text;
    if (employeeId.isEmpty || password.isEmpty) {
      setState(() => _staffError = l10nFor(context).invalidCredentials);
      return;
    }
    await _directLoginAsStaff(employeeId, password);
  }

  Future<void> _directLoginAsStaff(String employeeId, String password) async {
    setState(() {
      _staffError = null;
      _staffBusy = true;
    });
    final admin = await ref
        .read(staffLoginControllerProvider.notifier)
        .attemptLogin(employeeId, password);
    if (!mounted) return;
    setState(() => _staffBusy = false);
    if (admin == null) {
      final l10n = AppLocalizations.of(context);
      final error = ref.read(staffLoginControllerProvider);
      setState(() {
        _staffError = error == StaffLoginError.locked
            ? l10n.accountLocked(10)
            : l10n.invalidCredentials;
      });
      return;
    }
    await ref.read(authControllerProvider.notifier).loginAsAdmin(admin);
    if (mounted) {
      final target = switch (admin.role) {
        UserRole.centreOperator => '/operator',
        UserRole.districtAdmin => '/district-admin',
        UserRole.stateAdmin => '/state-admin',
        _ => '/login',
      };
      context.go(target);
    }
  }

  Future<void> _directLoginAsFarmer(String phone) async {
    setState(() {
      _farmerError = null;
      _sending = true;
    });
    final farmer = await ref.read(farmerRepositoryProvider).findByPhone(phone);
    if (!mounted) return;
    setState(() => _sending = false);
    if (farmer == null) {
      setState(() => _farmerError = 'Farmer record not found for phone $phone.');
      return;
    }
    await ref.read(authControllerProvider.notifier).loginAsFarmer(farmer);
    if (mounted) context.go('/farmer');
  }

  Future<void> _forgotPassword() async {
    final employeeId = _employeeIdController.text.trim();
    if (employeeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Employee ID first')),
      );
      return;
    }
    final temp = await ref
        .read(staffLoginControllerProvider.notifier)
        .resetPassword(employeeId);
    setState(() {
      _tempPasswordMessage = temp == null
          ? 'No account found for Employee ID "$employeeId".'
          : 'Temporary Password: $temp';
    });
  }

  AppLocalizations l10nFor(BuildContext context) =>
      AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeControllerProvider) ?? const Locale('en');

    return Scaffold(
      backgroundColor: AgrivaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Government of India Header Banner
            _buildGovHeader(context, currentLocale),

            // Main Content Area
            Expanded(
              child: MaxWidthBody(
                maxWidth: 480,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Streamlined Brand Hero (Emblem only)
                      _buildBrandHero(),
                      const SizedBox(height: 14),

                      // 4-Role Segmented Selector (Farmer, Operator, District, State)
                      _buildRoleSelector(),
                      const SizedBox(height: 14),

                      // Form Container (Identical clean card styling for every role)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AgrivaColors.surfaceDark
                              : AgrivaColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AgrivaColors.borderDark
                                : AgrivaColors.border,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: switch (_role) {
                          _LoginRole.farmer => _buildFarmerPortal(l10n),
                          _LoginRole.operator => _buildOperatorPortal(l10n),
                          _LoginRole.districtAdmin => _buildDistrictAdminPortal(l10n),
                          _LoginRole.stateAdmin => _buildStateAdminPortal(l10n),
                        },
                      ),
                      const SizedBox(height: 18),

                      // Official Footer Note
                      _buildPortalFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGovHeader(BuildContext context, Locale currentLocale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AgrivaColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AgrivaColors.borderDark : AgrivaColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // National Flag Tricolor Accent Strip
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GOVERNMENT OF INDIA',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AgrivaColors.primary,
                  ),
                ),
                Text(
                  'Ministry of Consumer Affairs, Food & Public Distribution',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AgrivaColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Language Switcher Dropdown
          PopupMenuButton<Locale>(
            tooltip: 'Select Language',
            initialValue: currentLocale,
            onSelected: (locale) {
              ref.read(localeControllerProvider.notifier).setLocale(locale);
            },
            itemBuilder: (context) => supportedAgrivaLocales.map((l) {
              final isSelected = l.languageCode == currentLocale.languageCode;
              return PopupMenuItem<Locale>(
                value: l,
                child: Row(
                  children: [
                    Text(
                      localeDisplayNames[l.languageCode] ?? l.languageCode,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AgrivaColors.primary : AgrivaColors.textPrimary,
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 16, color: AgrivaColors.primary),
                    ],
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AgrivaColors.primaryLight50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AgrivaColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate_rounded, size: 13, color: AgrivaColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    localeDisplayNames[currentLocale.languageCode] ?? 'English',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AgrivaColors.primary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: AgrivaColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHero() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Image.asset(
          'assets/images/app_icon.png',
          height: 64,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2E23) : const Color(0xFFE8ECE9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _rolePill(_LoginRole.farmer, 'Farmer', Icons.agriculture_rounded),
          _rolePill(_LoginRole.operator, 'Operator', Icons.storefront_outlined),
          _rolePill(_LoginRole.districtAdmin, 'District', Icons.location_city_outlined),
          _rolePill(_LoginRole.stateAdmin, 'State', Icons.account_balance_outlined),
        ],
      ),
    );
  }

  Widget _rolePill(_LoginRole role, String label, IconData icon) {
    final selected = _role == role;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? AgrivaColors.surfaceDark : Colors.white;
    final selectedFg = isDark ? AgrivaColors.primaryAccentDark : AgrivaColors.primary;
    final unselectedFg = isDark ? AgrivaColors.textSecondaryDark : AgrivaColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchRole(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: selected && isDark ? Border.all(color: AgrivaColors.borderDark) : null,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? selectedFg : unselectedFg,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? selectedFg : (isDark ? AgrivaColors.textPrimaryDark : AgrivaColors.textPrimary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- 1. Farmer Portal ----------------
  Widget _buildFarmerPortal(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Farmer Login',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimary),
        ),
        const SizedBox(height: 2),
        const Text(
          'Enter your 10-digit registered mobile number to continue.',
          style: TextStyle(fontSize: 12, color: AgrivaColors.textSecondary),
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: l10n.mobileNumber,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          hint: '98765 43210',
          maxLength: 10,
          prefix: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AgrivaColors.border, width: 1)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🇮🇳', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text(
                  '+91',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimary),
                ),
              ],
            ),
          ),
        ),

        if (_farmerError != null) ...[
          const SizedBox(height: 8),
          Text(
            _farmerError!,
            style: const TextStyle(color: AgrivaColors.error, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],

        const SizedBox(height: 14),
        PrimaryButton(
          label: l10n.sendOtp,
          loading: _sending,
          icon: Icons.arrow_forward_rounded,
          onPressed: _sendOtp,
        ),

        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () => context.push('/register'),
            child: const Text(
              'New Farmer? Register for MSP Procurement',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AgrivaColors.primary),
            ),
          ),
        ),

        const Divider(height: 22),

        const Row(
          children: [
            Icon(Icons.bolt, size: 14, color: AgrivaColors.primary),
            SizedBox(width: 4),
            Text(
              '1-Tap Demo Sign-In (Select Farmer):',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AgrivaColors.primaryDark),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _oneTapButton(
          label: 'R. Murugan (Approved • Ready to Book)',
          phone: '9876543210',
          badgeColor: AgrivaColors.success,
          onTap: () => _directLoginAsFarmer('9876543210'),
        ),
        const SizedBox(height: 6),
        _oneTapButton(
          label: 'K. Senthil (Pending Approval >48h)',
          phone: '9876543211',
          badgeColor: AgrivaColors.warning,
          onTap: () => _directLoginAsFarmer('9876543211'),
        ),
        const SizedBox(height: 6),
        _oneTapButton(
          label: 'M. Palanisamy (In Live Queue #T003)',
          phone: '9876543212',
          badgeColor: AgrivaColors.primary,
          onTap: () => _directLoginAsFarmer('9876543212'),
        ),
      ],
    );
  }

  // ---------------- 2. Centre Operator Portal ----------------
  Widget _buildOperatorPortal(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Centre Operator Login',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimary),
        ),
        const SizedBox(height: 2),
        const Text(
          'Official login for Tamil Nadu grain procurement centres.',
          style: TextStyle(fontSize: 12, color: AgrivaColors.textSecondary),
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'Operator Employee ID',
          controller: _employeeIdController,
          hint: 'e.g. OP-Erode-01',
          prefixIcon: const Icon(Icons.storefront_outlined, size: 20, color: AgrivaColors.primary),
        ),
        const SizedBox(height: 12),

        AppTextField(
          label: l10n.password,
          controller: _passwordController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: _obscurePassword,
          hint: '••••••••',
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AgrivaColors.primary),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: AgrivaColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        if (_staffError != null) ...[
          const SizedBox(height: 8),
          Text(
            _staffError!,
            style: const TextStyle(color: AgrivaColors.error, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],

        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Sign In as Centre Operator',
          loading: _staffBusy,
          icon: Icons.login_rounded,
          onPressed: _staffLogin,
        ),

        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: _forgotPassword,
            child: Text(
              l10n.forgotPassword,
              style: const TextStyle(fontSize: 12, color: AgrivaColors.textSecondary),
            ),
          ),
        ),

        if (_tempPasswordMessage != null) _buildTempPasswordBadge(),

        const Divider(height: 18),

        const Row(
          children: [
            Icon(Icons.bolt, size: 14, color: AgrivaColors.primary),
            SizedBox(width: 4),
            Text(
              '1-Tap Demo Sign-In (Select Centre):',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AgrivaColors.primaryDark),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _oneTapStaffButton(
          label: 'Erode Hub (OP-Erode-01)',
          id: 'OP-Erode-01',
          roleBadge: 'OPERATOR',
          badgeColor: const Color(0xFF1565C0),
          onTap: () => _directLoginAsStaff('OP-Erode-01', 'agriva123'),
        ),
        const SizedBox(height: 6),
        _oneTapStaffButton(
          label: 'Tiruppur APMC Depot (OP-Tiruppur-01)',
          id: 'OP-Tiruppur-01',
          roleBadge: 'OPERATOR',
          badgeColor: const Color(0xFF1565C0),
          onTap: () => _directLoginAsStaff('OP-Tiruppur-01', 'agriva123'),
        ),
        const SizedBox(height: 6),
        _oneTapStaffButton(
          label: 'Thanjavur Mandi (OP-Thanjavur-01)',
          id: 'OP-Thanjavur-01',
          roleBadge: 'OPERATOR',
          badgeColor: const Color(0xFF1565C0),
          onTap: () => _directLoginAsStaff('OP-Thanjavur-01', 'agriva123'),
        ),
      ],
    );
  }

  // ---------------- 3. District Admin Portal ----------------
  Widget _buildDistrictAdminPortal(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'District Admin Login',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimary),
        ),
        const SizedBox(height: 2),
        const Text(
          'Official login for District Grain Procurement Administration.',
          style: TextStyle(fontSize: 12, color: AgrivaColors.textSecondary),
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'District Officer ID',
          controller: _employeeIdController,
          hint: 'e.g. DT-Erode',
          prefixIcon: const Icon(Icons.location_city_outlined, size: 20, color: AgrivaColors.primary),
        ),
        const SizedBox(height: 12),

        AppTextField(
          label: l10n.password,
          controller: _passwordController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: _obscurePassword,
          hint: '••••••••',
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AgrivaColors.primary),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: AgrivaColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        if (_staffError != null) ...[
          const SizedBox(height: 8),
          Text(
            _staffError!,
            style: const TextStyle(color: AgrivaColors.error, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],

        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Sign In as District Admin',
          loading: _staffBusy,
          icon: Icons.login_rounded,
          onPressed: _staffLogin,
        ),

        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: _forgotPassword,
            child: Text(
              l10n.forgotPassword,
              style: const TextStyle(fontSize: 12, color: AgrivaColors.textSecondary),
            ),
          ),
        ),

        if (_tempPasswordMessage != null) _buildTempPasswordBadge(),

        const Divider(height: 18),

        const Row(
          children: [
            Icon(Icons.bolt, size: 14, color: AgrivaColors.primary),
            SizedBox(width: 4),
            Text(
              '1-Tap Demo Sign-In (Select District):',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AgrivaColors.primaryDark),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _oneTapStaffButton(
          label: 'DT-Erode (Thiru. S. Kandasamy, IAS)',
          id: 'DT-Erode',
          roleBadge: 'DISTRICT',
          badgeColor: const Color(0xFF6A1B9A),
          onTap: () => _directLoginAsStaff('DT-Erode', 'agriva123'),
        ),
        const SizedBox(height: 6),
        _oneTapStaffButton(
          label: 'DT-Tiruppur (Tmt. R. Jayanthi, IAS)',
          id: 'DT-Tiruppur',
          roleBadge: 'DISTRICT',
          badgeColor: const Color(0xFF6A1B9A),
          onTap: () => _directLoginAsStaff('DT-Tiruppur', 'agriva123'),
        ),
        const SizedBox(height: 6),
        _oneTapStaffButton(
          label: 'DT-Thanjavur (Thiru. D. Baskaran, IAS)',
          id: 'DT-Thanjavur',
          roleBadge: 'DISTRICT',
          badgeColor: const Color(0xFF6A1B9A),
          onTap: () => _directLoginAsStaff('DT-Thanjavur', 'agriva123'),
        ),
      ],
    );
  }

  // ---------------- 4. State Admin Portal ----------------
  Widget _buildStateAdminPortal(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'State Admin Login',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimary),
        ),
        const SizedBox(height: 2),
        const Text(
          'Tamil Nadu State Grain Procurement & Policy Directorate.',
          style: TextStyle(fontSize: 12, color: AgrivaColors.textSecondary),
        ),
        const SizedBox(height: 14),

        AppTextField(
          label: 'State Officer ID',
          controller: _employeeIdController,
          hint: 'e.g. ST-Admin',
          prefixIcon: const Icon(Icons.account_balance_outlined, size: 20, color: AgrivaColors.primary),
        ),
        const SizedBox(height: 12),

        AppTextField(
          label: l10n.password,
          controller: _passwordController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: _obscurePassword,
          hint: '••••••••',
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AgrivaColors.primary),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: AgrivaColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        if (_staffError != null) ...[
          const SizedBox(height: 8),
          Text(
            _staffError!,
            style: const TextStyle(color: AgrivaColors.error, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],

        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Sign In as State Admin',
          loading: _staffBusy,
          icon: Icons.login_rounded,
          onPressed: _staffLogin,
        ),

        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: _forgotPassword,
            child: Text(
              l10n.forgotPassword,
              style: const TextStyle(fontSize: 12, color: AgrivaColors.textSecondary),
            ),
          ),
        ),

        if (_tempPasswordMessage != null) _buildTempPasswordBadge(),

        const Divider(height: 18),

        const Row(
          children: [
            Icon(Icons.bolt, size: 14, color: AgrivaColors.primary),
            SizedBox(width: 4),
            Text(
              '1-Tap Demo Sign-In (State Directorate):',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AgrivaColors.primaryDark),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _oneTapStaffButton(
          label: 'ST-Admin (Dr. K. Vijayakumar, IAS)',
          id: 'ST-Admin',
          roleBadge: 'STATE HEAD',
          badgeColor: const Color(0xFFE65100),
          onTap: () => _directLoginAsStaff('ST-Admin', 'agriva123'),
        ),
      ],
    );
  }

  Widget _buildTempPasswordBadge() {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AgrivaColors.warningBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AgrivaColors.gold.withValues(alpha: 0.3)),
      ),
      child: Text(
        _tempPasswordMessage!,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AgrivaColors.warning),
      ),
    );
  }

  Widget _oneTapButton({
    required String label,
    required String phone,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = isDark ? const Color(0xFF1E3025) : const Color(0xFFF6F8F6);
    final btnBorder = isDark ? AgrivaColors.borderDark : AgrivaColors.border;
    final textCol = isDark ? AgrivaColors.textPrimaryDark : AgrivaColors.textPrimary;
    final arrowCol = isDark ? AgrivaColors.primaryAccentDark : AgrivaColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: btnBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: btnBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: badgeColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textCol),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 14, color: arrowCol),
          ],
        ),
      ),
    );
  }

  Widget _oneTapStaffButton({
    required String label,
    required String id,
    required String roleBadge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = isDark ? const Color(0xFF1E3025) : const Color(0xFFF6F8F6);
    final btnBorder = isDark ? AgrivaColors.borderDark : AgrivaColors.border;
    final textCol = isDark ? AgrivaColors.textPrimaryDark : AgrivaColors.textPrimary;
    final arrowCol = isDark ? AgrivaColors.primaryAccentDark : AgrivaColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: btnBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: btnBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                roleBadge,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: badgeColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textCol),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 14, color: arrowCol),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 13, color: AgrivaColors.textMuted),
        SizedBox(width: 5),
        Text(
          'National Informatics Centre & DoCA Infrastructure',
          style: TextStyle(fontSize: 10.5, color: AgrivaColors.textMuted),
        ),
      ],
    );
  }
}
