import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/providers/auth_provider.dart';
import '../../../app/cupertino_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String _selectedRole = 'member';
  String? _error;
  String? _prefixWarning;
  bool _loading = false;
  bool _obscurePassword = true;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _errorCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _errorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _codeController.addListener(() => setState(() { _prefixWarning = null; }));
    _passwordController.addListener(() => setState(() {}));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeCtrl.forward();
        _slideCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _errorCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;

    if (code.isEmpty) {
      setState(() => _error = 'Please enter your code');
      _errorCtrl.forward(from: 0);
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your password');
      _errorCtrl.forward(from: 0);
      return;
    }

    final prefix = code.isNotEmpty ? code[0] : '';
    setState(() => _prefixWarning = null);
    if (_selectedRole == 'trainer' && prefix == 'M') {
      setState(() => _prefixWarning = 'This is a member account, trainer access only.');
      return;
    }
    if (_selectedRole == 'member' && prefix == 'T') {
      setState(() => _prefixWarning = 'This is a trainer account, member access only.');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await ref.read(authProvider.notifier).signInWithCode(
        _codeController.text.trim().toUpperCase(),
        _passwordController.text,
      );

      if (!mounted) return;
      final profile = ref.read(authProvider).valueOrNull;
      if (profile == null) return;

      if (profile.role != _selectedRole) {
        setState(() {
          _prefixWarning = profile.role == 'member'
            ? 'This account is a member, not a trainer'
            : 'This account is a trainer, not a member';
          _loading = false;
        });
        return;
      }

      context.go(
        profile.role == 'trainer' ? '/trainer/dashboard' : '/member/home',
      );
    } catch (e) {
      setState(() => _error = e.toString());
      _errorCtrl.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.3,
            colors: [Color(0xFF1A0A2E), Color(0xFF0D0D1A), Color(0xFF000000)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogoSection(),
                      const SizedBox(height: 36),
                      _buildLoginCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CupertinoAppColors.purple.withAlpha(60),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('assets/logo.png', width: 120, height: 120, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: CupertinoAppColors.groupedBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CupertinoAppColors.separator.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoAppColors.purple.withAlpha(30),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FitTrack',
              style: sfText(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: CupertinoAppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your fitness journey starts here',
              style: sfText(
                fontSize: 13,
                color: CupertinoAppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            _buildRoleToggle(),
            const SizedBox(height: 22),
            _buildFloatingField(
              controller: _codeController,
              focusNode: _emailFocus,
              label: 'Code',
              icon: CupertinoIcons.mail,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              prefixWidget: Text(
                '#',
                style: sfText(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CupertinoAppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildFloatingField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: 'Password',
              icon: CupertinoIcons.lock,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
              suffixIcon: Icon(
                _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                color: CupertinoAppColors.textTertiary,
                size: 18,
              ),
              onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _errorCtrl,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoAppColors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CupertinoAppColors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_circle,
                        color: CupertinoAppColors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: sfText(
                            color: CupertinoAppColors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _error = null),
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: CupertinoAppColors.red,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_prefixWarning != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: CupertinoAppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CupertinoAppColors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.info_circle_fill,
                      color: CupertinoAppColors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _prefixWarning!,
                        style: sfText(
                          color: CupertinoAppColors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _prefixWarning = null),
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: CupertinoAppColors.orange,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: GestureDetector(
                onTap: _loading ? null : _login,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [
                        CupertinoAppColors.purple,
                        CupertinoAppColors.primaryBlue,
                      ],
                    ),
                  ),
                  child: _loading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoAppColors.textPrimary,
                        )
                      : Text(
                          'Sign In',
                          style: sfText(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: CupertinoAppColors.textPrimary,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'v1.0.0 \u00b7 Powered by FitTrack',
              style: sfText(
                fontSize: 11,
                color: CupertinoAppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: CupertinoAppColors.cardElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoAppColors.separator.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          _roleTab(
            label: 'MEMBER',
            icon: CupertinoIcons.person,
            isSelected: _selectedRole == 'member',
            onTap: () => setState(() { _selectedRole = 'member'; _prefixWarning = null; }),
          ),
          _roleTab(
            label: 'TRAINER',
            icon: CupertinoIcons.person,
            isSelected: _selectedRole == 'trainer',
            onTap: () => setState(() { _selectedRole = 'trainer'; _prefixWarning = null; }),
          ),
        ],
      ),
    );
  }

  Widget _roleTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _loading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      CupertinoAppColors.purple,
                      CupertinoAppColors.primaryBlue,
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: CupertinoAppColors.purple.withAlpha(60),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? CupertinoAppColors.textPrimary
                    : CupertinoAppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: sfText(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? CupertinoAppColors.textPrimary
                      : CupertinoAppColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? prefixWidget,
    Widget? suffixIcon,
    VoidCallback? onSuffixTap,
    void Function(String)? onSubmitted,
  }) {
    final isFloating = focusNode.hasFocus || controller.text.isNotEmpty;

    return Semantics(
      label: '$label input',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CupertinoTextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            onSubmitted: onSubmitted,
            style: sfText(fontSize: 14, color: CupertinoAppColors.textPrimary),
            padding: const EdgeInsets.only(left: 44, right: 44, top: 18, bottom: 18),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoAppColors.separator.withOpacity(0.4)),
            ),
          ),
          Positioned(
            left: 16,
            top: 18,
            child: prefixWidget ?? Icon(icon, color: CupertinoAppColors.textTertiary, size: 18),
          ),
          if (suffixIcon != null)
            Positioned(
              right: 16,
              top: 18,
              child: GestureDetector(onTap: onSuffixTap, child: suffixIcon),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            left: 44,
            top: isFloating ? -7 : 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: CupertinoAppColors.groupedBackground,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                style: sfText(
                  fontSize: isFloating ? 11 : 14,
                  color: CupertinoAppColors.textTertiary,
                ),
                child: Text(label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


