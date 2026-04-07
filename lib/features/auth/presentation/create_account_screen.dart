import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../l10n/app_locale.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../shared/widgets/blue_loader_overlay.dart';
import '../data/auth_session_store.dart';
import '../data/firebase_auth_repository.dart';
import 'login_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  static const String routeName = '/create-account';

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  static const int _totalSteps = 4;

  final FirebaseAuthRepository _authRepository = FirebaseAuthRepository();
  int _currentStep = 0;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _vehicleType = 'car';

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _vehicleModelController.dispose();
    _registrationNumberController.dispose();
    _vehicleColorController.dispose();
    _vehicleYearController.dispose();
    _manufacturerController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_isLoading) return;

    if (_currentStep == 0) {
      if (_fullNameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.createAccountIdentityRequired)),
        );
        return;
      }
      setState(() => _currentStep += 1);
      return;
    }

    if (_currentStep == 1) {
      final hasVehicleData = _vehicleModelController.text.trim().isNotEmpty &&
          _registrationNumberController.text.trim().isNotEmpty &&
          _vehicleColorController.text.trim().isNotEmpty &&
          _vehicleYearController.text.trim().isNotEmpty &&
          _manufacturerController.text.trim().isNotEmpty;
      if (!hasVehicleData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.createAccountVehicleRequired)),
        );
        return;
      }
      setState(() => _currentStep += 1);
      return;
    }

    if (_currentStep == 2) {
      setState(() => _currentStep += 1);
      return;
    }

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.createAccountPasswordTooShort)),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.createAccountPasswordMismatch)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.registerUser(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: password,
        vehicleType: _vehicleType,
        vehicleModel: _vehicleModelController.text,
        vehicleNumber: _registrationNumberController.text,
        vehicleColor: _vehicleColorController.text,
        vehicleYear: _vehicleYearController.text,
        vehicleManufacturer: _manufacturerController.text,
      );
      await AuthSessionStore.saveLoggedInUsername(_emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.createAccountDone)),
      );
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_firebaseErrorMessage(e))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.authGenericError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _firebaseErrorMessage(FirebaseAuthException e) {
    final message = (e.message ?? '').toUpperCase();
    if (message.contains('CONFIGURATION_NOT_FOUND')) {
      return context.l10n.authFirebaseConfigMissing;
    }

    final code = e.code;
    switch (code) {
      case 'email-already-in-use':
        return context.l10n.authEmailAlreadyInUse;
      case 'invalid-email':
        return context.l10n.authInvalidEmail;
      case 'weak-password':
        return context.l10n.authWeakPassword;
      case 'network-request-failed':
        return context.l10n.authNetworkError;
      case 'firestore-permission-denied':
        return context.l10n.authFirestoreDisabled;
      case 'profile-write-failed':
        return context.l10n.authProfileSaveFailed;
      default:
        return context.l10n.authGenericError;
    }
  }

  void _onBack() {
    if (_isLoading) return;

    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
      return;
    }
    Navigator.of(context).maybePop();
  }

  String _stepTitle(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return context.l10n.createAccountTitle;
      case 1:
        return context.l10n.createAccountVehicleTitle;
      case 2:
        return context.l10n.createAccountReviewTitle;
      default:
        return context.l10n.createAccountPasswordTitle;
    }
  }

  String _stepSubtitle(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return context.l10n.createAccountIdentitySubtitle;
      case 1:
        return context.l10n.createAccountVehicleSubtitle;
      case 2:
        return context.l10n.createAccountReviewSubtitle;
      default:
        return context.l10n.createAccountPasswordSubtitle;
    }
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _IdentityStep(
          fullNameController: _fullNameController,
          emailController: _emailController,
        );
      case 1:
        return _VehicleStep(
          vehicleType: _vehicleType,
          onVehicleTypeChanged: (type) => setState(() => _vehicleType = type),
          vehicleModelController: _vehicleModelController,
          registrationNumberController: _registrationNumberController,
          vehicleColorController: _vehicleColorController,
          vehicleYearController: _vehicleYearController,
          manufacturerController: _manufacturerController,
        );
      case 2:
        return _ReviewStep(
          fullName: _fullNameController.text,
          email: _emailController.text,
          vehicleType: _vehicleType,
          vehicleModel: _vehicleModelController.text,
          vehicleNumber: _registrationNumberController.text,
          vehicleColor: _vehicleColorController.text,
          vehicleYear: _vehicleYearController.text,
          manufacturer: _manufacturerController.text,
        );
      default:
        return _PasswordStep(
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          obscurePassword: _obscurePassword,
          obscureConfirmPassword: _obscureConfirmPassword,
          onTogglePassword: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          onToggleConfirmPassword: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepLabels = [
      context.l10n.createAccountIdentityTab,
      context.l10n.createAccountVehicleTab,
      context.l10n.createAccountReviewTab,
      context.l10n.createAccountPasswordTab,
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.neutral,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.neutral,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _isLoading ? null : _onBack,
                          splashRadius: 22,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        Text(
                          context.l10n.createAccountBrand,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        const _AuthLanguageToggle(),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE2E6ED),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 4),
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(stepLabels.length, (index) {
                            final selected = index == _currentStep;
                            return Expanded(
                              child: Text(
                                stepLabels[index],
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  color: selected
                                      ? AppColors.primary
                                      : const Color(0xFF69707C),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth =
                                constraints.maxWidth / _totalSteps;
                            return Stack(
                              children: [
                                Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE1E6EE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  width: itemWidth * (_currentStep + 1),
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stepTitle(context),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E232B),
                              height: 0.98,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _stepSubtitle(context),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF676D77),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _buildStepContent(context),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == _totalSteps - 1
                                  ? context.l10n.createAccountCreateButton
                                  : context.l10n.createAccountContinueButton,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, size: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading) const BlueLoaderOverlay(),
          ],
        ),
      ),
    );
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    required this.fullNameController,
    required this.emailController,
  });

  final TextEditingController fullNameController;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(context.l10n.createAccountFullName),
          const SizedBox(height: 8),
          _InputTile(
            controller: fullNameController,
            icon: Icons.person_outline,
            hintText: context.l10n.createAccountFullNameHint,
          ),
          const SizedBox(height: 14),
          _SectionLabel(context.l10n.createAccountEmail),
          const SizedBox(height: 8),
          _InputTile(
            controller: emailController,
            icon: Icons.mail_outline_rounded,
            hintText: context.l10n.createAccountEmailHint,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.createAccountIdentityNote,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8B909A),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleStep extends StatelessWidget {
  const _VehicleStep({
    required this.vehicleType,
    required this.onVehicleTypeChanged,
    required this.vehicleModelController,
    required this.registrationNumberController,
    required this.vehicleColorController,
    required this.vehicleYearController,
    required this.manufacturerController,
  });

  final String vehicleType;
  final ValueChanged<String> onVehicleTypeChanged;
  final TextEditingController vehicleModelController;
  final TextEditingController registrationNumberController;
  final TextEditingController vehicleColorController;
  final TextEditingController vehicleYearController;
  final TextEditingController manufacturerController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _VehicleTypeCard(
              label: context.l10n.createAccountVehicleTypeCar,
              icon: Icons.directions_car_rounded,
              selected: vehicleType == 'car',
              onTap: () => onVehicleTypeChanged('car'),
            ),
            const SizedBox(width: 12),
            _VehicleTypeCard(
              label: context.l10n.createAccountVehicleTypeBike,
              icon: Icons.two_wheeler_rounded,
              selected: vehicleType == 'bike',
              onTap: () => onVehicleTypeChanged('bike'),
            ),
            const SizedBox(width: 12),
            _VehicleTypeCard(
              label: context.l10n.createAccountVehicleTypeVan,
              icon: Icons.airport_shuttle_rounded,
              selected: vehicleType == 'van',
              onTap: () => onVehicleTypeChanged('van'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(context.l10n.createAccountVehicleModel),
              const SizedBox(height: 8),
              _InputTile(
                controller: vehicleModelController,
                icon: Icons.directions_car_outlined,
                hintText: context.l10n.createAccountVehicleModelHint,
              ),
              const SizedBox(height: 12),
              _SectionLabel(context.l10n.createAccountVehicleNumber),
              const SizedBox(height: 8),
              _InputTile(
                controller: registrationNumberController,
                icon: Icons.confirmation_number_outlined,
                hintText: context.l10n.createAccountVehicleNumberHint,
              ),
              const SizedBox(height: 12),
              _SectionLabel(context.l10n.createAccountVehicleColor),
              const SizedBox(height: 8),
              _InputTile(
                controller: vehicleColorController,
                icon: Icons.palette_outlined,
                hintText: context.l10n.createAccountVehicleColorHint,
              ),
              const SizedBox(height: 12),
              _SectionLabel(context.l10n.createAccountVehicleYear),
              const SizedBox(height: 8),
              _InputTile(
                controller: vehicleYearController,
                icon: Icons.calendar_today_outlined,
                hintText: context.l10n.createAccountVehicleYearHint,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _SectionLabel(context.l10n.createAccountVehicleManufacturer),
              const SizedBox(height: 8),
              _InputTile(
                controller: manufacturerController,
                icon: Icons.precision_manufacturing_outlined,
                hintText: context.l10n.createAccountVehicleManufacturerHint,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.fullName,
    required this.email,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.vehicleColor,
    required this.vehicleYear,
    required this.manufacturer,
  });

  final String fullName;
  final String email;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleNumber;
  final String vehicleColor;
  final String vehicleYear;
  final String manufacturer;

  String _valueOrDash(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ReviewCard(
          title: context.l10n.createAccountReviewIdentitySection,
          icon: Icons.person_outline_rounded,
          items: [
            _ReviewItem(
              label: context.l10n.createAccountFullName,
              value: _valueOrDash(fullName),
            ),
            _ReviewItem(
              label: context.l10n.createAccountEmail,
              value: _valueOrDash(email),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ReviewCard(
          title: context.l10n.createAccountReviewVehicleSection,
          icon: Icons.directions_car_outlined,
          items: [
            _ReviewItem(
              label: context.l10n.createAccountVehicleType,
              value: _valueOrDash(vehicleType.toUpperCase()),
            ),
            _ReviewItem(
              label: context.l10n.createAccountVehicleModel,
              value: _valueOrDash(vehicleModel),
            ),
            _ReviewItem(
              label: context.l10n.createAccountVehicleNumber,
              value: _valueOrDash(vehicleNumber),
            ),
            _ReviewItem(
              label: context.l10n.createAccountVehicleColor,
              value: _valueOrDash(vehicleColor),
            ),
            _ReviewItem(
              label: context.l10n.createAccountVehicleYear,
              value: _valueOrDash(vehicleYear),
            ),
            _ReviewItem(
              label: context.l10n.createAccountVehicleManufacturer,
              value: _valueOrDash(manufacturer),
            ),
          ],
        ),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(context.l10n.createAccountPasswordField),
          const SizedBox(height: 8),
          _InputTile(
            controller: passwordController,
            icon: Icons.lock_outline_rounded,
            hintText: context.l10n.createAccountPasswordFieldHint,
            obscureText: obscurePassword,
            suffix: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF8A8F99),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SectionLabel(context.l10n.createAccountConfirmPasswordField),
          const SizedBox(height: 8),
          _InputTile(
            controller: confirmPasswordController,
            icon: Icons.lock_reset_rounded,
            hintText: context.l10n.createAccountPasswordFieldHint,
            obscureText: obscureConfirmPassword,
            suffix: IconButton(
              onPressed: onToggleConfirmPassword,
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF8A8F99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoNote(
            icon: Icons.security_rounded,
            title: context.l10n.createAccountPasswordRuleTitle,
            body: context.l10n.createAccountPasswordRuleBody,
          ),
          const SizedBox(height: 10),
          _InfoNote(
            icon: Icons.shield_outlined,
            title: context.l10n.createAccountPasswordSafetyTitle,
            body: context.l10n.createAccountPasswordSafetyBody,
          ),
        ],
      ),
    );
  }
}

class _VehicleTypeCard extends StatelessWidget {
  const _VehicleTypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 106,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE5E8EE),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF3F444C),
                size: 26,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : const Color(0xFF23272E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({
    required this.controller,
    required this.icon,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAECEF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF848A95)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2F353D),
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9DA3AD),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_ReviewItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                  radius: 3, backgroundColor: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF555B66),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Icon(icon, color: const Color(0xFFC2C7CF), size: 22),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A909B),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAECEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D323A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7D838D),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4F5661),
        letterSpacing: 0.6,
      ),
    );
  }
}

class _AuthLanguageToggle extends StatelessWidget {
  const _AuthLanguageToggle();

  @override
  Widget build(BuildContext context) {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final label =
        isUrdu ? context.l10n.switchToEnglish : context.l10n.switchToUrdu;
    final targetLocale = isUrdu ? const Locale('en') : const Locale('ur');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => AppLocale.setLocale(targetLocale),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF5272A5).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public_rounded,
                size: 17, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem {
  const _ReviewItem({required this.label, required this.value});

  final String label;
  final String value;
}
